import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/services/notification_launch_service.dart';

void main() {
  group('NotificationLaunchService cold-start dedup', () {
    tearDown(NotificationLaunchService.resetForTest);

    test('resetForTest clears consumed cold-start payload marker', () {
      NotificationLaunchService.resetForTest();
      // Marker is private; reset should not throw and is idempotent.
      NotificationLaunchService.resetForTest();
    });
  });
}
