import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

/// Zakat & Fidyah season summary for Ramadan Wawasan.
class ObligationsSeasonCard extends StatelessWidget {
  final ObligationsSeasonAnalytics data;
  final String currency;
  final VoidCallback onViewDetails;

  const ObligationsSeasonCard({
    super.key,
    required this.data,
    required this.currency,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

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
                  s.obligationsSeasonTitle,
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
                  sub: data.zakatPeople > 0
                      ? '${data.zakatPeople} ${s.peopleUnit}'
                      : null,
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
                  sub: data.fidyahDays > 0
                      ? '${data.fidyahDays} ${s.daysUnit}'
                      : null,
                ),
              ),
            ],
          ),
          if (data.paymentCount > 0) ...[
            const SizedBox(height: 16),
            _buildBarChart(context),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.receipt_long_outlined, size: 16),
              label: Text(s.viewObligationsDetails),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(
    BuildContext context, {
    required String label,
    required String value,
    String? sub,
  }) {
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
        if (sub != null)
          Text(
            sub,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }

  Widget _buildBarChart(BuildContext context) {
    if (data.dailyPaymentTotals.every((v) => v == 0)) {
      return const SizedBox.shrink();
    }

    final maxAmount =
        data.dailyPaymentTotals.reduce((a, b) => a > b ? a : b);
    const maxHeight = 40.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          SunnahStrings.of(context).paymentTimeline,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: maxHeight + 8,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.dailyPaymentTotals.asMap().entries.map((entry) {
              final amount = entry.value;
              final height =
                  maxAmount > 0 ? (amount / maxAmount) * maxHeight : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    height: height > 0 ? height : 2,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
