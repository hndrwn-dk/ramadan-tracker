import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

class SedekahReviewScreen extends ConsumerStatefulWidget {
  final InsightsRange range;
  final int seasonId;

  const SedekahReviewScreen({
    super.key,
    required this.range,
    required this.seasonId,
  });

  @override
  ConsumerState<SedekahReviewScreen> createState() => _SedekahReviewScreenState();
}

class _SedekahReviewScreenState extends ConsumerState<SedekahReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sedekah Financial Review'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadSedekahData(),
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
                _buildPatternsSection(context, data),
                const SizedBox(height: 24),
                _buildActionButton(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadSedekahData() async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah');
    final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    final goalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final goalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final target = goalEnabled == 'true' && goalAmount != null ? double.tryParse(goalAmount) : null;

    // Get range dates
    final season = await database.ramadanSeasonsDao.getSeasonById(widget.seasonId);
    if (season == null) return {};
    int startDayIndex, endDayIndex;
    
    switch (widget.range) {
      case InsightsRange.today:
        final currentDay = ref.read(currentDayIndexProvider);
        startDayIndex = currentDay;
        endDayIndex = currentDay;
        break;
      case InsightsRange.sevenDays:
        final currentDay = ref.read(currentDayIndexProvider);
        startDayIndex = (currentDay - 6).clamp(1, season.days);
        endDayIndex = currentDay.clamp(1, season.days);
        break;
      case InsightsRange.season:
        startDayIndex = 1;
        endDayIndex = ref.read(currentDayIndexProvider).clamp(1, season.days);
        break;
    }

    // Load sedekah entries
    int totalAmount = 0;
    int givingDays = 0;
    int highestDay = 0;
    double highestAmount = 0;
    final dailyAmounts = <int, double>{};
    final chipUsage = <double, int>{};

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final entries = await database.dailyEntriesDao.getDayEntries(widget.seasonId, day);
      final entry = entries.firstWhere(
        (e) => e.habitId == sedekahHabit.id,
        orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: sedekahHabit.id, valueInt: 0, updatedAt: 0),
      );
      final amount = (entry.valueInt ?? 0).toDouble();
      if (amount > 0) {
        totalAmount += amount.toInt();
        givingDays++;
        dailyAmounts[day] = amount;
        if (amount > highestAmount) {
          highestAmount = amount;
          highestDay = day;
        }
        // Track chip usage (simplified - would need to track actual chip values)
        chipUsage[amount] = (chipUsage[amount] ?? 0) + 1;
      }
    }

    final avgAmount = (endDayIndex - startDayIndex + 1) > 0
        ? totalAmount / (endDayIndex - startDayIndex + 1)
        : 0.0;

    return {
      'currency': currency,
      'totalAmount': totalAmount,
      'avgAmount': avgAmount,
      'givingDays': givingDays,
      'totalDays': endDayIndex - startDayIndex + 1,
      'highestDay': highestDay,
      'highestAmount': highestAmount,
      'target': target,
      'dailyAmounts': dailyAmounts,
      'chipUsage': chipUsage,
    };
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> data) {
    final currency = data['currency'] as String;
    final totalAmount = data['totalAmount'] as int;
    final avgAmount = data['avgAmount'] as double;
    final givingDays = data['givingDays'] as int;
    final totalDays = data['totalDays'] as int;
    final highestDay = data['highestDay'] as int;
    final highestAmount = data['highestAmount'] as double;
    final target = data['target'] as double?;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow(context, 'Total', SedekahUtils.formatCurrency(totalAmount.toDouble(), currency)),
          _buildSummaryRow(context, 'Avg/day', SedekahUtils.formatCurrency(avgAmount, currency)),
          _buildSummaryRow(context, 'Days hit target', '$givingDays/$totalDays days'),
          if (highestDay > 0)
            _buildSummaryRow(context, 'Biggest day', 'Day $highestDay: ${SedekahUtils.formatCurrency(highestAmount, currency)}'),
          if (target != null && target > 0)
            _buildSummaryRow(context, 'Daily goal', SedekahUtils.formatCurrency(target, currency)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(BuildContext context, Map<String, dynamic> data) {
    final dailyAmounts = data['dailyAmounts'] as Map<int, double>;
    if (dailyAmounts.isEmpty) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No data to display',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final spots = dailyAmounts.entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.range == InsightsRange.sevenDays ? 'Daily Trend' : 'Weekly Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                minY: 0,
                maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.2,
                barGroups: spots.map((spot) {
                  return BarChartGroupData(
                    x: spot.x.toInt(),
                    barRods: [
                      BarChartRodData(
                        toY: spot.y,
                        color: Theme.of(context).colorScheme.primary,
                        width: 16,
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatternsSection(BuildContext context, Map<String, dynamic> data) {
    final chipUsage = data['chipUsage'] as Map<double, int>;
    if (chipUsage.isEmpty) return const SizedBox.shrink();

    final sortedChips = chipUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most Used Amounts',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedChips.take(5).map((entry) {
              final currency = data['currency'] as String;
              return Chip(
                label: Text('${SedekahUtils.formatCurrency(entry.key, currency)} (${entry.value}x)'),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {
        // Navigate to Today Sedekah input (secondary CTA)
        ref.read(tabIndexProvider.notifier).state = 0;
        Navigator.pop(context);
      },
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add donation'),
    );
  }
}

