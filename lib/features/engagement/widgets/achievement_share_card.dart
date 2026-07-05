import 'package:flutter/material.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/share_card.dart';

/// Shareable card for unlocked achievements + companion level.
class AchievementShareCard extends StatelessWidget {
  final int companionLevel;
  final int totalXp;
  final int unlockedCount;
  final List<AchievementDefinition> highlights;
  final AppLocalizations l10n;

  const AchievementShareCard({
    super.key,
    required this.companionLevel,
    required this.totalXp,
    required this.unlockedCount,
    required this.highlights,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 340,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.25), scheme.primary),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.military_tech, color: scheme.onPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                l10n.achievementsTitle,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            l10n.companionLevelLabel(companionLevel),
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            l10n.totalXpLabel(totalXp),
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l10n.achievementsUnlockedCount(unlockedCount),
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          if (highlights.isNotEmpty) ...[
            const SizedBox(height: 16),
            Divider(color: scheme.onPrimary.withValues(alpha: 0.25)),
            const SizedBox(height: 8),
            ...highlights.take(3).map((def) {
              final title = CelebrationListenerHelper.titleFor(l10n, def.titleKey);
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(def.icon, color: scheme.onPrimary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.95),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          Text(
            l10n.achievementShareTagline,
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.75),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showAchievementShareDialog({
  required BuildContext context,
  required int companionLevel,
  required int totalXp,
  required int unlockedCount,
  required List<AchievementDefinition> highlights,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final boundaryKey = GlobalKey();
  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: boundaryKey,
              child: AchievementShareCard(
                companionLevel: companionLevel,
                totalXp: totalXp,
                unlockedCount: unlockedCount,
                highlights: highlights,
                l10n: l10n,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await ShareCard.captureAndShare(
                  boundaryKey,
                  fileName: 'achievements.png',
                  text: l10n.achievementsTitle,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.share),
              label: Text(l10n.shareAction),
            ),
          ],
        ),
      );
    },
  );
}
