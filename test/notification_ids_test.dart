import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/services/notification_ids.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';

void main() {
  group('NotificationIds.categoryOf', () {
    test('classifies sahur, iftar, goal, next Ramadan, and sunnah IDs', () {
      expect(
        NotificationIds.categoryOf(NotificationIds.baseSahur + 20260606),
        NotificationCategory.sahur,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseIftar + 20260606),
        NotificationCategory.iftar,
      );
      expect(
        NotificationIds.categoryOf(
          NotificationIds.baseGoal + 14000 + 20260606,
        ),
        NotificationCategory.goal,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseNextRamadan + 2027),
        NotificationCategory.nextRamadan,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseSunnah + 20260606),
        NotificationCategory.sunnah,
      );
    });

    test('countByCategory groups pending list', () {
      final counts = NotificationIds.countByCategory([
        NotificationInfo(
          id: NotificationIds.baseSahur + 20260606,
          title: 'S',
          body: null,
        ),
        NotificationInfo(
          id: NotificationIds.baseGoal + 20260606,
          title: 'G',
          body: null,
        ),
        NotificationInfo(
          id: NotificationIds.baseNextRamadan + 2028,
          title: 'N',
          body: null,
        ),
      ]);
      expect(counts[NotificationCategory.sahur], 1);
      expect(counts[NotificationCategory.goal], 1);
      expect(counts[NotificationCategory.nextRamadan], 1);
    });
  });
}
