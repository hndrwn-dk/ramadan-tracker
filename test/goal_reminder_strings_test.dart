import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/utils/goal_reminder_strings.dart';

void main() {
  group('GoalReminderStrings', () {
    test('returns Indonesian copy for id locale', () {
      final quran = GoalReminderStrings.forType('quran', 'id', 2, 5);
      expect(quran.title, 'Pengingat Target Quran');
      expect(quran.body, contains('2/5'));
      expect(quran.body, contains('halaman'));
    });

    test('returns English copy for en locale', () {
      final sedekah = GoalReminderStrings.forType('sedekah', 'en', 0, 10000);
      expect(sedekah.title, 'Sedekah Goal Reminder');
      expect(sedekah.body, contains('goodness'));
    });
  });
}
