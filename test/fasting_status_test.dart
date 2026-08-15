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

  group('FastingStatus.checklistTapAction', () {
    test('toggles notDone to fasted', () {
      expect(
        FastingStatus.checklistTapAction(
          currentStatus: FastingStatus.notDone,
        ),
        FastingChecklistTapAction.toggleToFasted,
      );
    });

    test('toggles fasted to notDone', () {
      expect(
        FastingStatus.checklistTapAction(
          currentStatus: FastingStatus.fasted,
        ),
        FastingChecklistTapAction.toggleToNotDone,
      );
    });

    test('opens status sheet for every excused variant', () {
      for (final status in [
        FastingStatus.excusedSick,
        FastingStatus.excusedNifas,
        FastingStatus.excusedHaid,
        FastingStatus.excusedOther,
      ]) {
        expect(
          FastingStatus.checklistTapAction(currentStatus: status),
          FastingChecklistTapAction.openStatusSheet,
          reason: 'status $status must not quick-toggle',
        );
      }
    });

    test('opens status sheet for pending intent status', () {
      expect(
        FastingStatus.checklistTapAction(
          currentStatus: FastingStatus.intentPendingFast,
        ),
        FastingChecklistTapAction.openStatusSheet,
      );
    });

    test('opens status sheet when pending intent KV is set', () {
      expect(
        FastingStatus.checklistTapAction(
          currentStatus: FastingStatus.notDone,
          hasPendingIntent: true,
        ),
        FastingChecklistTapAction.openStatusSheet,
      );
    });
  });
}
