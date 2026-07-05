import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Day Summary Bottom Sheet
class DaySummaryBottomSheet extends StatelessWidget {
  final int dayIndex;
  final DateTime date;
  final int score;
  final Map<String, dynamic> drivers;
  final SeasonModel season;
  final VoidCallback onOpenDay;

  const DaySummaryBottomSheet({
    super.key,
    required this.dayIndex,
    required this.date,
    required this.score,
    required this.drivers,
    required this.season,
    required this.onOpenDay,
  });

  static void show(
    BuildContext context, {
    required int dayIndex,
    required DateTime date,
    required int score,
    required Map<String, dynamic> drivers,
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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppSurface.borderColor(context),
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
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getHabitDisplayName(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return 'Fasting';
      case 'quran_pages':
        return 'Quran';
      case 'dhikr':
        return 'Dhikr';
      case 'taraweeh':
        return 'Taraweeh';
      case 'sedekah':
        return 'Sedekah';
      case 'prayers':
        return 'Prayers';
      case 'tahajud':
        return 'Tahajud';
      case 'itikaf':
        return 'I\'tikaf';
      default:
        return habitKey;
    }
  }
}
