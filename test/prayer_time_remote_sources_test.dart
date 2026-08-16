import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/aladhan_parser.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/myquran_parser.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_http.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_source.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_sync_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  group('AladhanParser', () {
    test('parses iso8601 Fajr and Maghrib with DST offset', () {
      final json = File(
        'test/fixtures/aladhan_calendar_nyc_2026_03.json',
      ).readAsStringSync();
      final days = AladhanParser.parseCalendar(json);
      expect(days, hasLength(1));
      final day = days.single;
      expect(day.dateYyyyMmDd, '2026-03-15');
      expect(day.fajrUtc.toUtc(), DateTime.parse('2026-03-15T05:45:00-04:00').toUtc());
      expect(
        day.maghribUtc.toUtc(),
        DateTime.parse('2026-03-15T19:02:00-04:00').toUtc(),
      );
      expect(day.utcOffsetMinutes, -4 * 60);
    });
  });

  group('MyQuranParser', () {
    test('parses city search without picking an unverified id', () {
      final json = File('test/fixtures/myquran_search_kediri.json').readAsStringSync();
      final cities = MyQuranParser.parseSearch(json);
      expect(cities, hasLength(2));
      expect(MyQuranParser.pickVerified(cities, 'kediri'), isNull);
      expect(
        MyQuranParser.pickVerified(cities, 'KOTA KEDIRI')?.id,
        'eda80a3d5b344bc40f3bc04f65b7a357',
      );
    });

    test('combines HH:MM with device timezone, ignoring tz query conversion', () {
      final json =
          File('test/fixtures/myquran_jadwal_kediri_2026_03.json').readAsStringSync();
      final days = MyQuranParser.parseMonthly(json, timezone: 'Asia/Singapore');
      expect(days, hasLength(1));
      final day = days.single;
      expect(day.dateYyyyMmDd, '2026-03-15');
      final location = tz.getLocation('Asia/Singapore');
      final fajrLocal = tz.TZDateTime.from(day.fajrUtc.toUtc(), location);
      expect(fajrLocal.hour, 4);
      expect(fajrLocal.minute, 23);
      final maghribLocal = tz.TZDateTime.from(day.maghribUtc.toUtc(), location);
      expect(maghribLocal.hour, 17);
      expect(maghribLocal.minute, 27);
    });
  });

  group('PrayerTimeSourceResolver', () {
    test('auto picks myquran only for Indonesia when a verified city id exists', () {
      expect(
        PrayerTimeSourceResolver.resolve(
          preference: PrayerTimeSourceKind.auto,
          latitude: -6.2,
          longitude: 106.8,
          timezone: 'Asia/Jakarta',
          locale: 'id',
          method: 'indonesia',
          myquranCityId: 'eda80a3d5b344bc40f3bc04f65b7a357',
        ),
        PrayerTimeSourceKind.myquran,
      );
    });

    test('auto picks aladhan for Singapore even with Indonesian locale', () {
      expect(
        PrayerTimeSourceResolver.resolve(
          preference: PrayerTimeSourceKind.auto,
          latitude: 1.35,
          longitude: 103.82,
          timezone: 'Asia/Singapore',
          locale: 'id',
          method: 'singapore',
          myquranCityId: null,
        ),
        PrayerTimeSourceKind.aladhan,
      );
    });

    test('explicit local stays local', () {
      expect(
        PrayerTimeSourceResolver.resolve(
          preference: PrayerTimeSourceKind.local,
          latitude: -6.2,
          longitude: 106.8,
          timezone: 'Asia/Jakarta',
          locale: 'id',
          method: 'indonesia',
          myquranCityId: 'x',
        ),
        PrayerTimeSourceKind.local,
      );
    });
  });

  group('MyQuranParser city ids', () {
    test('rejects numeric v2 city ids', () {
      expect(MyQuranParser.isV3CityId('1301'), isFalse);
      expect(
        MyQuranParser.isV3CityId('eda80a3d5b344bc40f3bc04f65b7a357'),
        isTrue,
      );
    });
  });

  group('PrayerTimeSyncService', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.test();
      await db.initialize();
      await db.kvSettingsDao.setValue('prayer_time_source', 'aladhan');
    });

    tearDown(() async {
      await db.close();
    });

    test('writes Aladhan fixture into cache without live HTTP', () async {
      final body = File(
        'test/fixtures/aladhan_calendar_nyc_2026_03.json',
      ).readAsStringSync();
      final sync = PrayerTimeSyncService(
        get: (uri) async {
          expect(uri.host, 'api.aladhan.com');
          expect(uri.queryParameters['iso8601'], 'true');
          expect(uri.queryParameters.containsKey('User-Agent'), isFalse);
          return PrayerHttpResponse(statusCode: 200, body: body);
        },
      );
      final count = await sync.syncMonth(
        database: db,
        seasonId: 1,
        month: DateTime(2026, 3, 1),
        latitude: 40.7128,
        longitude: -74.0060,
        timezone: 'America/New_York',
        method: 'isna',
        locale: 'en',
      );
      expect(count, 1);
      PrayerTimeService.debugAdhanCallCount = 0;
      final times = await PrayerTimeService.getCachedOrCalculate(
        database: db,
        seasonId: 1,
        date: DateTime(2026, 3, 15),
        latitude: 40.7128,
        longitude: -74.0060,
        timezone: 'America/New_York',
        method: 'isna',
        highLatRule: 'middle_of_the_night',
      );
      expect(PrayerTimeService.debugAdhanCallCount, 0);
      expect(
        times['fajr']!.toUtc(),
        DateTime.parse('2026-03-15T05:45:00-04:00').toUtc(),
      );
    });

    test('writes myQuran fixture using timezone HH:MM not HTTP tz conversion',
        () async {
      await db.kvSettingsDao.setValue('prayer_time_source', 'myquran');
      await db.kvSettingsDao.setValue(
        'prayer_myquran_city_id',
        'eda80a3d5b344bc40f3bc04f65b7a357',
      );
      final search = File('test/fixtures/myquran_search_kediri.json')
          .readAsStringSync();
      final jadwal = File('test/fixtures/myquran_jadwal_kediri_2026_03.json')
          .readAsStringSync();
      final sync = PrayerTimeSyncService(
        get: (uri) async {
          expect(uri.host, 'api.myquran.com');
          expect(uri.path, contains('/v3/'));
          if (uri.path.contains('jadwal')) {
            return PrayerHttpResponse(statusCode: 200, body: jadwal);
          }
          return PrayerHttpResponse(statusCode: 200, body: search);
        },
      );
      final count = await sync.syncMonth(
        database: db,
        seasonId: 1,
        month: DateTime(2026, 3, 1),
        latitude: -7.8,
        longitude: 112.0,
        timezone: 'Asia/Singapore',
        method: 'indonesia',
        locale: 'id',
      );
      expect(count, 1);
      final cached =
          await db.prayerTimesCacheDao.getCachedTime(1, '2026-03-15');
      expect(cached!.source, 'myquran');
      expect(cached.sourceRef, 'eda80a3d5b344bc40f3bc04f65b7a357');
      final location = tz.getLocation('Asia/Singapore');
      final fajrLocal =
          tz.TZDateTime.from(DateTime.parse(cached.fajrIso).toUtc(), location);
      expect(fajrLocal.hour, 4);
      expect(fajrLocal.minute, 23);
    });

    test('falls back to empty remote list on HTTP errors', () async {
      final sync = PrayerTimeSyncService(
        get: (uri) async => const PrayerHttpResponse(statusCode: 429, body: ''),
      );
      final count = await sync.syncMonth(
        database: db,
        seasonId: 1,
        month: DateTime(2026, 3, 1),
        latitude: 40.7128,
        longitude: -74.0060,
        timezone: 'America/New_York',
        method: 'isna',
        locale: 'en',
      );
      expect(count, 0);
    });
  });
}
