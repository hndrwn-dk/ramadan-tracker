import 'dart:math';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/models/day_point.dart';
import 'package:ramadan_tracker/features/insights/models/habit_stats.dart';
import 'package:ramadan_tracker/features/insights/services/insights_scoring_service.dart';

/// Service for computing insights data for different ranges.
class InsightsService {
  /// Generate InsightsData for a specific range.
  static Future<InsightsData> generateInsightsData({
    required InsightsRange rangeType,
    required SeasonModel season,
    required int currentDayIndex,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    // Determine date range
    final startDate = season.startDate;
    int startDayIndex;
    int endDayIndex;
    DateTime rangeStartDate;
    DateTime rangeEndDate;

    switch (rangeType) {
      case InsightsRange.today:
        startDayIndex = currentDayIndex.clamp(1, season.days);
        endDayIndex = startDayIndex;
        rangeStartDate = startDate.add(Duration(days: startDayIndex - 1));
        rangeEndDate = rangeStartDate;
        break;
      case InsightsRange.sevenDays:
        startDayIndex = (currentDayIndex - 6).clamp(1, season.days);
        endDayIndex = currentDayIndex.clamp(1, season.days);
        rangeStartDate = startDate.add(Duration(days: startDayIndex - 1));
        rangeEndDate = startDate.add(Duration(days: endDayIndex - 1));
        break;
      case InsightsRange.season:
        startDayIndex = 1;
        endDayIndex = currentDayIndex.clamp(1, season.days);
        rangeStartDate = startDate;
        rangeEndDate = startDate.add(Duration(days: endDayIndex - 1));
        break;
    }

    final daysCount = endDayIndex - startDayIndex + 1;

    // Load all data for the range
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(
      season.id,
      startDayIndex,
      endDayIndex,
    );
    final quranPlan = await database.quranPlanDao.getPlan(season.id);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');

    // Filter data to range
    final entriesByDay = <int, List<DailyEntryModel>>{};
    final quranByDay = <int, QuranDailyData>{};
    final prayerByDay = <int, PrayerDetail>{};

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      entriesByDay[day] = allEntries
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
      quranByDay[day] = quran;

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
      prayerByDay[day] = prayer;
    }

    // Calculate scores for each day
    final dayScores = <int, int>{};
    final trendSeries = <DayPoint>[];
    int totalScore = 0;
    int perfectDays = 0;

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final dayDate = startDate.add(Duration(days: day - 1));
      final entries = entriesByDay[day] ?? [];
      final quranDaily = quranByDay[day];
      final prayerDetail = prayerByDay[day];

      final scoreResult = await InsightsScoringService.calculateDailyScore(
        seasonId: season.id,
        dayIndex: day,
        season: season,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        entries: entries,
        database: database,
        quranDaily: quranDaily,
        prayerDetail: prayerDetail,
      );

      final score = scoreResult['score'] as int;
      dayScores[day] = score;
      totalScore += score;
      if (score == 100) perfectDays++;

      trendSeries.add(DayPoint(
        date: dayDate,
        score: score,
        completionPercent: score / 100.0,
      ));
    }

    // Calculate averages and streaks
    final avgScore = daysCount > 0 ? (totalScore / daysCount).round() : 0;
    final completionRate = daysCount > 0 ? (perfectDays / daysCount) : 0.0;

    final streakData = _calculateStreaks(dayScores, startDayIndex, endDayIndex);
    final currentStreak = streakData['current'] as int;
    final bestStreak = streakData['best'] as int;

    // Calculate per-habit stats
    final perHabitStats = await _calculateHabitStats(
      season: season,
      startDayIndex: startDayIndex,
      endDayIndex: endDayIndex,
      entriesByDay: entriesByDay,
      quranByDay: quranByDay,
      prayerByDay: prayerByDay,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      quranPlan: quranPlan,
      dhikrPlan: dhikrPlan,
      sedekahGoalEnabled: sedekahGoalEnabled,
      sedekahGoalAmount: sedekahGoalAmount,
    );

    return InsightsData(
      rangeType: rangeType,
      startDate: rangeStartDate,
      endDate: rangeEndDate,
      daysCount: daysCount,
      avgScore: avgScore,
      totalScore: totalScore,
      completionRate: completionRate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      trendSeries: trendSeries,
      perHabitStats: perHabitStats,
    );
  }

  static Map<String, int> _calculateStreaks(
    Map<int, int> dayScores,
    int startDay,
    int endDay,
  ) {
    if (dayScores.isEmpty) return {'current': 0, 'best': 0};

    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    // Calculate current streak from end backwards
    for (int day = endDay; day >= startDay; day--) {
      final score = dayScores[day] ?? 0;
      if (score == 100) {
        currentStreak++;
      } else {
        break;
      }
    }

    // Calculate best streak
    for (int day = startDay; day <= endDay; day++) {
      final score = dayScores[day] ?? 0;
      if (score == 100) {
        tempStreak++;
        bestStreak = max(bestStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }

    return {'current': currentStreak, 'best': bestStreak};
  }

  static Future<Map<String, HabitStats>> _calculateHabitStats({
    required SeasonModel season,
    required int startDayIndex,
    required int endDayIndex,
    required Map<int, List<DailyEntryModel>> entriesByDay,
    required Map<int, QuranDailyData> quranByDay,
    required Map<int, PrayerDetail> prayerByDay,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    QuranPlanData? quranPlan,
    DhikrPlanData? dhikrPlan,
    String? sedekahGoalEnabled,
    String? sedekahGoalAmount,
  }) async {
    final stats = <String, HabitStats>{};
    final last10Start = max(1, season.days - 9);

    for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
      final habit = allHabits.firstWhere((h) => h.id == seasonHabit.habitId);
      final habitKey = habit.key;

      // Skip Itikaf if not in last 10 nights range
      if (habitKey == 'itikaf') {
        final isInRange = endDayIndex >= last10Start;
        if (!isInRange) continue;
      }

      if (habitKey == 'fasting') {
        int doneDays = 0;
        for (int day = startDayIndex; day <= endDayIndex; day++) {
          final entries = entriesByDay[day] ?? [];
          final entry = entries.firstWhere(
            (e) => e.habitId == habit.id,
            orElse: () => DailyEntryModel(
              seasonId: season.id,
              dayIndex: day,
              habitId: habit.id,
              updatedAt: DateTime.now(),
            ),
          );
          if (entry.valueBool == true) doneDays++;
        }
        stats[habitKey] = HabitStats(
          doneDays: doneDays,
          totalDays: endDayIndex - startDayIndex + 1,
        );
      } else if (habitKey == 'prayers') {
        int all5Days = 0;
        final perPrayerCounts = <String, int>{
          'fajr': 0,
          'dhuhr': 0,
          'asr': 0,
          'maghrib': 0,
          'isha': 0,
        };
        for (int day = startDayIndex; day <= endDayIndex; day++) {
          final prayer = prayerByDay[day];
          if (prayer == null) continue;
          final completed = [
            prayer.fajr,
            prayer.dhuhr,
            prayer.asr,
            prayer.maghrib,
            prayer.isha,
          ].where((p) => p).length;
          if (completed == 5) all5Days++;
          if (prayer.fajr) perPrayerCounts['fajr'] = (perPrayerCounts['fajr'] ?? 0) + 1;
          if (prayer.dhuhr) perPrayerCounts['dhuhr'] = (perPrayerCounts['dhuhr'] ?? 0) + 1;
          if (prayer.asr) perPrayerCounts['asr'] = (perPrayerCounts['asr'] ?? 0) + 1;
          if (prayer.maghrib) perPrayerCounts['maghrib'] = (perPrayerCounts['maghrib'] ?? 0) + 1;
          if (prayer.isha) perPrayerCounts['isha'] = (perPrayerCounts['isha'] ?? 0) + 1;
        }
        stats[habitKey] = HabitStats(
          all5Days: all5Days,
          totalDays: endDayIndex - startDayIndex + 1,
          perPrayerCounts: perPrayerCounts,
        );
      } else if (habitKey == 'quran_pages') {
        int totalPages = 0;
        int daysMetTarget = 0;
        final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
        for (int day = startDayIndex; day <= endDayIndex; day++) {
          final quran = quranByDay[day];
          final pages = quran?.pagesRead ?? 0;
          totalPages += pages;
          if (target > 0 && pages >= target) daysMetTarget++;
        }
        final avgPages = (endDayIndex - startDayIndex + 1) > 0
            ? totalPages / (endDayIndex - startDayIndex + 1)
            : 0.0;
        stats[habitKey] = HabitStats(
          avgValue: avgPages,
          targetValue: target,
          totalValue: totalPages,
          daysMetTarget: daysMetTarget,
        );
      } else if (habitKey == 'dhikr') {
        int totalCount = 0;
        int daysMetTarget = 0;
        final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
        for (int day = startDayIndex; day <= endDayIndex; day++) {
          final entries = entriesByDay[day] ?? [];
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
          if (target > 0 && count >= target) daysMetTarget++;
        }
        final avgCount = (endDayIndex - startDayIndex + 1) > 0
            ? totalCount / (endDayIndex - startDayIndex + 1)
            : 0.0;
        stats[habitKey] = HabitStats(
          avgValue: avgCount,
          targetValue: target,
          totalValue: totalCount,
          daysMetTarget: daysMetTarget,
        );
      } else if (habitKey == 'taraweeh') {
        int doneDays = 0;
        for (int day = startDayIndex; day <= endDayIndex; day++) {
          final entries = entriesByDay[day] ?? [];
          final entry = entries.firstWhere(
            (e) => e.habitId == habit.id,
            orElse: () => DailyEntryModel(
              seasonId: season.id,
              dayIndex: day,
              habitId: habit.id,
              updatedAt: DateTime.now(),
            ),
          );
          if (entry.valueBool == true) doneDays++;
        }
        stats[habitKey] = HabitStats(
          doneDays: doneDays,
          totalDays: endDayIndex - startDayIndex + 1,
        );
      } else if (habitKey == 'sedekah') {
        int totalAmount = 0;
        int daysMetGoal = 0;
        double? target;
        if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
          target = double.tryParse(sedekahGoalAmount);
        }
        for (int day = startDayIndex; day <= endDayIndex; day++) {
          final entries = entriesByDay[day] ?? [];
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
          if (target != null && target > 0 && amount >= target) daysMetGoal++;
        }
        final avgAmount = (endDayIndex - startDayIndex + 1) > 0
            ? totalAmount / (endDayIndex - startDayIndex + 1)
            : 0.0;
        stats[habitKey] = HabitStats(
          totalAmount: totalAmount,
          avgAmount: avgAmount,
          daysMetGoal: target != null && target > 0 ? daysMetGoal : null,
        );
      } else if (habitKey == 'itikaf') {
        int nightsDone = 0;
        final nightsCompletedDates = <DateTime>[];
        for (int day = max(startDayIndex, last10Start); day <= endDayIndex; day++) {
          final entries = entriesByDay[day] ?? [];
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
            nightsDone++;
            nightsCompletedDates.add(season.startDate.add(Duration(days: day - 1)));
          }
        }
        stats[habitKey] = HabitStats(
          nightsDone: nightsDone,
          nightsCompletedDates: nightsCompletedDates,
        );
      }
    }

    return stats;
  }
}

