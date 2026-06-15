import 'package:ramadan_tracker/domain/services/notification_service.dart';

/// Categories for deterministic notification IDs used by [NotificationService].
enum NotificationCategory {
  sahur,
  iftar,
  nightPlan,
  habit,
  goal,
  nextRamadan,
  sunnah,
  other,
}

/// Helpers to classify and group scheduled notification IDs.
abstract final class NotificationIds {
  static const int baseSahur = 1000000;
  static const int baseIftar = 2000000;
  static const int baseNightPlan = 3000000;
  static const int baseHabit = 4000000;
  static const int baseGoal = 5000000;
  static const int baseNextRamadan = 6000000;
  static const int baseSunnah = 7000000;

  /// Season-bound reminders (Sahur, Iftar, night plan, goals, legacy habits).
  static const seasonCategories = {
    NotificationCategory.sahur,
    NotificationCategory.iftar,
    NotificationCategory.nightPlan,
    NotificationCategory.habit,
    NotificationCategory.goal,
  };

  static NotificationCategory categoryOf(int id) {
    if (id >= baseNextRamadan && id < baseSunnah) {
      return NotificationCategory.nextRamadan;
    }
    if (id >= 21000000 && id < 22000000) {
      return NotificationCategory.sahur;
    }
    if (id >= 22000000 && id < 23000000) {
      return NotificationCategory.iftar;
    }
    if (id >= 23000000 && id < 24000000) {
      return NotificationCategory.nightPlan;
    }
    if (id >= 24000000 && id < 25000000) {
      return NotificationCategory.habit;
    }
    if (id >= 25000000 && id < 27000000) {
      return NotificationCategory.goal;
    }
    if (id >= 27000000 && id < 28000000) {
      return NotificationCategory.sunnah;
    }
    return NotificationCategory.other;
  }

  static String label(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.sahur:
        return 'Sahur';
      case NotificationCategory.iftar:
        return 'Iftar';
      case NotificationCategory.nightPlan:
        return 'Night plan';
      case NotificationCategory.habit:
        return 'Habit';
      case NotificationCategory.goal:
        return 'Goal';
      case NotificationCategory.nextRamadan:
        return 'Next Ramadan';
      case NotificationCategory.sunnah:
        return 'Sunnah';
      case NotificationCategory.other:
        return 'Other';
    }
  }

  static Map<NotificationCategory, int> countByCategory(
    List<NotificationInfo> pending,
  ) {
    final counts = {
      for (final c in NotificationCategory.values) c: 0,
    };
    for (final n in pending) {
      counts[categoryOf(n.id)] = (counts[categoryOf(n.id)] ?? 0) + 1;
    }
    return counts;
  }
}
