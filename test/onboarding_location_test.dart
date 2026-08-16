import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/l10n/app_localizations_en.dart';
import 'package:ramadan_tracker/l10n/app_localizations_id.dart';
import 'package:ramadan_tracker/utils/onboarding_location.dart';

void main() {
  Position position({
    DateTime? timestamp,
    double latitude = -6.2088,
    double longitude = 106.8456,
  }) =>
      Position(
        longitude: longitude,
        latitude: latitude,
        timestamp: timestamp ?? DateTime.utc(2026, 3, 1),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  test('timeout maps to a friendly failure, not TimeoutException', () async {
    final result = await acquireOnboardingPosition(
      getCurrentPosition: () => Completer<Position>().future,
      timeout: const Duration(milliseconds: 20),
    );

    expect(result.ok, isFalse);
    expect(result.position, isNull);
    expect(result.failure, OnboardingLocationFailure.unavailable);
  });

  test('uses stale last-known immediately without waiting for current', () async {
    var currentCalled = false;
    final lastKnown = position(
      latitude: 1.309748,
      longitude: 103.927533,
      timestamp: DateTime.utc(2020, 1, 1),
    );
    final result = await acquireOnboardingPosition(
      getCurrentPosition: () {
        currentCalled = true;
        return Completer<Position>().future;
      },
      getLastKnownPosition: () async => lastKnown,
      timeout: const Duration(seconds: 8),
    );

    expect(result.ok, isTrue);
    expect(result.position!.latitude, 1.309748);
    expect(result.position!.longitude, 103.927533);
    expect(currentCalled, isFalse);
  });

  test('uses last-known when current position times out', () async {
    final lastKnown = position(latitude: -6.2, longitude: 106.8);
    var lastKnownCalls = 0;
    final result = await acquireOnboardingPosition(
      getCurrentPosition: () => Completer<Position>().future,
      getLastKnownPosition: () async {
        lastKnownCalls += 1;
        if (lastKnownCalls == 1) return null;
        return lastKnown;
      },
      timeout: const Duration(milliseconds: 20),
    );

    expect(result.ok, isTrue);
    expect(result.position!.latitude, -6.2);
    expect(result.position!.longitude, 106.8);
  });

  test('uses recent last-known without waiting for current', () async {
    final now = DateTime.utc(2026, 8, 16, 12);
    var currentCalled = false;
    final result = await acquireOnboardingPosition(
      getCurrentPosition: () {
        currentCalled = true;
        return Completer<Position>().future;
      },
      getLastKnownPosition: () async => position(timestamp: now),
      timeout: const Duration(seconds: 8),
    );

    expect(result.ok, isTrue);
    expect(result.position!.latitude, -6.2088);
    expect(currentCalled, isFalse);
  });

  test('acquireOnboardingPosition returns when current completes in time',
      () async {
    final result = await acquireOnboardingPosition(
      getCurrentPosition: () async => position(),
      timeout: const Duration(seconds: 1),
    );
    expect(result.ok, isTrue);
    expect(result.position!.latitude, -6.2088);
    expect(result.position!.longitude, 106.8456);
  });

  test('friendly snackbar text never includes TimeoutException', () {
    final en = AppLocalizationsEn().onboardingLocationGpsFailed;
    final id = AppLocalizationsId().onboardingLocationGpsFailed;
    expect(en.toLowerCase(), contains('gps'));
    expect(en.contains('TimeoutException'), isFalse);
    expect(en.startsWith('Error:'), isFalse);
    expect(id.contains('TimeoutException'), isFalse);
    expect(id.startsWith('Error:'), isFalse);
  });
}
