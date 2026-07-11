import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/providers/notification_launch_provider.dart';
import 'package:ramadan_tracker/features/today/widgets/fasting_notification_handler.dart';

void main() {
  group('FastingNotificationHandler.handledKvKey', () {
    tearDown(FastingNotificationHandler.resetHandledForTest);

    test('builds stable keys for ramadan sahur and iftar', () {
      const sahur = NotificationLaunchRequest(
        kind: FastingNotificationKind.ramadanSahur,
        seasonId: 3,
        dayIndex: 12,
      );
      const iftar = NotificationLaunchRequest(
        kind: FastingNotificationKind.ramadanIftar,
        seasonId: 3,
        dayIndex: 12,
      );

      expect(
        FastingNotificationHandler.handledKvKey(sahur),
        'notif_handled_ramadanSahur_3_12',
      );
      expect(
        FastingNotificationHandler.handledKvKey(iftar),
        'notif_handled_ramadanIftar_3_12',
      );
      expect(
        FastingNotificationHandler.handledKvKey(sahur),
        isNot(FastingNotificationHandler.handledKvKey(iftar)),
      );
    });

    test('builds stable keys for sunnah dates', () {
      final request = NotificationLaunchRequest(
        kind: FastingNotificationKind.sunnahIftar,
        sunnahDate: DateTime(2026, 6, 10),
      );
      expect(
        FastingNotificationHandler.handledKvKey(request),
        'notif_handled_sunnahIftar_20260610',
      );
    });
  });
}
