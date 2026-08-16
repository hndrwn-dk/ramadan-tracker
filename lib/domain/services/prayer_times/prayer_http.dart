import 'package:http/http.dart' as http;

class PrayerHttpResponse {
  const PrayerHttpResponse({required this.statusCode, required this.body});

  final int statusCode;
  final String body;
}

typedef PrayerHttpGet = Future<PrayerHttpResponse> Function(Uri uri);

class PrayerHttp {
  static const userAgent = 'RamadanTracker/1.0.3 (Flutter; offline-first)';

  static Map<String, String> get headers => {
        'User-Agent': userAgent,
        'Accept': 'application/json',
      };

  static PrayerHttpGet get defaultGet => (uri) async {
        final response = await http.get(uri, headers: headers);
        return PrayerHttpResponse(
          statusCode: response.statusCode,
          body: response.body,
        );
      };
}
