import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/providers/notification_launch_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_ids.dart';
import 'package:ramadan_tracker/domain/services/notification_launch_service.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';

void main() {
  group('NotificationIds.categoryOf', () {
    test('classifies sahur, iftar, imsak, goal, next Ramadan, and sunnah IDs', () {
      expect(
        NotificationIds.categoryOf(NotificationIds.baseSahur + 20260606),
        NotificationCategory.sahur,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseIftar + 20260606),
        NotificationCategory.iftar,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseImsak + 20260606),
        NotificationCategory.imsak,
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
      expect(
        NotificationIds.categoryOf(NotificationIds.baseSunnahSahur + 20260606),
        NotificationCategory.sunnah,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseSunnahIftar + 20260606),
        NotificationCategory.sunnah,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseSahur + 20260606),
        NotificationCategory.sahur,
      );
      expect(
        NotificationIds.categoryOf(NotificationIds.baseIftar + 20260606),
        NotificationCategory.iftar,
      );
    });

    test('sunnah Sahur/Iftar IDs are distinct from season Sahur/Iftar', () {
      const date = 20260610;
      final seasonSahur = NotificationIds.baseSahur + date;
      final seasonIftar = NotificationIds.baseIftar + date;
      final sunnahSahur = NotificationIds.baseSunnahSahur + date;
      final sunnahIftar = NotificationIds.baseSunnahIftar + date;

      expect(NotificationIds.categoryOf(seasonSahur), NotificationCategory.sahur);
      expect(NotificationIds.categoryOf(seasonIftar), NotificationCategory.iftar);
      expect(NotificationIds.categoryOf(sunnahSahur), NotificationCategory.sunnah);
      expect(NotificationIds.categoryOf(sunnahIftar), NotificationCategory.sunnah);
      expect(sunnahSahur, isNot(seasonSahur));
      expect(sunnahIftar, isNot(seasonIftar));
    });

    test('countByCategory groups pending list', () {
      final counts = NotificationIds.countByCategory([
        NotificationInfo(
          id: NotificationIds.baseSahur + 20260606,
          title: 'S',
          body: null,
        ),
        NotificationInfo(
          id: NotificationIds.baseImsak + 20260606,
          title: 'I',
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
      expect(counts[NotificationCategory.imsak], 1);
      expect(counts[NotificationCategory.goal], 1);
      expect(counts[NotificationCategory.nextRamadan], 1);
    });
  });

  group('FastingNotificationPayload', () {
    test('parses ramadan and sunnah sahur/iftar payloads', () {
      final ramadanSahur =
          FastingNotificationPayload.parse('ramadan_sahur:3:12');
      expect(ramadanSahur?.kind, FastingNotificationKind.ramadanSahur);
      expect(ramadanSahur?.seasonId, 3);
      expect(ramadanSahur?.dayIndex, 12);

      final legacyImsak =
          FastingNotificationPayload.parse('ramadan_imsak:3:12');
      expect(legacyImsak?.kind, FastingNotificationKind.ramadanSahur);

      final sunnahIftar =
          FastingNotificationPayload.parse('sunnah_iftar:20260610');
      expect(sunnahIftar?.kind, FastingNotificationKind.sunnahIftar);
      expect(sunnahIftar?.sunnahDate, DateTime(2026, 6, 10));
    });
  });
}
