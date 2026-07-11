import 'package:flutter/material.dart';
import 'dart:math' as math;

class ScoreRing extends StatelessWidget {
  final double score;
  final double size;
  final double strokeWidth;
  final String? label;

  const ScoreRing({
    super.key,
    required this.score,
    this.size = 120,
    this.strokeWidth = 12,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final innerPadding = math.max(6.0, size * 0.1);
    final contentSize = size - (strokeWidth * 2) - (innerPadding * 2);
    final scoreFontSize = size * 0.24;
    final labelFontSize = size * 0.13;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ScoreRingPainter(
              score: score,
              strokeWidth: strokeWidth,
            ),
          ),
          SizedBox(
            width: contentSize,
            height: contentSize,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${score.round()}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: scoreFontSize,
                      height: 1.0,
                      color: scheme.onSurface,
                    ),
                  ),
                  SizedBox(height: size * 0.03),
                  Text(
                    label ?? 'Score',
                    style: TextStyle(
                      fontSize: labelFontSize,
                      height: 1.0,
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double score;
  final double strokeWidth;

  _ScoreRingPainter({
    required this.score,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = _getScoreColor(score)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    final sweepAngle = (score / 100) * 2 * math.pi;
    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return const Color(0xFF4CAF50);
    if (score >= 60) return const Color(0xFFFFC107);
    return const Color(0xFFFF5722);
  }

  @override
  bool shouldRepaint(_ScoreRingPainter oldDelegate) {
    return oldDelegate.score != score;
  }
}
