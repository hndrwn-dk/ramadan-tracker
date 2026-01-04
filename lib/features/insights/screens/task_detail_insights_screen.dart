import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/models/habit_stats.dart';
import 'package:ramadan_tracker/features/insights/services/insights_service.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

class TaskDetailInsightsScreen extends ConsumerStatefulWidget {
  final String habitKey;
  final InsightsRange range;
  final int seasonId;

  const TaskDetailInsightsScreen({
    super.key,
    required this.habitKey,
    required this.range,
    required this.seasonId,
  });

  @override
  ConsumerState<TaskDetailInsightsScreen> createState() => _TaskDetailInsightsScreenState();
}

class _TaskDetailInsightsScreenState extends ConsumerState<TaskDetailInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getHabitDisplayName(widget.habitKey)),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) return const Center(child: Text('No season found'));
          return habitsAsync.when(
            data: (habits) {
              final habit = habits.firstWhere((h) => h.key == widget.habitKey);
              return FutureBuilder<Map<String, dynamic>>(
                future: _loadTaskData(season, habit),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(context, data),
                        const SizedBox(height: 24),
                        _buildTrendChart(context, data),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, ref, habit),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadTaskData(SeasonModel season, habit) async {
    final database = ref.read(databaseProvider);
    final seasonHabits = await ref.read(seasonHabitsProvider(widget.seasonId).future);
    final allHabits = await ref.read(habitsProvider.future);
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(widget.seasonId);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(widget.seasonId);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(
      widget.seasonId,
      1,
      season.days,
    );

    // Get insights data for the range
    final insightsData = await InsightsService.generateInsightsData(
      rangeType: widget.range,
      season: season,
      currentDayIndex: ref.read(currentDayIndexProvider),
      database: database,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
    );

    final stats = insightsData.perHabitStats[widget.habitKey];

    return {
      'stats': stats,
      'insightsData': insightsData,
    };
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> data) {
    final stats = data['stats'] as HabitStats?;
    if (stats == null) return const SizedBox.shrink();

    String title = _getRangeTitle();
    String subtitle = _getRangeSubtitle(data);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, Map<String, dynamic> data) {
    final insightsData = data['insightsData'] as InsightsData;
    final stats = data['stats'] as HabitStats?;

    if (widget.range == InsightsRange.today) {
      // Show breakdown list for Today
      return _buildTodayBreakdown(context, stats);
    } else {
      // Show trend chart for 7 Days and Season
      return _buildTrendChartWidget(context, insightsData, stats);
    }
  }

  Widget _buildTodayBreakdown(BuildContext context, HabitStats? stats) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Score Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          // Show completion states and score drivers
          Text(
            'Completion states and score drivers will be shown here',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChartWidget(BuildContext context, InsightsData insightsData, HabitStats? stats) {
    // Build trend chart based on range
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (insightsData.trendSeries.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: insightsData.trendSeries.asMap().entries.map((e) {
                      return FlSpot(e.key.toDouble(), e.value.score.toDouble());
                    }).toList(),
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, habit) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // Navigate to Today and scroll to task (secondary CTA)
              ref.read(tabIndexProvider.notifier).state = 0;
              Navigator.pop(context);
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Log now'),
          ),
        ),
        if (_canAdjustTarget(habit)) ...[
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _showAdjustTargetSheet(context, ref, habit);
              },
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Adjust target'),
            ),
          ),
        ],
      ],
    );
  }

  bool _canAdjustTarget(habit) {
    return widget.habitKey == 'quran_pages' || 
           widget.habitKey == 'dhikr' || 
           widget.habitKey == 'sedekah';
  }

  void _showAdjustTargetSheet(BuildContext context, WidgetRef ref, habit) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _AdjustTargetSheet(
        habitKey: widget.habitKey,
        seasonId: widget.seasonId,
        habitId: habit.id,
      ),
    );
  }

  String _getRangeTitle() {
    switch (widget.range) {
      case InsightsRange.today:
        return 'Today Breakdown';
      case InsightsRange.sevenDays:
        return '7-Day Analytics';
      case InsightsRange.season:
        return 'Season Analytics';
    }
  }

  String _getRangeSubtitle(Map<String, dynamic> data) {
    final stats = data['stats'] as HabitStats?;
    if (stats == null) return '';
    // Return key metrics based on habit type
    return 'Key metrics will be shown here';
  }

  String _getHabitDisplayName(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return 'Fasting';
      case 'quran_pages':
        return 'Quran';
      case 'dhikr':
        return 'Dhikr';
      case 'taraweeh':
        return 'Taraweeh';
      case 'sedekah':
        return 'Sedekah';
      case 'prayers':
        return '5 Prayers';
      case 'itikaf':
        return 'I\'tikaf';
      default:
        return habitKey;
    }
  }
}

class _AdjustTargetSheet extends ConsumerStatefulWidget {
  final String habitKey;
  final int seasonId;
  final int habitId;

  const _AdjustTargetSheet({
    required this.habitKey,
    required this.seasonId,
    required this.habitId,
  });

  @override
  ConsumerState<_AdjustTargetSheet> createState() => _AdjustTargetSheetState();
}

class _AdjustTargetSheetState extends ConsumerState<_AdjustTargetSheet> {
  double _targetValue = 0;

  @override
  void initState() {
    super.initState();
    _loadCurrentTarget();
  }

  Future<void> _loadCurrentTarget() async {
    final database = ref.read(databaseProvider);
    if (widget.habitKey == 'quran_pages') {
      final plan = await database.quranPlanDao.getPlan(widget.seasonId);
      setState(() {
        _targetValue = plan?.dailyTargetPages?.toDouble() ?? 20.0;
      });
    } else if (widget.habitKey == 'dhikr') {
      final plan = await database.dhikrPlanDao.getPlan(widget.seasonId);
      setState(() {
        _targetValue = plan?.dailyTarget?.toDouble() ?? 100.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Adjust Target',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Text('Target: ${_targetValue.round()}'),
          Slider(
            value: _targetValue,
            min: 1,
            max: widget.habitKey == 'quran_pages' ? 100 : 1000,
            divisions: widget.habitKey == 'quran_pages' ? 99 : 999,
            label: _targetValue.round().toString(),
            onChanged: (value) {
              setState(() {
                _targetValue = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _saveTarget();
                    Navigator.pop(context);
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveTarget() async {
    final database = ref.read(databaseProvider);
    if (widget.habitKey == 'quran_pages') {
      final plan = await database.quranPlanDao.getPlan(widget.seasonId);
      if (plan != null) {
        await database.quranPlanDao.setPlan(QuranPlanData(
          seasonId: widget.seasonId,
          pagesPerJuz: plan.pagesPerJuz,
          juzTargetPerDay: plan.juzTargetPerDay,
          dailyTargetPages: _targetValue.round(),
          totalJuz: plan.totalJuz,
          totalPages: plan.totalPages,
          catchupCapPages: plan.catchupCapPages,
          createdAt: plan.createdAt,
        ));
      }
    } else if (widget.habitKey == 'dhikr') {
      final plan = await database.dhikrPlanDao.getPlan(widget.seasonId);
      if (plan != null) {
        await database.dhikrPlanDao.setPlan(DhikrPlanData(
          seasonId: widget.seasonId,
          dailyTarget: _targetValue.round(),
          createdAt: plan.createdAt,
        ));
      }
    }
  }
}

