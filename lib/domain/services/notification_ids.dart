import 'package:ramadan_tracker/domain/services/notification_service.dart';

enum NotificationCategory {
  sahur,
  iftar,
  imsak,
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
  static const int baseImsak = 8000000;
  static const int baseSunnahSahur = 9000000;
  static const int baseSunnahIftar = 10000000;

  /// Stable eve slots so Android replaces the previous Monday/Thursday reminder
  /// instead of stacking identical copies. Must stay inside 27M-31M (sunnah).
  static const int sunnahEveMonday = 27000001;
  static const int sunnahEveThursday = 27000002;

  /// Season-bound reminders (Sahur, Imsak, Iftar, night plan, goals, legacy habits).
  static const seasonCategories = {
    NotificationCategory.sahur,
    NotificationCategory.iftar,
    NotificationCategory.imsak,
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
    if (id >= 28000000 && id < 29000000) {
      return NotificationCategory.imsak;
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
    // Sunnah family: eve (27M), sahur (29M), iftar (30M).
    if (id >= 27000000 && id < 31000000) {
      return NotificationCategory.sunnah;
    }
    return NotificationCategory.other;
  }

  /// Eve reminders only (not sunnah Sahur/Iftar). Used to dismiss stacked copies.
  static bool isSunnahEve(int id) {
    return id >= 27000000 && id < 28000000;
  }

  static String label(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.sahur:
        return 'Sahur';
      case NotificationCategory.iftar:
        return 'Iftar';
      case NotificationCategory.imsak:
        return 'Imsak';
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
