import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Season Audit Bottom Sheet
class SeasonAuditBottomSheet extends StatelessWidget {
  final List<SeasonDayStatus> dayStatuses;
  final SeasonModel season;
  final Function(int dayIndex) onAuditDay;

  const SeasonAuditBottomSheet({
    super.key,
    required this.dayStatuses,
    required this.season,
    required this.onAuditDay,
  });

  static void show(
    BuildContext context, {
    required List<SeasonDayStatus> dayStatuses,
    required SeasonModel season,
    required Function(int dayIndex) onAuditDay,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SeasonAuditBottomSheet(
        dayStatuses: dayStatuses,
        season: season,
        onAuditDay: onAuditDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missedDays = dayStatuses.where((d) => d.status != 'Perfect' && d.status != 'Untracked').toList();
    final untrackedDays = dayStatuses.where((d) => d.status == 'Untracked').toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Season Audit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 24),
                  // Missed Days
                  if (missedDays.isNotEmpty) ...[
                    Text(
                      'Missed Days',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...missedDays.map((dayStatus) {
                      return _buildDayCard(
                        context,
                        dayStatus: dayStatus,
                        onTap: () {
                          Navigator.pop(context);
                          onAuditDay(dayStatus.dayIndex);
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                  // Untracked Days
                  if (untrackedDays.isNotEmpty) ...[
                    Text(
                      'Untracked Days',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...untrackedDays.map((dayStatus) {
                      return _buildDayCard(
                        context,
                        dayStatus: dayStatus,
                        onTap: () {
                          Navigator.pop(context);
                          onAuditDay(dayStatus.dayIndex);
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                  // Quick Fix Suggestions
                  Text(
                    'Quick Fix Suggestions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildSuggestionCard(
                    context,
                    'Review missed days to identify patterns and improve consistency.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(
    BuildContext context, {
    required SeasonDayStatus dayStatus,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Text(
              DateFormat('MMM d, yyyy').format(dayStatus.date),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Day ${dayStatus.dayIndex}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getStatusColor(dayStatus.status).withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${dayStatus.score}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getStatusColor(dayStatus.status),
                    ),
              ),
            ),
          ],
        ),
        subtitle: dayStatus.missedTasks.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: dayStatus.missedTasks.map((taskKey) {
                    return Chip(
                      label: Text(
                        _getHabitDisplayName(taskKey),
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              )
            : null,
        trailing: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          child: const Text('Audit'),
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(BuildContext context, String text) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Perfect':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Low':
        return Colors.red;
      default:
        return Colors.grey;
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

