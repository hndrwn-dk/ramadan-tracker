import 'package:flutter_timezone/flutter_timezone.dart';

/// Resolves the device IANA timezone, never leaving callers on a silent UTC default.
Future<String> resolveDeviceTimezone({String fallback = 'UTC'}) async {
  try {
    final tz = await FlutterTimezone.getLocalTimezone();
    if (tz.isNotEmpty && tz != 'UTC') {
      return tz;
    }
    return tz.isNotEmpty ? tz : fallback;
  } catch (_) {
    return fallback;
  }
}
