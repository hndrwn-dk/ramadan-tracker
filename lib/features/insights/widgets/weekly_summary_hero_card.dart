import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';

/// Weekly Summary Hero Card for 7 Days tab
class WeeklySummaryHeroCard extends StatelessWidget {
  final int weeklyScore; // 0-100
  final int totalEarned;
  final int maxPossible;
  final int bestStreak;
  final int perfectDays;
  final int totalDays;
  final int missedTasksCount;
  final VoidCallback onReviewMissedDays;

  const WeeklySummaryHeroCard({
    super.key,
    required this.weeklyScore,
    required this.totalEarned,
    required this.maxPossible,
    required this.bestStreak,
    required this.perfectDays,
    required this.totalDays,
    required this.missedTasksCount,
    required this.onReviewMissedDays,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-Day Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$weeklyScore',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Total: $totalEarned/$maxPossible',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                ),
              ),
              ScoreRing(score: weeklyScore.toDouble()),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                context,
                Icons.local_fire_department,
                'Best streak: $bestStreak days',
              ),
              _buildChip(
                context,
                Icons.check_circle,
                'Perfect days: $perfectDays/$totalDays',
              ),
              _buildChip(
                context,
                Icons.warning_amber_rounded,
                'Missed tasks: $missedTasksCount',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onReviewMissedDays,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Review missed days'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}

