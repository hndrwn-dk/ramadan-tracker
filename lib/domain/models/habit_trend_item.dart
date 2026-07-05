import 'package:flutter/material.dart';

enum HabitTrendDirection { up, down, neutral }

class HabitTrendItem {
  final String habitKey;
  final String label;
  final String valueText;
  final HabitTrendDirection direction;
  final Color accentColor;

  const HabitTrendItem({
    required this.habitKey,
    required this.label,
    required this.valueText,
    required this.direction,
    required this.accentColor,
  });
}
