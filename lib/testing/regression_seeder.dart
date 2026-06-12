import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/obligations_utils.dart';

/// Deterministic Ramadan simulation for emulator regression tests.
///
/// Timeline (relative to [anchorDate] = today):
/// - 30-day Ramadan ending 7 days before today
/// - Days 1–20: berpuasa, 21–27: uzur haid, 28–30: uzur sakit
/// - Sedekah on fasted days; zakat + fidyah logged in season
/// - 6 Syawal sunnah fasts on the 6 days before today
class RegressionSeeder {
  RegressionSeeder._();

  static const scenarioVersion = 'v1';
  static const ramadanDays = 30;
  static const fastedDays = 20;
  static const haidDays = 7;
  static const sickDays = 3;
  static const syawalDays = 6;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Seeds a completed Ramadan + Syawal session. Safe to call on empty DB.
  static Future<RegressionSeedResult> seed(
    AppDatabase db, {
    DateTime? anchorDate,
  }) async {
    final today = _dateOnly(anchorDate ?? DateTime.now());

    // Syawal: 6 consecutive days ending yesterday.
    final syawalLast = today.subtract(const Duration(days: 1));
    final syawalFirst = syawalLast.subtract(Duration(days: syawalDays - 1));
    final seasonEnd = syawalFirst.subtract(const Duration(days: 1));
    final seasonStart = seasonEnd.subtract(Duration(days: ramadanDays - 1));

    await _clearUserData(db);

    final seasonId = await db.ramadanSeasonsDao.createSeason(
      label: 'Regression Ramadan ${seasonStart.year}',
      startDate: seasonStart,
      days: ramadanDays,
    );

      await db.kvSettingsDao.setValue('onboarding_skipped', 'true');
      await db.kvSettingsDao.setValue('onboarding_done_season_$seasonId', 'true');
      await db.kvSettingsDao.setValue('app_language', 'id');
    await db.kvSettingsDao.setValue('regression_scenario', scenarioVersion);
    await db.kvSettingsDao.setValue('sedekah_currency', 'IDR');
    await db.kvSettingsDao.setValue('sedekah_goal_enabled', 'true');
    await db.kvSettingsDao.setValue('sedekah_goal_amount', '10000');
    await db.kvSettingsDao.setValue('prayer_latitude', '-6.2088');
    await db.kvSettingsDao.setValue('prayer_longitude', '106.8456');
    await db.kvSettingsDao.setValue('prayer_timezone', 'Asia/Jakarta');

    final habits = await db.habitsDao.getAllHabits();
    final fastingHabit = habits.firstWhere((h) => h.key == 'fasting');
    final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah');

    for (final habit in habits) {
      await db.seasonHabitsDao.setSeasonHabit(
        SeasonHabit(
          seasonId: seasonId,
          habitId: habit.id,
          isEnabled: true,
          targetValue: habit.defaultTarget,
          reminderEnabled: false,
          reminderTime: null,
        ),
      );
    }

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.quranPlanDao.setPlan(
      QuranPlanData(
        seasonId: seasonId,
        pagesPerJuz: 20,
        juzTargetPerDay: 1,
        dailyTargetPages: 20,
        totalJuz: 30,
        totalPages: 600,
        catchupCapPages: 5,
        createdAt: nowMs,
      ),
    );

    await db.dhikrPlanDao.setPlan(
      DhikrPlanData(
        seasonId: seasonId,
        dailyTarget: 100,
        createdAt: nowMs,
      ),
    );

    var fastedCount = 0;
    var haidCount = 0;
    var sickCount = 0;

    for (var day = 1; day <= ramadanDays; day++) {
      final int status;
      if (day <= fastedDays) {
        status = FastingStatus.fasted;
        fastedCount++;
      } else if (day <= fastedDays + haidDays) {
        status = FastingStatus.excusedHaid;
        haidCount++;
      } else {
        status = FastingStatus.excusedSick;
        sickCount++;
      }

      await db.dailyEntriesDao.setFastingStatus(
        seasonId,
        day,
        fastingHabit.id,
        status,
      );

      if (status == FastingStatus.fasted) {
        await db.dailyEntriesDao.setIntValue(
          seasonId,
          day,
          sedekahHabit.id,
          10000,
        );
      }
    }

    await db.qadhaLedgerDao.addEntry(
      kind: 'zakat',
      direction: 'paid',
      days: 3,
      amount: 150000,
      dateYmd: _ymd(seasonEnd),
      sourceSeasonId: seasonId,
      note: ObligationsUtils.encodeCurrencyNote('IDR'),
    );
    await db.qadhaLedgerDao.addEntry(
      kind: 'fidyah',
      direction: 'paid',
      days: 2,
      amount: 80000,
      dateYmd: _ymd(seasonEnd.subtract(const Duration(days: 2))),
      sourceSeasonId: seasonId,
      note: ObligationsUtils.encodeCurrencyNote('IDR'),
    );

    for (var i = 0; i < syawalDays; i++) {
      final syawalDate = syawalFirst.add(Duration(days: i));
      await db.sunnahFastsDao.upsert(
        syawalDate,
        status: FastingStatus.fasted,
        type: 'syawal',
      );
    }

    return RegressionSeedResult(
      seasonId: seasonId,
      seasonStart: seasonStart,
      seasonEnd: seasonEnd,
      syawalFirst: syawalFirst,
      syawalLast: syawalLast,
      fastedDays: fastedCount,
      haidDays: haidCount,
      sickDays: sickCount,
      syawalDays: syawalDays,
    );
  }

  static Future<void> _clearUserData(AppDatabase db) async {
    await db.customStatement('DELETE FROM daily_entries');
    await db.customStatement('DELETE FROM qadha_ledger');
    await db.customStatement('DELETE FROM sunnah_fasts');
    await db.customStatement('DELETE FROM season_habits');
    await db.customStatement('DELETE FROM quran_plan');
    await db.customStatement('DELETE FROM quran_daily');
    await db.customStatement('DELETE FROM dhikr_plan');
    await db.customStatement('DELETE FROM notes');
    await db.customStatement('DELETE FROM prayer_details');
    await db.customStatement('DELETE FROM prayer_times_cache');
    await db.customStatement('DELETE FROM ramadan_seasons');
    await db.customStatement(
      "DELETE FROM kv_settings WHERE key NOT LIKE 'habit_%'",
    );
  }

  static String _ymd(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}

class RegressionSeedResult {
  final int seasonId;
  final DateTime seasonStart;
  final DateTime seasonEnd;
  final DateTime syawalFirst;
  final DateTime syawalLast;
  final int fastedDays;
  final int haidDays;
  final int sickDays;
  final int syawalDays;

  const RegressionSeedResult({
    required this.seasonId,
    required this.seasonStart,
    required this.seasonEnd,
    required this.syawalFirst,
    required this.syawalLast,
    required this.fastedDays,
    required this.haidDays,
    required this.sickDays,
    required this.syawalDays,
  });
}
