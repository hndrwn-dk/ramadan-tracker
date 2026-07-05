import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/features/engagement/widgets/achievement_share_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Shows achievement unlock modals from [pendingCelebrationsProvider].
class CelebrationListener extends ConsumerWidget {
  final Widget child;

  const CelebrationListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<List<dynamic>>(pendingCelebrationsProvider, (prev, next) {
      if (next.isEmpty) return;
      if (prev != null && prev.isNotEmpty && prev.first == next.first) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        _showCelebration(context, ref, next.first);
      });
    });

    return child;
  }

  void _showCelebration(BuildContext context, WidgetRef ref, dynamic unlock) {
    final l10n = AppLocalizations.of(context)!;
    final definition = unlock.definition;
    final title = _localized(l10n, definition.titleKey);
    final description = _localized(l10n, definition.descriptionKey);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        icon: Icon(definition.icon, size: 48, color: Theme.of(ctx).colorScheme.primary),
        title: Text(l10n.achievementUnlocked),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(ctx).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (unlock.xpAwarded > 0) ...[
              const SizedBox(height: 12),
              Text(
                l10n.achievementXpGained(unlock.xpAwarded),
                style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      color: Theme.of(ctx).colorScheme.primary,
                    ),
              ),
            ],
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          TextButton(
            onPressed: () async {
              final engagement = ref.read(userEngagementProvider).valueOrNull;
              final unlocked = ref.read(unlockedAchievementsProvider).valueOrNull ?? [];
              if (engagement != null) {
                await showAchievementShareDialog(
                  context: ctx,
                  companionLevel: engagement.companionLevel,
                  totalXp: engagement.totalXp,
                  unlockedCount: unlocked.length,
                  highlights: [definition],
                );
              }
            },
            child: Text(l10n.shareAction),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              dismissCelebration(ref);
            },
            child: Text(l10n.continueButton),
          ),
        ],
      ),
    );
  }

  String _localized(AppLocalizations l10n, String key) {
    switch (key) {
      case 'achievementFirstLogTitle':
        return l10n.achievementFirstLogTitle;
      case 'achievementFirstLogDesc':
        return l10n.achievementFirstLogDesc;
      case 'achievementFirstFullDayTitle':
        return l10n.achievementFirstFullDayTitle;
      case 'achievementFirstFullDayDesc':
        return l10n.achievementFirstFullDayDesc;
      case 'achievementStreak3Title':
        return l10n.achievementStreak3Title;
      case 'achievementStreak3Desc':
        return l10n.achievementStreak3Desc;
      case 'achievementStreak7Title':
        return l10n.achievementStreak7Title;
      case 'achievementStreak7Desc':
        return l10n.achievementStreak7Desc;
      case 'achievementStreak14Title':
        return l10n.achievementStreak14Title;
      case 'achievementStreak14Desc':
        return l10n.achievementStreak14Desc;
      case 'achievementQuranHalfTitle':
        return l10n.achievementQuranHalfTitle;
      case 'achievementQuranHalfDesc':
        return l10n.achievementQuranHalfDesc;
      case 'achievementQuranCompleteTitle':
        return l10n.achievementQuranCompleteTitle;
      case 'achievementQuranCompleteDesc':
        return l10n.achievementQuranCompleteDesc;
      case 'achievementSeasonCompleteTitle':
        return l10n.achievementSeasonCompleteTitle;
      case 'achievementSeasonCompleteDesc':
        return l10n.achievementSeasonCompleteDesc;
      case 'achievementFirstSunnahTitle':
        return l10n.achievementFirstSunnahTitle;
      case 'achievementFirstSunnahDesc':
        return l10n.achievementFirstSunnahDesc;
      case 'achievementSeninKamis4Title':
        return l10n.achievementSeninKamis4Title;
      case 'achievementSeninKamis4Desc':
        return l10n.achievementSeninKamis4Desc;
      case 'achievementShawwalCompleteTitle':
        return l10n.achievementShawwalCompleteTitle;
      case 'achievementShawwalCompleteDesc':
        return l10n.achievementShawwalCompleteDesc;
      case 'achievementReflectionFirstTitle':
        return l10n.achievementReflectionFirstTitle;
      case 'achievementReflectionFirstDesc':
        return l10n.achievementReflectionFirstDesc;
      case 'achievementLast10Title':
        return l10n.achievementLast10Title;
      case 'achievementLast10Desc':
        return l10n.achievementLast10Desc;
      case 'achievementWeeklyPerfectTitle':
        return l10n.achievementWeeklyPerfectTitle;
      case 'achievementWeeklyPerfectDesc':
        return l10n.achievementWeeklyPerfectDesc;
      case 'achievementLevel5Title':
        return l10n.achievementLevel5Title;
      case 'achievementLevel5Desc':
        return l10n.achievementLevel5Desc;
      default:
        return key;
    }
  }
}

/// Shared title lookup for celebration + gallery + share cards.
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
