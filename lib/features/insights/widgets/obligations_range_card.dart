import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

/// Compact Zakat & Fidyah card for Today / 7 Days Wawasan tabs.
class ObligationsRangeCard extends StatelessWidget {
  final ObligationsSeasonAnalytics data;
  final String currency;
  final String title;
  final VoidCallback onViewDetails;

  const ObligationsRangeCard({
    super.key,
    required this.data,
    required this.currency,
    required this.title,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final total = data.zakatTotal + data.fidyahTotal;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.volunteer_activism, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metric(
                  context,
                  label: s.zakatPaidStat,
                  value: data.zakatTotal > 0
                      ? SedekahUtils.formatCurrency(
                          data.zakatTotal.toDouble(), currency)
                      : '-',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metric(
                  context,
                  label: s.fidyahPaidStat,
                  value: data.fidyahTotal > 0
                      ? SedekahUtils.formatCurrency(
                          data.fidyahTotal.toDouble(), currency)
                      : '-',
                ),
              ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 8),
            Text(
              '${data.paymentCount} ${s.obligationsPaymentCountLabel}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
          ],
          if (data.dailyPaymentTotals.any((v) => v > 0)) ...[
            const SizedBox(height: 16),
            _buildBarChart(context, scheme),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.viewObligationsDetails),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(BuildContext context,
      {required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context, ColorScheme scheme) {
    final maxAmount =
        data.dailyPaymentTotals.reduce((a, b) => a > b ? a : b);
    const maxHeight = 48.0;
    final hasSplit = data.dailyZakatTotals.length == data.dailyPaymentTotals.length &&
        data.dailyFidyahTotals.length == data.dailyPaymentTotals.length;

    return SizedBox(
      height: maxHeight + 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.dailyPaymentTotals.asMap().entries.map((entry) {
          final idx = entry.key;
          final total = entry.value;
          final zakat = hasSplit ? data.dailyZakatTotals[idx] : 0;
          final height =
              maxAmount > 0 ? (total / maxAmount) * maxHeight : 0.0;
          final zakatHeight =
              total > 0 ? height * (zakat / total) : 0.0;
          final fidyahHeight = height - zakatHeight;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (height > 0)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: SizedBox(
                        height: height,
                        width: double.infinity,
                        child: Column(
                          children: [
                            if (fidyahHeight > 0)
                              Expanded(
                                flex: fidyahHeight.round().clamp(1, 999),
                                child: ColoredBox(color: scheme.secondary),
                              ),
                            if (zakatHeight > 0)
                              Expanded(
                                flex: zakatHeight.round().clamp(1, 999),
                                child: ColoredBox(color: scheme.primary),
                              ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: scheme.outline.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  const SizedBox(height: 4),
                  if (data.dailyPaymentTotals.length <= 7)
                    Text(
                      '${data.startDayIndex + idx}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 8,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
