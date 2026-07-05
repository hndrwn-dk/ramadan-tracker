import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Progress ring for checklist header — theme primary, premium center fill.
class ChecklistProgressRing extends StatelessWidget {
  final double progress;
  final int completed;
  final int total;
  final double size;
  final double strokeWidth;

  const ChecklistProgressRing({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    this.size = 60,
    this.strokeWidth = 5.5,
  });

  bool get _isComplete => progress >= 1.0 && total > 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final clamped = progress.clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _ChecklistProgressRingPainter(
              progress: clamped,
              strokeWidth: strokeWidth,
              trackColor: scheme.primary.withValues(alpha: 0.14),
              progressColor: scheme.primary,
              innerFillColor: _isComplete
                  ? scheme.primary.withValues(alpha: 0.14)
                  : scheme.primaryContainer.withValues(alpha: 0.45),
              complete: _isComplete,
            ),
          ),
          if (_isComplete)
            Icon(
              Icons.check_rounded,
              size: size * 0.36,
              color: scheme.primary,
            )
          else if (total > 0)
            Text(
              '$completed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                    height: 1,
                  ),
            ),
        ],
      ),
    );
  }
}

class _ChecklistProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color progressColor;
  final Color innerFillColor;
  final bool complete;

  _ChecklistProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.progressColor,
    required this.innerFillColor,
    required this.complete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final innerRadius = radius - strokeWidth * 0.65;

    canvas.drawCircle(
      center,
      innerRadius,
      Paint()..color = innerFillColor,
    );

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (complete) {
      canvas.drawCircle(center, radius, progressPaint);
    } else if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChecklistProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.innerFillColor != innerFillColor ||
        oldDelegate.complete != complete;
  }
}
