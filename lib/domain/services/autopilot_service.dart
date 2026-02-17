import 'package:flutter/foundation.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';

class AutopilotService {
  static const double quranMinutesPerPage = 1.5;
  static const double dhikrMinutesPerCount = 0.02;
  static const int quranTotalPages = 604; // Total pages of complete Quran

  static Future<AutopilotPlan> generatePlan({
    required int seasonId,
    required int currentDayIndex,
    required int totalDays,
    required TimeBlocks timeBlocks,
    required QuranPlanData? quranPlan,
    required DhikrPlanData? dhikrPlan,
    required AppDatabase database,
  }) async {
    final quranDaily = await database.quranDailyDao.getAllDaily(seasonId);
    // Only sum pages from days up to current day (don't count future days)
    // Also only count entries that actually have pages read (exclude 0 or null)
    final totalPagesRead = quranDaily
        .where((entry) => entry.dayIndex <= currentDayIndex && (entry.pagesRead as int? ?? 0) > 0)
        .fold<int>(
          0,
          (sum, entry) {
            final pages = entry.pagesRead as int? ?? 0;
            return sum + pages;
          },
        );

    // Total Quran is always 604 pages regardless of goal (1 khatam, 2 khatam, or custom)
    final totalPages = quranTotalPages;
    final remainingPages = (totalPages - totalPagesRead).clamp(0, totalPages);
    
    // Debug logging to verify calculation
    debugPrint('AutopilotService.generatePlan:');
    debugPrint('  quranTotalPages (constant) = $quranTotalPages');
    debugPrint('  totalPagesRead = $totalPagesRead');
    debugPrint('  remainingPages = $remainingPages');
    debugPrint('  quranDaily entries (filtered): ${quranDaily.where((e) => e.dayIndex <= currentDayIndex && (e.pagesRead as int? ?? 0) > 0).length}');
    for (final entry in quranDaily.where((e) => e.dayIndex <= currentDayIndex)) {
      debugPrint('    Day ${entry.dayIndex}: ${entry.pagesRead} pages');
    }
    // Days left = total days minus current day (e.g., if day 1 of 29, then 28 days left)
    final remainingDays = (totalDays - currentDayIndex).clamp(0, totalDays);

    final defaultDailyTarget = quranPlan?.dailyTargetPages ?? 20;
    
    int baseDailyPages = defaultDailyTarget;
    if (remainingDays > 0 && remainingPages > 0) {
      final calculated = (remainingPages / remainingDays).ceil();
      baseDailyPages = calculated.clamp(1, remainingPages);
    }
    
    final capIncrease = quranPlan?.catchupCapPages ?? 5;
    final dailyTarget = baseDailyPages.clamp(
      defaultDailyTarget,
      defaultDailyTarget + capIncrease,
    );
    
    if (dailyTarget > defaultDailyTarget + capIncrease) {
      final warning = 'Daily target ($dailyTarget pages) exceeds recommended cap. Consider adjusting your goal.';
    }

    final dhikrTarget = dhikrPlan?.dailyTarget ?? 100;

    final quranMinutes = dailyTarget * quranMinutesPerPage;
    final dhikrMinutes = dhikrTarget * dhikrMinutesPerCount;
    const qiyamMinutes = 20;

    final morningTasks = <Task>[];
    final dayTasks = <Task>[];
    final nightTasks = <Task>[];

    int morningUsed = 0;
    int dayUsed = 0;
    int nightUsed = 0;

    if (timeBlocks.morning >= quranMinutes) {
      morningTasks.add(Task(
        name: 'Quran Reading',
        minutes: quranMinutes.round(),
        pages: dailyTarget,
      ));
      morningUsed += quranMinutes.round();
    } else if (timeBlocks.day >= quranMinutes) {
      dayTasks.add(Task(
        name: 'Quran Reading',
        minutes: quranMinutes.round(),
        pages: dailyTarget,
      ));
      dayUsed += quranMinutes.round();
    } else {
      nightTasks.add(Task(
        name: 'Quran Reading',
        minutes: quranMinutes.round(),
        pages: dailyTarget,
      ));
      nightUsed += quranMinutes.round();
    }

    if (timeBlocks.night >= qiyamMinutes) {
      nightTasks.add(Task(
        name: 'Qiyam',
        minutes: qiyamMinutes,
      ));
      nightUsed += qiyamMinutes;
    }

    if (timeBlocks.morning - morningUsed >= dhikrMinutes) {
      morningTasks.add(Task(
        name: 'Dhikr',
        minutes: dhikrMinutes.round(),
        count: dhikrTarget,
      ));
    } else if (timeBlocks.day - dayUsed >= dhikrMinutes) {
      dayTasks.add(Task(
        name: 'Dhikr',
        minutes: dhikrMinutes.round(),
        count: dhikrTarget,
      ));
    } else {
      nightTasks.add(Task(
        name: 'Dhikr',
        minutes: dhikrMinutes.round(),
        count: dhikrTarget,
      ));
    }

    return AutopilotPlan(
      morning: TimelineBlock(
        tasks: morningTasks,
        totalMinutes: morningUsed,
      ),
      day: TimelineBlock(
        tasks: dayTasks,
        totalMinutes: dayUsed,
      ),
      night: TimelineBlock(
        tasks: nightTasks,
        totalMinutes: nightUsed,
      ),
      quranRemainingPages: remainingPages,
      quranRemainingDays: remainingDays,
      quranDailyTarget: dailyTarget,
      dhikrTarget: dhikrTarget,
    );
  }

}

class TimeBlocks {
  final int morning;
  final int day;
  final int night;

  TimeBlocks({
    required this.morning,
    required this.day,
    required this.night,
  });
}

class AutopilotPlan {
  final TimelineBlock morning;
  final TimelineBlock day;
  final TimelineBlock night;
  final int quranRemainingPages;
  final int quranRemainingDays;
  final int quranDailyTarget;
  final int dhikrTarget;

  AutopilotPlan({
    required this.morning,
    required this.day,
    required this.night,
    required this.quranRemainingPages,
    required this.quranRemainingDays,
    required this.quranDailyTarget,
    required this.dhikrTarget,
  });
}

class TimelineBlock {
  final List<Task> tasks;
  final int totalMinutes;

  TimelineBlock({
    required this.tasks,
    required this.totalMinutes,
  });
}

class Task {
  final String name;
  final int minutes;
  final int? pages;
  final int? count;

  Task({
    required this.name,
    required this.minutes,
    this.pages,
    this.count,
  });
}

