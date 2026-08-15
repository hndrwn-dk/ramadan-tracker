import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/services/zoned_schedule_retry_plan.dart';

void main() {
  group('ZonedScheduleRetryPlan.forScheduleError', () {
    test('corrupt payload retry keeps original payload and does not wipe batch', () {
      final plan = ZonedScheduleRetryPlan.forScheduleError(
        Exception('Missing type parameter'),
      );

      expect(plan.clearCorruptDatabase, isFalse);
      expect(plan.includePayload, isTrue);
    });

    test('payloadForRetry returns the original payload', () {
      final plan = ZonedScheduleRetryPlan.forScheduleError(
        Exception('Missing type parameter'),
      );

      expect(
        plan.payloadForRetry('sunnah_iftar:20260615'),
        'sunnah_iftar:20260615',
      );
    });
  });
}
