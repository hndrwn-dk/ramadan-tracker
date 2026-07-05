import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

enum HabitMasteryTier { none, bronze, silver, gold }

/// Season consistency tiers per enabled habit (Bronze 50%, Silver 75%, Gold 90%).
class HabitMasteryService {
  HabitMasteryService._();

  static HabitMasteryTier tierFromRate(double rate) {
    if (rate >= 0.9) return HabitMasteryTier.gold;
    if (rate >= 0.75) return HabitMasteryTier.silver;
    if (rate >= 0.5) return HabitMasteryTier.bronze;
    return HabitMasteryTier.none;
  }

  static Future<Map<String, HabitMasteryTier>> tiersForSeason(
    AppDatabase database,
    int seasonId,
    int seasonDays,
  ) async {
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
    final enabled = seasonHabits.where((s) => s.isEnabled).toList();
    final habits = await database.habitsDao.getAllHabits();
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    final last10Start = season != null ? season.days - 9 : 0;
    final result = <String, HabitMasteryTier>{};

    for (final sh in enabled) {
      final habit = habits.where((h) => h.id == sh.habitId).firstOrNull;
      if (habit == null) continue;

      if (habit.key == 'itikaf') {
        final applicableDays = seasonDays >= 10 ? 10 : 0;
        if (applicableDays <= 0) {
          result[habit.key] = HabitMasteryTier.none;
          continue;
        }
        var completedDays = 0;
        for (var day = last10Start; day <= seasonDays; day++) {
          if (day < 1) continue;
          final entries = await database.dailyEntriesDao.getDayEntries(seasonId, day);
          final entry = entries.where((e) => e.habitId == sh.habitId).firstOrNull;
          if (entry != null && entry.valueBool == true) completedDays++;
        }
        result[habit.key] = tierFromRate(completedDays / applicableDays);
        continue;
      }

      var completedDays = 0;
      var countedDays = 0;
      for (var day = 1; day <= seasonDays; day++) {
        final entries = await database.dailyEntriesDao.getDayEntries(seasonId, day);
        final entry = entries.where((e) => e.habitId == sh.habitId).firstOrNull;
        if (entry == null) continue;
        countedDays++;

        final model = DailyEntryModel(
          seasonId: seasonId,
          dayIndex: day,
          habitId: sh.habitId,
          valueBool: entry.valueBool,
          valueInt: entry.valueInt,
          note: entry.note,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(entry.updatedAt),
        );

        if (await _isHabitComplete(
          database: database,
          seasonId: seasonId,
          dayIndex: day,
          habitKey: habit.key,
          entry: model,
          quranDailyPages: (await database.quranDailyDao.getDaily(seasonId, day))?.pagesRead ?? 0,
          quranTarget: quranPlan?.dailyTargetPages ?? 20,
          dhikrTarget: dhikrPlan?.dailyTarget ?? 100,
          sedekahGoalEnabled: sedekahGoalEnabled == 'true',
          sedekahGoalAmount: double.tryParse(sedekahGoalAmount ?? '') ?? 0,
        )) {
          completedDays++;
        }
      }

      final rate = countedDays > 0 ? completedDays / countedDays : 0.0;
      result[habit.key] = tierFromRate(rate);
    }
    return result;
  }

  static Future<bool> _isHabitComplete({
    required AppDatabase database,
    required int seasonId,
    required int dayIndex,
    required String habitKey,
    required DailyEntryModel entry,
    required int quranDailyPages,
    required int quranTarget,
    required int dhikrTarget,
    required bool sedekahGoalEnabled,
    required double sedekahGoalAmount,
  }) async {
    switch (habitKey) {
      case 'quran_pages':
        if (quranTarget > 0) return quranDailyPages >= quranTarget;
        return quranDailyPages > 0;
      case 'dhikr':
        if (dhikrTarget > 0) return (entry.valueInt ?? 0) >= dhikrTarget;
        return (entry.valueInt ?? 0) > 0;
      case 'sedekah':
        if (sedekahGoalEnabled && sedekahGoalAmount > 0) {
          return (entry.valueInt ?? 0) >= sedekahGoalAmount;
        }
        return (entry.valueInt ?? 0) > 0;
      case 'fasting':
        return FastingStatus.isCompletedForDay(entry.valueInt, entry.valueBool);
      default:
        return entry.isCompleted;
    }
  }
}
