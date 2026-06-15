import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';

void main() {
  group('HomeWidgetService.formatSunnahTodayLine', () {
    test('returns logged message when fasted', () {
      expect(
        HomeWidgetService.formatSunnahTodayLine(
          isId: true,
          fasted: true,
          today: DateTime(2026, 6, 10),
        ),
        'Puasa sunnah tercatat',
      );
    });

    test('does not depend on Ramadan season state', () {
      final line = HomeWidgetService.formatSunnahTodayLine(
        isId: true,
        fasted: false,
        today: DateTime(2026, 6, 10),
      );
      expect(line, isNotEmpty);
      expect(line, isNot(contains('Musim')));
    });
  });
}
