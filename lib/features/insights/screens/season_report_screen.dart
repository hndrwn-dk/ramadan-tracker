import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/insights/providers/insights_provider.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

class SeasonReportScreen extends ConsumerWidget {
  final int seasonId;

  const SeasonReportScreen({
    super.key,
    required this.seasonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final insightsAsync = ref.watch(insightsDataProvider(InsightsRange.season));
    final comparisonAsync = ref.watch(seasonComparisonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Season Report'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) return const Center(child: Text('No season found'));
          return insightsAsync.when(
            data: (insightsData) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSeasonSummary(context, season, insightsData),
                    const SizedBox(height: 24),
                    _buildHabitSummary(context, insightsData),
                    const SizedBox(height: 24),
                    comparisonAsync.when(
                      data: (comparison) {
                        if (comparison == null) return const SizedBox.shrink();
                        return _buildComparisonSection(context, comparison);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
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

  Widget _buildSeasonSummary(BuildContext context, season, insightsData) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text('Average Score: ${insightsData.avgScore}'),
          Text('Perfect Days: ${(insightsData.completionRate * insightsData.daysCount).round()}/${insightsData.daysCount}'),
          Text('Longest Streak: ${insightsData.bestStreak} days'),
        ],
      ),
    );
  }

  Widget _buildHabitSummary(BuildContext context, insightsData) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Habit Summary',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...insightsData.perHabitStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(_formatHabitStat(entry.value)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildComparisonSection(BuildContext context, Map<String, dynamic> comparison) {
    final current = comparison['current'] as InsightsData;
    final previous = comparison['previous'] as InsightsData;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Season Comparison',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildComparisonRow(context, 'Avg score', current.avgScore, previous.avgScore),
          _buildComparisonRow(context, 'Perfect days', 
            (current.completionRate * current.daysCount).round(),
            (previous.completionRate * previous.daysCount).round()),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String label, int current, int previous) {
    final delta = current - previous;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              Text('$current', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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

  String _formatHabitStat(habitStats) {
    if (habitStats.totalValue != null) {
      return 'Total: ${habitStats.totalValue}';
    } else if (habitStats.doneDays != null) {
      return 'Done: ${habitStats.doneDays}/${habitStats.totalDays}';
    }
    return '';
  }
}

