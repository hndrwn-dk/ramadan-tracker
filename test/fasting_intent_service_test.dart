import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/fasting_intent_service.dart';
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

  group('FastingIntentService', () {
    test('stores and reads pending Ramadan intent', () async {
      await FastingIntentService.setRamadanIntent(
        db,
        seasonId: 1,
        dayIndex: 5,
        status: FastingStatus.intentPendingFast,
      );

      final intent = await FastingIntentService.getRamadanIntent(
        db,
        seasonId: 1,
        dayIndex: 5,
      );

      expect(intent, isNotNull);
      expect(intent!.status, FastingStatus.intentPendingFast);
      expect(
        await FastingIntentService.hasPendingRamadanIntent(
          db,
          seasonId: 1,
          dayIndex: 5,
        ),
        isTrue,
      );
    });

    test('clearing Ramadan intent removes KV entry', () async {
      await FastingIntentService.setRamadanIntent(
        db,
        seasonId: 2,
        dayIndex: 1,
        status: FastingStatus.intentPendingFast,
      );
      await FastingIntentService.clearRamadanIntent(
        db,
        seasonId: 2,
        dayIndex: 1,
      );

      expect(
        await FastingIntentService.getRamadanIntent(
          db,
          seasonId: 2,
          dayIndex: 1,
        ),
        isNull,
      );
    });

    test('non-pending status clears Ramadan intent key', () async {
      await FastingIntentService.setRamadanIntent(
        db,
        seasonId: 3,
        dayIndex: 2,
        status: FastingStatus.intentPendingFast,
      );
      await FastingIntentService.setRamadanIntent(
        db,
        seasonId: 3,
        dayIndex: 2,
        status: FastingStatus.notDone,
      );

      expect(
        await FastingIntentService.getRamadanIntent(
          db,
          seasonId: 3,
          dayIndex: 2,
        ),
        isNull,
      );
    });

    test('stores and reads pending Sunnah intent by date', () async {
      final date = DateTime(2026, 6, 10);
      await FastingIntentService.setSunnahIntent(
        db,
        date: date,
        status: FastingStatus.intentPendingFast,
      );

      final intent = await FastingIntentService.getSunnahIntent(db, date: date);
      expect(intent?.status, FastingStatus.intentPendingFast);
      expect(
        await FastingIntentService.hasPendingSunnahIntent(db, date: date),
        isTrue,
      );
    });
  });
}
