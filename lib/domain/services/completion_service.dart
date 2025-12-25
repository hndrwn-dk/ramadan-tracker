import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

class CompletionService {
  static double calculateCompletionScore({
    required List enabledHabits,
    required List entries,
  }) {
    if (enabledHabits.isEmpty) return 0.0;

    double totalScore = 0.0;
    int count = 0;

    for (final habit in enabledHabits) {
      final entry = entries.where((e) => e.habitId == habit.habitId).firstOrNull ??
          DailyEntryModel(
            seasonId: habit.seasonId,
            dayIndex: 0,
            habitId: habit.habitId,
            updatedAt: DateTime.now(),
          );

      double habitScore = 0.0;
      if (habit.habitId == 7 || habit.habitId == 8) {
        final target = habit.targetValue ?? 0;
        if (target > 0) {
          final progress = (entry.valueInt ?? 0) / target;
          habitScore = progress.clamp(0.0, 1.0);
        }
      } else {
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

