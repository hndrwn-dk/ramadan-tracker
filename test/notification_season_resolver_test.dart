import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/goal_reminder_service.dart';
import 'package:ramadan_tracker/domain/services/notification_season_resolver.dart';

void main() {
  RamadanSeason season({
    required int id,
    required String startDate,
    int days = 30,
  }) {
    return RamadanSeason(
      id: id,
      label: 'Season $id',
      startDate: startDate,
      days: days,
      createdAt: 0,
    );
  }

  group('NotificationSeasonResolver.pickForScheduling', () {
    test('returns null when list is empty', () {
      expect(
        NotificationSeasonResolver.pickForScheduling([], DateTime(2026, 6, 6)),
        isNull,
      );
    });

    test('returns null when only ended seasons exist', () {
      final ended = season(id: 1, startDate: '2025-02-19');
      expect(
        NotificationSeasonResolver.pickForScheduling(
          [ended],
          DateTime(2026, 6, 6),
        ),
        isNull,
      );
    });

    test('prefers active season over upcoming and ended', () {
      final ended = season(id: 1, startDate: '2025-02-19');
      final active = season(id: 2, startDate: '2026-02-19');
      final upcoming = season(id: 3, startDate: '2027-02-08');

      expect(
        NotificationSeasonResolver.pickForScheduling(
          [ended, upcoming, active],
          DateTime(2026, 3, 1),
        )?.id,
        2,
      );
    });

    test('returns nearest upcoming when no active season', () {
      final ended = season(id: 1, startDate: '2025-02-19');
      final far = season(id: 2, startDate: '2027-02-08');
      final near = season(id: 3, startDate: '2026-12-01');

      expect(
        NotificationSeasonResolver.pickForScheduling(
          [ended, far, near],
          DateTime(2026, 6, 6),
        )?.id,
        3,
      );
    });
  });

  group('NotificationSeasonResolver.hasSchedulableDateRange', () {
    test('false when start is after end (post-Ramadan leftover)', () {
      expect(
        NotificationSeasonResolver.hasSchedulableDateRange(
          DateTime(2026, 6, 6),
          DateTime(2026, 3, 20),
        ),
        isFalse,
      );
    });

    test('true when range includes at least one day', () {
      expect(
        NotificationSeasonResolver.hasSchedulableDateRange(
          DateTime(2026, 2, 19),
          DateTime(2026, 3, 20),
        ),
        isTrue,
      );
    });
  });

  group('GoalReminderService.shouldScheduleNumericGoal', () {
    test('requires enabled habit, positive target, and incomplete progress', () {
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: true,
          target: 20,
          progress: 5,
        ),
        isTrue,
      );
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: false,
          target: 20,
          progress: 0,
        ),
        isFalse,
      );
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: true,
          target: 0,
          progress: 0,
        ),
        isFalse,
      );
      expect(
        GoalReminderService.shouldScheduleNumericGoal(
          habitEnabled: true,
          target: 20,
          progress: 20,
        ),
        isFalse,
      );
    });
  });
}
