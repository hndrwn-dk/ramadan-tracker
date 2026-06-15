import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/insights/widgets/qadha_progress_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_compare_teaser_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/year_round_obligations_card.dart';
import 'package:ramadan_tracker/features/insights/screens/season_report_screen.dart';
import 'package:ramadan_tracker/features/insights/screens/sunnah_insights_screen.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/features/insights/widgets/sunnah_insights_charts.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/year_round/year_round_navigation.dart';
import 'package:ramadan_tracker/features/year_round/widgets/pre_ramadan_banner.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Wawasan year-round content (pre-Ramadan, post-Ramadan, or no season).
class SunnahOnlyInsightsView extends ConsumerWidget {
  final bool duringRamadan;
  final bool showPostRamadanReview;

  const SunnahOnlyInsightsView({
    super.key,
    this.duringRamadan = false,
    this.showPostRamadanReview = false,
  });

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
              if (showPostRamadanReview)
                seasonAsync.when(
                  data: (season) {
                    if (season == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        PremiumCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.mosque,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.postRamadanReviewBanner,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SeasonReportScreen(
                                          seasonId: season.id,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.insights, size: 16),
                                  label: Text(s.viewPastRamadanInsights),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              if (!duringRamadan && !showPostRamadanReview)
                seasonAsync.when(
                  data: (season) {
                    if (season == null) return const SizedBox.shrink();
                    return const PreRamadanBanner(showButton: false);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              if (!duringRamadan && !showPostRamadanReview) const SizedBox(height: 16),
              if (!duringRamadan) ...[
                const QadhaProgressCard(),
                const SizedBox(height: 16),
                const YearRoundObligationsCard(),
                const SizedBox(height: 16),
              ],
              if (showPostRamadanReview)
                seasonAsync.when(
                  data: (season) {
                    if (season == null) return const SizedBox.shrink();
                    return Column(
                      children: [
                        SeasonCompareTeaserCard(seasonId: season.id),
                        const SizedBox(height: 16),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
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
                  onPressed: () => YearRoundNavigation.openSunnahTab(ref),
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
