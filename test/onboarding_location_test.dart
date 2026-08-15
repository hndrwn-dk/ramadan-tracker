import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/utils/onboarding_location.dart';

void main() {
  Position position() => Position(
        longitude: 106.8456,
        latitude: -6.2088,
        timestamp: DateTime.utc(2026, 3, 1),
        accuracy: 1,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );

  test('acquireCurrentPosition times out instead of hanging forever', () async {
    await expectLater(
      acquireCurrentPosition(
        getPosition: () => Completer<Position>().future,
        timeout: const Duration(milliseconds: 20),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('acquireCurrentPosition returns when the getter completes in time',
      () async {
    final result = await acquireCurrentPosition(
      getPosition: () async => position(),
      timeout: const Duration(seconds: 1),
    );
    expect(result.latitude, -6.2088);
    expect(result.longitude, 106.8456);
  });
}
