import 'package:flutter/material.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/share_card.dart';

/// Shareable end-of-season summary card.
class SeasonShareCard extends StatelessWidget {
  final String seasonLabel;
  final int avgScore;
  final int strongDays;
  final int totalDays;
  final int longestStreak;
  final int unlockedCount;
  final List<AchievementDefinition> highlights;
  final AppLocalizations l10n;

  const SeasonShareCard({
    super.key,
    required this.seasonLabel,
    required this.avgScore,
    required this.strongDays,
    required this.totalDays,
    required this.longestStreak,
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
              Icon(Icons.emoji_events, color: scheme.onPrimary, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.seasonShareTitle,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            seasonLabel,
            style: TextStyle(
              color: scheme.onPrimary.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.seasonReportAvgScore('$avgScore'),
            style: TextStyle(color: scheme.onPrimary, fontSize: 15),
          ),
          Text(
            l10n.seasonReportPerfectDays(strongDays, totalDays),
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9), fontSize: 14),
          ),
          Text(
            l10n.seasonReportLongestStreak(longestStreak),
            style: TextStyle(color: scheme.onPrimary.withValues(alpha: 0.9), fontSize: 14),
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
            l10n.seasonShareTagline,
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

Future<void> showSeasonShareDialog({
  required BuildContext context,
  required String seasonLabel,
  required int avgScore,
  required int strongDays,
  required int totalDays,
  required int longestStreak,
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
              child: SeasonShareCard(
                seasonLabel: seasonLabel,
                avgScore: avgScore,
                strongDays: strongDays,
                totalDays: totalDays,
                longestStreak: longestStreak,
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
                  fileName: 'season-report.png',
                  text: l10n.seasonShareTitle,
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
