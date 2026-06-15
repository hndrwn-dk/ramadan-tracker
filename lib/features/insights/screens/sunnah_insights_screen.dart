import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/widgets/app_back_button.dart';

class SunnahInsightsScreen extends ConsumerWidget {
  const SunnahInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final year = DateTime.now().year;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(s.insightsSunnahTitleFor(year)),
      ),
      body: FutureBuilder<SunnahInsightsData>(
        future: SunnahInsightsService.load(ref.read(databaseProvider)),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final scheme = Theme.of(context).colorScheme;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              PremiumCard(
                child: Row(
                  children: [
                    _heroStat(context, '${data.totalThisYear}', s.thisYear),
                    _heroStat(context, '${data.seninKamisStreak}', s.streak),
                    _heroStat(context, '${data.totalAllTime}', s.allTime),
                  ],
                ),
              ),
              if (data.qadhaFastsThisYear > 0) ...[
                const SizedBox(height: 12),
                Text(
                  s.qadhaFastsThisYear(data.qadhaFastsThisYear),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                s.yearBreakdownTitleFor(year),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                s.yearBreakdownHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 16),
              ...sunnahBreakdownTypes.map((type) {
                final count = data.typeCountsThisYear[type.key] ?? 0;
                final target = sunnahTypeTarget(type.key);
                final label = sunnahTypeLabel(type, s.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PremiumCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: count == 0
                                          ? scheme.onSurface
                                              .withValues(alpha: 0.45)
                                          : null,
                                    ),
                              ),
                            ),
                            Text(
                              s.timesCount(count),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: count == 0
                                        ? scheme.onSurface
                                            .withValues(alpha: 0.35)
                                        : scheme.primary,
                                  ),
                            ),
                          ],
                        ),
                        if (target != null) ...[
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (count / target).clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: scheme.surfaceContainerHighest,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count / $target',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _heroStat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
