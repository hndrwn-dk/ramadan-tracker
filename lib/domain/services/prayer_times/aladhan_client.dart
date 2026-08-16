import 'package:ramadan_tracker/domain/services/prayer_times/aladhan_parser.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_http.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';

class AladhanClient {
  AladhanClient({PrayerHttpGet? get}) : _get = get ?? PrayerHttp.defaultGet;

  static const _host = 'api.aladhan.com';

  final PrayerHttpGet _get;

  static int methodIdFor(String method) {
    switch (method.toLowerCase()) {
      case 'karachi':
        return 1;
      case 'isna':
      case 'north_america':
        return 2;
      case 'egypt':
      case 'egyptian':
        return 5;
      case 'umm_al_qura':
      case 'ummalqura':
        return 4;
      case 'singapore':
        return 11;
      case 'indonesia':
      case 'kemenag':
        return 20;
      case 'dubai':
        return 16;
      case 'qatar':
        return 10;
      case 'kuwait':
        return 9;
      case 'turkey':
        return 13;
      case 'tehran':
        return 7;
      case 'mwl':
      case 'muslim_world_league':
      default:
        return 3;
    }
  }

  Future<List<RemotePrayerDay>> fetchMonth({
    required double latitude,
    required double longitude,
    required int year,
    required int month,
    required String method,
  }) async {
    final uri = Uri.https(_host, '/v1/calendar/$year/$month', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'method': methodIdFor(method).toString(),
      'iso8601': 'true',
    });
    final response = await _get(uri);
    if (response.statusCode == 429 || response.statusCode >= 400) {
      return const [];
    }
    return AladhanParser.parseCalendar(response.body);
  }
}
