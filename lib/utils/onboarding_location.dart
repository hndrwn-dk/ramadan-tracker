import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/utils/device_timezone.dart';

/// Location + timezone helpers for onboarding Step 4.
/// Keep this off the Android UI thread: no Process.run, and always time-bound GPS.
Future<Position> acquireCurrentPosition({
  required Future<Position> Function() getPosition,
  Duration timeout = const Duration(seconds: 8),
}) {
  return getPosition().timeout(timeout);
}

Future<String> acquireDeviceTimezone() => resolveDeviceTimezone();
