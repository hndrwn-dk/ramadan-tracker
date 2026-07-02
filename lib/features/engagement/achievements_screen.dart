import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final engagementAsync = ref.watch(userEngagementProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          engagementAsync.when(
            data: (e) => PremiumCard(
              child: Row(
                children: [
                  Icon(Icons.military_tech, color: Theme.of(context).colorScheme.primary, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.companionLevelLabel(e.companionLevel),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          l10n.totalXpLabel(e.totalXp),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          unlockedAsync.when(
            data: (unlocked) {
              final unlockedKeys = unlocked.map((u) => u.achievementKey).toSet();
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: AchievementCatalog.all.length,
                itemBuilder: (context, index) {
                  final def = AchievementCatalog.all[index];
                  final isUnlocked = unlockedKeys.contains(def.key);
                  return _AchievementTile(definition: def, unlocked: isUnlocked);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text(l10n.errorMessage(e.toString())),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final AchievementDefinition definition;
  final bool unlocked;

  const _AchievementTile({required this.definition, required this.unlocked});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final title = CelebrationListenerHelper.titleFor(l10n, definition.titleKey);

    return Card(
      elevation: 0,
      color: unlocked
          ? scheme.primaryContainer.withValues(alpha: 0.4)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              definition.icon,
              size: 28,
              color: unlocked ? scheme.primary : scheme.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
                    color: unlocked ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.45),
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared title lookup for celebration + gallery.
class CelebrationListenerHelper {
  CelebrationListenerHelper._();

  static String titleFor(AppLocalizations l10n, String key) {
    switch (key) {
      case 'achievementFirstLogTitle':
        return l10n.achievementFirstLogTitle;
      case 'achievementFirstFullDayTitle':
        return l10n.achievementFirstFullDayTitle;
      case 'achievementStreak3Title':
        return l10n.achievementStreak3Title;
      case 'achievementStreak7Title':
        return l10n.achievementStreak7Title;
      case 'achievementStreak14Title':
        return l10n.achievementStreak14Title;
      case 'achievementQuranHalfTitle':
        return l10n.achievementQuranHalfTitle;
      case 'achievementQuranCompleteTitle':
        return l10n.achievementQuranCompleteTitle;
      case 'achievementSeasonCompleteTitle':
        return l10n.achievementSeasonCompleteTitle;
      case 'achievementFirstSunnahTitle':
        return l10n.achievementFirstSunnahTitle;
      case 'achievementSeninKamis4Title':
        return l10n.achievementSeninKamis4Title;
      case 'achievementShawwalCompleteTitle':
        return l10n.achievementShawwalCompleteTitle;
      case 'achievementReflectionFirstTitle':
        return l10n.achievementReflectionFirstTitle;
      case 'achievementLast10Title':
        return l10n.achievementLast10Title;
      case 'achievementWeeklyPerfectTitle':
        return l10n.achievementWeeklyPerfectTitle;
      case 'achievementLevel5Title':
        return l10n.achievementLevel5Title;
      default:
        return key;
    }
  }
}
