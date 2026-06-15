import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/year_round/year_round_dates.dart';
import 'package:ramadan_tracker/features/year_round/year_round_navigation.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Countdown banner shown before Ramadan starts (Today, Sunnah, Wawasan).
class PreRamadanBanner extends ConsumerWidget {
  final bool showPlanButton;

  const PreRamadanBanner({
    super.key,
    this.showPlanButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        final daysUntil = YearRoundDates.daysUntilRamadan(season: season);
        if (daysUntil == null || daysUntil <= 0) {
          return const SizedBox.shrink();
        }

        return PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.preRamadanBanner(daysUntil),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.preRamadanBannerHint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (showPlanButton) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => YearRoundNavigation.openPlanTab(ref),
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(s.openAutopilotPlan),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
