import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Evaluates worship milestones and unlocks achievements with XP rewards.
class AchievementService {
  AchievementService._();

  static const int _streakScoreThreshold = 60;
  static const int _fullDayScoreThreshold = 80;

  /// Run all applicable checks after user activity.
  static Future<List<AchievementUnlock>> evaluateAfterActivity({
    required AppDatabase database,
    int? seasonId,
    int? dayIndex,
  }) async {
    final unlocks = <AchievementUnlock>[];

    Future<void> tryKey(
      String key, {
      int? sid,
      required Future<bool> Function() condition,
    }) async {
      if (!await condition()) return;
      final unlock = await _tryUnlock(database, key, seasonId: sid);
      if (unlock != null) unlocks.add(unlock);
    }

    final hasAnyLog = await _hasAnyHabitLog(database) ||
        (await database.sunnahFastsDao.getAll()).isNotEmpty;

    await tryKey('first_log', condition: () async => hasAnyLog);

    if (seasonId != null && dayIndex != null) {
      final score = await _dayScore(database, seasonId, dayIndex);
      await tryKey(
        'first_full_day',
        sid: seasonId,
        condition: () async => score >= _fullDayScoreThreshold,
      );

      final streak = await _scoreStreak(database, seasonId, dayIndex);
      await tryKey('streak_3', sid: seasonId, condition: () async => streak >= 3);
      await tryKey('streak_7', sid: seasonId, condition: () async => streak >= 7);
      await tryKey('streak_14', sid: seasonId, condition: () async => streak >= 14);

      await tryKey(
        'weekly_perfect',
        sid: seasonId,
        condition: () async => _isWeeklyPerfect(database, seasonId, dayIndex),
      );

      final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
      if (season != null) {
        final last10Start = season.days - 9;
        if (dayIndex >= last10Start) {
          await tryKey(
            'last_10_hero',
            sid: seasonId,
            condition: () async => hasAnyLog,
          );
        }
      }

      await _checkQuranAchievements(database, seasonId, unlocks);
    }

    final sunnahRows = await database.sunnahFastsDao.getAll();
    await tryKey(
      'first_sunnah',
      condition: () async => sunnahRows.isNotEmpty,
    );
    await tryKey(
      'senin_kamis_4',
      condition: () async => _seninKamisCountThisMonth(sunnahRows) >= 4,
    );
    await tryKey(
      'shawwal_complete',
      condition: () async =>
          sunnahRows.where((r) => r.type == 'syawal' && r.status == FastingStatus.fasted).length >= 6,
    );

    final notes = await database.notesDao.getAllNotes();
    await tryKey(
      'reflection_first',
      condition: () async =>
          notes.any((n) => (n.mood != null && n.mood!.isNotEmpty) || n.body.isNotEmpty),
    );

    final engagement = await database.userEngagementDao.getOrCreate();
    await tryKey(
      'companion_level_5',
      condition: () async => engagement.companionLevel >= 5,
    );

    return unlocks;
  }

  static Future<void> _checkQuranAchievements(
    AppDatabase database,
    int seasonId,
    List<AchievementUnlock> unlocks,
  ) async {
    final plan = await database.quranPlanDao.getPlan(seasonId);
    if (plan == null || plan.totalPages <= 0) return;

    final allDaily = await database.quranDailyDao.getAllDaily(seasonId);
    var pagesRead = 0;
    for (final d in allDaily) {
      pagesRead += d.pagesRead;
    }
    final progress = pagesRead / plan.totalPages;

    if (progress >= 0.5) {
      final unlock = await _tryUnlock(database, 'quran_half', seasonId: seasonId);
      if (unlock != null) unlocks.add(unlock);
    }
    if (progress >= 1.0) {
      final unlock = await _tryUnlock(database, 'quran_complete', seasonId: seasonId);
      if (unlock != null) unlocks.add(unlock);
    }
  }

  /// Call when a season ends (post-Ramadan).
  static Future<List<AchievementUnlock>> evaluateSeasonComplete({
    required AppDatabase database,
    required int seasonId,
  }) async {
    final unlocks = <AchievementUnlock>[];
    final entries = await database.dailyEntriesDao.getAllSeasonEntries(seasonId);
    if (entries.isNotEmpty) {
      final unlock = await _tryUnlock(database, 'season_complete', seasonId: seasonId);
      if (unlock != null) unlocks.add(unlock);
    }
    unlocks.addAll(await evaluateAfterActivity(
      database: database,
      seasonId: seasonId,
      dayIndex: null,
    ));
    return unlocks;
  }

  static Future<AchievementUnlock?> _tryUnlock(
    AppDatabase database,
    String key, {
    int? seasonId,
  }) async {
    if (await database.userAchievementsDao.isUnlocked(key)) return null;
    final definition = AchievementCatalog.byKey(key);
    if (definition == null) return null;

    await database.userAchievementsDao.unlock(
      achievementKey: key,
      seasonId: seasonId,
    );

    if (definition.xpReward > 0) {
      await database.userEngagementDao.addXp(definition.xpReward);
    }

    final unlockedAt = DateTime.now();
    return AchievementUnlock(
      definition: definition,
      xpAwarded: definition.xpReward,
      unlockedAt: unlockedAt,
    );
  }

  static Future<bool> _hasAnyHabitLog(AppDatabase database) async {
    final seasons = await database.ramadanSeasonsDao.getAllSeasons();
    for (final season in seasons) {
      final entries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
      if (entries.isNotEmpty) return true;
    }
    return false;
  }

  static Future<double> _dayScore(
    AppDatabase database,
    int seasonId,
    int dayIndex,
  ) async {
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
    final enabled = seasonHabits.where((sh) => sh.isEnabled).toList();
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final habits = await database.habitsDao.getAllHabits();
    final entryModels = entries
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
    return CompletionService.calculateCompletionScore(
      seasonId: seasonId,
      dayIndex: dayIndex,
      enabledHabits: enabled,
      entries: entryModels,
      database: database,
      allHabits: habits,
    );
  }

  /// Consecutive days (ending at [upToDay]) with score >= threshold.
  static Future<int> _scoreStreak(
    AppDatabase database,
    int seasonId,
    int upToDay,
  ) async {
    var streak = 0;
    for (var day = upToDay; day >= 1; day--) {
      final entries = await database.dailyEntriesDao.getDayEntries(seasonId, day);
      if (entries.isEmpty) break;
      final score = await _dayScore(database, seasonId, day);
      if (score >= _streakScoreThreshold) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static Future<bool> _isWeeklyPerfect(
    AppDatabase database,
    int seasonId,
    int upToDay,
  ) async {
    if (upToDay < 7) return false;
    for (var day = upToDay - 6; day <= upToDay; day++) {
      final entries = await database.dailyEntriesDao.getDayEntries(seasonId, day);
      if (entries.isEmpty) return false;
      final score = await _dayScore(database, seasonId, day);
      if (score < _streakScoreThreshold) return false;
    }
    return true;
  }

  static int _seninKamisCountThisMonth(List<SunnahFast> rows) {
    final now = DateTime.now();
    var count = 0;
    for (final row in rows) {
      if (row.status != FastingStatus.fasted) continue;
      final parts = row.dateYmd.split('-');
      if (parts.length != 3) continue;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != now.year || m != now.month || d == null) continue;
      if (y == null || m == null) continue;
      final weekday = DateTime(y, m, d).weekday;
      if (weekday == DateTime.monday || weekday == DateTime.thursday) {
        count++;
      }
    }
    return count;
  }
}
