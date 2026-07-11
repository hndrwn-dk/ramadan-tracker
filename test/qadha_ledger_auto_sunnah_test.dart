import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

void main() {
  group('QadhaLedgerDao auto sunnah entries', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.test();
    });

    tearDown(() async {
      await db.close();
    });

    test('ensureAutoSunnahPaidEntry inserts only once per date', () async {
      const dateKey = '2026-07-13';

      await db.qadhaLedgerDao.ensureAutoSunnahPaidEntry(dateKey);
      await db.qadhaLedgerDao.ensureAutoSunnahPaidEntry(dateKey);

      final entries = await db.qadhaLedgerDao.getAll();
      final auto = entries
          .where((e) =>
              e.kind == 'qadha' &&
              e.direction == 'paid' &&
              e.dateYmd == dateKey &&
              e.note == QadhaLedgerDao.autoSunnahNote)
          .toList();

      expect(auto, hasLength(1));
      expect(auto.first.days, 1);
    });

    test('dedupeAutoSunnahEntries keeps one row per date', () async {
      const dateKey = '2026-07-13';

      for (var i = 0; i < 5; i++) {
        await db.qadhaLedgerDao.addEntry(
          kind: 'qadha',
          direction: 'paid',
          days: 1,
          dateYmd: dateKey,
          note: QadhaLedgerDao.autoSunnahNote,
        );
      }

      final deleted = await db.qadhaLedgerDao.dedupeAutoSunnahEntries();

      expect(deleted, 4);
      final entries = await db.qadhaLedgerDao.getAll();
      expect(entries, hasLength(1));
    });

    test('reconcile removes duplicate auto rows for the same date', () async {
      const dateKey = '2026-07-13';
      final date = DateTime(2026, 7, 13);

      await db.sunnahFastsDao.upsert(
        date,
        status: FastingStatus.fasted,
        isQadha: true,
      );

      for (var i = 0; i < 5; i++) {
        await db.qadhaLedgerDao.addEntry(
          kind: 'qadha',
          direction: 'paid',
          days: 1,
          dateYmd: dateKey,
          note: QadhaLedgerDao.autoSunnahNote,
        );
      }

      await db.qadhaLedgerDao.reconcileAutoSunnahQadhaLedger();

      final entries = await db.qadhaLedgerDao.getAll();
      final auto = entries
          .where((e) =>
              e.note == QadhaLedgerDao.autoSunnahNote &&
              e.dateYmd == dateKey)
          .toList();

      expect(auto, hasLength(1));
    });

    test('reconcile removes orphan auto row when sunnah fast is not qadha',
        () async {
      const dateKey = '2026-07-13';
      final date = DateTime(2026, 7, 13);

      await db.qadhaLedgerDao.addEntry(
        kind: 'qadha',
        direction: 'paid',
        days: 1,
        dateYmd: dateKey,
        note: QadhaLedgerDao.autoSunnahNote,
      );
      await db.sunnahFastsDao.upsert(
        date,
        status: FastingStatus.fasted,
        isQadha: false,
      );

      await db.qadhaLedgerDao.reconcileAutoSunnahQadhaLedger();

      final entries = await db.qadhaLedgerDao.getAll();
      expect(entries, isEmpty);
    });

    test('reconcile ensures auto row exists for qadha sunnah fast', () async {
      final date = DateTime(2026, 7, 13);

      await db.sunnahFastsDao.upsert(
        date,
        status: FastingStatus.fasted,
        isQadha: true,
      );

      await db.qadhaLedgerDao.reconcileAutoSunnahQadhaLedger();

      final hasEntry =
          await db.qadhaLedgerDao.hasAutoSunnahPaidForDate('2026-07-13');
      expect(hasEntry, isTrue);
    });
  });
}
