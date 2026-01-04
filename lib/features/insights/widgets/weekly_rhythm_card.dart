import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/insights/services/weekly_insights_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Weekly Rhythm Card showing 7-day calendar strip and sparkline
class WeeklyRhythmCard extends StatelessWidget {
  final List<WeeklyDayStatus> dayStatuses;
  final SeasonModel season;
  final Function(DateTime date) onDayTap;

  const WeeklyRhythmCard({
    super.key,
    required this.dayStatuses,
    required this.season,
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
          Text(
            'Weekly Rhythm',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 16),
          // 7-column mini calendar strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: dayStatuses.map((dayStatus) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => onDayTap(dayStatus.date),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('E').format(dayStatus.date), // Mon, Tue, etc.
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${dayStatus.date.day}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: _getDayColor(context, dayStatus.status),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${dayStatus.score}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: _getTextColor(context, dayStatus.status),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Sparkline
          _buildSparkline(context),
        ],
      ),
    );
  }

  Widget _buildSparkline(BuildContext context) {
    if (dayStatuses.length < 2) {
      return const SizedBox.shrink();
    }

    final scores = dayStatuses.map((d) => d.score.toDouble()).toList();
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final range = maxScore - minScore;
    final normalizedScores = range > 0
        ? scores.map((s) => (s - minScore) / range).toList()
        : scores.map((_) => 0.5).toList();

    return Container(
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: CustomPaint(
        painter: _SparklinePainter(
          normalizedScores: normalizedScores,
          color: Theme.of(context).colorScheme.primary,
        ),
        size: Size.infinite,
      ),
    );
  }

  Color _getDayColor(BuildContext context, String status) {
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

  Color _getTextColor(BuildContext context, String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Miss':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.onSurface.withOpacity(0.5);
    }
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> normalizedScores;
  final Color color;

  _SparklinePainter({
    required this.normalizedScores,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (normalizedScores.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (normalizedScores.length - 1);
    final padding = 8.0;

    for (int i = 0; i < normalizedScores.length; i++) {
      final x = i * stepX;
      final y = size.height - (normalizedScores[i] * (size.height - padding * 2)) - padding;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < normalizedScores.length; i++) {
      final x = i * stepX;
      final y = size.height - (normalizedScores[i] * (size.height - padding * 2)) - padding;
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.normalizedScores != normalizedScores || oldDelegate.color != color;
  }
}

