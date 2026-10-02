import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/sunnah_monthly_challenge_service.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_iftar_confirm_sheet.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/hijri_calendar.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

DateTime _syawalOnlyDay() {
  // Walk Syawal days until the default type is syawal (skip Mon/Thu overlap).
  for (var day = 2; day <= 28; day++) {
    final date = HijriCalendar.toGregorian(1447, 10, day);
    final types = SunnahFastingRules.typesFor(date);
    if (types.isNotEmpty && types.first == SunnahType.syawal) {
      return date;
    }
  }
  fail('expected a Syawal-first day in 1447');
}

void main() {
  group('applySunnahIftarConfirmed', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('sets default sunnah type when confirming a brand-new pending day',
        () async {
      final date = _syawalOnlyDay();

      await applySunnahIftarConfirmed(
        db: db,
        date: date,
        existing: null,
      );

      final row = await db.sunnahFastsDao.getByDate(date);
      expect(row, isNotNull);
      expect(row!.status, FastingStatus.fasted);
      expect(row.type, 'syawal');
      expect(row.isQadha, isFalse);
      expect(row.note, isNull);
    });

    test('preserves existing type, note, and isQadha instead of DAO defaults',
        () async {
      final date = _syawalOnlyDay().add(const Duration(days: 1));
      await db.sunnahFastsDao.upsert(
        date,
        status: FastingStatus.notDone,
        type: 'syawal',
        isQadha: true,
        note: 'makeup noted earlier',
      );

      await applySunnahIftarConfirmed(
        db: db,
        date: date,
        existing: await db.sunnahFastsDao.getByDate(date),
      );

      final row = await db.sunnahFastsDao.getByDate(date);
      expect(row!.status, FastingStatus.fasted);
      expect(row.type, 'syawal');
      expect(row.isQadha, isTrue);
      expect(row.note, 'makeup noted earlier');
      expect(
        await db.qadhaLedgerDao.hasAutoSunnahPaidForDate(
          SunnahFastsDao.dateKey(date),
        ),
        isTrue,
      );
    });

    test('confirmed Syawal day counts toward monthly Shawwal progress',
        () async {
      final date = _syawalOnlyDay();

      await applySunnahIftarConfirmed(
        db: db,
        date: date,
        existing: null,
      );

      // Challenge service only exposes Shawwal totals in Gregorian October.
      final progress = await SunnahMonthlyChallengeService.progress(
        db,
        DateTime(2026, 10, 15),
      );
      expect(progress.shawwalDone, 1);
    });
  });
}
