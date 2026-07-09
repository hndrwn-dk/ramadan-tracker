import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/utils/goal_reminder_strings.dart';

void main() {
  group('GoalReminderStrings.forType', () {
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

  group('GoalReminderStrings.forDigest', () {
    test('three pending habits — Indonesian', () {
      final copy = GoalReminderStrings.forDigest(
        ['quran', 'dhikr', 'sedekah'],
        'id',
      );
      expect(copy.title, 'Menjelang Maghrib 🌇');
      expect(
        copy.body,
        'Tilawah, dzikir, dan sedekah hari ini masih bisa kamu tunaikan.',
      );
    });

    test('three pending habits — English', () {
      final copy = GoalReminderStrings.forDigest(
        ['sedekah', 'quran', 'dhikr'],
        'en',
      );
      expect(copy.title, 'Almost Maghrib 🌇');
      expect(
        copy.body,
        'Qur\'an, dhikr, and sedekah today are still within reach.',
      );
    });

    test('two pending habits — habit labels in body', () {
      final copy = GoalReminderStrings.forDigest(['quran', 'dhikr'], 'id');
      expect(copy.title, 'Hampir Maghrib');
      expect(copy.body, 'Masih ada waktu untuk tilawah & dzikir sebelum hari berganti.');
    });

    test('single pending quran', () {
      final copy = GoalReminderStrings.forDigest(['quran'], 'id');
      expect(copy.title, 'Waktu tilawah 📖');
      expect(copy.body, 'Beberapa ayat hari ini masih menunggu kamu.');
    });

    test('single pending sedekah — English', () {
      final copy = GoalReminderStrings.forDigest(['sedekah'], 'en');
      expect(copy.title, 'Sedekah today 💛');
      expect(copy.body, contains('share today'));
    });
  });
}
