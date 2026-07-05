import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/companion_level.dart';
import 'package:ramadan_tracker/domain/services/streak_shield_service.dart';
import 'package:ramadan_tracker/features/engagement/achievements_screen.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Time-of-day greeting plus a contextual Ramadan nudge for Today home.
class TodayHomeGreeting extends StatelessWidget {
  final int dayIndex;
  final int totalDays;

  const TodayHomeGreeting({
    super.key,
    required this.dayIndex,
    required this.totalDays,
  });

  static String _greeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l10n.todayGreetingMorning;
    if (hour < 17) return l10n.todayGreetingAfternoon;
    return l10n.todayGreetingEvening;
  }

  static String _nudge(AppLocalizations l10n, int dayIndex, int totalDays) {
    if (dayIndex <= 1) return l10n.todayNudgeDayOne;
    final last10Start = totalDays - 9;
    if (dayIndex >= last10Start && dayIndex > 0) return l10n.todayNudgeLastTen;
    if (dayIndex <= 10) return l10n.todayNudgeEarly;
    return l10n.todayNudgeMid;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _greeting(l10n),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          _nudge(l10n, dayIndex, totalDays),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.75),
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

/// Compact companion level + XP progress; taps through to achievements.
class TodayJourneyMiniStrip extends ConsumerWidget {
  const TodayJourneyMiniStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final engagementAsync = ref.watch(userEngagementProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return engagementAsync.when(
      data: (engagement) {
        final level = engagement.companionLevel;
        final nextXp = CompanionLevel.xpForNextLevel(level);
        final xpToNext = (nextXp - engagement.totalXp).clamp(0, nextXp);
        final progress = nextXp > 0
            ? (engagement.totalXp / nextXp).clamp(0.0, 1.0)
            : 1.0;
        final scheme = Theme.of(context).colorScheme;
        final tierName = _companionTierName(l10n, level);

        return seasonAsync.when(
          data: (season) {
            return FutureBuilder<int>(
              future: season == null
                  ? Future.value(0)
                  : StreakShieldService.shieldsRemaining(
                      ref.read(databaseProvider),
                      season.id,
                    ),
              builder: (context, shieldSnapshot) {
                final shieldsLeft = shieldSnapshot.data ?? 0;

                return InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.military_tech_outlined,
                              size: 18,
                              color: scheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.todayHomeCompanionLine(level, engagement.totalXp),
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: scheme.onSurface.withValues(alpha: 0.4),
                            ),
                          ],
                        ),
                        if (tierName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            tierName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.primary.withValues(alpha: 0.85),
                                ),
                          ),
                        ],
                        if (season != null && shieldsLeft > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.streakShieldsRemaining(shieldsLeft),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 5,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                        if (xpToNext > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.todayHomeXpToNext(xpToNext, level + 1),
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => _buildProgressOnly(context, l10n, level, engagement, progress, xpToNext),
          error: (_, __) => _buildProgressOnly(context, l10n, level, engagement, progress, xpToNext),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  static String _companionTierName(AppLocalizations l10n, int level) {
    switch (CompanionLevel.tierKeyForLevel(level)) {
      case 'companionTierMubtadi':
        return l10n.companionTierMubtadi;
      case 'companionTierMumayyiz':
        return l10n.companionTierMumayyiz;
      case 'companionTierMujahid':
        return l10n.companionTierMujahid;
      default:
        return '';
    }
  }

  Widget _buildProgressOnly(
    BuildContext context,
    AppLocalizations l10n,
    int level,
    dynamic engagement,
    double progress,
    int xpToNext,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todayHomeCompanionLine(level, engagement.totalXp),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            if (xpToNext > 0) ...[
              const SizedBox(height: 4),
              Text(
                l10n.todayHomeXpToNext(xpToNext, level + 1),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
