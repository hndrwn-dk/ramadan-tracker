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

  group('HomeWidgetService Ramadan helpers', () {
    final sahur = DateTime(2026, 3, 20, 4, 30);
    final iftar = DateTime(2026, 3, 20, 18, 15);

    test('formatRamadanCountdownLine shows iftar before sunset', () {
      final line = HomeWidgetService.formatRamadanCountdownLine(
        isId: true,
        now: DateTime(2026, 3, 20, 12, 0),
        sahurTime: sahur,
        iftarTime: iftar,
      );
      expect(line, startsWith('Iftar dalam'));
    });

    test('formatRamadanSecondaryLine shows taraweeh after iftar', () {
      final line = HomeWidgetService.formatRamadanSecondaryLine(
        isId: true,
        dayIndex: 5,
        totalDays: 30,
        taraweehEnabled: true,
        taraweehDone: false,
        afterIftar: true,
        ramadanFastLogged: true,
      );
      expect(line, 'Tarawih belum dicatat');
    });

    test('formatRamadanSecondaryLine shows day index before iftar', () {
      final line = HomeWidgetService.formatRamadanSecondaryLine(
        isId: false,
        dayIndex: 5,
        totalDays: 30,
        taraweehEnabled: true,
        taraweehDone: false,
        afterIftar: false,
        ramadanFastLogged: false,
      );
      expect(line, contains('Day 5/30'));
      expect(line, contains('Fast not logged'));
    });
  });
}
