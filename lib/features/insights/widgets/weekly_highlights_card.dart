import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Weekly Highlights Card showing insights
class WeeklyHighlightsCard extends StatelessWidget {
  final String? mostConsistentTask;
  final String? needsAttentionTask;
  final String? biggestImprovementTask;
  final Function(String habitKey) onTaskTap;

  const WeeklyHighlightsCard({
    super.key,
    this.mostConsistentTask,
    this.needsAttentionTask,
    this.biggestImprovementTask,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnyHighlight = mostConsistentTask != null ||
        needsAttentionTask != null ||
        biggestImprovementTask != null;

    if (!hasAnyHighlight) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Highlights',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          if (mostConsistentTask != null)
            _buildHighlightItem(
              context,
              icon: Icons.trending_up,
              iconColor: Colors.green,
              title: 'Most consistent',
              taskKey: mostConsistentTask!,
              onTap: () => onTaskTap(mostConsistentTask!),
            ),
          if (needsAttentionTask != null) ...[
            if (mostConsistentTask != null) const SizedBox(height: 12),
            _buildHighlightItem(
              context,
              icon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              title: 'Needs attention',
              taskKey: needsAttentionTask!,
              onTap: () => onTaskTap(needsAttentionTask!),
            ),
          ],
          if (biggestImprovementTask != null) ...[
            if (mostConsistentTask != null || needsAttentionTask != null) const SizedBox(height: 12),
            _buildHighlightItem(
              context,
              icon: Icons.arrow_upward,
              iconColor: Colors.blue,
              title: 'Biggest improvement',
              taskKey: biggestImprovementTask!,
              onTap: () => onTaskTap(biggestImprovementTask!),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String taskKey,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getHabitDisplayName(taskKey),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }

  String _getHabitDisplayName(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return 'Fasting';
      case 'prayers':
        return '5 Prayers';
      case 'quran_pages':
        return 'Quran';
      case 'dhikr':
        return 'Dhikr';
      case 'taraweeh':
        return 'Taraweeh';
      case 'sedekah':
        return 'Sedekah';
      case 'itikaf':
        return "I'tikaf";
      default:
        return habitKey;
    }
  }
}

