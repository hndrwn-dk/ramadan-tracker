import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/utils/goal_reminder_strings.dart';

void main() {
  const banned = [
    'ko-fi',
    'kofi',
    'saweria',
    'trakteer',
    'github.com/sponsors',
    'buymeacoffee',
    'support_10k',
    'support_25k',
    'support_50k',
  ];

  const sources = [
    'lib/utils/goal_reminder_strings.dart',
    'lib/domain/services/goal_reminder_service.dart',
    'lib/domain/services/notification_service.dart',
    'lib/domain/services/sunnah_eve_reminder_plan.dart',
    'lib/utils/next_ramadan_reminder_strings.dart',
  ];

  test('notification and digest copy does not pitch a donation', () {
    for (final path in sources) {
      final text = File(path).readAsStringSync().toLowerCase();
      for (final phrase in banned) {
        expect(text.contains(phrase), isFalse,
            reason: '$path contains $phrase');
      }
    }
  });

  test('digest bodies stay on worship, in both languages', () {
    for (final locale in ['id', 'en']) {
      final copy = GoalReminderStrings.forDigest(
        ['quran', 'dhikr', 'sedekah'],
        locale,
      );
      final folded = '${copy.title} ${copy.body}'.toLowerCase();
      for (final phrase in banned) {
        expect(folded.contains(phrase), isFalse);
      }
    }
  });
}
