import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/year_round/year_round_dates.dart';
import 'package:ramadan_tracker/features/year_round/year_round_navigation.dart';
import 'package:ramadan_tracker/features/engagement/widgets/pre_ramadan_quests_strip.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Where the pre-Ramadan countdown banner is shown — copy and CTA differ.
enum PreRamadanBannerTarget {
  /// Hari Ini: season setup only (not Autopilot).
  today,

  /// Rencana Autopilot: Quran/dhikr/time-block setup.
  autopilot,
}

/// Countdown banner shown before Ramadan starts.
class PreRamadanBanner extends ConsumerWidget {
  final PreRamadanBannerTarget target;
  final bool showButton;

  const PreRamadanBanner({
    super.key,
    this.target = PreRamadanBannerTarget.today,
    this.showButton = true,
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

        final hint = target == PreRamadanBannerTarget.today
            ? s.preRamadanTodayHint
            : s.preRamadanAutopilotHint;

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
                          hint,
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
              if (showButton &&
                  target == PreRamadanBannerTarget.today) ...[
                const PreRamadanQuestsStrip(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        YearRoundNavigation.openCreateSeason(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(s.setupRamadanSeason),
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

/// Countdown for Autopilot when no season exists yet.
class RamadanCountdownCard extends ConsumerWidget {
  const RamadanCountdownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final seasonAsync = ref.watch(currentSeasonProvider);
    final scheme = Theme.of(context).colorScheme;

    return seasonAsync.when(
      data: (season) {
        final daysUntil = YearRoundDates.daysUntilRamadan(season: season);
        if (daysUntil == null || daysUntil <= 0) {
          return const SizedBox.shrink();
        }

        return PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.celebration, color: scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.preRamadanBanner(daysUntil),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      s.preRamadanAutopilotHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
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
