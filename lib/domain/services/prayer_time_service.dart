import 'package:adhan_dart/adhan_dart.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';

class PrayerTimeService {
  static CalculationParameters _getCalculationParameters(String method) {
    switch (method.toLowerCase()) {
      case 'isna':
        return CalculationParameters(
          fajrAngle: 15.0,
          ishaAngle: 15.0,
          method: CalculationMethod.other,
        );
      case 'egypt':
        return CalculationParameters(
          fajrAngle: 19.5,
          ishaAngle: 17.5,
          method: CalculationMethod.other,
        );
      case 'umm_al_qura':
      case 'ummalqura':
        return CalculationParameters(
          fajrAngle: 18.5,
          ishaAngle: 0.0,
          ishaInterval: 90,
          method: CalculationMethod.other,
        );
      case 'karachi':
        return CalculationParameters(
          fajrAngle: 18.0,
          ishaAngle: 18.0,
          method: CalculationMethod.other,
        );
      default:
        return CalculationParameters(
          fajrAngle: 18.0,
          ishaAngle: 17.0,
          method: CalculationMethod.other,
        );
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
    
    final prayerTimes = PrayerTimes(
      coordinates: coordinates,
      date: date,
      calculationParameters: params,
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
    final prayerTimes = calculatePrayerTimes(
      date: date,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      method: method,
      highLatRule: highLatRule,
      fajrAdjust: fajrAdjust,
      maghribAdjust: maghribAdjust,
    );

    var fajr = prayerTimes.fajr;
    var maghrib = prayerTimes.maghrib;

    if (fajrAdjust != 0) {
      fajr = fajr.add(Duration(minutes: fajrAdjust));
    }
    if (maghribAdjust != 0) {
      maghrib = maghrib.add(Duration(minutes: maghribAdjust));
    }

    return {
      'fajr': fajr,
      'maghrib': maghrib,
    };
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
    
    final cached = await database.prayerTimesCacheDao.getCachedTime(seasonId, dateStr);
    
    if (cached != null) {
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
}
