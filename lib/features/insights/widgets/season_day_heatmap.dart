import 'package:flutter/material.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';

/// Season Day Heatmap - 29/30 cells representing overall day status
class SeasonDayHeatmap extends StatelessWidget {
  final List<SeasonDayStatus> dayStatuses;
  final Function(int dayIndex) onDayTap;

  const SeasonDayHeatmap({
    super.key,
    required this.dayStatuses,
    required this.onDayTap,
  });

  @override
  Widget build(BuildContext context) {
    if (dayStatuses.isEmpty) {
      return const SizedBox.shrink();
    }

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Season Overview',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Flexible(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  alignment: WrapAlignment.end,
                  children: [
                    _buildLegendItem(context, 'Perfect', Colors.green),
                    _buildLegendItem(context, 'Partial', Colors.orange),
                    _buildLegendItem(context, 'Low', Colors.red),
                    _buildLegendItem(context, 'Untracked', Colors.grey),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: dayStatuses.map((dayStatus) {
              return GestureDetector(
                onTap: () => onDayTap(dayStatus.dayIndex),
                child: Tooltip(
                  message: 'Day ${dayStatus.dayIndex} • ${dayStatus.score}%',
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _getStatusColor(dayStatus.status),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${dayStatus.dayIndex}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: _getTextColor(dayStatus.status),
                            ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Perfect':
        return Colors.green.withOpacity(0.3);
      case 'Partial':
        return Colors.orange.withOpacity(0.3);
      case 'Low':
        return Colors.red.withOpacity(0.2);
      case 'Untracked':
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getTextColor(String status) {
    switch (status) {
      case 'Perfect':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Low':
        return Colors.red;
      case 'Untracked':
      default:
        return Colors.grey;
    }
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color, width: 1),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }
}
