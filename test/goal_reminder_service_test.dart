import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/goal_reminder_service.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test();
    await db.initialize();
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedSeason({String startDate = '2026-02-19'}) async {
    final seasonId = await db.ramadanSeasonsDao.createSeason(
      label: 'Test Ramadan',
      startDate: DateTime.parse(startDate),
      days: 30,
    );
    final habits = await db.habitsDao.getAllHabits();
    await db.seasonHabitsDao.initializeSeasonHabits(seasonId, habits);
    return seasonId;
  }

  group('GoalReminderService.isActiveSeasonDay', () {
    RamadanSeason season({required String startDate, int days = 30}) {
      return RamadanSeason(
        id: 1,
        label: 'Test',
        startDate: startDate,
        days: days,
        createdAt: 0,
      );
    }

    test('returns true on first and last day of season', () {
      final s = season(startDate: '2026-02-19');
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 2, 19)),
        isTrue,
      );
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 3, 20)),
        isTrue,
      );
    });

    test('returns false before season and after season ends', () {
      final s = season(startDate: '2026-02-19');
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 2, 18)),
        isFalse,
      );
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 3, 21)),
        isFalse,
      );
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 6, 6)),
        isFalse,
      );
    });
  });

  group('GoalReminderService.shouldScheduleNumericGoal', () {
    test('requires enabled habit, positive target, incomplete progress', () {
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: true,
          target: 5,
          progress: 2,
        ),
        isTrue,
      );
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: false,
          target: 5,
          progress: 0,
        ),
        isFalse,
      );
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: true,
          target: 0,
          progress: 0,
        ),
        isFalse,
      );
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: true,
          target: 5,
          progress: 5,
        ),
        isFalse,
      );
    });
  });

  group('GoalReminderService.isDigestReminderEnabled', () {
    test('uses digest key when set', () async {
      await db.kvSettingsDao.setValue('goal_reminder_digest_enabled', 'false');
      expect(await GoalReminderService.isDigestReminderEnabled(db), isFalse);

      await db.kvSettingsDao.setValue('goal_reminder_digest_enabled', 'true');
      expect(await GoalReminderService.isDigestReminderEnabled(db), isTrue);
    });

    test('falls back to legacy per-habit keys when digest key absent', () async {
      await db.kvSettingsDao.setValue('goal_reminder_quran_enabled', 'false');
      await db.kvSettingsDao.setValue('goal_reminder_dhikr_enabled', 'false');
      await db.kvSettingsDao.setValue('goal_reminder_sedekah_enabled', 'false');
      expect(await GoalReminderService.isDigestReminderEnabled(db), isFalse);

      await db.kvSettingsDao.setValue('goal_reminder_quran_enabled', 'true');
      expect(await GoalReminderService.isDigestReminderEnabled(db), isTrue);
    });
  });

  group('GoalReminderService.getPendingGoalTypesForDate', () {
    test('returns empty outside active season day', () async {
      final seasonId = await seedSeason();
      final pending = await GoalReminderService.getPendingGoalTypesForDate(
        database: db,
        seasonId: seasonId,
        date: DateTime(2026, 4, 1),
      );
      expect(pending, isEmpty);
    });

    test('returns quran when habit enabled and pages below target', () async {
      final seasonId = await seedSeason();
      await db.quranPlanDao.setPlan(
        QuranPlanData(
          seasonId: seasonId,
          pagesPerJuz: 20,
          juzTargetPerDay: 1,
          dailyTargetPages: 5,
          totalJuz: 30,
          totalPages: 600,
          catchupCapPages: 5,
          createdAt: 0,
        ),
      );

      final pending = await GoalReminderService.getPendingGoalTypesForDate(
        database: db,
        seasonId: seasonId,
        date: DateTime(2026, 2, 19),
      );

      expect(pending, ['quran']);
    });

    test('returns empty when quran target already met', () async {
      final seasonId = await seedSeason();
      await db.quranPlanDao.setPlan(
        QuranPlanData(
          seasonId: seasonId,
          pagesPerJuz: 20,
          juzTargetPerDay: 1,
          dailyTargetPages: 3,
          totalJuz: 30,
          totalPages: 600,
          catchupCapPages: 5,
          createdAt: 0,
        ),
      );
      await db.quranDailyDao.setPages(seasonId, 1, 3);

      final pending = await GoalReminderService.getPendingGoalTypesForDate(
        database: db,
        seasonId: seasonId,
        date: DateTime(2026, 2, 19),
      );

      expect(pending, isEmpty);
    });
  });
}
