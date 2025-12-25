import 'package:ramadan_tracker/data/database/app_database.dart';

class AutopilotService {
  static const double quranMinutesPerPage = 1.5;
  static const double dhikrMinutesPerCount = 0.02;

  static Future<AutopilotPlan> generatePlan({
    required int seasonId,
    required int currentDayIndex,
    required int totalDays,
    required AutopilotIntensity intensity,
    required TimeBlocks timeBlocks,
    required QuranPlanData? quranPlan,
    required DhikrPlanData? dhikrPlan,
    required AppDatabase database,
  }) async {
    final quranDaily = await database.quranDailyDao.getAllDaily(seasonId);
    final totalPagesRead = quranDaily.fold<int>(
      0,
      (sum, entry) => sum + (entry.pagesRead as int),
    );

    final totalPages = quranPlan?.totalPages ?? 600;
    final remainingPages = (totalPages - totalPagesRead).clamp(0, totalPages);
    final remainingDays = (totalDays - currentDayIndex + 1).clamp(1, totalDays);

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
    final qiyamMinutes = _getQiyamMinutes(intensity);

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

  static int _getQiyamMinutes(AutopilotIntensity intensity) {
    switch (intensity) {
      case AutopilotIntensity.light:
        return 10;
      case AutopilotIntensity.balanced:
        return 20;
      case AutopilotIntensity.strong:
        return 30;
    }
  }
}

enum AutopilotIntensity {
  light,
  balanced,
  strong,
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

