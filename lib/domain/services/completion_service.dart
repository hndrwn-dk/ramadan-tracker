import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

class CompletionService {
  static Future<double> calculateCompletionScore({
    required int seasonId,
    required int dayIndex,
    required List enabledHabits,
    required List entries,
    required AppDatabase database,
    List? allHabits,
  }) async {
    if (enabledHabits.isEmpty) return 0.0;

    // Load plans for count-based habits
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    
    // Load Quran daily data (Quran uses separate table)
    final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
    
    // Check if we're in the last 10 days (for Itikaf)
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    final last10Start = season != null ? season.days - 9 : 0;
    final isInLast10Days = dayIndex >= last10Start && dayIndex > 0;

    double totalScore = 0.0;
    int count = 0;

    for (final habit in enabledHabits) {
      // Get habit key to identify count habits and Itikaf
      String? habitKey;
      if (allHabits != null) {
        try {
          final fullHabit = allHabits.firstWhere((h) => h.id == habit.habitId);
          habitKey = fullHabit.key;
        } catch (e) {
          habitKey = null;
        }
      }
      
      // Skip Itikaf if not in last 10 days
      if (habitKey == 'itikaf' && !isInLast10Days) {
        continue;
      }
      final entry = entries.where((e) => 
        e.habitId == habit.habitId && 
        e.seasonId == seasonId && 
        e.dayIndex == dayIndex
      ).firstOrNull ??
          DailyEntryModel(
            seasonId: seasonId,
            dayIndex: dayIndex,
            habitId: habit.habitId,
            updatedAt: DateTime.now(),
          );

      double habitScore = 0.0;
      
      // Count habits (quran_pages, dhikr, sedekah) should be calculated based on progress
      // habitKey already defined above for Itikaf check
      if (habitKey == 'quran_pages') {
        // Quran uses QuranDaily table, not DailyEntries
        final target = quranPlan?.dailyTargetPages ?? 20;
        if (target > 0) {
          final currentValue = quranDaily?.pagesRead ?? 0;
          final progress = currentValue / target;
          habitScore = progress.clamp(0.0, 1.0);
        } else {
          final currentValue = quranDaily?.pagesRead ?? 0;
          habitScore = currentValue > 0 ? 1.0 : 0.0;
        }
      } else if (habitKey == 'dhikr') {
        // Dhikr target from DhikrPlan
        final target = dhikrPlan?.dailyTarget ?? 100;
        if (target > 0) {
          final progress = (entry.valueInt ?? 0) / target;
          habitScore = progress.clamp(0.0, 1.0);
        } else {
          habitScore = (entry.valueInt ?? 0) > 0 ? 1.0 : 0.0;
        }
      } else if (habitKey == 'sedekah') {
        // Sedekah target from KvSettings
        if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
          final target = double.tryParse(sedekahGoalAmount) ?? 0;
          if (target > 0) {
            // Convert valueInt to double for accurate comparison
            final currentValue = (entry.valueInt ?? 0).toDouble();
            final progress = currentValue / target;
            habitScore = progress.clamp(0.0, 1.0);
          } else {
            habitScore = (entry.valueInt ?? 0) > 0 ? 1.0 : 0.0;
          }
        } else {
          // If sedekah goal disabled, consider completed if value > 0
          habitScore = (entry.valueInt ?? 0) > 0 ? 1.0 : 0.0;
        }
      } else {
        // Boolean habits (fasting, taraweeh, itikaf)
        habitScore = entry.isCompleted ? 1.0 : 0.0;
      }

      totalScore += habitScore;
      count++;
    }

    return count > 0 ? (totalScore / count) * 100 : 0.0;
  }

  static Future<int> calculateStreak({
    required int seasonId,
    required int currentDayIndex,
    required AppDatabase database,
  }) async {
    int streak = 0;
    for (int day = currentDayIndex; day >= 1; day--) {
      final entries = await database.dailyEntriesDao.getDayEntries(seasonId, day);
      final fastingEntry = entries.firstWhere(
        (e) => e.habitId == 1,
        orElse: () => DailyEntry(
          seasonId: seasonId,
          dayIndex: day,
          habitId: 1,
          valueBool: false,
          updatedAt: 0,
        ),
      );

      if (fastingEntry.valueBool == true) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

