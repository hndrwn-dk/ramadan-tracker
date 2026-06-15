import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/providers/insights_provider.dart';
import 'package:ramadan_tracker/features/insights/screens/season_report_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Teaser when at least two Ramadan seasons exist (year-round Wawasan).
class SeasonCompareTeaserCard extends ConsumerWidget {
  final int seasonId;

  const SeasonCompareTeaserCard({super.key, required this.seasonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final comparisonAsync = ref.watch(seasonComparisonProvider);

    return comparisonAsync.when(
      data: (comparison) {
        if (comparison == null) return const SizedBox.shrink();

        final current = comparison['current'] as InsightsData;
        final previous = comparison['previous'] as InsightsData;
        final delta = current.avgScore - previous.avgScore;
        final deltaLabel = delta >= 0 ? '+$delta' : '$delta';

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                s.compareSeasonsTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                s.compareSeasonsSubtitle(
                  current.avgScore,
                  previous.avgScore,
                  deltaLabel,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SeasonReportScreen(seasonId: seasonId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.compare_arrows, size: 16),
                  label: Text(s.viewSeasonComparison),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
