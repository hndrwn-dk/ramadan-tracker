import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/insights/insights_aggregator.dart';
import 'package:ramadan_tracker/insights/models.dart';
import 'package:ramadan_tracker/insights/task_registry.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/insights/widgets/task_card.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  int _selectedTimeframe = 0; // 0: Today, 1: 7 Days, 2: Season

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => ref.read(tabIndexProvider.notifier).state = 0,
        ),
        title: const Text('Insights'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildInsights(context, ref, season);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInsights(BuildContext context, WidgetRef ref, season) {
    final seasonId = season.id;
    final days = season.days;
    final startDate = season.startDate;

    return FutureBuilder<InsightsResult>(
      key: ValueKey(_selectedTimeframe), // Rebuild when timeframe changes
      future: _loadInsightsData(ref, seasonId, days, startDate, _selectedTimeframe),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(context, ref);
        }

        final result = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeframe selector
              _buildTimeframeSelector(),
              const SizedBox(height: 24),

              // Coach Summary Card
              _buildCoachSummaryCard(context, ref, result.overallSummary, days),
              const SizedBox(height: 24),

              // Highlights
              if (result.highlights.isNotEmpty) ...[
                _buildHighlightsSection(context, result.highlights),
                const SizedBox(height: 24),
              ],

              // Task Insights
              FutureBuilder<String?>(
                future: ref.read(databaseProvider).kvSettingsDao.getValue('sedekah_currency'),
                builder: (context, currencySnapshot) {
                  final currency = currencySnapshot.data ?? 'IDR';
                  return _buildTaskInsightsSection(context, result.taskSummaries, currency);
                },
              ),
              const SizedBox(height: 24),

              // Trends Card
              _buildTrendsCard(context, result),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeframeSelector() {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 0, label: Text('Today')),
        ButtonSegment(value: 1, label: Text('7 Days')),
        ButtonSegment(value: 2, label: Text('Season')),
      ],
      selected: {_selectedTimeframe},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          _selectedTimeframe = newSelection.first;
        });
      },
    );
  }

  Widget _buildCoachSummaryCard(
    BuildContext context,
    WidgetRef ref,
    OverallSummary summary,
    int totalDays,
  ) {
    final currentDayIndex = ref.read(currentDayIndexProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) {
          return PremiumCard(
            child: Text('No season found'),
          );
        }

        return FutureBuilder<Map<String, dynamic>>(
          future: _getTodayScoreAndStreak(ref, season.id, currentDayIndex, _selectedTimeframe),
          builder: (context, snapshot) {
            final todayScore = snapshot.data?['score'] ?? summary.scoreToday;
            final streak = snapshot.data?['streak'] ?? summary.currentStreakDays;
            final completionPercent = (todayScore / 100).clamp(0.0, 1.0);

            return PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today Score',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${todayScore.round()}',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          ref.read(tabIndexProvider.notifier).state = 0;
                        },
                        icon: const Icon(Icons.today, size: 18),
                        label: const Text('Go to Today'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _getExplanation(todayScore),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(context, Icons.local_fire_department,
                          'Streak: $streak days'),
                      _buildChip(
                          context,
                          Icons.check_circle,
                          'Completed: ${(completionPercent * 100).round()}%'),
                      _buildChip(context, Icons.calendar_today, 'Day $currentDayIndex of $totalDays'),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => PremiumCard(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => PremiumCard(
        child: Text('Error loading season'),
      ),
    );
  }

  Future<Map<String, dynamic>> _getTodayScoreAndStreak(
    WidgetRef ref,
    int seasonId,
    int dayIndex,
    int timeframe, // 0: Today, 1: 7 Days, 2: Season
  ) async {
    final database = ref.read(databaseProvider);
    final allHabits = await ref.read(habitsProvider.future);
    final seasonHabits = await ref.read(seasonHabitsProvider(seasonId).future);
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);

    final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();
    final score = await CompletionService.calculateCompletionScore(
      seasonId: seasonId,
      dayIndex: dayIndex,
      enabledHabits: enabledHabits,
      entries: entries.map((e) => DailyEntryModel(
        seasonId: e.seasonId,
        dayIndex: e.dayIndex,
        habitId: e.habitId,
        valueBool: e.valueBool,
        valueInt: e.valueInt,
        note: e.note,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
      )).toList(),
      database: database,
      allHabits: allHabits,
    );

    // Calculate streak based on timeframe
    int streak;
    if (timeframe == 0) {
      // Today: Only show 1 if today is completed, otherwise 0
      final fastingEntry = entries.firstWhere(
        (e) => e.habitId == 1,
        orElse: () => DailyEntry(
          seasonId: seasonId,
          dayIndex: dayIndex,
          habitId: 1,
          valueBool: false,
          updatedAt: 0,
        ),
      );
      streak = fastingEntry.valueBool == true ? 1 : 0;
    } else {
      // 7 Days or Season: Show total streak
      streak = await CompletionService.calculateStreak(
        seasonId: seasonId,
        currentDayIndex: dayIndex,
        database: database,
      );
    }

    return {
      'score': score,
      'streak': streak,
    };
  }

  String _getExplanation(double score) {
    if (score >= 80) {
      return "Excellent! You're on track with most tasks completed.";
    } else if (score >= 60) {
      return "Good progress! A few tasks still need attention.";
    } else if (score >= 40) {
      return "You're making progress. Keep going!";
    } else {
      return "Start tracking to build momentum.";
    }
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildHighlightsSection(BuildContext context, List<Highlight> highlights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Highlights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length,
            itemBuilder: (context, index) {
              final highlight = highlights[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 12),
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        highlight.icon,
                        size: 32,
                        color: highlight.colorHint ??
                            Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              highlight.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              highlight.subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNextActionsSection(
    BuildContext context,
    WidgetRef ref,
    List<NextAction> actions,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...actions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: PremiumCard(
                onTap: action.onTap,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(action.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.label,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    if (action.quickValue != null)
                      OutlinedButton(
                        onPressed: action.onTap,
                        child: Text(action.quickValue!),
                      ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildTaskInsightsSection(
    BuildContext context,
    Map<TaskKey, TaskInsightSummary> taskSummaries,
    String sedekahCurrency,
  ) {
    final currentDayIndex = ref.read(currentDayIndexProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    // Check if we're in the last 10 days (for Itikaf)
    final isInLast10Days = seasonAsync.when(
      data: (season) {
        if (season == null) return false;
        final last10Start = season.days - 9;
        return currentDayIndex >= last10Start && currentDayIndex > 0;
      },
      loading: () => false,
      error: (_, __) => false,
    );

    // Filter out Itikaf if not in last 10 days
    final filteredSummaries = taskSummaries.entries.where((entry) {
      if (entry.key == TaskKey.itikaf && !isInLast10Days) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...filteredSummaries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TaskCard(
                taskKey: entry.key,
                summary: entry.value,
                sedekahCurrency: sedekahCurrency,
                onTap: () {
                  // TODO: Open task detail sheet
                },
              ),
            )),
      ],
    );
  }

  Widget _buildTrendsCard(BuildContext context, InsightsResult result) {
    // Build completion score trend based on selected timeframe
    final trendData = <FlSpot>[];
    final currentDayIndex = ref.read(currentDayIndexProvider);
    
    // Get day range based on selected timeframe
    int startDay;
    int endDay;
    switch (_selectedTimeframe) {
      case 0: // Today
        startDay = currentDayIndex;
        endDay = currentDayIndex;
        break;
      case 1: // 7 Days
        startDay = (currentDayIndex - 6).clamp(1, currentDayIndex);
        endDay = currentDayIndex;
        break;
      case 2: // Season
      default:
        startDay = 1;
        endDay = currentDayIndex;
        break;
    }
    
    // Build trend data from dayCompletions
    int relativeDay = 1;
    for (int day = startDay; day <= endDay; day++) {
      final completion = result.dayCompletions[day] ?? 0.0;
      final score = completion * 100; // Convert to 0-100 scale
      trendData.add(FlSpot(relativeDay.toDouble(), score));
      relativeDay++;
    }

    // For "Today" filter, chart is not useful (only 1 data point)
    if (_selectedTimeframe == 0 && trendData.length == 1) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (trendData.isNotEmpty)
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minX: 1,
                  maxX: trendData.length.toDouble(),
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}%',
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          // Show actual day index, not relative day
                          final dayIndex = startDay + value.toInt() - 1;
                          if (dayIndex >= startDay && dayIndex <= endDay) {
                            return Text(
                              'Day $dayIndex',
                              style: Theme.of(context).textTheme.bodySmall,
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendData,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Theme.of(context).colorScheme.primary,
                            strokeWidth: 2,
                            strokeColor: Theme.of(context).colorScheme.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No trend data available'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking today to see insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(tabIndexProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.today),
              label: const Text('Go to Today'),
            ),
          ],
        ),
      ),
    );
  }

  Future<InsightsResult> _loadInsightsData(
    WidgetRef ref,
    int seasonId,
    int days,
    DateTime startDate,
    int timeframe, // 0: Today, 1: 7 Days, 2: Season
  ) async {
    final database = ref.read(databaseProvider);

    // Use currentDayIndexProvider for consistency with other screens
    final currentDayIndex = ref.read(currentDayIndexProvider);
    final currentDayIndexClamped = currentDayIndex.clamp(1, days);

    // Determine day range based on timeframe
    int startDayIndex;
    int endDayIndex;
    switch (timeframe) {
      case 0: // Today
        startDayIndex = currentDayIndexClamped;
        endDayIndex = currentDayIndexClamped;
        break;
      case 1: // 7 Days
        startDayIndex = (currentDayIndexClamped - 6).clamp(1, days);
        endDayIndex = currentDayIndexClamped;
        break;
      case 2: // Season
      default:
        startDayIndex = 1;
        endDayIndex = currentDayIndexClamped;
        break;
    }

    // Load all data
    final allHabits = await ref.read(habitsProvider.future);
    final seasonHabits = await ref.read(seasonHabitsProvider(seasonId).future);
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(seasonId);
    final allQuranDailyData = await database.quranDailyDao.getAllDaily(seasonId);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(seasonId, startDayIndex, endDayIndex);
    final allNotes = await database.notesDao.getDayNotes(seasonId, null); // Get all notes for the season
    
    // Filter entries and quran data based on timeframe
    final filteredEntries = allEntries.where((e) => 
      e.dayIndex >= startDayIndex && e.dayIndex <= endDayIndex
    ).toList();
    final filteredQuranDailyData = allQuranDailyData.where((q) => 
      q.dayIndex >= startDayIndex && q.dayIndex <= endDayIndex
    ).toList();
    final filteredNotes = allNotes.where((n) => 
      n.dayIndex != null && n.dayIndex! >= startDayIndex && n.dayIndex! <= endDayIndex
    ).toList();
    
    // Load Sedekah currency
    final sedekahCurrency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';

    // Convert entries to models
    final entryModels = filteredEntries.map((e) => DailyEntryModel(
          seasonId: e.seasonId,
          dayIndex: e.dayIndex,
          habitId: e.habitId,
          valueBool: e.valueBool,
          valueInt: e.valueInt,
          note: e.note,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
        )).toList();

    // Build enabled tasks set
    final enabledTasks = <TaskKey>{};
    final targets = <TaskKey, int?>{};

    for (final sh in seasonHabits.where((s) => s.isEnabled)) {
      final habit = allHabits.firstWhere((h) => h.id == sh.habitId);
      final taskKey = TaskRegistry.getTaskKeyByHabitKey(habit.key);
      if (taskKey != null) {
        enabledTasks.add(taskKey);
        targets[taskKey] = sh.targetValue;
      }
    }

    // Create profile
    final profile = RamadanProfile(
      seasonId: seasonId,
      startDate: startDate,
      days: days,
      enabledTasks: enabledTasks,
      targets: targets,
    );

    // Aggregate insights
    return InsightsAggregator.aggregate(
      profile: profile,
      allEntries: entryModels,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      quranDailyData: filteredQuranDailyData,
      prayerDetails: allPrayerDetails,
      notes: filteredNotes,
      todayDayIndex: currentDayIndexClamped,
      sedekahCurrency: sedekahCurrency,
      startDayIndex: startDayIndex,
      endDayIndex: endDayIndex,
    );
  }
}

