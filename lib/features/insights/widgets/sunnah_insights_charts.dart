import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';

class SunnahInsightsHeroCard extends StatelessWidget {
  final SunnahInsightsData data;
  final SunnahStrings strings;

  const SunnahInsightsHeroCard({
    super.key,
    required this.data,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final year = DateTime.now().year;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.sunnahHeroTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            strings.insightsSunnahTitleFor(year),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.thisYear,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                    Text(
                      '${data.totalThisYear}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      strings.sunnahHeroSub(data.totalAllTime, data.seninKamisStreak),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
              ScoreRing(score: data.yearProgressPercent.toDouble()),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(context, Icons.local_fire_department, strings.streak,
                  '${data.seninKamisStreak}'),
              _chip(context, Icons.history, strings.allTime,
                  '${data.totalAllTime}'),
              if (data.qadhaFastsThisYear > 0)
                _chip(context, Icons.replay, strings.qadhaShort,
                    '${data.qadhaFastsThisYear}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text('$label: $value',
              style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class SunnahMonthlyBarChartCard extends StatelessWidget {
  final SunnahInsightsData data;
  final SunnahStrings strings;

  const SunnahMonthlyBarChartCard({
    super.key,
    required this.data,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = data.monthlyCountsThisYear.fold<int>(
      0,
      (prev, v) => v > prev ? v : prev,
    );
    final monthLabels = strings.id
        ? ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']
        : ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.monthlyFastsChart,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: maxCount == 0
                ? _emptyChartHint(context, strings.sunnahChartEmptyHint)
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxCount.toDouble() + 1,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: scheme.outline.withValues(alpha: 0.12),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              if (value != value.roundToDouble()) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurface.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= 12) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  monthLabels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(12, (i) {
                        final count = data.monthlyCountsThisYear[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              width: 12,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              color: scheme.primary.withValues(alpha: 0.75),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SunnahWeeklyTrendCard extends StatelessWidget {
  final SunnahInsightsData data;
  final SunnahStrings strings;

  const SunnahWeeklyTrendCard({
    super.key,
    required this.data,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxCount = data.weeklyCountsLast8Weeks.fold<int>(
      0,
      (prev, v) => v > prev ? v : prev,
    );
    final today = DateTime.now();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.weeklyFastsChart,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: maxCount == 0
                ? _emptyChartHint(context, strings.sunnahChartEmptyHint)
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxCount.toDouble() + 1,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: scheme.outline.withValues(alpha: 0.12),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              if (value != value.roundToDouble()) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurface.withValues(alpha: 0.5),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= 8) return const SizedBox.shrink();
                              final weekEnd = today.subtract(
                                Duration(days: (7 - i) * 7),
                              );
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  DateFormat('d/M').format(weekEnd),
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: scheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(8, (i) {
                        final count = data.weeklyCountsLast8Weeks[i];
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: count.toDouble(),
                              width: 14,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                              color: scheme.secondary.withValues(alpha: 0.8),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class SunnahRecentHeatmapCard extends StatelessWidget {
  final SunnahInsightsData data;
  final SunnahStrings strings;

  const SunnahRecentHeatmapCard({
    super.key,
    required this.data,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  strings.recentFastsHeatmap,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  _legend(context, strings.legendFasted, scheme.primary),
                  _legend(context, strings.legendExcused,
                      scheme.tertiary.withValues(alpha: 0.5)),
                  _legend(context, strings.legendNone,
                      scheme.surfaceContainerHighest),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: data.last35Days.map((cell) {
              final isToday = cell.date.year == today.year &&
                  cell.date.month == today.month &&
                  cell.date.day == today.day;
              return Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: _cellColor(scheme, cell.status),
                  borderRadius: BorderRadius.circular(6),
                  border: isToday
                      ? Border.all(color: scheme.primary, width: 2)
                      : Border.all(
                          color: scheme.outline.withValues(alpha: 0.15),
                        ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${cell.date.day}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: cell.status == FastingStatus.fasted
                            ? scheme.onPrimary
                            : scheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _cellColor(ColorScheme scheme, int status) {
    if (status == FastingStatus.fasted) return scheme.primary;
    if (FastingStatus.isExcused(status)) {
      return scheme.tertiary.withValues(alpha: 0.45);
    }
    return scheme.surfaceContainerHighest;
  }

  Widget _legend(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 9)),
      ],
    );
  }
}

class SunnahTypeBreakdownCard extends StatelessWidget {
  final SunnahInsightsData data;
  final SunnahStrings strings;

  const SunnahTypeBreakdownCard({
    super.key,
    required this.data,
    required this.strings,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = sunnahBreakdownTypes
        .map((type) {
          final count = data.typeCountsThisYear[type.key] ?? 0;
          return (type: type, count: count);
        })
        .where((e) => e.count > 0)
        .toList();

    if (entries.isEmpty) {
      return PremiumCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.typeBreakdownTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              strings.sunnahInsightsEmpty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ),
      );
    }

    final maxCount =
        entries.map((e) => e.count).reduce((a, b) => a > b ? a : b);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.typeBreakdownTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          ...entries.map((entry) {
            final label = sunnahTypeLabel(entry.type, strings.id);
            final target = sunnahTypeTarget(entry.type.key);
            final fraction = maxCount > 0 ? entry.count / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(label,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                      Text(
                        target != null
                            ? '${entry.count} / $target'
                            : strings.timesCount(entry.count),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: scheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: scheme.surfaceContainerHighest,
                      color: scheme.primary.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

Widget _emptyChartHint(BuildContext context, String message) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.bar_chart_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55),
              ),
        ),
      ],
    ),
  );
}
