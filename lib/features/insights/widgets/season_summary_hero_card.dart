import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';

/// Season Summary Hero Card for Season tab
class SeasonSummaryHeroCard extends StatelessWidget {
  final int seasonScore; // 0-100
  final int totalEarned;
  final int maxPossible;
  final int perfectDays;
  final int totalDays;
  final int bestStreak;
  final int missedDays;
  final VoidCallback onSeasonAudit;

  const SeasonSummaryHeroCard({
    super.key,
    required this.seasonScore,
    required this.totalEarned,
    required this.maxPossible,
    required this.perfectDays,
    required this.totalDays,
    required this.bestStreak,
    required this.missedDays,
    required this.onSeasonAudit,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How did my Ramadan go?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Season Score',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$seasonScore',
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
              ScoreRing(score: seasonScore.toDouble()),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildChip(
                context,
                Icons.check_circle,
                'Perfect days: $perfectDays/$totalDays',
              ),
              _buildChip(
                context,
                Icons.local_fire_department,
                'Best streak: $bestStreak days',
              ),
              _buildChip(
                context,
                Icons.warning_amber_rounded,
                'Missed days: $missedDays',
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSeasonAudit,
              icon: const Icon(Icons.search, size: 18),
              label: const Text('Season audit'),
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
