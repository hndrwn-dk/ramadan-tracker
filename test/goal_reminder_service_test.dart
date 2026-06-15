import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/goal_reminder_service.dart';

void main() {
  group('GoalReminderService.isActiveSeasonDay', () {
    RamadanSeason season({required String startDate, int days = 30}) {
      return RamadanSeason(
        id: 1,
        label: 'Test',
        startDate: startDate,
        days: days,
        createdAt: 0,
      );
    }

    test('returns true on first and last day of season', () {
      final s = season(startDate: '2026-02-19');
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 2, 19)),
        isTrue,
      );
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 3, 20)),
        isTrue,
      );
    });

    test('returns false before season and after season ends', () {
      final s = season(startDate: '2026-02-19');
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 2, 18)),
        isFalse,
      );
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 3, 21)),
        isFalse,
      );
      expect(
        GoalReminderService.isActiveSeasonDay(s, DateTime(2026, 6, 6)),
        isFalse,
      );
    });
  });
}
