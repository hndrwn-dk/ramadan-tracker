import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/features/engagement/widgets/achievement_share_card.dart';
import 'package:ramadan_tracker/features/insights/screens/season_report_screen.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// End-of-season summary shown once when opening Month after Ramadan ends.
class SeasonTrophySheet {
  SeasonTrophySheet._();

  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final seasonState = ref.read(seasonStateProvider);
    if (seasonState != SeasonState.postRamadan) return;

    final season = await ref.read(currentSeasonProvider.future);
    if (season == null) return;

    final db = ref.read(databaseProvider);
    final flagKey = 'season_trophy_shown_${season.id}';
    final shown = await db.kvSettingsDao.getValue(flagKey);
    if (shown == 'true') return;

    await evaluateSeasonCompleteAchievements(ref, seasonId: season.id);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _SeasonTrophyBody(seasonId: season.id, seasonLabel: season.label),
    );

    await db.kvSettingsDao.setValue(flagKey, 'true');
  }
}

class _SeasonTrophyBody extends ConsumerWidget {
  final int seasonId;
  final String seasonLabel;

  const _SeasonTrophyBody({required this.seasonId, required this.seasonLabel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final engagementAsync = ref.watch(userEngagementProvider);
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Material(
          color: Theme.of(context).colorScheme.surface,
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.seasonTrophyTitle,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                seasonLabel,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.seasonTrophyMessage,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              engagementAsync.when(
                data: (e) => AppSurface(
                  child: Column(
                    children: [
                      Text(l10n.companionLevelLabel(e.companionLevel)),
                      Text(l10n.totalXpLabel(e.totalXp)),
                    ],
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              unlockedAsync.when(
                data: (list) {
                  final keys = list.map((u) => u.achievementKey).toSet();
                  final scheme = Theme.of(context).colorScheme;
                  return Column(
                    children: [
                      Text(
                        l10n.achievementsUnlockedCount(list.length),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (keys.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          l10n.seasonReportTrophies,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: AchievementCatalog.all.map((def) {
                            final unlocked = keys.contains(def.key);
                            final title = CelebrationListenerHelper.titleFor(l10n, def.titleKey);
                            return SizedBox(
                              width: 72,
                              child: Column(
                                children: [
                                  Icon(
                                    def.icon,
                                    size: 26,
                                    color: unlocked
                                        ? scheme.primary
                                        : scheme.onSurface.withValues(alpha: 0.2),
                                  ),
                                  if (unlocked)
                                    Text(
                                      title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context).textTheme.labelSmall,
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              unlockedAsync.when(
                data: (list) {
                  final highlights = AchievementCatalog.all
                      .where((d) => list.any((u) => u.achievementKey == d.key))
                      .take(3)
                      .toList();
                  return engagementAsync.when(
                    data: (e) => OutlinedButton.icon(
                      onPressed: highlights.isEmpty
                          ? null
                          : () async {
                              await showAchievementShareDialog(
                                context: context,
                                companionLevel: e.companionLevel,
                                totalXp: e.totalXp,
                                unlockedCount: list.length,
                                highlights: highlights,
                              );
                            },
                      icon: const Icon(Icons.share_outlined),
                      label: Text(l10n.shareAction),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SeasonReportScreen(seasonId: seasonId),
                    ),
                  );
                },
                child: Text(l10n.seasonReportViewReport),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.seasonTrophyDismiss),
              ),
            ],
          ),
        );
      },
    );
  }
}
