import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/providers/insights_provider.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';

/// Refactored Insights Screen with proper range-based scoring and comparison.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  InsightsRange _selectedRange = InsightsRange.today;

  @override
  Widget build(BuildContext context) {
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
      body: ref.watch(currentSeasonProvider).when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildInsights(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInsights(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsDataProvider(_selectedRange));

    return insightsAsync.when(
      data: (data) {
        if (data.daysCount == 0) {
          return _buildEmptyState(context, ref);
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeframeSelector(),
              const SizedBox(height: 24),
              _buildSummaryCard(context, ref, data),
              const SizedBox(height: 24),
              _buildHighlightsSection(context, ref, data),
              const SizedBox(height: 24),
              _buildTaskInsightsSection(context, ref, data),
              const SizedBox(height: 24),
              if (data.trendSeries.length > 1) ...[
                _buildTrendsCard(context, data),
                const SizedBox(height: 24),
              ],
              if (_selectedRange == InsightsRange.season) ...[
                _buildCompareSeasonsSection(context, ref),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildTimeframeSelector() {
    return SegmentedButton<InsightsRange>(
      segments: const [
        ButtonSegment(value: InsightsRange.today, label: Text('Today')),
        ButtonSegment(value: InsightsRange.sevenDays, label: Text('7 Days')),
        ButtonSegment(value: InsightsRange.season, label: Text('Season')),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (Set<InsightsRange> newSelection) {
        setState(() {
          _selectedRange = newSelection.first;
        });
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, InsightsData data) {
    final currentDayIndex = ref.read(currentDayIndexProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();

        String title;
        String? subtitle;
        List<Widget> chips = [];

        switch (_selectedRange) {
          case InsightsRange.today:
            title = 'Today Score';
            final completionPercent = data.avgScore / 100.0;
            chips = [
              _buildChip(context, Icons.local_fire_department, 'Streak: ${data.currentStreak} days'),
              _buildChip(
                context,
                Icons.check_circle,
                completionPercent >= 1.0 ? '100% Complete' : '${data.avgScore}% Complete',
              ),
              _buildChip(context, Icons.calendar_today, 'Day $currentDayIndex of ${season.days}'),
            ];
            break;
          case InsightsRange.sevenDays:
            title = '7-Day Average Score';
            subtitle = 'Total: ${data.totalScore}/${data.daysCount * 100}';
            final perfectDays = (data.completionRate * data.daysCount).round();
            chips = [
              _buildChip(context, Icons.local_fire_department, 'Best streak: ${data.bestStreak} days'),
              _buildChip(context, Icons.check_circle, '$perfectDays/${data.daysCount} perfect'),
            ];
            break;
          case InsightsRange.season:
            title = 'Season Average Score';
            subtitle = 'Total: ${data.totalScore}/${data.daysCount * 100}';
            chips = [
              _buildChip(context, Icons.calendar_today, 'Day $currentDayIndex of ${season.days}'),
              _buildChip(context, Icons.local_fire_department, 'Best streak: ${data.bestStreak} days'),
              _buildChip(context, Icons.check_circle, '${(data.completionRate * 100).round()}% perfect days'),
            ];
            break;
        }

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${data.avgScore}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ScoreRing(score: data.avgScore.toDouble()),
                  if (_selectedRange == InsightsRange.today)
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  Widget _buildHighlightsSection(BuildContext context, WidgetRef ref, InsightsData data) {
    final highlights = <Widget>[];

    // Best day / Hardest day (for 7 Days and Season)
    if (_selectedRange != InsightsRange.today && data.trendSeries.isNotEmpty) {
      final sorted = List<DayPoint>.from(data.trendSeries)..sort((a, b) => b.score.compareTo(a.score));
      final bestDay = sorted.first;
      final worstDay = sorted.last;
      highlights.add(_buildHighlightCard(
        context,
        icon: Icons.emoji_events,
        title: 'Best day',
        subtitle: DateFormat('MMM d').format(bestDay.date) + ' (${bestDay.score})',
      ));
      if (worstDay.score < bestDay.score) {
        highlights.add(_buildHighlightCard(
          context,
          icon: Icons.trending_down,
          title: 'Hardest day',
          subtitle: DateFormat('MMM d').format(worstDay.date) + ' (${worstDay.score})',
        ));
      }
    }

    // Most consistent habit
    if (data.perHabitStats.isNotEmpty) {
      String? mostConsistent;
      double highestRate = 0;
      for (final entry in data.perHabitStats.entries) {
        final stats = entry.value;
        double rate = 0;
        if (stats.doneDays != null && stats.totalDays != null && stats.totalDays! > 0) {
          rate = stats.doneDays! / stats.totalDays!;
        } else if (stats.daysMetTarget != null && stats.totalDays != null && stats.totalDays! > 0) {
          rate = stats.daysMetTarget! / stats.totalDays!;
        }
        if (rate > highestRate) {
          highestRate = rate;
          mostConsistent = entry.key;
        }
      }
      if (mostConsistent != null && highestRate > 0.7) {
        highlights.add(_buildHighlightCard(
          context,
          icon: Icons.check_circle_outline,
          title: 'Most consistent',
          subtitle: _getHabitDisplayName(mostConsistent),
        ));
      }
    }

    // Quran total (for Season)
    if (_selectedRange == InsightsRange.season) {
      final quranStats = data.perHabitStats['quran_pages'];
      if (quranStats != null && quranStats.totalValue != null) {
        highlights.add(_buildHighlightCard(
          context,
          icon: Icons.menu_book,
          iconWidget: QuranIcon(size: 32, color: Theme.of(context).colorScheme.primary),
          title: 'Total Quran pages',
          subtitle: '${quranStats.totalValue} pages',
        ));
      }
    }

    if (highlights.isEmpty) return const SizedBox.shrink();

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
            itemBuilder: (context, index) => Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              child: highlights[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(BuildContext context, {required IconData icon, Widget? iconWidget, required String title, required String subtitle}) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          iconWidget ?? Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInsightsSection(BuildContext context, WidgetRef ref, InsightsData data) {
    // This will be implemented with habit cards
    // For now, return a placeholder
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
        ...data.perHabitStats.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildHabitCard(context, entry.key, entry.value),
          );
        }),
      ],
    );
  }

  Widget _buildHabitCard(BuildContext context, String habitKey, HabitStats stats) {
    final name = _getHabitDisplayName(habitKey);
    String statText = '';

    if (stats.doneDays != null && stats.totalDays != null) {
      statText = 'Done ${stats.doneDays}/${stats.totalDays} days';
    } else if (stats.avgValue != null && stats.targetValue != null) {
      statText = 'Avg ${stats.avgValue!.round()}/${stats.targetValue}';
    } else if (stats.totalValue != null) {
      statText = 'Total: ${stats.totalValue}';
    }

    return PremiumCard(
      onTap: () {
        // TODO: Open detail bottom sheet
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          getHabitIconWidget(context, habitKey, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  statText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildTrendsCard(BuildContext context, InsightsData data) {
    if (data.trendSeries.length <= 1) return const SizedBox.shrink();

    final spots = data.trendSeries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score.toDouble());
    }).toList();

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
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.trendSeries.length - 1).toDouble(),
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
                        if (value.toInt() < data.trendSeries.length) {
                          final dayPoint = data.trendSeries[value.toInt()];
                          return Text(
                            DateFormat('MMM d').format(dayPoint.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                    spots: spots,
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
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareSeasonsSection(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(seasonComparisonProvider);

    return comparisonAsync.when(
      data: (comparison) {
        if (comparison == null) {
          return PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No previous season yet',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final current = comparison['current'] as InsightsData;
        final previous = comparison['previous'] as InsightsData;
        final currentSeason = comparison['currentSeason'];
        final previousSeason = comparison['previousSeason'];

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compare Seasons',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildComparisonRow(
                context,
                'Avg score',
                '${current.avgScore}',
                '${previous.avgScore}',
                current.avgScore - previous.avgScore,
              ),
              _buildComparisonRow(
                context,
                'Perfect days',
                '${(current.completionRate * current.daysCount).round()}/${current.daysCount}',
                '${(previous.completionRate * previous.daysCount).round()}/${previous.daysCount}',
                (current.completionRate * current.daysCount).round() - (previous.completionRate * previous.daysCount).round(),
              ),
              // Add more comparison rows for Quran, Dhikr, Sedekah
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String label, String currentValue, String previousValue, int delta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              Text(
                currentValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                delta >= 0 ? '+$delta' : '$delta',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: delta >= 0 ? Colors.green : Colors.red,
                    ),
              ),
            ],
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

  IconData _getHabitIcon(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return Icons.no_meals;
      case 'quran_pages':
        return Icons.menu_book;
      case 'dhikr':
        return Icons.favorite;
      case 'taraweeh':
        return Icons.nights_stay;
      case 'sedekah':
        return Icons.volunteer_activism;
      case 'prayers':
        return Icons.mosque;
      case 'itikaf':
        return Icons.mosque;
      default:
        return Icons.check_circle;
    }
  }
}
