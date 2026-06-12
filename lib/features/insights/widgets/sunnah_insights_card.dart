import 'package:flutter/material.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

class SunnahInsightsCard extends StatelessWidget {
  final SunnahInsightsData data;
  final VoidCallback onViewDetails;

  const SunnahInsightsCard({
    super.key,
    required this.data,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final year = DateTime.now().year;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.nightlight_round, size: 20, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.insightsSunnahTitleFor(year),
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
                child: _stat(context, '${data.totalThisYear}', s.thisYear),
              ),
              Expanded(
                child: _stat(context, '${data.seninKamisStreak}', s.streak),
              ),
              Expanded(
                child: _stat(context, '${data.totalAllTime}', s.allTime),
              ),
            ],
          ),
          if (data.qadhaFastsThisYear > 0) ...[
            const SizedBox(height: 12),
            Text(
              s.qadhaFastsThisYear(data.qadhaFastsThisYear),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ],
          const SizedBox(height: 16),
          _buildMonthlyChart(context),
          const SizedBox(height: 12),
          ...sunnahBreakdownTypes.take(4).map((type) {
            final count = data.typeCountsThisYear[type.key] ?? 0;
            if (count == 0) return const SizedBox.shrink();
            final target = sunnahTypeTarget(type.key);
            final label = sunnahTypeLabel(type, s.id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: Theme.of(context).textTheme.bodySmall),
                  ),
                  Text(
                    target != null ? '$count / $target' : s.timesCount(count),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(s.viewSunnahInsights),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65),
              ),
        ),
      ],
    );
  }

  Widget _buildMonthlyChart(BuildContext context) {
    final maxCount = data.monthlyCountsThisYear.fold<int>(
      0,
      (prev, v) => v > prev ? v : prev,
    );
    if (maxCount == 0) return const SizedBox.shrink();

    const maxHeight = 36.0;
    final s = SunnahStrings.of(context);
    final monthLabels = s.id
        ? ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D']
        : ['J', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.monthlyFastsChart,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: maxHeight + 18,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(12, (i) {
              final count = data.monthlyCountsThisYear[i];
              final height =
                  maxCount > 0 ? (count / maxCount) * maxHeight : 0.0;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: height > 0 ? height : 2,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabels[i],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontSize: 9,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
