import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Mercy streak freezes: 2 per season, auto-used on excused fasting days.
class StreakShieldService {
  StreakShieldService._();

  static const int shieldsPerSeason = 2;

  static String _usedKey(int seasonId) => 'streak_shields_used_$seasonId';

  static Future<int> shieldsUsed(AppDatabase database, int seasonId) async {
    final raw = await database.kvSettingsDao.getValue(_usedKey(seasonId));
    return int.tryParse(raw ?? '0') ?? 0;
  }

  static Future<int> shieldsRemaining(AppDatabase database, int seasonId) async {
    final used = await shieldsUsed(database, seasonId);
    return (shieldsPerSeason - used).clamp(0, shieldsPerSeason);
  }

  /// Returns true if a shield was consumed for this excused day.
  static Future<bool> tryConsumeForExcusedDay({
    required AppDatabase database,
    required int seasonId,
    required int dayIndex,
  }) async {
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final habits = await database.habitsDao.getAllHabits();
    final fastingHabit = habits.where((h) => h.key == 'fasting').firstOrNull;
    if (fastingHabit == null) return false;

    final fastingEntry = entries.where((e) => e.habitId == fastingHabit.id).firstOrNull;
    if (fastingEntry == null) return false;

    final status = FastingStatus.fromEntry(fastingEntry.valueInt, fastingEntry.valueBool);
    if (!FastingStatus.isExcused(status)) return false;

    final flagKey = 'streak_shield_applied_s${seasonId}_d$dayIndex';
    if (await database.kvSettingsDao.getValue(flagKey) == 'true') return true;

    final remaining = await shieldsRemaining(database, seasonId);
    if (remaining <= 0) return false;

    await database.kvSettingsDao.setValue(flagKey, 'true');
    await database.kvSettingsDao.setValue(
      _usedKey(seasonId),
      (await shieldsUsed(database, seasonId) + 1).toString(),
    );
    return true;
  }
}
