import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/features/insights/services/insights_scoring_service.dart';

/// Weekly insights data models
class WeeklyDayStatus {
  final int dayIndex;
  final DateTime date;
  final int score; // 0-100
  final String status; // 'Done', 'Partial', 'Miss', 'No data'
  final List<String> missedTasks; // List of habit keys that were missed

  WeeklyDayStatus({
    required this.dayIndex,
    required this.date,
    required this.score,
    required this.status,
    required this.missedTasks,
  });
}

class WeeklyTaskStatus {
  final String habitKey;
  final List<String> statuses; // 7 statuses: 'Done', 'Partial', 'Miss', 'No data'
  final int doneCount;
  final int partialCount;
  final int missCount;
  final double? avgActual;
  final double? target;
  final int? metTargetCount;
  final double? avgCompleted; // For prayers
  final int? perfectDaysCount; // For prayers

  WeeklyTaskStatus({
    required this.habitKey,
    required this.statuses,
    required this.doneCount,
    required this.partialCount,
    required this.missCount,
    this.avgActual,
    this.target,
    this.metTargetCount,
    this.avgCompleted,
    this.perfectDaysCount,
  });
}

class WeeklyHighlights {
  final String? mostConsistentTask;
  final String? needsAttentionTask;
  final String? biggestImprovementTask;

  WeeklyHighlights({
    this.mostConsistentTask,
    this.needsAttentionTask,
    this.biggestImprovementTask,
  });
}

class SedekahWeeklyData {
  final int totalAmount;
  final double avgAmount;
  final int daysMetGoal;
  final List<double> dailyAmounts; // 7 values

  SedekahWeeklyData({
    required this.totalAmount,
    required this.avgAmount,
    required this.daysMetGoal,
    required this.dailyAmounts,
  });
}

/// Service for computing weekly (7-day) insights data
class WeeklyInsightsService {
  /// Get last 7 days range ending at endDate (or today)
  static ({int startDayIndex, int endDayIndex, DateTime startDate, DateTime endDate}) getLast7DaysRange({
    required SeasonModel season,
    required int currentDayIndex,
  }) {
    final endDayIndex = currentDayIndex.clamp(1, season.days);
    final startDayIndex = (endDayIndex - 6).clamp(1, season.days);
    final startDate = season.startDate.add(Duration(days: startDayIndex - 1));
    final endDate = season.startDate.add(Duration(days: endDayIndex - 1));
    return (
      startDayIndex: startDayIndex,
      endDayIndex: endDayIndex,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get daily score for a specific day
  static Future<Map<String, dynamic>> getDayScore({
    required int seasonId,
    required int dayIndex,
    required SeasonModel season,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    required List<DailyEntryModel> entries,
    required AppDatabase database,
    QuranDailyData? quranDaily,
    PrayerDetail? prayerDetail,
  }) async {
    return await InsightsScoringService.calculateDailyScore(
      seasonId: seasonId,
      dayIndex: dayIndex,
      season: season,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      entries: entries,
      database: database,
      quranDaily: quranDaily,
      prayerDetail: prayerDetail,
    );
  }

  /// Get weekly score summary
  static Future<({
    int weeklyScore,
    int totalEarned,
    int maxPossible,
    int bestStreak,
    int perfectDays,
    int missedTasksCount,
  })> getWeeklyScore({
    required SeasonModel season,
    required int startDayIndex,
    required int endDayIndex,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(
      season.id,
      startDayIndex,
      endDayIndex,
    );

    final dayScores = <int, int>{};
    final missedTasksByDay = <int, List<String>>{};
    int totalEarned = 0;
    int perfectDays = 0;
    int bestStreak = 0;
    int tempStreak = 0;
    int totalMissedTasks = 0;

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final entries = allEntries
          .where((e) => e.dayIndex == day)
          .map((e) => DailyEntryModel(
                seasonId: e.seasonId,
                dayIndex: e.dayIndex,
                habitId: e.habitId,
                valueBool: e.valueBool,
                valueInt: e.valueInt,
                note: e.note,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
              ))
          .toList();

      final quran = allQuranDaily.firstWhere(
        (q) => q.dayIndex == day,
        orElse: () => QuranDailyData(
          seasonId: season.id,
          dayIndex: day,
          pagesRead: 0,
          updatedAt: 0,
        ),
      );

      final prayer = allPrayerDetails.firstWhere(
        (p) => p.dayIndex == day,
        orElse: () => PrayerDetail(
          seasonId: season.id,
          dayIndex: day,
          fajr: false,
          dhuhr: false,
          asr: false,
          maghrib: false,
          isha: false,
          updatedAt: 0,
        ),
      );

      final scoreResult = await getDayScore(
        seasonId: season.id,
        dayIndex: day,
        season: season,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        entries: entries,
        database: database,
        quranDaily: quran,
        prayerDetail: prayer,
      );

      final score = scoreResult['score'] as int;
      dayScores[day] = score;
      totalEarned += score;
      if (score == 100) {
        perfectDays++;
        tempStreak++;
        bestStreak = bestStreak > tempStreak ? bestStreak : tempStreak;
      } else {
        tempStreak = 0;
        // Calculate missed tasks for this day
        final missed = <String>[];
        // Check each habit
        for (final habit in allHabits) {
          final seasonHabit = seasonHabits.firstWhere(
            (sh) => sh.habitId == habit.id,
            orElse: () => throw StateError('Season habit not found'),
          );
          if (!seasonHabit.isEnabled) continue;
          if (habit.key == 'itikaf') {
            final last10Start = season.days - 9;
            if (day < last10Start) continue;
          }

          bool isMissed = false;
          if (habit.key == 'fasting' || habit.key == 'taraweeh' || habit.key == 'itikaf') {
            final entry = entries.firstWhere(
              (e) => e.habitId == habit.id,
              orElse: () => DailyEntryModel(
                seasonId: season.id,
                dayIndex: day,
                habitId: habit.id,
                updatedAt: DateTime.now(),
              ),
            );
            isMissed = entry.valueBool != true;
          } else if (habit.key == 'prayers') {
            final completed = [
              prayer.fajr,
              prayer.dhuhr,
              prayer.asr,
              prayer.maghrib,
              prayer.isha,
            ].where((p) => p).length;
            isMissed = completed < 5;
          } else if (habit.key == 'quran_pages') {
            final quranPlan = await database.quranPlanDao.getPlan(season.id);
            final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
            isMissed = quran.pagesRead < target;
          } else if (habit.key == 'dhikr') {
            final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
            final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
            final entry = entries.firstWhere(
              (e) => e.habitId == habit.id,
              orElse: () => DailyEntryModel(
                seasonId: season.id,
                dayIndex: day,
                habitId: habit.id,
                updatedAt: DateTime.now(),
              ),
            );
            isMissed = (entry.valueInt ?? 0) < target;
          } else if (habit.key == 'sedekah') {
            final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
            final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
            if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
              final target = double.tryParse(sedekahGoalAmount) ?? 0;
              final entry = entries.firstWhere(
                (e) => e.habitId == habit.id,
                orElse: () => DailyEntryModel(
                  seasonId: season.id,
                  dayIndex: day,
                  habitId: habit.id,
                  updatedAt: DateTime.now(),
                ),
              );
              isMissed = (entry.valueInt ?? 0) < target;
            }
          }
          if (isMissed) {
            missed.add(habit.key);
            totalMissedTasks++;
          }
        }
        missedTasksByDay[day] = missed;
      }
    }

    final daysCount = endDayIndex - startDayIndex + 1;
    final weeklyScore = daysCount > 0 ? (totalEarned / daysCount).round() : 0;
    final maxPossible = daysCount * 100;

    return (
      weeklyScore: weeklyScore,
      totalEarned: totalEarned,
      maxPossible: maxPossible,
      bestStreak: bestStreak,
      perfectDays: perfectDays,
      missedTasksCount: totalMissedTasks,
    );
  }

  /// Get weekly status for each day
  static Future<List<WeeklyDayStatus>> getWeeklyDayStatuses({
    required SeasonModel season,
    required int startDayIndex,
    required int endDayIndex,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(
      season.id,
      startDayIndex,
      endDayIndex,
    );

    final statuses = <WeeklyDayStatus>[];

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final entries = allEntries
          .where((e) => e.dayIndex == day)
          .map((e) => DailyEntryModel(
                seasonId: e.seasonId,
                dayIndex: e.dayIndex,
                habitId: e.habitId,
                valueBool: e.valueBool,
                valueInt: e.valueInt,
                note: e.note,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
              ))
          .toList();

      final quran = allQuranDaily.firstWhere(
        (q) => q.dayIndex == day,
        orElse: () => QuranDailyData(
          seasonId: season.id,
          dayIndex: day,
          pagesRead: 0,
          updatedAt: 0,
        ),
      );

      final prayer = allPrayerDetails.firstWhere(
        (p) => p.dayIndex == day,
        orElse: () => PrayerDetail(
          seasonId: season.id,
          dayIndex: day,
          fajr: false,
          dhuhr: false,
          asr: false,
          maghrib: false,
          isha: false,
          updatedAt: 0,
        ),
      );

      final scoreResult = await getDayScore(
        seasonId: season.id,
        dayIndex: day,
        season: season,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        entries: entries,
        database: database,
        quranDaily: quran,
        prayerDetail: prayer,
      );

      final score = scoreResult['score'] as int;
      String status;
      if (score == 100) {
        status = 'Done';
      } else if (score > 0) {
        status = 'Partial';
      } else {
        status = 'Miss';
      }

      // Calculate missed tasks
      final missed = <String>[];
      for (final habit in allHabits) {
        final seasonHabit = seasonHabits.firstWhere(
          (sh) => sh.habitId == habit.id,
          orElse: () => throw StateError('Season habit not found'),
        );
        if (!seasonHabit.isEnabled) continue;
        if (habit.key == 'itikaf') {
          final last10Start = season.days - 9;
          if (day < last10Start) continue;
        }

        bool isMissed = false;
        if (habit.key == 'fasting' || habit.key == 'taraweeh' || habit.key == 'itikaf') {
          final entry = entries.firstWhere(
            (e) => e.habitId == habit.id,
            orElse: () => DailyEntryModel(
              seasonId: season.id,
              dayIndex: day,
              habitId: habit.id,
              updatedAt: DateTime.now(),
            ),
          );
          isMissed = entry.valueBool != true;
        } else if (habit.key == 'prayers') {
          final completed = [
            prayer.fajr,
            prayer.dhuhr,
            prayer.asr,
            prayer.maghrib,
            prayer.isha,
          ].where((p) => p).length;
          isMissed = completed < 5;
        } else if (habit.key == 'quran_pages') {
          final quranPlan = await database.quranPlanDao.getPlan(season.id);
          final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
          isMissed = quran.pagesRead < target;
        } else if (habit.key == 'dhikr') {
          final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
          final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
          final entry = entries.firstWhere(
            (e) => e.habitId == habit.id,
            orElse: () => DailyEntryModel(
              seasonId: season.id,
              dayIndex: day,
              habitId: habit.id,
              updatedAt: DateTime.now(),
            ),
          );
          isMissed = (entry.valueInt ?? 0) < target;
        } else if (habit.key == 'sedekah') {
          final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
          final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
          if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
            final target = double.tryParse(sedekahGoalAmount) ?? 0;
            final entry = entries.firstWhere(
              (e) => e.habitId == habit.id,
              orElse: () => DailyEntryModel(
                seasonId: season.id,
                dayIndex: day,
                habitId: habit.id,
                updatedAt: DateTime.now(),
              ),
            );
            isMissed = (entry.valueInt ?? 0) < target;
          }
        }
        if (isMissed) {
          missed.add(habit.key);
        }
      }

      statuses.add(WeeklyDayStatus(
        dayIndex: day,
        date: season.startDate.add(Duration(days: day - 1)),
        score: score,
        status: status,
        missedTasks: missed,
      ));
    }

    return statuses;
  }

  /// Get weekly task summary for a specific habit
  static Future<WeeklyTaskStatus> getWeeklyTaskSummary({
    required String habitKey,
    required SeasonModel season,
    required int startDayIndex,
    required int endDayIndex,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final habit = allHabits.firstWhere((h) => h.key == habitKey);
    final seasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == habit.id);

    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(
      season.id,
      startDayIndex,
      endDayIndex,
    );

    final statuses = <String>[];
    int doneCount = 0;
    int partialCount = 0;
    int missCount = 0;
    double? avgActual;
    double? target;
    int? metTargetCount;
    double? avgCompleted;
    int? perfectDaysCount;

    if (habitKey == 'fasting' || habitKey == 'taraweeh' || habitKey == 'itikaf') {
      for (int day = startDayIndex; day <= endDayIndex; day++) {
        if (habitKey == 'itikaf') {
          final last10Start = season.days - 9;
          if (day < last10Start) {
            statuses.add('No data');
            continue;
          }
        }
        final entries = allEntries
            .where((e) => e.dayIndex == day)
            .map((e) => DailyEntryModel(
                  seasonId: e.seasonId,
                  dayIndex: e.dayIndex,
                  habitId: e.habitId,
                  valueBool: e.valueBool,
                  valueInt: e.valueInt,
                  note: e.note,
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
                ))
            .toList();
        final entry = entries.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(
            seasonId: season.id,
            dayIndex: day,
            habitId: habit.id,
            updatedAt: DateTime.now(),
          ),
        );
        if (entry.valueBool == true) {
          statuses.add('Done');
          doneCount++;
        } else {
          statuses.add('Miss');
          missCount++;
        }
      }
    } else if (habitKey == 'prayers') {
      int totalCompleted = 0;
      perfectDaysCount = 0;
      for (int day = startDayIndex; day <= endDayIndex; day++) {
        final prayer = allPrayerDetails.firstWhere(
          (p) => p.dayIndex == day,
          orElse: () => PrayerDetail(
            seasonId: season.id,
            dayIndex: day,
            fajr: false,
            dhuhr: false,
            asr: false,
            maghrib: false,
            isha: false,
            updatedAt: 0,
          ),
        );
        final completed = [
          prayer.fajr,
          prayer.dhuhr,
          prayer.asr,
          prayer.maghrib,
          prayer.isha,
        ].where((p) => p).length;
        totalCompleted += completed;
        if (completed == 5) {
          statuses.add('Done');
          doneCount++;
          perfectDaysCount = (perfectDaysCount ?? 0) + 1;
        } else if (completed > 0) {
          statuses.add('Partial');
          partialCount++;
        } else {
          statuses.add('Miss');
          missCount++;
        }
      }
      final daysCount = endDayIndex - startDayIndex + 1;
      avgCompleted = daysCount > 0 ? totalCompleted / daysCount : 0.0;
    } else if (habitKey == 'quran_pages') {
      final quranPlan = await database.quranPlanDao.getPlan(season.id);
      target = (quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20).toDouble();
      int totalPages = 0;
      metTargetCount = 0;
      for (int day = startDayIndex; day <= endDayIndex; day++) {
        final quran = allQuranDaily.firstWhere(
          (q) => q.dayIndex == day,
          orElse: () => QuranDailyData(
            seasonId: season.id,
            dayIndex: day,
            pagesRead: 0,
            updatedAt: 0,
          ),
        );
        final pages = quran.pagesRead;
        totalPages += pages;
        if (target != null && target! > 0 && pages >= target!.toInt()) {
          statuses.add('Done');
          doneCount++;
          metTargetCount = (metTargetCount ?? 0) + 1;
        } else if (pages > 0) {
          statuses.add('Partial');
          partialCount++;
        } else {
          statuses.add('Miss');
          missCount++;
        }
      }
      final daysCount = endDayIndex - startDayIndex + 1;
      avgActual = daysCount > 0 ? (totalPages / daysCount).toDouble() : 0.0;
    } else if (habitKey == 'dhikr') {
      final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
      target = (dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100).toDouble();
      int totalCount = 0;
      metTargetCount = 0;
      for (int day = startDayIndex; day <= endDayIndex; day++) {
        final entries = allEntries
            .where((e) => e.dayIndex == day)
            .map((e) => DailyEntryModel(
                  seasonId: e.seasonId,
                  dayIndex: e.dayIndex,
                  habitId: e.habitId,
                  valueBool: e.valueBool,
                  valueInt: e.valueInt,
                  note: e.note,
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
                ))
            .toList();
        final entry = entries.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(
            seasonId: season.id,
            dayIndex: day,
            habitId: habit.id,
            updatedAt: DateTime.now(),
          ),
        );
        final count = entry.valueInt ?? 0;
        totalCount += count;
        if (target != null && target! > 0 && count >= target!.toInt()) {
          statuses.add('Done');
          doneCount++;
          metTargetCount = (metTargetCount ?? 0) + 1;
        } else if (count > 0) {
          statuses.add('Partial');
          partialCount++;
        } else {
          statuses.add('Miss');
          missCount++;
        }
      }
      final daysCount = endDayIndex - startDayIndex + 1;
      avgActual = daysCount > 0 ? (totalCount / daysCount).toDouble() : 0.0;
    } else if (habitKey == 'sedekah') {
      final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
      final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
      if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
        target = double.tryParse(sedekahGoalAmount);
      }
      int totalAmount = 0;
      metTargetCount = 0;
      for (int day = startDayIndex; day <= endDayIndex; day++) {
        final entries = allEntries
            .where((e) => e.dayIndex == day)
            .map((e) => DailyEntryModel(
                  seasonId: e.seasonId,
                  dayIndex: e.dayIndex,
                  habitId: e.habitId,
                  valueBool: e.valueBool,
                  valueInt: e.valueInt,
                  note: e.note,
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
                ))
            .toList();
        final entry = entries.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(
            seasonId: season.id,
            dayIndex: day,
            habitId: habit.id,
            updatedAt: DateTime.now(),
          ),
        );
        final amount = entry.valueInt ?? 0;
        totalAmount += amount;
        if (target != null && target > 0 && amount >= target) {
          statuses.add('Done');
          doneCount++;
          metTargetCount = (metTargetCount ?? 0) + 1;
        } else if (amount > 0) {
          statuses.add('Partial');
          partialCount++;
        } else {
          statuses.add('Miss');
          missCount++;
        }
      }
      final daysCount = endDayIndex - startDayIndex + 1;
      avgActual = daysCount > 0 ? (totalAmount / daysCount).toDouble() : 0.0;
    }

    return WeeklyTaskStatus(
      habitKey: habitKey,
      statuses: statuses,
      doneCount: doneCount,
      partialCount: partialCount,
      missCount: missCount,
      avgActual: avgActual,
      target: target,
      metTargetCount: metTargetCount,
      avgCompleted: avgCompleted,
      perfectDaysCount: perfectDaysCount,
    );
  }

  /// Get weekly highlights
  static Future<WeeklyHighlights> getWeeklyHighlights({
    required SeasonModel season,
    required int startDayIndex,
    required int endDayIndex,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    // Get previous 7-day window for comparison
    final prevStartDayIndex = (startDayIndex - 7).clamp(1, season.days);
    final prevEndDayIndex = (startDayIndex - 1).clamp(1, season.days);
    final hasPreviousWindow = prevEndDayIndex >= prevStartDayIndex && prevEndDayIndex > 0;

    final currentTaskStats = <String, WeeklyTaskStatus>{};
    final previousTaskStats = <String, WeeklyTaskStatus>{};

    for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
      final habit = allHabits.firstWhere((h) => h.id == seasonHabit.habitId);
      final habitKey = habit.key;

      if (habitKey == 'itikaf') {
        final last10Start = season.days - 9;
        if (endDayIndex < last10Start) continue;
      }

      currentTaskStats[habitKey] = await getWeeklyTaskSummary(
        habitKey: habitKey,
        season: season,
        startDayIndex: startDayIndex,
        endDayIndex: endDayIndex,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );

      if (hasPreviousWindow) {
        previousTaskStats[habitKey] = await getWeeklyTaskSummary(
          habitKey: habitKey,
          season: season,
          startDayIndex: prevStartDayIndex,
          endDayIndex: prevEndDayIndex,
          database: database,
          allHabits: allHabits,
          seasonHabits: seasonHabits,
        );
      }
    }

    // Find most consistent (highest completion rate)
    String? mostConsistent;
    double highestRate = 0.0;
    for (final entry in currentTaskStats.entries) {
      final total = entry.value.doneCount + entry.value.partialCount + entry.value.missCount;
      if (total > 0) {
        final rate = entry.value.doneCount / total;
        if (rate > highestRate) {
          highestRate = rate;
          mostConsistent = entry.key;
        }
      }
    }

    // Find needs attention (lowest completion rate or most misses)
    String? needsAttention;
    double lowestRate = 1.0;
    int maxMisses = 0;
    for (final entry in currentTaskStats.entries) {
      final total = entry.value.doneCount + entry.value.partialCount + entry.value.missCount;
      if (total > 0) {
        final rate = entry.value.doneCount / total;
        if (rate < lowestRate || entry.value.missCount > maxMisses) {
          lowestRate = rate;
          maxMisses = entry.value.missCount;
          needsAttention = entry.key;
        }
      }
    }

    // Find biggest improvement (compare with previous window)
    String? biggestImprovement;
    double maxImprovement = 0.0;
    if (hasPreviousWindow) {
      for (final entry in currentTaskStats.entries) {
        final prev = previousTaskStats[entry.key];
        if (prev == null) continue;

        final currentTotal = entry.value.doneCount + entry.value.partialCount + entry.value.missCount;
        final prevTotal = prev.doneCount + prev.partialCount + prev.missCount;

        if (currentTotal > 0 && prevTotal > 0) {
          final currentRate = entry.value.doneCount / currentTotal;
          final prevRate = prev.doneCount / prevTotal;
          final improvement = currentRate - prevRate;
          if (improvement > maxImprovement) {
            maxImprovement = improvement;
            biggestImprovement = entry.key;
          }
        }
      }
    }

    return WeeklyHighlights(
      mostConsistentTask: mostConsistent,
      needsAttentionTask: needsAttention,
      biggestImprovementTask: maxImprovement > 0 ? biggestImprovement : null,
    );
  }

  /// Get Sedekah weekly data
  static Future<SedekahWeeklyData> getSedekahWeeklyData({
    required SeasonModel season,
    required int startDayIndex,
    required int endDayIndex,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final habit = allHabits.firstWhere((h) => h.key == 'sedekah');
    final seasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == habit.id);

    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null
        ? double.tryParse(sedekahGoalAmount)
        : null;

    int totalAmount = 0;
    int daysMetGoal = 0;
    final dailyAmounts = <double>[];

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final entries = allEntries
          .where((e) => e.dayIndex == day)
          .map((e) => DailyEntryModel(
                seasonId: e.seasonId,
                dayIndex: e.dayIndex,
                habitId: e.habitId,
                valueBool: e.valueBool,
                valueInt: e.valueInt,
                note: e.note,
                updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
              ))
          .toList();
      final entry = entries.firstWhere(
        (e) => e.habitId == habit.id,
        orElse: () => DailyEntryModel(
          seasonId: season.id,
          dayIndex: day,
          habitId: habit.id,
          updatedAt: DateTime.now(),
        ),
      );
      final amount = entry.valueInt ?? 0;
      dailyAmounts.add(amount.toDouble());
      totalAmount += amount;
      if (target != null && target > 0 && amount >= target) {
        daysMetGoal++;
      }
    }

    final daysCount = endDayIndex - startDayIndex + 1;
    final avgAmount = daysCount > 0 ? totalAmount / daysCount : 0.0;

    return SedekahWeeklyData(
      totalAmount: totalAmount,
      avgAmount: avgAmount,
      daysMetGoal: daysMetGoal,
      dailyAmounts: dailyAmounts,
    );
  }
}

