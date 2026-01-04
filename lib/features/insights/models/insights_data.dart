import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/day_point.dart';
import 'package:ramadan_tracker/features/insights/models/habit_stats.dart';

class InsightsData {
  final InsightsRange rangeType;
  final DateTime startDate;
  final DateTime endDate;
  final int daysCount;
  final int avgScore; // 0-100
  final int totalScore; // 0 to daysCount*100
  final double completionRate; // percent of days with score==100
  final int currentStreak;
  final int bestStreak;
  final List<DayPoint> trendSeries;
  final Map<String, HabitStats> perHabitStats;

  InsightsData({
    required this.rangeType,
    required this.startDate,
    required this.endDate,
    required this.daysCount,
    required this.avgScore,
    required this.totalScore,
    required this.completionRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.trendSeries,
    required this.perHabitStats,
  });
}

