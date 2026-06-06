import 'package:flutter/material.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/utils/share_card.dart';

/// A branded, shareable summary card for sunnah fasting stats.
class SunnahShareCard extends StatelessWidget {
  final SunnahStats stats;
  final SunnahStrings s;

  const SunnahShareCard({super.key, required this.stats, required this.s});

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
            Color.alphaBlend(Colors.black.withOpacity(0.25), scheme.primary),
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
              Icon(Icons.nightlight_round, color: scheme.onPrimary, size: 22),
              const SizedBox(width: 8),
              Text(
                s.shareStreakTitle,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '${stats.seninKamisStreak}',
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 64,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          Text(
            '${s.streak} (${s.weeksUnit})',
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.85),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _stat(scheme, '${stats.totalThisYear}', s.thisYear),
              const SizedBox(width: 24),
              _stat(scheme, '${stats.totalAllTime}', s.allTime),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: scheme.onPrimary.withOpacity(0.25)),
          const SizedBox(height: 8),
          Text(
            s.t('Puasa & Ibadah', 'Fasting & Worship'),
            style: TextStyle(
              color: scheme.onPrimary.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(ColorScheme scheme, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: TextStyle(
            color: scheme.onPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: scheme.onPrimary.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Shows a preview dialog of the share card with a Share button.
Future<void> showSunnahShareDialog(
  BuildContext context,
  SunnahStats stats,
  SunnahStrings s,
) async {
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
              child: SunnahShareCard(stats: stats, s: s),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                await ShareCard.captureAndShare(
                  boundaryKey,
                  fileName: 'sunnah_streak.png',
                  text: s.shareStreakTitle,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              icon: const Icon(Icons.share),
              label: Text(s.share),
            ),
          ],
        ),
      );
    },
  );
}
