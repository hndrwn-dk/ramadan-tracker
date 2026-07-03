import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/domain/models/companion_level.dart';
import 'package:ramadan_tracker/features/engagement/achievements_screen.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Season journey summary and primary entry to [AchievementsScreen].
class MonthJourneyCard extends ConsumerWidget {
  const MonthJourneyCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final engagementAsync = ref.watch(userEngagementProvider);
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);
    final dayIndex = ref.watch(currentDayIndexProvider);

    return engagementAsync.when(
      data: (engagement) {
        final unlockedCount = unlockedAsync.valueOrNull?.length ?? 0;
        final totalBadges = AchievementCatalog.all.length;
        final level = engagement.companionLevel;
        final nextXp = CompanionLevel.xpForNextLevel(level);
        final xpToNext = (nextXp - engagement.totalXp).clamp(0, nextXp);

        final season = seasonAsync.valueOrNull;
        final seasonDays = season?.days ?? 30;
        final progress = seasonDays > 0 ? (dayIndex / seasonDays).clamp(0.0, 1.0) : 0.0;

        return AppSurface(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
            );
          },
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.route_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.monthJourneyTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.monthJourneySubtitle(
                            l10n.companionLevelLabel(level),
                            unlockedCount,
                            totalBadges,
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              if (season != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.monthJourneyDayProgress(dayIndex, seasonDays),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              if (xpToNext > 0) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.monthJourneyXpToNext(xpToNext),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
