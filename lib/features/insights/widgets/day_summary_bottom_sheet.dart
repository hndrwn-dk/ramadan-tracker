import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Day Summary Bottom Sheet
class DaySummaryBottomSheet extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final int score;
  final Map<String, dynamic> drivers;
  final String? mood;
  final String? reflection;
  final SeasonModel season;
  final VoidCallback onOpenDay;

  const DaySummaryBottomSheet({
    super.key,
    required this.dayIndex,
    required this.date,
    required this.score,
    required this.drivers,
    this.mood,
    this.reflection,
    required this.season,
    required this.onOpenDay,
  });

  static void show(
    BuildContext context, {
    required int dayIndex,
    required DateTime date,
    required int score,
    required Map<String, dynamic> drivers,
    String? mood,
    String? reflection,
    required SeasonModel season,
    required VoidCallback onOpenDay,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => DaySummaryBottomSheet(
        dayIndex: dayIndex,
        date: date,
        score: score,
        drivers: drivers,
        mood: mood,
        reflection: reflection,
        season: season,
        onOpenDay: onOpenDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMM d, yyyy').format(date),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Day $dayIndex of ${season.days}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$score%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: _getScoreColor(score),
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Mood
                if (mood != null) ...[
                  Row(
                    children: [
                      Icon(
                        _getMoodIcon(mood!),
                        size: 18,
                        color: _getMoodColor(mood!),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mood: ${_getMoodDisplayName(mood!)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                // Score drivers
                if (drivers.isNotEmpty) ...[
                  Text(
                    'Score Drivers',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: drivers.entries.map((entry) {
                      return Chip(
                        label: Text('${_getHabitDisplayName(entry.key)}: ${entry.value}'),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Reflection
                if (reflection != null && reflection!.isNotEmpty) ...[
                  Text(
                    'Reflection',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reflection!,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onOpenDay();
                    },
                    icon: const Icon(Icons.today, size: 18),
                    label: const Text('Open Day'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score == 100) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
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

