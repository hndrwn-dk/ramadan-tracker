import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/services/notification_ids.dart';
import 'package:ramadan_tracker/domain/services/sunnah_eve_reminder_plan.dart';

void main() {
  group('SunnahEveReminderPlan.build', () {
    test('schedules only one Monday reminder in a 14-day window with two Mondays',
        () {
      // Sunday 7 Jun 2026. Fast days 8-21 Jun include Mondays 8 and 15.
      final plan = SunnahEveReminderPlan.build(
        today: DateTime(2026, 6, 7),
        now: DateTime(2026, 6, 7, 10),
        isId: true,
      );

      final mondays = plan
          .where((item) => item.fastDay.weekday == DateTime.monday)
          .toList();
      expect(mondays, hasLength(1));
      expect(mondays.single.fastDay, DateTime(2026, 6, 8));
      expect(mondays.single.id, NotificationIds.sunnahEveMonday);
    });

    test('uses a stable Monday id so a later reschedule replaces the previous',
        () {
      final thisWeek = SunnahEveReminderPlan.build(
        today: DateTime(2026, 6, 7),
        now: DateTime(2026, 6, 7, 10),
        isId: false,
      );
      final afterMonday = SunnahEveReminderPlan.build(
        today: DateTime(2026, 6, 8),
        now: DateTime(2026, 6, 8, 10),
        isId: false,
      );

      final thisWeekMonday = thisWeek.singleWhere(
        (item) => item.fastDay.weekday == DateTime.monday,
      );
      final nextMonday = afterMonday.singleWhere(
        (item) => item.fastDay.weekday == DateTime.monday,
      );
      expect(thisWeekMonday.id, NotificationIds.sunnahEveMonday);
      expect(nextMonday.id, thisWeekMonday.id);
      expect(nextMonday.fastDay, DateTime(2026, 6, 15));
    });

    test('labels Monday and Thursday eves as distinct days, not Senin/Kamis',
        () {
      final plan = SunnahEveReminderPlan.build(
        today: DateTime(2026, 6, 7),
        now: DateTime(2026, 6, 7, 10),
        isId: true,
      );

      final monday = plan.singleWhere(
        (item) => item.fastDay.weekday == DateTime.monday,
      );
      final thursday = plan.singleWhere(
        (item) => item.fastDay.weekday == DateTime.thursday,
      );
      expect(monday.body, contains('Puasa Senin'));
      expect(monday.body, isNot(contains('Kamis')));
      expect(thursday.body, contains('Puasa Kamis'));
      expect(thursday.body, isNot(contains('Senin')));
      expect(thursday.id, NotificationIds.sunnahEveThursday);
    });

    test('skips tonight when the Monday eve hour has already passed', () {
      final plan = SunnahEveReminderPlan.build(
        today: DateTime(2026, 6, 7),
        now: DateTime(2026, 6, 7, 20),
        isId: false,
      );

      final monday = plan.singleWhere(
        (item) => item.fastDay.weekday == DateTime.monday,
      );
      expect(monday.fastDay, DateTime(2026, 6, 15));
    });

    test('never emits two reminders with the same notification id', () {
      final plan = SunnahEveReminderPlan.build(
        today: DateTime(2026, 6, 7),
        now: DateTime(2026, 6, 7, 10),
        isId: false,
      );
      final ids = plan.map((item) => item.id).toList();
      expect(ids.toSet().length, ids.length);
    });
  });
}
