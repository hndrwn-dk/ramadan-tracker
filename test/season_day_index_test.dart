import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

void main() {
  group('SeasonModel day index before start', () {
    final season = SeasonModel(
      id: 1,
      label: 'Test',
      startDate: DateTime(2026, 10, 21),
      days: 30,
      createdAt: DateTime(2026, 10, 1),
    );

    test('raw index is 0 the day before start', () {
      expect(season.getRawDayIndex(DateTime(2026, 10, 20)), 0);
    });

    test('date before start is not in season', () {
      expect(season.isDateInSeason(DateTime(2026, 10, 20)), isFalse);
    });

    test('day 1 starts on the season start date', () {
      expect(season.getRawDayIndex(DateTime(2026, 10, 21)), 1);
      expect(season.getDayIndex(DateTime(2026, 10, 21)), 1);
      expect(season.isDateInSeason(DateTime(2026, 10, 21)), isTrue);
    });
  });
}
