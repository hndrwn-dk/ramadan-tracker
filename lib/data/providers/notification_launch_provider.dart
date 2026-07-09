import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending UI action from a tapped fasting notification.
enum FastingNotificationKind {
  ramadanSahur,
  ramadanIftar,
  sunnahSahur,
  sunnahIftar,
}

class NotificationLaunchRequest {
  final FastingNotificationKind kind;
  final int? seasonId;
  final int? dayIndex;
  final DateTime? sunnahDate;

  const NotificationLaunchRequest({
    required this.kind,
    this.seasonId,
    this.dayIndex,
    this.sunnahDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationLaunchRequest &&
          kind == other.kind &&
          seasonId == other.seasonId &&
          dayIndex == other.dayIndex &&
          _sameDate(sunnahDate, other.sunnahDate);

  @override
  int get hashCode => Object.hash(kind, seasonId, dayIndex, sunnahDate?.millisecondsSinceEpoch);

  static bool _sameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

final notificationLaunchProvider =
    StateProvider<NotificationLaunchRequest?>((ref) => null);
