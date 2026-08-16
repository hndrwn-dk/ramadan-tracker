import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';
import 'package:ramadan_tracker/utils/location_helper.dart';

export 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';

class PrayerTimeSourceResolver {
  static PrayerTimeSourceKind resolve({
    required PrayerTimeSourceKind preference,
    required double latitude,
    required double longitude,
    required String timezone,
    required String locale,
    required String method,
    String? myquranCityId,
  }) {
    if (preference == PrayerTimeSourceKind.local) {
      return PrayerTimeSourceKind.local;
    }
    if (preference == PrayerTimeSourceKind.aladhan) {
      return PrayerTimeSourceKind.aladhan;
    }
    if (preference == PrayerTimeSourceKind.myquran) {
      if (myquranCityId != null && myquranCityId.isNotEmpty) {
        return PrayerTimeSourceKind.myquran;
      }
      return PrayerTimeSourceKind.aladhan;
    }

    if (isIndonesia(
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
          locale: locale,
          method: method,
        ) &&
        myquranCityId != null &&
        myquranCityId.isNotEmpty) {
      return PrayerTimeSourceKind.myquran;
    }
    return PrayerTimeSourceKind.aladhan;
  }

  static bool isIndonesia({
    required double latitude,
    required double longitude,
    required String timezone,
    required String locale,
    required String method,
  }) {
    final methodLower = method.toLowerCase();
    if (methodLower == 'indonesia' || methodLower == 'kemenag') return true;
    const indonesianZones = {
      'Asia/Jakarta',
      'Asia/Makassar',
      'Asia/Jayapura',
      'Asia/Pontianak',
    };
    if (indonesianZones.contains(timezone)) return true;
    if (LocationHelper.detectCalculationMethod(latitude, longitude) ==
        'indonesia') {
      return true;
    }
    if (locale.toLowerCase().startsWith('id') &&
        LocationHelper.detectCalculationMethod(latitude, longitude) ==
            'indonesia') {
      return true;
    }
    return false;
  }
}
