import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/services/weekly_insights_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Weekly Task Row with 7-cell mini strip
class WeeklyTaskRow extends StatelessWidget {
  final String habitKey;
  final String habitName;
  final IconData icon;
  final Widget? iconWidget;
  final WeeklyTaskStatus taskStatus;
  final SeasonModel season;
  final int startDayIndex;
  final Function(String habitKey, DateTime date) onCellTap;
  final VoidCallback onAnalyticsTap;

  const WeeklyTaskRow({
    super.key,
    required this.habitKey,
    required this.habitName,
    required this.icon,
    this.iconWidget,
    required this.taskStatus,
    required this.season,
    required this.startDayIndex,
    required this.onCellTap,
    required this.onAnalyticsTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Name
          Row(
            children: [
              iconWidget ?? Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  habitName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Weekly completion text
          Text(
            _buildCompletionText(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 12),
          // 7-cell mini strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              if (index >= taskStatus.statuses.length) {
                return const SizedBox(width: 32, height: 32);
              }
              final status = taskStatus.statuses[index];
              final dayIndex = startDayIndex + index;
              final date = season.startDate.add(Duration(days: dayIndex - 1));
              
              return GestureDetector(
                onTap: () => onCellTap(habitKey, date),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _getStatusColor(context, status),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Analytics CTA
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAnalyticsTap,
              icon: const Icon(Icons.analytics_outlined, size: 16),
              label: const Text('Analytics'),
            ),
          ),
        ],
      ),
    );
  }

  String _buildCompletionText() {
    if (habitKey == 'fasting' || habitKey == 'taraweeh' || habitKey == 'tahajud' || habitKey == 'itikaf') {
      return 'Done ${taskStatus.doneCount}/7';
    } else if (habitKey == 'prayers') {
      final avgCompleted = taskStatus.avgCompleted ?? 0.0;
      final perfectDays = taskStatus.perfectDaysCount ?? 0;
      return 'Perfect days $perfectDays/7 • Avg prayers/day ${avgCompleted.toStringAsFixed(1)}/5';
    } else if (habitKey == 'quran_pages' || habitKey == 'dhikr') {
      final avgActual = taskStatus.avgActual ?? 0.0;
      final target = taskStatus.target ?? 0.0;
      final metTarget = taskStatus.metTargetCount ?? 0;
      return 'Avg ${avgActual.toStringAsFixed(1)}/$target • Met target $metTarget/7';
    } else if (habitKey == 'sedekah') {
      final avgAmount = taskStatus.avgActual ?? 0.0;
      final metGoal = taskStatus.metTargetCount ?? 0;
      return 'Avg ${avgAmount.toStringAsFixed(0)} • Met goal $metGoal/7';
    }
    return 'Done ${taskStatus.doneCount}/7';
  }

  Color _getStatusColor(BuildContext context, String status) {
    switch (status) {
      case 'Done':
        return Colors.green.withOpacity(0.3);
      case 'Partial':
        return Colors.orange.withOpacity(0.3);
      case 'Miss':
        return Colors.red.withOpacity(0.2);
      default:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }
}

