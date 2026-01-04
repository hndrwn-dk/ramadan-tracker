import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum TaskKey {
  fasting,
  quran,
  dhikr,
  taraweeh,
  sedekah,
  prayers5,
  itikaf,
}

enum TaskType {
  boolean,
  counter,
  amount,
  composite,
}

class TaskInsightSummary {
  final TaskKey taskKey;
  final double completionRate; // 0..1
  final int? streak; // null if not applicable
  final int? bestDay; // dayIndex with best performance
  final int? worstDay; // dayIndex with worst performance
  final bool needAttention;
  final List<FlSpot> chartSeries;
  final Map<String, dynamic> metadata; // task-specific data

  TaskInsightSummary({
    required this.taskKey,
    required this.completionRate,
    this.streak,
    this.bestDay,
    this.worstDay,
    required this.needAttention,
    required this.chartSeries,
    this.metadata = const {},
  });
}

class Highlight {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color? colorHint;

  Highlight({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.colorHint,
  });
}

class NextAction {
  final TaskKey taskKey;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? quickValue; // e.g., "+33", "+100" for quick add

  NextAction({
    required this.taskKey,
    required this.label,
    required this.icon,
    required this.onTap,
    this.quickValue,
  });
}

class OverallSummary {
  final double todayCompletionPercent;
  final double weekCompletionPercent;
  final double monthCompletionPercent;
  final int currentStreakDays;
  final int bestStreakDays;
  final int daysStrong; // >= 0.8
  final int daysOk; // 0.5-0.8
  final int daysLow; // < 0.5
  final double scoreToday; // 0..100
  final String explanation;

  OverallSummary({
    required this.todayCompletionPercent,
    required this.weekCompletionPercent,
    required this.monthCompletionPercent,
    required this.currentStreakDays,
    required this.bestStreakDays,
    required this.daysStrong,
    required this.daysOk,
    required this.daysLow,
    required this.scoreToday,
    required this.explanation,
  });
}

class InsightsResult {
  final OverallSummary overallSummary;
  final Map<TaskKey, TaskInsightSummary> taskSummaries;
  final List<Highlight> highlights;
  final List<NextAction> nextActions;
  final Map<int, double> dayCompletions; // dayIndex -> completion score (0..1)

  InsightsResult({
    required this.overallSummary,
    required this.taskSummaries,
    required this.highlights,
    required this.nextActions,
    required this.dayCompletions,
  });
}

