import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';
import 'package:timezone/timezone.dart' as tz;

class PrayerTimeService {
  /// Counts [getFajrAndMaghrib] calls. Used to prove cache hits skip adhan.
  @visibleForTesting
  static int debugAdhanCallCount = 0;

  /// UTC offset for [timezone] on [date] (midnight local), including DST.
  static Duration utcOffsetForDate({
    required String timezone,
    required DateTime date,
  }) {
    try {
      final targetLocation = tz.getLocation(timezone);
      return tz.TZDateTime(
        targetLocation,
        date.year,
        date.month,
        date.day,
      ).timeZoneOffset;
    } catch (e) {
      return DateTime.now().timeZoneOffset;
    }
  }

  static CalculationParameters _getCalculationParameters(String method) {
    // Use CalculationMethod from adhan package directly
    switch (method.toLowerCase()) {
      case 'mwl':
      case 'muslim_world_league':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'isna':
      case 'north_america':
        return CalculationMethod.north_america.getParameters();
      case 'egypt':
      case 'egyptian':
        return CalculationMethod.egyptian.getParameters();
      case 'umm_al_qura':
      case 'ummalqura':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'karachi':
        return CalculationMethod.karachi.getParameters();
      case 'singapore':
        return CalculationMethod.singapore.getParameters();
      case 'indonesia':
      case 'kemenag':
        // Indonesia/Kemenag (Sihat): 20 deg Fajr, 18 deg Isha per official Bimasislam/Kemenag.
        // Matches jadwal imsakiyah for Jakarta and other Indonesian cities.
        return CalculationParameters(
          method: CalculationMethod.other,
          fajrAngle: 20.0,
          ishaAngle: 18.0,
        );
      case 'dubai':
        return CalculationMethod.dubai.getParameters();
      case 'qatar':
        return CalculationMethod.qatar.getParameters();
      case 'kuwait':
        return CalculationMethod.kuwait.getParameters();
      case 'turkey':
        return CalculationMethod.turkey.getParameters();
      case 'tehran':
        return CalculationMethod.tehran.getParameters();
      default:
        // Default to MWL
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }

  static PrayerTimes calculatePrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) {
    final coordinates = Coordinates(latitude, longitude);
    final params = _getCalculationParameters(method);
    
    // Convert DateTime to DateComponents
    final dateComponents = DateComponents(
      date.year,
      date.month,
      date.day,
    );
    
    // UTC offset for the target date (not "now") so DST seasons cache correctly.
    final utcOffset = utcOffsetForDate(timezone: timezone, date: date);
    
    // PrayerTimes constructor with utcOffset parameter
    final prayerTimes = PrayerTimes(
      coordinates,
      dateComponents,
      params,
      utcOffset: utcOffset,
    );

    return prayerTimes;
  }

  static Map<String, DateTime> getFajrAndMaghrib({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) {
    debugAdhanCallCount++;
    final coordinates = Coordinates(latitude, longitude);
    final params = _getCalculationParameters(method);
    
    // Convert DateTime to DateComponents
    final dateComponents = DateComponents(
      date.year,
      date.month,
      date.day,
    );
    
    // UTC offset for the target date (not "now") so DST seasons cache correctly.
    final utcOffset = utcOffsetForDate(timezone: timezone, date: date);
    
    // PrayerTimes constructor with utcOffset parameter
    // According to adhan package docs, this returns times in the specified timezone
    final prayerTimes = PrayerTimes(
      coordinates,
      dateComponents,
      params,
      utcOffset: utcOffset,
    );

    // adhan v2.0: When utcOffset is provided, prayerTimes.fajr/maghrib are DateTime objects
    // that represent local time in the target timezone (e.g., 04:32 in Asia/Jakarta).
    // However, DateTime in Dart doesn't store timezone info - it's always in device local timezone.
    // So prayerTimes.fajr (04:32) is actually 04:32 in device local timezone, not target timezone.
    
    // Apply adjustments
    var fajr = prayerTimes.fajr.add(Duration(minutes: fajrAdjust));
    var maghrib = prayerTimes.maghrib.add(Duration(minutes: maghribAdjust));

    // The issue: fajr/maghrib from adhan represent local time in target timezone,
    // but DateTime interprets them as device local timezone.
    // Solution: Create TZDateTime in target timezone using the hour/minute from adhan,
    // then convert to UTC for storage. Caller converts back to target timezone for display.
    
    try {
      final targetLocation = tz.getLocation(timezone);
      
      // Create TZDateTime in target timezone using hour/minute from adhan result
      // This ensures the time represents the correct local time in target timezone
      final fajrTz = tz.TZDateTime(
        targetLocation,
        date.year,
        date.month,
        date.day,
        fajr.hour,
        fajr.minute,
        fajr.second,
      );
      final maghribTz = tz.TZDateTime(
        targetLocation,
        date.year,
        date.month,
        date.day,
        maghrib.hour,
        maghrib.minute,
        maghrib.second,
      );
      
      // Convert to UTC for storage - caller will convert back to target timezone
      return {
        'fajr': fajrTz.toUtc(),
        'maghrib': maghribTz.toUtc(),
      };
    } catch (e) {
      // Fallback: return as-is (shouldn't happen)
      return {
        'fajr': fajr,
        'maghrib': maghrib,
      };
    }
  }

  static Future<Map<String, DateTime>> getCachedOrCalculate({
    required AppDatabase database,
    required int seasonId,
    required DateTime date,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final dateOffsetMinutes =
        utcOffsetForDate(timezone: timezone, date: date).inMinutes;

    final cached =
        await database.prayerTimesCacheDao.getCachedTime(seasonId, dateStr);
    final sourcePref = PrayerTimeSourceKindCodec.parse(
      await database.kvSettingsDao.getValue('prayer_time_source'),
    );
    if (cached != null &&
        _cacheReusable(
          cached: cached,
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
          method: method,
          fajrAdjust: fajrAdjust,
          maghribAdjust: maghribAdjust,
          dateOffsetMinutes: dateOffsetMinutes,
        ) &&
        _cacheAllowedForPreference(cached: cached, preference: sourcePref)) {
      return {
        'fajr': DateTime.parse(cached.fajrIso),
        'maghrib': DateTime.parse(cached.maghribIso),
      };
    }

    final times = getFajrAndMaghrib(
      date: date,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      method: method,
      highLatRule: highLatRule,
      fajrAdjust: fajrAdjust,
      maghribAdjust: maghribAdjust,
    );

    await database.prayerTimesCacheDao.cacheTime(
      PrayerTimesCacheData(
        seasonId: seasonId,
        dateYyyyMmDd: dateStr,
        fajrIso: times['fajr']!.toIso8601String(),
        maghribIso: times['maghrib']!.toIso8601String(),
        method: method,
        lat: latitude,
        lon: longitude,
        timezone: timezone,
        fajrAdj: fajrAdjust,
        maghribAdj: maghribAdjust,
        utcOffsetMinutes: dateOffsetMinutes,
        source: 'local',
        sourceRef: null,
        fetchedAt: null,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    return times;
  }

  static Future<void> ensureTodayAndTomorrowCached({
    required AppDatabase database,
    required int seasonId,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    await getCachedOrCalculate(
      database: database,
      seasonId: seasonId,
      date: today,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      method: method,
      highLatRule: highLatRule,
      fajrAdjust: fajrAdjust,
      maghribAdjust: maghribAdjust,
    );

    await getCachedOrCalculate(
      database: database,
      seasonId: seasonId,
      date: tomorrow,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      method: method,
      highLatRule: highLatRule,
      fajrAdjust: fajrAdjust,
      maghribAdjust: maghribAdjust,
    );
  }

  static bool _cacheReusable({
    required PrayerTimesCacheData cached,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required int fajrAdjust,
    required int maghribAdjust,
    required int dateOffsetMinutes,
  }) {
    if (cached.utcOffsetMinutes == null) return false;
    return cached.method == method &&
        cached.timezone == timezone &&
        cached.fajrAdj == fajrAdjust &&
        cached.maghribAdj == maghribAdjust &&
        cached.lat == latitude &&
        cached.lon == longitude &&
        cached.utcOffsetMinutes == dateOffsetMinutes;
  }

  static bool _cacheAllowedForPreference({
    required PrayerTimesCacheData cached,
    required PrayerTimeSourceKind preference,
  }) {
    if (preference != PrayerTimeSourceKind.local) return true;
    return cached.source == null || cached.source == 'local';
  }
}
