import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/utils/device_timezone.dart';

enum OnboardingLocationFailure { unavailable }

class OnboardingLocationResult {
  const OnboardingLocationResult.ok(this.position) : failure = null;

  const OnboardingLocationResult.failed(this.failure) : position = null;

  final Position? position;
  final OnboardingLocationFailure? failure;

  bool get ok => position != null && failure == null;
}

const Duration onboardingGpsTimeout = Duration(seconds: 8);

/// Location + timezone helpers for onboarding Step 4.
/// Keep this off the Android UI thread: no Process.run, and always time-bound GPS.
Future<Position> acquireCurrentPosition({
  required Future<Position> Function() getPosition,
  Duration timeout = onboardingGpsTimeout,
}) {
  return getPosition().timeout(timeout);
}

/// Android LocationManager GPS last-known, not Fused app-scoped last location.
/// Emulator-injected coordinates (e.g. Singapore) live on the GPS provider.
Future<Position?> onboardingLastKnownPosition() {
  return Geolocator.getLastKnownPosition(forceAndroidLocationManager: true);
}

/// LocationManager current fix with a hard timeout so ANR cannot return.
/// Fused + LOW_POWER/BALANCED waits on network location, which is often null
/// on emulators even when GPS already has a fix.
Future<Position> onboardingCurrentPosition({
  Duration timeout = onboardingGpsTimeout,
}) {
  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
    forceAndroidLocationManager: true,
    timeLimit: timeout,
  );
}

Future<OnboardingLocationResult> acquireOnboardingPosition({
  required Future<Position> Function() getCurrentPosition,
  Future<Position?> Function()? getLastKnownPosition,
  Duration timeout = onboardingGpsTimeout,
}) async {
  Position? lastKnown = await _tryLastKnown(getLastKnownPosition);
  if (lastKnown != null) {
    return OnboardingLocationResult.ok(lastKnown);
  }

  try {
    final current = await getCurrentPosition().timeout(timeout);
    return OnboardingLocationResult.ok(current);
  } catch (_) {
    lastKnown = await _tryLastKnown(getLastKnownPosition);
    if (lastKnown != null) {
      return OnboardingLocationResult.ok(lastKnown);
    }
    return const OnboardingLocationResult.failed(
      OnboardingLocationFailure.unavailable,
    );
  }
}

Future<Position?> _tryLastKnown(
  Future<Position?> Function()? getLastKnownPosition,
) async {
  if (getLastKnownPosition == null) return null;
  try {
    return await getLastKnownPosition();
  } catch (_) {
    return null;
  }
}

Future<String> acquireDeviceTimezone() => resolveDeviceTimezone();
