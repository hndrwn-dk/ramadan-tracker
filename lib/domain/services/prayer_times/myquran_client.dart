import 'package:ramadan_tracker/domain/services/prayer_times/myquran_parser.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_http.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';

class MyQuranClient {
  MyQuranClient({PrayerHttpGet? get}) : _get = get ?? PrayerHttp.defaultGet;

  static const _host = 'api.myquran.com';

  final PrayerHttpGet _get;

  Future<List<MyQuranCity>> searchCities(String keyword) async {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return const [];
    final uri = Uri.https(
      _host,
      '/v3/sholat/kabkota/cari/${Uri.encodeComponent(trimmed)}',
    );
    final response = await _get(uri);
    if (response.statusCode == 403 ||
        response.statusCode == 429 ||
        response.statusCode >= 400) {
      return const [];
    }
    return MyQuranParser.parseSearch(response.body);
  }

  Future<List<RemotePrayerDay>> fetchMonth({
    required String cityId,
    required int year,
    required int month,
    required String timezone,
  }) async {
    if (cityId.isEmpty) return const [];
    final period =
        '$year-${month.toString().padLeft(2, '0')}';
    final uri = Uri.https(_host, '/v3/sholat/jadwal/$cityId/$period');
    final response = await _get(uri);
    if (response.statusCode == 429 || response.statusCode >= 400) {
      return const [];
    }
    return MyQuranParser.parseMonthly(response.body, timezone: timezone);
  }
}
