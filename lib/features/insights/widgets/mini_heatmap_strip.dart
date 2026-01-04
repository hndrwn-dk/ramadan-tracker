import 'package:flutter/material.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Status for a single day in the heatmap
class DayStatus {
  final int dayIndex;
  final double completion; // 0.0 to 1.0 (for numeric habits) or 0.0/1.0 (for binary)
  final bool isToday;

  DayStatus({
    required this.dayIndex,
    required this.completion,
    this.isToday = false,
  });
}

/// Mini heatmap strip showing 29-day Ramadan progress
class MiniHeatmapStrip extends StatelessWidget {
  final List<DayStatus> days;
  final int selectedDayIndex;
  final Function(int dayIndex) onDayTap;
  final SeasonModel season;

  const MiniHeatmapStrip({
    super.key,
    required this.days,
    required this.selectedDayIndex,
    required this.onDayTap,
    required this.season,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ramadan Progress',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
            ),
            Row(
              children: [
                _buildLegendItem(context, 'Done', Colors.green),
                const SizedBox(width: 8),
                _buildLegendItem(context, 'Partial', Colors.orange),
                const SizedBox(width: 8),
                _buildLegendItem(context, 'Miss', Colors.red.withOpacity(0.3)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: days.map((day) {
            return GestureDetector(
              onTap: () => onDayTap(day.dayIndex),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: _getDayColor(context, day.completion),
                  borderRadius: BorderRadius.circular(4),
                  border: day.isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 2,
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
        ),
      ],
    );
  }

  Color _getDayColor(BuildContext context, double completion) {
    if (completion >= 1.0) {
      return Colors.green;
    } else if (completion > 0.0) {
      return Colors.orange;
    } else {
      return Colors.red.withOpacity(0.3);
    }
  }
}


