import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/features/insights/screens/sunnah_insights_screen.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/features/insights/widgets/sunnah_insights_charts.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Wawasan content before Ramadan starts (or when no season exists yet).
class SunnahOnlyInsightsView extends ConsumerWidget {
  final bool duringRamadan;

  const SunnahOnlyInsightsView({super.key, this.duringRamadan = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return FutureBuilder<SunnahInsightsData>(
      future: SunnahInsightsService.load(ref.read(databaseProvider)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        if (data == null) {
          return Center(child: Text(s.sunnahInsightsEmpty));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (duringRamadan) ...[
                PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.nightlight_round,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.duringRamadanSunnahInsightsHint,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (!duringRamadan)
                seasonAsync.when(
                  data: (season) {
                    if (season == null) {
                      return PremiumCard(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          s.noSeasonSunnahInsightsHint,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }
                    final today = DateTime.now();
                    final daysUntil = season.startDate
                        .difference(
                            DateTime(today.year, today.month, today.day))
                        .inDays;
                    if (daysUntil <= 0) return const SizedBox.shrink();
                    return PremiumCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.schedule,
                              color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              s.preRamadanBanner(daysUntil),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              if (!duringRamadan) const SizedBox(height: 16),
              SunnahInsightsHeroCard(data: data, strings: s),
              const SizedBox(height: 16),
              SunnahRecentHeatmapCard(data: data, strings: s),
              const SizedBox(height: 16),
              SunnahMonthlyBarChartCard(data: data, strings: s),
              const SizedBox(height: 16),
              SunnahWeeklyTrendCard(data: data, strings: s),
              const SizedBox(height: 16),
              SunnahTypeBreakdownCard(data: data, strings: s),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SunnahInsightsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(s.viewSunnahInsights),
                ),
              ),
              const SizedBox(height: 8),
              if (!duringRamadan)
                OutlinedButton.icon(
                  onPressed: () => ref.read(tabIndexProvider.notifier).state = 3,
                  icon: const Icon(Icons.nightlight_round),
                  label: Text(s.openSunnahTab),
                ),
            ],
          ),
        );
      },
    );
  }
}
