import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';

/// Mood & Reflection Season Card
class MoodReflectionSeasonCard extends StatelessWidget {
  final ReflectionSeasonAnalytics analytics;
  final VoidCallback onReviewReflections;

  const MoodReflectionSeasonCard({
    super.key,
    required this.analytics,
    required this.onReviewReflections,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sentiment_satisfied_alt,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Mood & Reflection',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mood distribution
          if (analytics.mostCommonMood != null) ...[
            Text(
              'Most common mood: ${_getMoodDisplayName(analytics.mostCommonMood!)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          // Mood counts
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analytics.moodCounts.entries.map((entry) {
              if (entry.value == 0) return const SizedBox.shrink();
              return _buildMoodChip(
                context,
                entry.key,
                entry.value,
                analytics.avgScoreByMood[entry.key],
              );
            }).toList(),
          ),
          if (analytics.avgScoreByMood.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Average score by mood:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            ...analytics.avgScoreByMood.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getMoodDisplayName(entry.key),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onReviewReflections,
              icon: const Icon(Icons.book_outlined, size: 16),
              label: const Text('Review reflections'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodChip(BuildContext context, String mood, int count, double? avgScore) {
    return Chip(
      avatar: Icon(
        _getMoodIcon(mood),
        size: 16,
        color: _getMoodColor(mood),
      ),
      label: Text(
        '${_getMoodDisplayName(mood)}: $count',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood) {
      case 'excellent':
        return Icons.sentiment_very_satisfied;
      case 'good':
        return Icons.sentiment_satisfied;
      case 'ok':
        return Icons.sentiment_neutral;
      case 'difficult':
        return Icons.sentiment_very_dissatisfied;
      default:
        return Icons.sentiment_neutral;
    }
  }

  Color _getMoodColor(String mood) {
    switch (mood) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'ok':
        return Colors.orange;
      case 'difficult':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getMoodDisplayName(String mood) {
    switch (mood) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'ok':
        return 'Ok';
      case 'difficult':
        return 'Difficult';
      default:
        return mood;
    }
  }
}

