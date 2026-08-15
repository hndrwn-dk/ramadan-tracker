import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/notification_launch_provider.dart';
import 'package:ramadan_tracker/features/today/widgets/fasting_notification_handler.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

void main() {
  group('FastingNotificationHandler.handledKvKey', () {
    tearDown(FastingNotificationHandler.resetHandledForTest);

    test('builds stable keys for ramadan sahur and iftar', () {
      const sahur = NotificationLaunchRequest(
        kind: FastingNotificationKind.ramadanSahur,
        seasonId: 3,
        dayIndex: 12,
      );
      const iftar = NotificationLaunchRequest(
        kind: FastingNotificationKind.ramadanIftar,
        seasonId: 3,
        dayIndex: 12,
      );

      expect(
        FastingNotificationHandler.handledKvKey(sahur),
        'notif_handled_ramadanSahur_3_12',
      );
      expect(
        FastingNotificationHandler.handledKvKey(iftar),
        'notif_handled_ramadanIftar_3_12',
      );
      expect(
        FastingNotificationHandler.handledKvKey(sahur),
        isNot(FastingNotificationHandler.handledKvKey(iftar)),
      );
    });

    test('builds stable keys for sunnah dates', () {
      final request = NotificationLaunchRequest(
        kind: FastingNotificationKind.sunnahIftar,
        sunnahDate: DateTime(2026, 6, 10),
      );
      expect(
        FastingNotificationHandler.handledKvKey(request),
        'notif_handled_sunnahIftar_20260610',
      );
    });
  });

  group('FastingNotificationHandler.shouldMarkIftarNotificationHandled', () {
    test('does not mark handled when confirm sheet is dismissed', () {
      expect(
        FastingNotificationHandler.shouldMarkIftarNotificationHandled(null),
        isFalse,
      );
    });

    test('marks handled after confirm', () {
      expect(
        FastingNotificationHandler.shouldMarkIftarNotificationHandled(true),
        isTrue,
      );
    });

    test('marks handled after decline', () {
      expect(
        FastingNotificationHandler.shouldMarkIftarNotificationHandled(false),
        isTrue,
      );
    });
  });

  group('FastingNotificationHandler.applySunnahSahurStatus', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('clears isQadha and removes auto ledger when demoting a qadha fast',
        () async {
      final date = DateTime(2026, 6, 15);
      await db.sunnahFastsDao.upsert(
        date,
        status: FastingStatus.fasted,
        type: 'custom',
        isQadha: true,
        note: 'makeup from last Ramadan',
      );
      await db.qadhaLedgerDao.ensureAutoSunnahPaidEntry(
        SunnahFastsDao.dateKey(date),
      );

      await FastingNotificationHandler.applySunnahSahurStatus(
        db: db,
        date: date,
        status: FastingStatus.excusedSick,
        existing: await db.sunnahFastsDao.getByDate(date),
        defaultType: 'monday_thursday',
      );

      final row = await db.sunnahFastsDao.getByDate(date);
      expect(row, isNotNull);
      expect(row!.status, FastingStatus.excusedSick);
      expect(row.isQadha, isFalse);
      expect(row.note, 'makeup from last Ramadan');
      expect(row.type, 'custom');
      expect(
        await db.qadhaLedgerDao.hasAutoSunnahPaidForDate(
          SunnahFastsDao.dateKey(date),
        ),
        isFalse,
      );
    });

    test('syncs qadha ledger when the preserved row is a qadha fast', () async {
      final date = DateTime(2026, 6, 16);
      await db.sunnahFastsDao.upsert(
        date,
        status: FastingStatus.fasted,
        type: 'monday_thursday',
        isQadha: true,
        note: 'qadha',
      );

      await FastingNotificationHandler.applySunnahSahurStatus(
        db: db,
        date: date,
        status: FastingStatus.fasted,
        existing: await db.sunnahFastsDao.getByDate(date),
        defaultType: 'custom',
      );

      expect(
        await db.qadhaLedgerDao.hasAutoSunnahPaidForDate(
          SunnahFastsDao.dateKey(date),
        ),
        isTrue,
      );
      final row = await db.sunnahFastsDao.getByDate(date);
      expect(row!.isQadha, isTrue);
      expect(row.note, 'qadha');
    });

    test('does not invent qadha when inserting a new sunnah row', () async {
      final date = DateTime(2026, 6, 17);
      await FastingNotificationHandler.applySunnahSahurStatus(
        db: db,
        date: date,
        status: FastingStatus.excusedHaid,
        existing: null,
        defaultType: 'monday_thursday',
        note: 'haid',
      );

      final row = await db.sunnahFastsDao.getByDate(date);
      expect(row, isNotNull);
      expect(row!.isQadha, isFalse);
      expect(row.type, 'monday_thursday');
      expect(row.note, 'haid');
    });
  });

  group('FastingNotificationHandler.shouldOpenStatusSheetForSahur', () {
    test('is true when a final status already exists', () {
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.fasted,
        ),
        isTrue,
      );
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.excusedSick,
        ),
        isTrue,
      );
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.excusedHaid,
        ),
        isTrue,
      );
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.excusedNifas,
        ),
        isTrue,
      );
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.excusedOther,
        ),
        isTrue,
      );
    });

    test('is false when there is no final logged status', () {
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(null),
        isFalse,
      );
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.notDone,
        ),
        isFalse,
      );
      expect(
        FastingNotificationHandler.shouldOpenStatusSheetForSahur(
          FastingStatus.intentPendingFast,
        ),
        isFalse,
      );
    });
  });
}
