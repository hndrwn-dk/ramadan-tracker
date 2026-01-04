import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/features/insights/services/insights_scoring_service.dart';

/// Season insights data models
class SeasonDayStatus {
  final int dayIndex;
  final DateTime date;
  final int score; // 0-100
  final String status; // 'Perfect', 'Partial', 'Low', 'Untracked'
  final List<String> missedTasks;
  final String? mood; // 'excellent', 'good', 'ok', 'difficult'
  final String? reflection;

  SeasonDayStatus({
    required this.dayIndex,
    required this.date,
    required this.score,
    required this.status,
    required this.missedTasks,
    this.mood,
    this.reflection,
  });
}

class SeasonHighlights {
  final ({DateTime date, int score})? bestDay;
  final ({DateTime date, int score})? toughestDay;
  final String? mostConsistentTask;
  final ({DateTime date, int score, int previousScore})? biggestComeback;

  SeasonHighlights({
    this.bestDay,
    this.toughestDay,
    this.mostConsistentTask,
    this.biggestComeback,
  });
}

class TaskSeasonAnalytics {
  final String habitKey;
  // Boolean tasks
  final int? doneCount;
  final int? missCount;
  final int? bestStreak;
  // Numeric tasks
  final double? total;
  final double? avg;
  final int? metTargetDays;
  final ({int dayIndex, double value})? bestDay;
  // Prayers
  final int? perfectDays;
  final double? avgPerDay;
  final int? totalMissedPrayers;

  TaskSeasonAnalytics({
    required this.habitKey,
    this.doneCount,
    this.missCount,
    this.bestStreak,
    this.total,
    this.avg,
    this.metTargetDays,
    this.bestDay,
    this.perfectDays,
    this.avgPerDay,
    this.totalMissedPrayers,
  });
}

class SedekahSeasonAnalytics {
  final int total;
  final double avg;
  final int metTargetDays;
  final ({int dayIndex, int amount})? bestDay;
  final List<int> dailyAmounts; // All season days

  SedekahSeasonAnalytics({
    required this.total,
    required this.avg,
    required this.metTargetDays,
    this.bestDay,
    required this.dailyAmounts,
  });
}

class ReflectionSeasonAnalytics {
  final Map<String, int> moodCounts; // 'excellent', 'good', 'ok', 'difficult'
  final String? mostCommonMood;
  final Map<String, double> avgScoreByMood;

  ReflectionSeasonAnalytics({
    required this.moodCounts,
    this.mostCommonMood,
    required this.avgScoreByMood,
  });
}

/// Service for computing season-wide insights data
class SeasonInsightsService {
  /// Get all season days
  static List<DateTime> getSeasonDays(SeasonModel season) {
    return List.generate(
      season.days,
      (index) => season.startDate.add(Duration(days: index)),
    );
  }

  /// Get day summary for a specific date
  static Future<Map<String, dynamic>> getDaySummary({
    required int seasonId,
    required int dayIndex,
    required SeasonModel season,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    required AppDatabase database,
  }) async {
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
    final prayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(seasonId, dayIndex, dayIndex);
    final prayerDetail = prayerDetails.isNotEmpty ? prayerDetails.first : null;
    final notes = await database.notesDao.getDayNotes(seasonId, dayIndex);
    final note = notes.isNotEmpty ? notes.first : null;

    final entriesModel = entries.map((e) => DailyEntryModel(
          seasonId: e.seasonId,
          dayIndex: e.dayIndex,
          habitId: e.habitId,
          valueBool: e.valueBool,
          valueInt: e.valueInt,
          note: e.note,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
        )).toList();

    final scoreResult = await InsightsScoringService.calculateDailyScore(
      seasonId: seasonId,
      dayIndex: dayIndex,
      season: season,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      entries: entriesModel,
      database: database,
      quranDaily: quranDaily,
      prayerDetail: prayerDetail,
    );

    final score = scoreResult['score'] as int;
    final drivers = scoreResult['drivers'] as Map<String, dynamic>?;

    return {
      'score': score,
      'drivers': drivers ?? {},
      'mood': note?.mood,
      'reflection': note?.body,
    };
  }

  /// Compute season aggregate statistics
  static Future<({
    int seasonScoreAvg,
    int totalEarned,
    int totalMax,
    int perfectDaysCount,
    int missedDaysCount,
    int bestStreak,
  })> computeSeasonAggregate({
    required SeasonModel season,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(
      season.id,
      1,
      season.days,
    );

    final dayScores = <int, int>{};
    int totalEarned = 0;
    int perfectDays = 0;
    int missedDays = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    for (int day = 1; day <= season.days; day++) {
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

      final scoreResult = await InsightsScoringService.calculateDailyScore(
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
        // Check if any task was missed (score < 100 means something was missed)
        if (score < 100) {
          missedDays++;
        }
      }
    }

    final seasonScoreAvg = season.days > 0 ? (totalEarned / season.days).round() : 0;
    final totalMax = season.days * 100;

    return (
      seasonScoreAvg: seasonScoreAvg,
      totalEarned: totalEarned,
      totalMax: totalMax,
      perfectDaysCount: perfectDays,
      missedDaysCount: missedDays,
      bestStreak: bestStreak,
    );
  }

  /// Get season trend series (date, score)
  static Future<List<({DateTime date, int score})>> getSeasonTrendSeries({
    required SeasonModel season,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final series = <({DateTime date, int score})>[];
    
    for (int day = 1; day <= season.days; day++) {
      final date = season.startDate.add(Duration(days: day - 1));
      final summary = await getDaySummary(
        seasonId: season.id,
        dayIndex: day,
        season: season,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        database: database,
      );
      final score = summary['score'] as int;
      series.add((date: date, score: score));
    }
    
    return series;
  }

  /// Get season heatmap status for a day
  static Future<String> getSeasonHeatmapStatus({
    required int dayIndex,
    required SeasonModel season,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final summary = await getDaySummary(
      seasonId: season.id,
      dayIndex: dayIndex,
      season: season,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      database: database,
    );
    
    final score = summary['score'] as int;
    
    // Check if day has any data
    final entries = await database.dailyEntriesDao.getDayEntries(season.id, dayIndex);
    final quranDaily = await database.quranDailyDao.getDaily(season.id, dayIndex);
    final prayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(season.id, dayIndex, dayIndex);
    
    final hasData = entries.isNotEmpty || 
        (quranDaily != null && quranDaily.pagesRead > 0) ||
        (prayerDetails.isNotEmpty && (
          prayerDetails.first.fajr ||
          prayerDetails.first.dhuhr ||
          prayerDetails.first.asr ||
          prayerDetails.first.maghrib ||
          prayerDetails.first.isha
        ));
    
    if (!hasData) return 'Untracked';
    if (score == 100) return 'Perfect';
    if (score >= 60) return 'Partial';
    return 'Low';
  }

  /// Get all season day statuses
  static Future<List<SeasonDayStatus>> getAllSeasonDayStatuses({
    required SeasonModel season,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final statuses = <SeasonDayStatus>[];
    
    for (int day = 1; day <= season.days; day++) {
      final date = season.startDate.add(Duration(days: day - 1));
      final summary = await getDaySummary(
        seasonId: season.id,
        dayIndex: day,
        season: season,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        database: database,
      );
      
      final score = summary['score'] as int;
      final heatmapStatus = await getSeasonHeatmapStatus(
        dayIndex: day,
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      // Calculate missed tasks
      final missed = <String>[];
      if (score < 100) {
        // Check each habit to see which ones were missed
        final entriesRaw = await database.dailyEntriesDao.getDayEntries(season.id, day);
        final entries = entriesRaw.map((e) => DailyEntryModel(
              seasonId: e.seasonId,
              dayIndex: e.dayIndex,
              habitId: e.habitId,
              valueBool: e.valueBool,
              valueInt: e.valueInt,
              note: e.note,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
            )).toList();
        final quranDaily = await database.quranDailyDao.getDaily(season.id, day);
        final prayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(season.id, day, day);
        final prayer = prayerDetails.isNotEmpty ? prayerDetails.first : null;
        
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
            if (prayer != null) {
              final completed = [
                prayer.fajr,
                prayer.dhuhr,
                prayer.asr,
                prayer.maghrib,
                prayer.isha,
              ].where((p) => p).length;
              isMissed = completed < 5;
            } else {
              isMissed = true;
            }
          } else if (habit.key == 'quran_pages') {
            final quranPlan = await database.quranPlanDao.getPlan(season.id);
            final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
            isMissed = (quranDaily?.pagesRead ?? 0) < target;
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
      }
      
      final notes = await database.notesDao.getDayNotes(season.id, day);
      final note = notes.isNotEmpty ? notes.first : null;
      
      statuses.add(SeasonDayStatus(
        dayIndex: day,
        date: date,
        score: score,
        status: heatmapStatus,
        missedTasks: missed,
        mood: note?.mood,
        reflection: note?.body,
      ));
    }
    
    return statuses;
  }

  /// Get season highlights
  static Future<SeasonHighlights> getSeasonHighlights({
    required SeasonModel season,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final trendSeries = await getSeasonTrendSeries(
      season: season,
      database: database,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
    );
    
    if (trendSeries.isEmpty) {
      return SeasonHighlights();
    }
    
    // Best day
    final bestDayEntry = trendSeries.reduce((a, b) => a.score > b.score ? a : b);
    final bestDay = (date: bestDayEntry.date, score: bestDayEntry.score);
    
    // Toughest day (lowest score, but only tracked days)
    final trackedDays = trendSeries.where((d) => d.score > 0).toList();
    final toughestDay = trackedDays.isNotEmpty
        ? trackedDays.reduce((a, b) => a.score < b.score ? a : b)
        : null;
    final toughest = toughestDay != null ? (date: toughestDay.date, score: toughestDay.score) : null;
    
    // Most consistent task (calculate from task analytics)
    String? mostConsistentTask;
    double highestRate = 0.0;
    
    for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
      final habit = allHabits.firstWhere((h) => h.id == seasonHabit.habitId);
      final analytics = await getTaskSeasonAnalytics(
        habitKey: habit.key,
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      if (analytics.doneCount != null && analytics.missCount != null) {
        final total = analytics.doneCount! + analytics.missCount!;
        if (total > 0) {
          final rate = analytics.doneCount! / total;
          if (rate > highestRate) {
            highestRate = rate;
            mostConsistentTask = habit.key;
          }
        }
      }
    }
    
    // Biggest comeback (largest score jump)
    ({DateTime date, int score, int previousScore})? biggestComeback;
    int maxJump = 0;
    
    for (int i = 1; i < trendSeries.length; i++) {
      final prev = trendSeries[i - 1];
      final curr = trendSeries[i];
      final jump = curr.score - prev.score;
      if (jump > maxJump && prev.score < 100) {
        maxJump = jump;
        biggestComeback = (
          date: curr.date,
          score: curr.score,
          previousScore: prev.score,
        );
      }
    }
    
    return SeasonHighlights(
      bestDay: bestDay,
      toughestDay: toughest,
      mostConsistentTask: mostConsistentTask,
      biggestComeback: biggestComeback,
    );
  }

  /// Get task season analytics
  static Future<TaskSeasonAnalytics> getTaskSeasonAnalytics({
    required String habitKey,
    required SeasonModel season,
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
      1,
      season.days,
    );
    
    if (habitKey == 'fasting' || habitKey == 'taraweeh' || habitKey == 'itikaf') {
      int doneCount = 0;
      int missCount = 0;
      int bestStreak = 0;
      int tempStreak = 0;
      
      final last10Start = habitKey == 'itikaf' ? season.days - 9 : 1;
      
      for (int day = last10Start; day <= season.days; day++) {
        if (habitKey == 'itikaf' && day < last10Start) continue;
        
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
          doneCount++;
          tempStreak++;
          bestStreak = bestStreak > tempStreak ? bestStreak : tempStreak;
        } else {
          missCount++;
          tempStreak = 0;
        }
      }
      
      return TaskSeasonAnalytics(
        habitKey: habitKey,
        doneCount: doneCount,
        missCount: missCount,
        bestStreak: bestStreak,
      );
    } else if (habitKey == 'prayers') {
      int perfectDays = 0;
      int totalPrayers = 0;
      int totalMissed = 0;
      
      for (int day = 1; day <= season.days; day++) {
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
        
        if (completed == 5) perfectDays++;
        totalPrayers += completed;
        totalMissed += (5 - completed);
      }
      
      final avgPerDay = season.days > 0 ? totalPrayers / season.days : 0.0;
      
      return TaskSeasonAnalytics(
        habitKey: habitKey,
        perfectDays: perfectDays,
        avgPerDay: avgPerDay,
        totalMissedPrayers: totalMissed,
      );
    } else if (habitKey == 'quran_pages') {
      final quranPlan = await database.quranPlanDao.getPlan(season.id);
      final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
      int totalPages = 0;
      int metTargetDays = 0;
      int bestDayIndex = 0;
      int bestDayPages = 0;
      
      for (int day = 1; day <= season.days; day++) {
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
        if (pages >= target) metTargetDays++;
        if (pages > bestDayPages) {
          bestDayPages = pages;
          bestDayIndex = day;
        }
      }
      
      final avg = season.days > 0 ? totalPages / season.days : 0.0;
      
      return TaskSeasonAnalytics(
        habitKey: habitKey,
        total: totalPages.toDouble(),
        avg: avg,
        metTargetDays: metTargetDays,
        bestDay: bestDayPages > 0 ? (dayIndex: bestDayIndex, value: bestDayPages.toDouble()) : null,
      );
    } else if (habitKey == 'dhikr') {
      final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
      final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
      int totalCount = 0;
      int metTargetDays = 0;
      int bestDayIndex = 0;
      int bestDayCount = 0;
      
      for (int day = 1; day <= season.days; day++) {
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
        if (count >= target) metTargetDays++;
        if (count > bestDayCount) {
          bestDayCount = count;
          bestDayIndex = day;
        }
      }
      
      final avg = season.days > 0 ? totalCount / season.days : 0.0;
      
      return TaskSeasonAnalytics(
        habitKey: habitKey,
        total: totalCount.toDouble(),
        avg: avg,
        metTargetDays: metTargetDays,
        bestDay: bestDayCount > 0 ? (dayIndex: bestDayIndex, value: bestDayCount.toDouble()) : null,
      );
    }
    
    return TaskSeasonAnalytics(habitKey: habitKey);
  }

  /// Get Sedekah season analytics
  static Future<SedekahSeasonAnalytics> getSedekahSeasonAnalytics({
    required SeasonModel season,
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
    int metTargetDays = 0;
    int bestDayIndex = 0;
    int bestDayAmount = 0;
    final dailyAmounts = <int>[];
    
    for (int day = 1; day <= season.days; day++) {
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
      dailyAmounts.add(amount);
      totalAmount += amount;
      if (target != null && target > 0 && amount >= target) {
        metTargetDays++;
      }
      if (amount > bestDayAmount) {
        bestDayAmount = amount;
        bestDayIndex = day;
      }
    }
    
    final avg = season.days > 0 ? totalAmount / season.days : 0.0;
    
    return SedekahSeasonAnalytics(
      total: totalAmount,
      avg: avg,
      metTargetDays: metTargetDays,
      bestDay: bestDayAmount > 0 ? (dayIndex: bestDayIndex, amount: bestDayAmount) : null,
      dailyAmounts: dailyAmounts,
    );
  }

  /// Get reflection season analytics
  static Future<ReflectionSeasonAnalytics> getReflectionSeasonAnalytics({
    required SeasonModel season,
    required AppDatabase database,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
  }) async {
    final moodCounts = <String, int>{
      'excellent': 0,
      'good': 0,
      'ok': 0,
      'difficult': 0,
    };
    final moodScores = <String, List<int>>{
      'excellent': [],
      'good': [],
      'ok': [],
      'difficult': [],
    };
    
    for (int day = 1; day <= season.days; day++) {
      final notes = await database.notesDao.getDayNotes(season.id, day);
      final note = notes.isNotEmpty ? notes.first : null;
      
      final mood = note?.mood;
      if (mood != null && moodCounts.containsKey(mood)) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
        
        // Get score for this day
        final summary = await getDaySummary(
          seasonId: season.id,
          dayIndex: day,
          season: season,
          allHabits: allHabits,
          seasonHabits: seasonHabits,
          database: database,
        );
        final score = summary['score'] as int;
        moodScores[mood]?.add(score);
      }
    }
    
    // Find most common mood
    String? mostCommonMood;
    int maxCount = 0;
    for (final entry in moodCounts.entries) {
      if (entry.value > maxCount) {
        maxCount = entry.value;
        mostCommonMood = entry.key;
      }
    }
    
    // Calculate avg score by mood
    final avgScoreByMood = <String, double>{};
    for (final entry in moodScores.entries) {
      if (entry.value.isNotEmpty) {
        avgScoreByMood[entry.key] = entry.value.reduce((a, b) => a + b) / entry.value.length;
      }
    }
    
    return ReflectionSeasonAnalytics(
      moodCounts: moodCounts,
      mostCommonMood: mostCommonMood,
      avgScoreByMood: avgScoreByMood,
    );
  }
}
