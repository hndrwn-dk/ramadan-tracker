import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/features/qadha/services/obligations_history_analytics.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

class ObligationsHistoryCharts extends StatelessWidget {
  final List<QadhaLedgerData> entries;
  final String currency;
  final SeasonModel? season;
  final ObligationsSeasonAnalytics? rangeAnalytics;

  const ObligationsHistoryCharts({
    super.key,
    required this.entries,
    required this.currency,
    this.season,
    this.rangeAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final data = ObligationsHistoryAnalytics.compute(
      entries: entries,
      currency: currency,
      season: rangeAnalytics == null ? season : null,
    );
    final range = rangeAnalytics;
    final hasData = range != null ? range.hasPayments : data.hasData;

    if (!hasData) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            s.obligationsChartEmpty,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (range != null)
          _buildRangeSummaryCard(context, s, range)
        else
          _buildSummaryCard(context, s, data),
        const SizedBox(height: 16),
        if (range != null)
          _buildRangeBreakdownChart(context, s, range)
        else
          _buildBreakdownChart(context, s, data),
        const SizedBox(height: 16),
        if (range != null &&
            range.dailyPaymentTotals.any((v) => v > 0)) ...[
          _buildRangeDailyTimelineChart(context, s, range),
          const SizedBox(height: 16),
        ] else if (data.seasonDailyTimeline.any((d) => d.total > 0)) ...[
          _buildSeasonTimelineChart(context, s, data),
          const SizedBox(height: 16),
        ],
        if (data.monthlyTimeline.isNotEmpty)
          _buildMonthlyTimelineChart(context, s, data),
      ],
    );
  }

  Widget _buildRangeSummaryCard(
    BuildContext context,
    SunnahStrings s,
    ObligationsSeasonAnalytics range,
  ) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.paymentSummary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _summaryRow(
            context,
            s.zakatPaidStat,
            SedekahUtils.formatCurrency(range.zakatTotal.toDouble(), currency),
            range.zakatPeople > 0 ? '${range.zakatPeople} ${s.peopleUnit}' : null,
          ),
          const SizedBox(height: 12),
          _summaryRow(
            context,
            s.fidyahPaidStat,
            SedekahUtils.formatCurrency(range.fidyahTotal.toDouble(), currency),
            range.fidyahDays > 0 ? '${range.fidyahDays} ${s.daysUnit}' : null,
          ),
          const SizedBox(height: 12),
          _summaryRow(
            context,
            s.obligationsTotalPaid,
            SedekahUtils.formatCurrency(
              (range.zakatTotal + range.fidyahTotal).toDouble(),
              currency,
            ),
            '${range.paymentCount} ${s.obligationsPaymentCountLabel}',
          ),
        ],
      ),
    );
  }

  Widget _buildRangeBreakdownChart(
    BuildContext context,
    SunnahStrings s,
    ObligationsSeasonAnalytics range,
  ) {
    final total = range.zakatTotal + range.fidyahTotal;
    final zakatShare = total > 0 ? range.zakatTotal / total : 0.0;
    final fidyahShare = total > 0 ? range.fidyahTotal / total : 0.0;
    return _buildBreakdownChart(
      context,
      s,
      _BreakdownData(
        zakatTotal: range.zakatTotal,
        fidyahTotal: range.fidyahTotal,
        zakatShare: zakatShare,
        fidyahShare: fidyahShare,
      ),
    );
  }

  Widget _buildRangeDailyTimelineChart(
    BuildContext context,
    SunnahStrings s,
    ObligationsSeasonAnalytics range,
  ) {
    final timeline = List.generate(range.dailyPaymentTotals.length, (i) {
      return DailyPaymentBucket(
        dayIndex: range.startDayIndex + i,
        zakatAmount: range.dailyZakatTotals.length > i
            ? range.dailyZakatTotals[i]
            : 0,
        fidyahAmount: range.dailyFidyahTotals.length > i
            ? range.dailyFidyahTotals[i]
            : 0,
      );
    });
    final maxY = timeline
        .map((d) => d.total.toDouble())
        .fold(0.0, (a, b) => a > b ? a : b);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.obligationsChartPeriodTimelineTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              _stackedBarChartData(
                context,
                itemCount: timeline.length,
                maxY: maxY,
                getZakat: (i) => timeline[i].zakatAmount.toDouble(),
                getFidyah: (i) => timeline[i].fidyahAmount.toDouble(),
                bottomLabel: (i) {
                  final day = timeline[i].dayIndex;
                  if (timeline.length <= 7 ||
                      day == range.startDayIndex ||
                      day % 5 == 0) {
                    return day.toString();
                  }
                  return '';
                },
                barWidth: timeline.length <= 7 ? 20 : 6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _chartLegend(context, s),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    SunnahStrings s,
    ObligationsHistoryAnalytics data,
  ) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.paymentSummary,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _summaryRow(
            context,
            s.zakatPaidStat,
            SedekahUtils.formatCurrency(data.zakatTotal.toDouble(), currency),
            data.zakatPeople > 0 ? '${data.zakatPeople} ${s.peopleUnit}' : null,
          ),
          const SizedBox(height: 12),
          _summaryRow(
            context,
            s.fidyahPaidStat,
            SedekahUtils.formatCurrency(data.fidyahTotal.toDouble(), currency),
            data.fidyahDays > 0 ? '${data.fidyahDays} ${s.daysUnit}' : null,
          ),
          const SizedBox(height: 12),
          _summaryRow(
            context,
            s.obligationsTotalPaid,
            SedekahUtils.formatCurrency(
              (data.zakatTotal + data.fidyahTotal).toDouble(),
              currency,
            ),
            '${data.paymentCount} ${s.obligationsPaymentCountLabel}',
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    BuildContext context,
    String label,
    String value,
    String? sub,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              if (sub != null)
                Text(
                  sub,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildBreakdownChart(
    BuildContext context,
    SunnahStrings s,
    dynamic data,
  ) {
    final breakdown = data is ObligationsHistoryAnalytics
        ? _BreakdownData(
            zakatTotal: data.zakatTotal,
            fidyahTotal: data.fidyahTotal,
            zakatShare: (data.zakatTotal + data.fidyahTotal) > 0
                ? data.zakatTotal / (data.zakatTotal + data.fidyahTotal)
                : 0.0,
            fidyahShare: (data.zakatTotal + data.fidyahTotal) > 0
                ? data.fidyahTotal / (data.zakatTotal + data.fidyahTotal)
                : 0.0,
          )
        : data as _BreakdownData;

    final scheme = Theme.of(context).colorScheme;
    final zakatShare = breakdown.zakatShare;
    final fidyahShare = breakdown.fidyahShare;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.obligationsChartBreakdownTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 16,
              child: Row(
                children: [
                  if (breakdown.zakatTotal > 0)
                    Expanded(
                      flex: breakdown.zakatTotal,
                      child: ColoredBox(color: scheme.primary),
                    ),
                  if (breakdown.fidyahTotal > 0)
                    Expanded(
                      flex: breakdown.fidyahTotal,
                      child: ColoredBox(color: scheme.secondary),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _breakdownLegendRow(
            context,
            color: scheme.primary,
            title: s.zakatTitle,
            amount: breakdown.zakatTotal,
            share: zakatShare,
          ),
          const SizedBox(height: 10),
          _breakdownLegendRow(
            context,
            color: scheme.secondary,
            title: s.fidyahTitle,
            amount: breakdown.fidyahTotal,
            share: fidyahShare,
          ),
        ],
      ),
    );
  }

  Widget _breakdownLegendRow(
    BuildContext context, {
    required Color color,
    required String title,
    required int amount,
    required double share,
  }) {
    final pct = (share * 100).round();
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          SedekahUtils.formatCurrency(amount.toDouble(), currency),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        Text(
          '$pct%',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      ],
    );
  }

  Widget _buildSeasonTimelineChart(
    BuildContext context,
    SunnahStrings s,
    ObligationsHistoryAnalytics data,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final daysWithData = data.seasonDailyTimeline
        .where((d) => d.total > 0)
        .toList();
    if (daysWithData.isEmpty) return const SizedBox.shrink();

    final maxY = daysWithData
        .map((d) => d.total.toDouble())
        .reduce((a, b) => a > b ? a : b);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.obligationsChartSeasonTimelineTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            s.paymentTimeline,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.65),
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              _stackedBarChartData(
                context,
                itemCount: data.seasonDailyTimeline.length,
                maxY: maxY,
                getZakat: (i) =>
                    data.seasonDailyTimeline[i].zakatAmount.toDouble(),
                getFidyah: (i) =>
                    data.seasonDailyTimeline[i].fidyahAmount.toDouble(),
                bottomLabel: (i) {
                  final day = data.seasonDailyTimeline[i].dayIndex;
                  if (day == 1 ||
                      day == data.seasonDays ||
                      day % 5 == 0) {
                    return day.toString();
                  }
                  return '';
                },
                barWidth: 6,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _chartLegend(context, s),
        ],
      ),
    );
  }

  Widget _buildMonthlyTimelineChart(
    BuildContext context,
    SunnahStrings s,
    ObligationsHistoryAnalytics data,
  ) {
    final timeline = data.monthlyTimeline;
    final maxY = timeline
        .map((m) => m.total.toDouble())
        .reduce((a, b) => a > b ? a : b);

    final locale = s.id ? 'id_ID' : 'en_US';

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.obligationsChartMonthlyTimelineTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              _stackedBarChartData(
                context,
                itemCount: timeline.length,
                maxY: maxY,
                getZakat: (i) => timeline[i].zakatAmount.toDouble(),
                getFidyah: (i) => timeline[i].fidyahAmount.toDouble(),
                bottomLabel: (i) {
                  final date = DateTime(timeline[i].year, timeline[i].month);
                  return DateFormat('MMM', locale).format(date);
                },
                barWidth: timeline.length <= 6 ? 24 : 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _chartLegend(context, s),
        ],
      ),
    );
  }

  BarChartData _stackedBarChartData(
    BuildContext context, {
    required int itemCount,
    required double maxY,
    required double Function(int index) getZakat,
    required double Function(int index) getFidyah,
    required String Function(int index) bottomLabel,
    required double barWidth,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return BarChartData(
      minY: 0,
      maxY: maxY <= 0 ? 1 : maxY * 1.15,
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
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles:
            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              if (value != value.roundToDouble() || value < 0) {
                return const SizedBox.shrink();
              }
              return Text(
                _compactAmount(value.toInt()),
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
              final index = value.toInt();
              if (index < 0 || index >= itemCount) {
                return const SizedBox.shrink();
              }
              final label = bottomLabel(index);
              if (label.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: List.generate(itemCount, (index) {
        final zakat = getZakat(index);
        final fidyah = getFidyah(index);
        final total = zakat + fidyah;
        return BarChartGroupData(
          x: index,
          barRods: [
            if (total > 0)
              BarChartRodData(
                toY: total,
                width: barWidth,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                rodStackItems: [
                  BarChartRodStackItem(0, zakat, scheme.primary),
                  BarChartRodStackItem(zakat, total, scheme.secondary),
                ],
              )
            else
              BarChartRodData(
                toY: 0,
                width: barWidth,
                color: scheme.outline.withValues(alpha: 0.08),
              ),
          ],
        );
      }),
    );
  }

  Widget _chartLegend(BuildContext context, SunnahStrings s) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(context, scheme.primary, s.zakatTitle),
        const SizedBox(width: 16),
        _legendDot(context, scheme.secondary, s.fidyahTitle),
      ],
    );
  }

  Widget _legendDot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  String _compactAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }
}

class _BreakdownData {
  final int zakatTotal;
  final int fidyahTotal;
  final double zakatShare;
  final double fidyahShare;

  const _BreakdownData({
    required this.zakatTotal,
    required this.fidyahTotal,
    required this.zakatShare,
    required this.fidyahShare,
  });
}
