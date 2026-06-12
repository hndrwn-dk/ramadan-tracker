import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/features/insights/services/sunnah_insights_service.dart';
import 'package:ramadan_tracker/testing/regression_seeder.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

void main() {
  test('RegressionSeeder builds Ramadan + uzur + Syawal scenario', () async {
    final db = AppDatabase.test();
    await db.initialize();

    final result = await RegressionSeeder.seed(db);

    expect(result.fastedDays, RegressionSeeder.fastedDays);
    expect(result.haidDays, RegressionSeeder.haidDays);
    expect(result.sickDays, RegressionSeeder.sickDays);
    expect(result.syawalDays, RegressionSeeder.syawalDays);

    final seasons = await db.ramadanSeasonsDao.getAllSeasons();
    expect(seasons, hasLength(1));

    final entries = await db.dailyEntriesDao.getAllSeasonEntries(result.seasonId);
    final habits = await db.habitsDao.getAllHabits();
    final fastingId = habits.firstWhere((h) => h.key == 'fasting').id;

    var fasted = 0;
    var haid = 0;
    var sick = 0;
    for (final e in entries.where((x) => x.habitId == fastingId)) {
      switch (e.valueInt) {
        case FastingStatus.fasted:
          fasted++;
        case FastingStatus.excusedHaid:
          haid++;
        case FastingStatus.excusedSick:
          sick++;
      }
    }
    expect(fasted, 20);
    expect(haid, 7);
    expect(sick, 3);

    final syawalRows = await db.sunnahFastsDao.getAll();
    expect(syawalRows.where((r) => r.type == 'syawal').length, 6);

    final sunnahInsights = await SunnahInsightsService.load(db);
    expect(sunnahInsights.totalThisYear, 6);
    expect(sunnahInsights.hasAnyData, isTrue);

    final seasonModel = SeasonModel.fromDb(seasons.first);
    final obligations = await SeasonInsightsService.getObligationsSeasonAnalytics(
      season: seasonModel,
      database: db,
      displayCurrency: 'IDR',
    );
    expect(obligations.paymentCount, 2);
    expect(obligations.zakatTotal, 150000);
    expect(obligations.fidyahTotal, 80000);

    final habitModels = habits
        .map((h) => HabitModel.fromDb(h))
        .toList();
    final seasonHabits = await db.seasonHabitsDao.getSeasonHabits(result.seasonId);
    final seasonHabitModels = seasonHabits
        .map((sh) => SeasonHabitModel.fromDb(sh))
        .toList();
    final sedekah = await SeasonInsightsService.getSedekahSeasonAnalytics(
      season: seasonModel,
      database: db,
      allHabits: habitModels,
      seasonHabits: seasonHabitModels,
    );
    expect(sedekah.total, 200000);

    await db.close();
  });
}
