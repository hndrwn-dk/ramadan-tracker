import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/achievement_service.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test();
    await db.initialize();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> _seedSeason() async {
    final seasonId = await db.ramadanSeasonsDao.createSeason(
      label: 'Test 1447',
      startDate: DateTime(2026, 2, 18),
      days: 30,
    );
    final habits = await db.habitsDao.getAllHabits();
    await db.seasonHabitsDao.initializeSeasonHabits(seasonId, habits);
    return seasonId;
  }

  group('AchievementService', () {
    test('unlocks first_log after any habit entry', () async {
      final seasonId = await _seedSeason();
      final fasting = await db.habitsDao.getHabitByKey('fasting');
      expect(fasting, isNotNull);

      await db.dailyEntriesDao.setFastingStatus(
        seasonId,
        1,
        fasting!.id,
        FastingStatus.fasted,
      );

      final unlocks = await AchievementService.evaluateAfterActivity(
        database: db,
        seasonId: seasonId,
        dayIndex: 1,
      );

      expect(unlocks.any((u) => u.definition.key == 'first_log'), isTrue);
      expect(await db.userAchievementsDao.isUnlocked('first_log'), isTrue);
      final engagement = await db.userEngagementDao.getOrCreate();
      expect(engagement.totalXp, greaterThanOrEqualTo(10));
    });

    test('does not duplicate first_log unlock', () async {
      final seasonId = await _seedSeason();
      final fasting = await db.habitsDao.getHabitByKey('fasting');
      await db.dailyEntriesDao.setFastingStatus(
        seasonId,
        1,
        fasting!.id,
        FastingStatus.fasted,
      );

      await AchievementService.evaluateAfterActivity(
        database: db,
        seasonId: seasonId,
        dayIndex: 1,
      );
      final second = await AchievementService.evaluateAfterActivity(
        database: db,
        seasonId: seasonId,
        dayIndex: 1,
      );

      expect(second.where((u) => u.definition.key == 'first_log'), isEmpty);
    });

    test('unlocks first_sunnah after sunnah fast logged', () async {
      await db.sunnahFastsDao.upsert(
        DateTime(2026, 6, 9),
        status: FastingStatus.fasted,
        type: 'senin_kamis',
      );

      final unlocks = await AchievementService.evaluateAfterActivity(database: db);

      expect(unlocks.any((u) => u.definition.key == 'first_sunnah'), isTrue);
    });

    test('excused fasting day can still contribute to streak via other habits', () async {
      final seasonId = await _seedSeason();
      final habits = await db.habitsDao.getAllHabits();
      final fasting = habits.firstWhere((h) => h.key == 'fasting');
      final taraweeh = habits.firstWhere((h) => h.key == 'taraweeh');

      final seasonHabits = await db.seasonHabitsDao.getSeasonHabits(seasonId);
      for (final sh in seasonHabits) {
        await db.seasonHabitsDao.setSeasonHabit(
          sh.copyWith(isEnabled: sh.habitId == fasting.id || sh.habitId == taraweeh.id),
        );
      }

      for (var day = 1; day <= 3; day++) {
        await db.dailyEntriesDao.setFastingStatus(
          seasonId,
          day,
          fasting.id,
          FastingStatus.excusedHaid,
        );
        await db.dailyEntriesDao.setBoolValue(seasonId, day, taraweeh.id, true);
      }

      final unlocks = await AchievementService.evaluateAfterActivity(
        database: db,
        seasonId: seasonId,
        dayIndex: 3,
      );

      expect(unlocks.any((u) => u.definition.key == 'streak_3'), isTrue);
    });
  });
}
