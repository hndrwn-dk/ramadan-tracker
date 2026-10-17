import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/support/support_moment.dart';
import 'package:ramadan_tracker/domain/support/support_prompt_policy.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.test();
  });

  tearDown(() async {
    await db.close();
  });

  test('day ten counts checklist days through CompletionService', () async {
    await db.initialize();
    final start = DateTime(2026, 2, 18);
    final seasonId = await db.ramadanSeasonsDao.createSeason(
      label: 'Ramadan',
      startDate: start,
      days: 30,
    );
    final habits = await db.habitsDao.getAllHabits();
    await db.seasonHabitsDao.initializeSeasonHabits(seasonId, habits);
    final fasting = habits.firstWhere((habit) => habit.key == 'fasting');

    for (var day = 1; day <= 7; day++) {
      await db.dailyEntriesDao.setBoolValue(seasonId, day, fasting.id, true);
    }

    final moment = await loadSupportMoment(db, DateTime(2026, 2, 27));
    expect(moment.milestone?.kind, SupportMilestoneKind.dayTen);
    expect(moment.inLastTenNights, isFalse);

    await db.dailyEntriesDao.setBoolValue(seasonId, 7, fasting.id, false);
    final short = await loadSupportMoment(db, DateTime(2026, 2, 27));
    expect(short.milestone, isNull);
  });

  test('recorded sunnah fasts ignore qadha and excused days', () async {
    final today = DateTime(2026, 6, 1);
    for (var i = 0; i < 9; i++) {
      await db.sunnahFastsDao.upsert(
        today.subtract(Duration(days: i + 1)),
        status: FastingStatus.fasted,
      );
    }
    await db.sunnahFastsDao.upsert(
      today.subtract(const Duration(days: 20)),
      status: FastingStatus.fasted,
      isQadha: true,
    );
    await db.sunnahFastsDao.upsert(
      today.subtract(const Duration(days: 21)),
      status: FastingStatus.excusedSick,
    );

    final short = await loadSupportMoment(db, today);
    expect(short.milestone, isNull);

    await db.sunnahFastsDao.upsert(
      today.subtract(const Duration(days: 22)),
      status: FastingStatus.fasted,
    );
    final ready = await loadSupportMoment(db, today);
    expect(ready.milestone?.kind, SupportMilestoneKind.sunnahTen);
  });
}
