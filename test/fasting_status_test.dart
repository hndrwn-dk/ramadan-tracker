import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

void main() {
  group('FastingStatus.isCompletedForDay', () {
    test('fasted counts as completed', () {
      expect(
        FastingStatus.isCompletedForDay(FastingStatus.fasted, true),
        isTrue,
      );
    });

    test('excused statuses count as completed for day score', () {
      for (final status in [
        FastingStatus.excusedSick,
        FastingStatus.excusedNifas,
        FastingStatus.excusedHaid,
        FastingStatus.excusedOther,
      ]) {
        expect(
          FastingStatus.isCompletedForDay(status, false),
          isTrue,
          reason: 'status $status should count for day score',
        );
      }
    });

    test('not done does not count as completed', () {
      expect(
        FastingStatus.isCompletedForDay(FastingStatus.notDone, false),
        isFalse,
      );
    });

    test('legacy entries with only valueBool true count as completed', () {
      expect(FastingStatus.isCompletedForDay(null, true), isTrue);
    });
  });
}
