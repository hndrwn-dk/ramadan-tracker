import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/insights/models.dart';
import 'package:ramadan_tracker/insights/task_registry.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:intl/intl.dart';

class RamadanProfile {
  final int seasonId;
  final DateTime startDate;
  final int days;
  final Set<TaskKey> enabledTasks;
  final Map<TaskKey, int?> targets; // task -> target value
  final double streakThreshold; // default 0.70

  RamadanProfile({
    required this.seasonId,
    required this.startDate,
    required this.days,
    required this.enabledTasks,
    required this.targets,
    this.streakThreshold = 0.70,
  });
}

class InsightsAggregator {
  static InsightsResult aggregate({
    required RamadanProfile profile,
    required List<DailyEntryModel> allEntries,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    List<QuranDailyData>? quranDailyData,
    List<PrayerDetail>? prayerDetails,
    List<Note>? notes,
    int todayDayIndex = 0, // 0 means use current day
    String? sedekahCurrency, // Currency for Sedekah formatting
    int? startDayIndex, // Optional: filter start day (for timeframe)
    int? endDayIndex, // Optional: filter end day (for timeframe)
  }) {
    // Group entries by day
    final entriesByDay = <int, List<DailyEntryModel>>{};
    for (final entry in allEntries) {
      entriesByDay.putIfAbsent(entry.dayIndex, () => []).add(entry);
    }

    // Calculate today's day index
    final now = DateTime.now();
    final currentDayIndex = todayDayIndex > 0
        ? todayDayIndex
        : profile.startDate.difference(now).inDays.abs() + 1;
    final currentDayIndexClamped = currentDayIndex.clamp(1, profile.days);

    // Determine day range for calculations
    final calcStartDay = startDayIndex ?? 1;
    final calcEndDay = endDayIndex ?? currentDayIndexClamped;

    // Calculate overall summary and day completions
    final summaryResult = _calculateOverallSummary(
      profile: profile,
      entriesByDay: entriesByDay,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      quranDailyData: quranDailyData,
      currentDayIndex: currentDayIndexClamped,
      startDayIndex: calcStartDay,
      endDayIndex: calcEndDay,
    );
    final overallSummary = summaryResult['summary'] as OverallSummary;
    final dayCompletions = summaryResult['dayCompletions'] as Map<int, double>;

    // Calculate task summaries
    final taskSummaries = <TaskKey, TaskInsightSummary>{};
    // Check if we're in the last 10 days (for Itikaf)
    final last10Start = max(1, profile.days - 9);
    final isInLast10Days = currentDayIndexClamped >= last10Start && currentDayIndexClamped > 0;
    
    for (final taskKey in profile.enabledTasks) {
      // Skip Itikaf if not in last 10 days
      if (taskKey == TaskKey.itikaf && !isInLast10Days) {
        continue;
      }
      
      final summary = _calculateTaskSummary(
        taskKey: taskKey,
        profile: profile,
        entriesByDay: entriesByDay,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        quranDailyData: quranDailyData,
        prayerDetails: prayerDetails,
        currentDayIndex: currentDayIndexClamped,
        startDayIndex: calcStartDay,
        endDayIndex: calcEndDay,
      );
      if (summary != null) {
        taskSummaries[taskKey] = summary;
      }
    }

    // Generate highlights
    final highlights = _generateHighlights(
      profile: profile,
      overallSummary: overallSummary,
      taskSummaries: taskSummaries,
      currentDayIndex: currentDayIndexClamped,
      sedekahCurrency: sedekahCurrency,
      notes: notes,
    );

    // Generate next actions
    final nextActions = _generateNextActions(
      profile: profile,
      entriesByDay: entriesByDay,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      currentDayIndex: currentDayIndexClamped,
    );

    return InsightsResult(
      overallSummary: overallSummary,
      taskSummaries: taskSummaries,
      highlights: highlights,
      nextActions: nextActions,
      dayCompletions: dayCompletions, // Pass day-by-day completion data for chart
    );
  }

  static Map<String, dynamic> _calculateOverallSummary({
    required RamadanProfile profile,
    required Map<int, List<DailyEntryModel>> entriesByDay,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    List<QuranDailyData>? quranDailyData,
    required int currentDayIndex,
    required int startDayIndex,
    required int endDayIndex,
  }) {
    // Calculate completion for each day in the range
    final dayCompletions = <int, double>{};
    final todayCompletion = _calculateDayCompletion(
      dayIndex: currentDayIndex,
      profile: profile,
      entriesByDay: entriesByDay,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
      quranDailyData: quranDailyData,
    );
    dayCompletions[currentDayIndex] = todayCompletion;

    // Calculate for the selected timeframe range
    double rangeTotal = 0.0;
    int rangeDays = 0;
    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final completion = _calculateDayCompletion(
        dayIndex: day,
        profile: profile,
        entriesByDay: entriesByDay,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
        quranDailyData: quranDailyData,
      );
      dayCompletions[day] = completion;
      rangeTotal += completion;
      rangeDays++;
    }

    // For backward compatibility, calculate week and season averages
    // But use the range data if it's a subset
    final weekStart = max(1, currentDayIndex - 6);
    double weekTotal = 0.0;
    int weekDays = 0;
    for (int day = weekStart; day <= currentDayIndex; day++) {
      final completion = dayCompletions[day] ??
          _calculateDayCompletion(
            dayIndex: day,
            profile: profile,
            entriesByDay: entriesByDay,
            allHabits: allHabits,
            seasonHabits: seasonHabits,
            quranDailyData: quranDailyData,
          );
      dayCompletions[day] = completion;
      weekTotal += completion;
      weekDays++;
    }

    // Calculate for entire season (only if range includes all days)
    double seasonTotal = 0.0;
    int seasonDays = 0;
    if (startDayIndex == 1 && endDayIndex >= currentDayIndex) {
      for (int day = 1; day <= min(currentDayIndex, profile.days); day++) {
            final completion = dayCompletions[day] ??
            _calculateDayCompletion(
              dayIndex: day,
              profile: profile,
              entriesByDay: entriesByDay,
              allHabits: allHabits,
              seasonHabits: seasonHabits,
              quranDailyData: quranDailyData,
            );
        seasonTotal += completion;
        seasonDays++;
      }
    } else {
      // Use range data for season if it's a subset
      seasonTotal = rangeTotal;
      seasonDays = rangeDays;
    }

    // Calculate streaks
    final streakData = _calculateStreaks(dayCompletions, profile.streakThreshold);
    final currentStreak = streakData['current'] as int;
    final bestStreak = streakData['best'] as int;

    // Categorize days
    int daysStrong = 0, daysOk = 0, daysLow = 0;
    for (final completion in dayCompletions.values) {
      if (completion >= 0.8) {
        daysStrong++;
      } else if (completion >= 0.5) {
        daysOk++;
      } else {
        daysLow++;
      }
    }

    // Generate explanation
    final score = todayCompletion * 100;
    String explanation;
    if (score >= 80) {
      explanation = "Excellent! You're on track with most tasks completed.";
    } else if (score >= 60) {
      explanation = "Good progress! A few tasks still need attention.";
    } else if (score >= 40) {
      explanation = "You're making progress. Keep going!";
    } else {
      explanation = "Start tracking to build momentum.";
    }

    // Use range average for the main completion percent
    final rangeAverage = rangeDays > 0 ? rangeTotal / rangeDays : 0.0;

    return {
      'summary': OverallSummary(
        todayCompletionPercent: todayCompletion,
        weekCompletionPercent: rangeAverage, // Use range average
        monthCompletionPercent: seasonDays > 0 ? seasonTotal / seasonDays : rangeAverage,
        currentStreakDays: currentStreak,
        bestStreakDays: bestStreak,
        daysStrong: daysStrong,
        daysOk: daysOk,
        daysLow: daysLow,
        scoreToday: score,
        explanation: explanation,
      ),
      'dayCompletions': dayCompletions,
    };
  }

  static double _calculateDayCompletion({
    required int dayIndex,
    required RamadanProfile profile,
    required Map<int, List<DailyEntryModel>> entriesByDay,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    List<QuranDailyData>? quranDailyData,
  }) {
    if (profile.enabledTasks.isEmpty) return 0.0;

    final dayEntries = entriesByDay[dayIndex] ?? [];
    double totalProgress = 0.0;
    int count = 0;

    for (final taskKey in profile.enabledTasks) {
      final taskDef = TaskRegistry.getTask(taskKey);
      if (taskDef == null) continue;

      // Find habit
      final habit = allHabits.firstWhere(
        (h) => h.key == taskDef.habitKey,
        orElse: () => throw StateError('Habit not found: ${taskDef.habitKey}'),
      );
      final seasonHabit = seasonHabits.firstWhere(
        (sh) => sh.habitId == habit.id,
        orElse: () => throw StateError('SeasonHabit not found'),
      );

      // Find entry - special handling for Quran (uses QuranDaily table)
      DailyEntryModel entry;
      if (taskKey == TaskKey.quran && quranDailyData != null) {
        final quranData = quranDailyData.firstWhere(
          (q) => q.dayIndex == dayIndex,
          orElse: () => QuranDailyData(
            seasonId: profile.seasonId,
            dayIndex: dayIndex,
            pagesRead: 0,
            updatedAt: 0,
          ),
        );
        entry = DailyEntryModel(
          seasonId: profile.seasonId,
          dayIndex: dayIndex,
          habitId: habit.id,
          valueInt: quranData.pagesRead,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(quranData.updatedAt),
        );
      } else {
        entry = dayEntries.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(
            seasonId: profile.seasonId,
            dayIndex: dayIndex,
            habitId: habit.id,
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Special handling for composite tasks
      if (taskKey == TaskKey.prayers5) {
        // For now, treat as boolean - all 5 done = 1.0
        // TODO: Implement proper 5-prayers tracking
        final progress = entry.isCompleted ? 1.0 : 0.0;
        totalProgress += progress;
        count++;
      } else {
        final progress = taskDef.calculateProgress(entry, seasonHabit, habit);
        totalProgress += progress;
        count++;
      }
    }

    return count > 0 ? totalProgress / count : 0.0;
  }

  static Map<String, int> _calculateStreaks(
    Map<int, double> dayCompletions,
    double threshold,
  ) {
    if (dayCompletions.isEmpty) {
      return {'current': 0, 'best': 0};
    }

    final sortedDays = dayCompletions.keys.toList()..sort((a, b) => b.compareTo(a));
    int currentStreak = 0;
    int bestStreak = 0;
    int tempStreak = 0;

    for (final day in sortedDays) {
      if (dayCompletions[day]! >= threshold) {
        if (currentStreak == 0 || day == sortedDays[0] - currentStreak) {
          currentStreak++;
        }
        tempStreak++;
        bestStreak = max(bestStreak, tempStreak);
      } else {
        if (currentStreak > 0 && day == sortedDays[0] - currentStreak) {
          // Streak broken
        }
        tempStreak = 0;
      }
    }

    // Recalculate current streak from today backwards
    currentStreak = 0;
    final today = sortedDays.isNotEmpty ? sortedDays[0] : 0;
    for (int day = today; day >= 1; day--) {
      if (dayCompletions.containsKey(day) && dayCompletions[day]! >= threshold) {
        currentStreak++;
      } else {
        break;
      }
    }

    return {'current': currentStreak, 'best': bestStreak};
  }

  static TaskInsightSummary? _calculateTaskSummary({
    required TaskKey taskKey,
    required RamadanProfile profile,
    required Map<int, List<DailyEntryModel>> entriesByDay,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    List<QuranDailyData>? quranDailyData,
    List<PrayerDetail>? prayerDetails,
    required int currentDayIndex,
    required int startDayIndex,
    required int endDayIndex,
  }) {
    final taskDef = TaskRegistry.getTask(taskKey);
    if (taskDef == null) return null;

    // Find habit
    final habit = allHabits.firstWhere(
      (h) => h.key == taskDef.habitKey,
      orElse: () => throw StateError('Habit not found: ${taskDef.habitKey}'),
    );
    final seasonHabit = seasonHabits.firstWhere(
      (sh) => sh.habitId == habit.id,
      orElse: () => throw StateError('SeasonHabit not found'),
    );

    // Collect data for days in the selected range
    final dayProgress = <int, double>{};
    final dayValues = <int, int>{};
    int? bestDay, worstDay;
    double bestValue = -1, worstValue = double.infinity;

    for (int day = startDayIndex; day <= endDayIndex; day++) {
      final dayEntries = entriesByDay[day] ?? [];
      DailyEntryModel? entry;

      // Special handling for Quran (uses QuranDaily table)
      if (taskKey == TaskKey.quran && quranDailyData != null) {
        final quranData = quranDailyData.firstWhere(
          (q) => q.dayIndex == day,
          orElse: () => QuranDailyData(
            seasonId: profile.seasonId,
            dayIndex: day,
            pagesRead: 0,
            updatedAt: 0,
          ),
        );
        entry = DailyEntryModel(
          seasonId: profile.seasonId,
          dayIndex: day,
          habitId: habit.id,
          valueInt: quranData.pagesRead,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(quranData.updatedAt),
        );
      } else {
        entry = dayEntries.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(
            seasonId: profile.seasonId,
            dayIndex: day,
            habitId: habit.id,
            updatedAt: DateTime.now(),
          ),
        );
      }

      // Special handling for 5 Prayers (composite task)
      double progress;
      if (taskKey == TaskKey.prayers5) {
        // Check if detailed prayer tracking is available
        if (prayerDetails != null) {
          final prayerDetail = prayerDetails.firstWhere(
            (p) => p.dayIndex == day,
            orElse: () => PrayerDetail(
              seasonId: profile.seasonId,
              dayIndex: day,
              fajr: false,
              dhuhr: false,
              asr: false,
              maghrib: false,
              isha: false,
              updatedAt: 0,
            ),
          );
          final completedCount = [
            prayerDetail.fajr,
            prayerDetail.dhuhr,
            prayerDetail.asr,
            prayerDetail.maghrib,
            prayerDetail.isha,
          ].where((p) => p).length;
          progress = completedCount / 5.0;
        } else {
          // Fallback to simple boolean entry
          progress = entry.isCompleted ? 1.0 : 0.0;
        }
      } else {
        progress = taskDef.calculateProgress(entry, seasonHabit, habit);
      }
      dayProgress[day] = progress;
      final value = entry.valueInt ?? (entry.isCompleted ? 1 : 0);
      dayValues[day] = value;

      if (taskDef.type == TaskType.counter || taskDef.type == TaskType.amount) {
      if (value > bestValue) {
        bestValue = value.toDouble();
        bestDay = day;
      }
      if (value > 0 && value < worstValue) {
        worstValue = value.toDouble();
        worstDay = day;
      }
      }
    }

    // Calculate completion rate
    final completionRate = dayProgress.values.isEmpty
        ? 0.0
        : dayProgress.values.reduce((a, b) => a + b) / dayProgress.length;

    // Calculate streak
    final streakData = _calculateTaskStreak(dayProgress, taskDef.type);
    final streak = streakData['streak'] as int?;

    // Generate chart series
    final chartSeries = dayProgress.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value * 100))
        .toList();

    // Determine if needs attention
    // For boolean/composite tasks (like 5 Prayers), check if today is completed
    // For other tasks, use completion rate
    bool needAttention;
    if (taskKey == TaskKey.prayers5 || taskDef.type == TaskType.boolean || taskDef.type == TaskType.composite) {
      // For boolean/composite tasks, only show warning if today is not completed
      final todayProgress = dayProgress[currentDayIndex] ?? 0.0;
      needAttention = todayProgress < 1.0;
    } else {
      // For counter/amount tasks, use completion rate
      needAttention = completionRate < 0.5 ||
          (currentDayIndex > 3 && (dayProgress[currentDayIndex] ?? 0.0) < 0.3);
    }

    // Build metadata
    final metadata = <String, dynamic>{};
    if (taskKey == TaskKey.sedekah) {
      final total = dayValues.values.fold<int>(0, (a, b) => a + b);
      final avg = dayValues.isNotEmpty ? total / dayValues.length : 0.0;
      final todayAmount = dayValues[currentDayIndex] ?? 0;
      metadata['total'] = total;
      metadata['average'] = avg.round();
      metadata['today'] = todayAmount;
      metadata['bestDay'] = bestDay;
    } else if (taskKey == TaskKey.quran) {
      final total = dayValues.values.fold<int>(0, (a, b) => a + b);
      final avg = dayValues.isNotEmpty ? total / dayValues.length : 0.0;
      metadata['total'] = total;
      metadata['average'] = avg.round();
      metadata['target'] = seasonHabit.targetValue ?? habit.defaultTarget ?? 0;
    } else if (taskKey == TaskKey.dhikr) {
      final total = dayValues.values.fold<int>(0, (a, b) => a + b);
      final avg = dayValues.isNotEmpty ? total / dayValues.length : 0.0;
      metadata['total'] = total;
      metadata['average'] = avg.round();
      metadata['target'] = seasonHabit.targetValue ?? habit.defaultTarget ?? 0;
    } else if (taskKey == TaskKey.prayers5) {
      // Count all-5 days and calculate prayer statistics
      int allFiveDays = 0;
      int totalPrayersCompleted = 0;
      final prayerCounts = <String, int>{
        'fajr': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      };
      
      if (prayerDetails != null) {
        for (final detail in prayerDetails) {
          if (detail.dayIndex >= startDayIndex && detail.dayIndex <= endDayIndex) {
            final completed = [
              detail.fajr,
              detail.dhuhr,
              detail.asr,
              detail.maghrib,
              detail.isha,
            ].where((p) => p).length;
            
            if (completed == 5) allFiveDays++;
            totalPrayersCompleted += completed;
            
            if (detail.fajr) prayerCounts['fajr'] = (prayerCounts['fajr'] ?? 0) + 1;
            if (detail.dhuhr) prayerCounts['dhuhr'] = (prayerCounts['dhuhr'] ?? 0) + 1;
            if (detail.asr) prayerCounts['asr'] = (prayerCounts['asr'] ?? 0) + 1;
            if (detail.maghrib) prayerCounts['maghrib'] = (prayerCounts['maghrib'] ?? 0) + 1;
            if (detail.isha) prayerCounts['isha'] = (prayerCounts['isha'] ?? 0) + 1;
          }
        }
      } else {
        // Fallback: use simple boolean entries
        for (final progress in dayProgress.values) {
          if (progress >= 1.0) {
            allFiveDays++;
            totalPrayersCompleted += 5;
          }
        }
      }
      
      // Find most missed prayer
      final maxCount = prayerCounts.values.isNotEmpty ? prayerCounts.values.reduce((a, b) => a > b ? a : b) : 0;
      final minCount = prayerCounts.values.isNotEmpty ? prayerCounts.values.reduce((a, b) => a < b ? a : b) : 0;
      String? mostMissed;
      if (prayerCounts.isNotEmpty && minCount < maxCount) {
        mostMissed = prayerCounts.entries.firstWhere((e) => e.value == minCount).key;
      }
      
      final totalPossible = dayProgress.length * 5;
      final completionRate = totalPossible > 0 ? (totalPrayersCompleted / totalPossible) : 0.0;
      
      metadata['allFiveDays'] = allFiveDays;
      metadata['totalDays'] = dayProgress.length;
      metadata['totalPrayersCompleted'] = totalPrayersCompleted;
      metadata['totalPossible'] = totalPossible;
      metadata['completionRate'] = completionRate;
      metadata['mostMissed'] = mostMissed;
      metadata['prayerCounts'] = prayerCounts;
    } else if (taskKey == TaskKey.itikaf) {
      // Last 10 nights
      final last10Start = max(1, profile.days - 9);
      int nightsDone = 0;
      for (int day = last10Start; day <= profile.days; day++) {
        if (dayProgress[day] != null && dayProgress[day]! >= 1.0) {
          nightsDone++;
        }
      }
      metadata['nightsDone'] = nightsDone;
      metadata['nightsRemaining'] = max(0, 10 - (currentDayIndex - last10Start + 1));
      metadata['streak'] = streak;
    }

    return TaskInsightSummary(
      taskKey: taskKey,
      completionRate: completionRate,
      streak: streak,
      bestDay: bestDay,
      worstDay: worstDay,
      needAttention: needAttention,
      chartSeries: chartSeries,
      metadata: metadata,
    );
  }

  static Map<String, int?> _calculateTaskStreak(
    Map<int, double> dayProgress,
    TaskType type,
  ) {
    if (dayProgress.isEmpty) return {'streak': null};

    final sortedDays = dayProgress.keys.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;

    // For boolean tasks, streak = consecutive days with progress >= 1.0
    // For counter/amount, streak = consecutive days with progress >= 0.7
    final threshold = type == TaskType.boolean ? 1.0 : 0.7;

    for (final day in sortedDays) {
      if (dayProgress[day]! >= threshold) {
        streak++;
      } else {
        break;
      }
    }

    return {'streak': streak > 0 ? streak : null};
  }

  static List<Highlight> _generateHighlights({
    required RamadanProfile profile,
    required OverallSummary overallSummary,
    required Map<TaskKey, TaskInsightSummary> taskSummaries,
    required int currentDayIndex,
    String? sedekahCurrency,
    List<Note>? notes,
  }) {
    final highlights = <Highlight>[];

    // Streak highlight
    if (overallSummary.currentStreakDays >= 3) {
      highlights.add(Highlight(
        icon: Icons.local_fire_department,
        title: '${overallSummary.currentStreakDays}-day streak!',
        subtitle: 'Keep the momentum going',
      ));
    }

    // Task-specific highlights
    for (final entry in taskSummaries.entries) {
      final taskKey = entry.key;
      final summary = entry.value;
      final taskDef = TaskRegistry.getTask(taskKey);

      if (taskKey == TaskKey.sedekah && summary.metadata['total'] != null) {
        final total = summary.metadata['total'] as int;
        final avg = summary.metadata['average'] as int;
        if (total > 0) {
          final currency = sedekahCurrency ?? 'IDR';
          final normalizedCurrency = _normalizeCurrency(currency);
          highlights.add(Highlight(
            icon: Icons.volunteer_activism,
            title: 'Sedekah total: ${_formatCurrency(total, normalizedCurrency)}',
            subtitle: 'Average ${_formatCurrency(avg, normalizedCurrency)}/day',
          ));
        }
      } else if (taskKey == TaskKey.prayers5 && summary.metadata['allFiveDays'] != null) {
        final allFiveDays = summary.metadata['allFiveDays'] as int;
        final totalDays = summary.metadata['totalDays'] as int;
        final totalPrayers = summary.metadata['totalPrayersCompleted'] as int? ?? 0;
        final mostMissed = summary.metadata['mostMissed'] as String?;
        if (allFiveDays > 0) {
          highlights.add(Highlight(
            icon: Icons.mosque,
            title: 'All-5 prayers: $allFiveDays/$totalDays days',
            subtitle: allFiveDays >= totalDays * 0.7
                ? 'Excellent consistency!'
                : 'Keep it up!',
          ));
        }
        if (mostMissed != null && totalPrayers > 0) {
          final prayerName = mostMissed[0].toUpperCase() + mostMissed.substring(1);
          highlights.add(Highlight(
            icon: Icons.info_outline,
            title: 'Most missed: $prayerName',
            subtitle: 'Focus on this prayer to improve',
          ));
        }
      } else if (taskKey == TaskKey.quran) {
        final avg = summary.metadata['average'] as int? ?? 0;
        final target = summary.metadata['target'] as int? ?? 0;
        if (target > 0 && avg < target * 0.7) {
          final behind = target - avg;
          highlights.add(Highlight(
            icon: Icons.menu_book,
            title: 'Quran pace',
            subtitle: 'You\'re $behind pages behind target — easy catch-up plan',
          ));
        } else if (avg >= target * 0.9) {
          highlights.add(Highlight(
            icon: Icons.menu_book,
            title: 'Quran on track',
            subtitle: 'Average $avg pages/day',
          ));
        }
      } else if (taskKey == TaskKey.dhikr && summary.completionRate < 0.7) {
        highlights.add(Highlight(
          icon: Icons.favorite,
          title: 'Dhikr needs attention',
          subtitle: '${(summary.completionRate * 100).round()}% completion rate',
        ));
      }
    }
    
    // Reflection highlights
    if (notes != null && notes.isNotEmpty) {
      final reflectionCount = notes.length;
      final moodCounts = <String, int>{};
      for (final note in notes) {
        if (note.mood != null) {
          moodCounts[note.mood!] = (moodCounts[note.mood!] ?? 0) + 1;
        }
      }
      if (reflectionCount > 0) {
        highlights.add(Highlight(
          icon: Icons.edit_note,
          title: '$reflectionCount reflections recorded',
          subtitle: moodCounts.isNotEmpty 
              ? 'Most common mood: ${moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key}'
              : 'Keep reflecting daily',
        ));
      }
    }

    // Limit to 5 highlights
    return highlights.take(5).toList();
  }

  static List<NextAction> _generateNextActions({
    required RamadanProfile profile,
    required Map<int, List<DailyEntryModel>> entriesByDay,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    required int currentDayIndex,
  }) {
    final actions = <NextAction>[];
    final todayEntries = entriesByDay[currentDayIndex] ?? [];

    for (final taskKey in profile.enabledTasks) {
      if (actions.length >= 3) break;

      final taskDef = TaskRegistry.getTask(taskKey);
      if (taskDef == null) continue;

      final habit = allHabits.firstWhere(
        (h) => h.key == taskDef.habitKey,
        orElse: () => throw StateError('Habit not found'),
      );

      final entry = todayEntries.firstWhere(
        (e) => e.habitId == habit.id,
        orElse: () => DailyEntryModel(
          seasonId: profile.seasonId,
          dayIndex: currentDayIndex,
          habitId: habit.id,
          updatedAt: DateTime.now(),
        ),
      );

      // Check if task needs action
      bool needsAction = false;
      String label = '';
      IconData icon = taskDef.icon;
      String? quickValue;

      if (taskDef.type == TaskType.boolean) {
        if (!entry.isCompleted) {
          needsAction = true;
          label = 'Mark ${taskDef.title}';
        }
      } else if (taskDef.type == TaskType.counter) {
        final target = taskDef.getTarget(
          seasonHabits.firstWhere((sh) => sh.habitId == habit.id),
          habit,
        ) ?? 0;
        final current = entry.valueInt ?? 0;
        if (current < target * 0.5) {
          needsAction = true;
          if (taskKey == TaskKey.dhikr) {
            label = 'Add Dhikr';
            quickValue = '+33';
          } else {
            label = 'Log ${taskDef.title}';
          }
        }
      } else if (taskDef.type == TaskType.amount) {
        if ((entry.valueInt ?? 0) == 0) {
          needsAction = true;
          label = 'Add Sedekah';
        }
      }

      if (needsAction) {
        actions.add(NextAction(
          taskKey: taskKey,
          label: label,
          icon: icon,
          onTap: () {}, // Will be set by UI
          quickValue: quickValue,
        ));
      }
    }

    return actions;
  }

  static String _formatCurrency(int amount, [String? currency]) {
    // If currency is provided, use SedekahUtils for proper formatting
    if (currency != null && currency.isNotEmpty) {
      return SedekahUtils.formatCurrency(amount.toDouble(), currency);
    }
    // Fallback: Simple formatting
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toString();
  }

  static String _normalizeCurrency(String currency) {
    // Handle currency symbols that might be passed directly (S$, $, RM, Rp)
    String normalizedCurrency = currency.trim();
    final symbolToCode = {
      'S\$': 'SGD',
      '\$': 'USD',
      'RM': 'MYR',
      'Rp': 'IDR',
      'RP': 'IDR',
    };
    if (symbolToCode.containsKey(normalizedCurrency)) {
      normalizedCurrency = symbolToCode[normalizedCurrency]!;
    } else {
      normalizedCurrency = normalizedCurrency.toUpperCase();
    }
    return normalizedCurrency;
  }
}

