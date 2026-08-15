/// How to recover from a failed `zonedSchedule` without harming the rest of the batch.
class ZonedScheduleRetryPlan {
  const ZonedScheduleRetryPlan({
    required this.clearCorruptDatabase,
    required this.includePayload,
  });

  final bool clearCorruptDatabase;
  final bool includePayload;

  /// Retry the failed item with its payload; do not cancel siblings already queued.
  static ZonedScheduleRetryPlan forScheduleError(Object error) {
    return const ZonedScheduleRetryPlan(
      clearCorruptDatabase: false,
      includePayload: true,
    );
  }

  String? payloadForRetry(String? originalPayload) {
    return includePayload ? originalPayload : null;
  }
}
