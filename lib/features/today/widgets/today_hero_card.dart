import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/data/providers/completion_score_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_quest_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/features/today/widgets/today_home_engagement.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';

/// Premium Today hero: motivation, score, stat chips, and journey card.
/// Checklist opens only from the sticky bar (single CTA).
class TodayHeroCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;
  final int totalDays;
  final Future<int> Function(int seasonId, int dayIndex) streakLoader;

  const TodayHeroCard({
    super.key,
    required this.seasonId,
    required this.dayIndex,
    required this.totalDays,
    required this.streakLoader,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final scoreAsync = ref.watch(
      completionScoreProvider((seasonId: seasonId, dayIndex: dayIndex)),
    );
    final questsAsync = ref.watch(
      dailyQuestsProvider((seasonId: seasonId, dayIndex: dayIndex)),
    );

    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TodayHomeGreeting(dayIndex: dayIndex, totalDays: totalDays),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                scoreAsync.when(
                  data: (score) => ScoreRing(
                    score: score,
                    label: l10n.scoreLabel,
                    size: 80,
                    strokeWidth: 5,
                  ),
                  loading: () => ScoreRing(
                    score: 0,
                    label: l10n.scoreLabel,
                    size: 80,
                    strokeWidth: 5,
                  ),
                  error: (_, __) => ScoreRing(
                    score: 0,
                    label: l10n.scoreLabel,
                    size: 80,
                    strokeWidth: 5,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: FutureBuilder<int>(
                          future: streakLoader(seasonId, dayIndex),
                          builder: (context, snapshot) {
                            final streak = snapshot.data ?? 0;
                            return _HeroStatChip(
                              label: l10n.todayHeroStreakLabel,
                              value: '$streak',
                              unit: l10n.todayHeroDaysUnit,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: questsAsync.when(
                          data: (state) {
                            final total = state.quests.length;
                            final completed =
                                state.progress.where((p) => p.completed).length;
                            return _HeroStatChip(
                              label: l10n.todayHeroQuestsLabel,
                              value: total > 0 ? '$completed/$total' : '—',
                              unit: l10n.todayHeroQuestsToday,
                            );
                          },
                          loading: () => _HeroStatChip(
                            label: l10n.todayHeroQuestsLabel,
                            value: '—',
                            unit: l10n.todayHeroQuestsToday,
                          ),
                          error: (_, __) => _HeroStatChip(
                            label: l10n.todayHeroQuestsLabel,
                            value: '—',
                            unit: l10n.todayHeroQuestsToday,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppSurface.borderColor(context)),
              ),
              child: TodayJourneyMiniStrip(
                seasonId: seasonId,
                dayIndex: dayIndex,
                showShields: false,
                showQuestCountInHeadline: false,
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _HeroStatChip({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outline.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                  letterSpacing: 0.4,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
          ),
          Text(
            unit,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}
