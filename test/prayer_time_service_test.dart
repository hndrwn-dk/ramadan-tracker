import 'package:adhan/adhan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  const nyc = 'America/New_York';
  // Lower Manhattan; method matches typical North America settings.
  const lat = 40.7128;
  const lon = -74.0060;

  setUpAll(() {
    tzdata.initializeTimeZones();
  });

  Map<String, DateTime> fajrMaghrib(DateTime date) {
    return PrayerTimeService.getFajrAndMaghrib(
      date: date,
      latitude: lat,
      longitude: lon,
      timezone: nyc,
      method: 'isna',
      highLatRule: 'middle_of_the_night',
    );
  }

  group('PrayerTimeService.utcOffsetForDate', () {
    test('uses standard time offset before America/New_York spring-forward', () {
      final date = DateTime(2026, 3, 7);
      final location = tz.getLocation(nyc);
      expect(
        PrayerTimeService.utcOffsetForDate(timezone: nyc, date: date),
        tz.TZDateTime(location, date.year, date.month, date.day).timeZoneOffset,
      );
      expect(
        PrayerTimeService.utcOffsetForDate(timezone: nyc, date: date),
        const Duration(hours: -5),
      );
    });

    test('uses daylight offset after America/New_York spring-forward', () {
      final date = DateTime(2026, 3, 9);
      final location = tz.getLocation(nyc);
      expect(
        PrayerTimeService.utcOffsetForDate(timezone: nyc, date: date),
        tz.TZDateTime(location, date.year, date.month, date.day).timeZoneOffset,
      );
      expect(
        PrayerTimeService.utcOffsetForDate(timezone: nyc, date: date),
        const Duration(hours: -4),
      );
    });

    test('does not use current New York offset for a date in the other season', () {
      final location = tz.getLocation(nyc);
      final nowOffset = tz.TZDateTime.now(location).timeZoneOffset;
      final winter = DateTime(2026, 1, 15);
      final summer = DateTime(2026, 7, 15);
      final winterOffset = PrayerTimeService.utcOffsetForDate(
        timezone: nyc,
        date: winter,
      );
      final summerOffset = PrayerTimeService.utcOffsetForDate(
        timezone: nyc,
        date: summer,
      );

      expect(winterOffset, const Duration(hours: -5));
      expect(summerOffset, const Duration(hours: -4));
      expect(winterOffset, isNot(summerOffset));
      expect(
        winterOffset == nowOffset || summerOffset == nowOffset,
        isTrue,
        reason: 'one of winter/summer should match current NY offset',
      );
    });
  });

  group('PrayerTimeService.getFajrAndMaghrib DST', () {
    test('post-DST local clock matches adhan with that date offset not now', () {
      final date = DateTime(2026, 3, 15);
      final location = tz.getLocation(nyc);
      final dateOffset = tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
      ).timeZoneOffset;
      final nowOffset = tz.TZDateTime.now(location).timeZoneOffset;

      final params = CalculationMethod.north_america.getParameters();
      final components = DateComponents(date.year, date.month, date.day);
      final coords = Coordinates(lat, lon);
      final withDateOffset = PrayerTimes(
        coords,
        components,
        params,
        utcOffset: dateOffset,
      );
      final withNowOffset = PrayerTimes(
        coords,
        components,
        params,
        utcOffset: nowOffset,
      );

      final times = fajrMaghrib(date);
      final fajrLocal = tz.TZDateTime.from(times['fajr']!.toUtc(), location);

      expect(fajrLocal.hour, withDateOffset.fajr.hour);
      expect(fajrLocal.minute, withDateOffset.fajr.minute);
      if (dateOffset != nowOffset) {
        expect(
          fajrLocal.hour == withNowOffset.fajr.hour &&
              fajrLocal.minute == withNowOffset.fajr.minute,
          isFalse,
          reason: 'must not stamp current-offset adhan times onto a DST date',
        );
      }
    });

    test('winter date local clock matches standard-time adhan offset', () {
      final date = DateTime(2026, 1, 15);
      final location = tz.getLocation(nyc);
      final dateOffset = tz.TZDateTime(
        location,
        date.year,
        date.month,
        date.day,
      ).timeZoneOffset;
      final params = CalculationMethod.north_america.getParameters();
      final withDateOffset = PrayerTimes(
        Coordinates(lat, lon),
        DateComponents(date.year, date.month, date.day),
        params,
        utcOffset: dateOffset,
      );

      final times = fajrMaghrib(date);
      final fajrLocal = tz.TZDateTime.from(times['fajr']!.toUtc(), location);
      expect(fajrLocal.hour, withDateOffset.fajr.hour);
      expect(fajrLocal.minute, withDateOffset.fajr.minute);
      expect(dateOffset, const Duration(hours: -5));
    });
  });

  group('PrayerTimeService.getCachedOrCalculate', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.test();
      await db.initialize();
    });

    tearDown(() async {
      await db.close();
    });

    test('does not rerun adhan when cache params and DST offset already match',
        () async {
      final date = DateTime(2026, 3, 15);
      final correct = fajrMaghrib(date);
      await db.prayerTimesCacheDao.cacheTime(
        PrayerTimesCacheData(
          seasonId: 1,
          dateYyyyMmDd: '2026-03-15',
          fajrIso: correct['fajr']!.toUtc().toIso8601String(),
          maghribIso: correct['maghrib']!.toUtc().toIso8601String(),
          method: 'isna',
          lat: lat,
          lon: lon,
          timezone: nyc,
          fajrAdj: 0,
          maghribAdj: 0,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
          utcOffsetMinutes: PrayerTimeService.utcOffsetForDate(
            timezone: nyc,
            date: date,
          ).inMinutes,
        ),
      );

      PrayerTimeService.debugAdhanCallCount = 0;
      final result = await PrayerTimeService.getCachedOrCalculate(
        database: db,
        seasonId: 1,
        date: date,
        latitude: lat,
        longitude: lon,
        timezone: nyc,
        method: 'isna',
        highLatRule: 'middle_of_the_night',
      );

      expect(PrayerTimeService.debugAdhanCallCount, 0);
      expect(
        result['fajr']!.toUtc().millisecondsSinceEpoch,
        correct['fajr']!.toUtc().millisecondsSinceEpoch,
      );
    });

    test('replaces cached fajr/maghrib computed with the wrong UTC offset', () async {
      final date = DateTime(2026, 3, 15);
      const dateStr = '2026-03-15';
      final correct = fajrMaghrib(date);
      final staleFajr = correct['fajr']!.toUtc().subtract(const Duration(hours: 1));
      final staleMaghrib =
          correct['maghrib']!.toUtc().subtract(const Duration(hours: 1));

      await db.prayerTimesCacheDao.cacheTime(
        PrayerTimesCacheData(
          seasonId: 1,
          dateYyyyMmDd: dateStr,
          fajrIso: staleFajr.toIso8601String(),
          maghribIso: staleMaghrib.toIso8601String(),
          method: 'isna',
          lat: lat,
          lon: lon,
          timezone: nyc,
          fajrAdj: 0,
          maghribAdj: 0,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final result = await PrayerTimeService.getCachedOrCalculate(
        database: db,
        seasonId: 1,
        date: date,
        latitude: lat,
        longitude: lon,
        timezone: nyc,
        method: 'isna',
        highLatRule: 'middle_of_the_night',
      );

      expect(
        result['fajr']!.toUtc().millisecondsSinceEpoch,
        correct['fajr']!.toUtc().millisecondsSinceEpoch,
      );
      expect(
        result['maghrib']!.toUtc().millisecondsSinceEpoch,
        correct['maghrib']!.toUtc().millisecondsSinceEpoch,
      );

      final stored = await db.prayerTimesCacheDao.getCachedTime(1, dateStr);
      expect(
        DateTime.parse(stored!.fajrIso).toUtc().millisecondsSinceEpoch,
        correct['fajr']!.toUtc().millisecondsSinceEpoch,
      );
      expect(
        DateTime.parse(stored.maghribIso).toUtc().millisecondsSinceEpoch,
        correct['maghrib']!.toUtc().millisecondsSinceEpoch,
      );
    });
  });
}
