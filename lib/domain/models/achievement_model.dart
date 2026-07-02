import 'package:flutter/material.dart';

/// Static achievement definition (not stored in DB).
class AchievementDefinition {
  final String key;
  final String titleKey;
  final String descriptionKey;
  final int xpReward;
  final IconData icon;

  const AchievementDefinition({
    required this.key,
    required this.titleKey,
    required this.descriptionKey,
    required this.xpReward,
    required this.icon,
  });
}

/// Result returned when a new achievement is unlocked.
class AchievementUnlock {
  final AchievementDefinition definition;
  final int xpAwarded;
  final DateTime unlockedAt;

  const AchievementUnlock({
    required this.definition,
    required this.xpAwarded,
    required this.unlockedAt,
  });
}

/// Catalog of launch achievements.
class AchievementCatalog {
  AchievementCatalog._();

  static const List<AchievementDefinition> all = [
    AchievementDefinition(
      key: 'first_log',
      titleKey: 'achievementFirstLogTitle',
      descriptionKey: 'achievementFirstLogDesc',
      xpReward: 10,
      icon: Icons.edit_note,
    ),
    AchievementDefinition(
      key: 'first_full_day',
      titleKey: 'achievementFirstFullDayTitle',
      descriptionKey: 'achievementFirstFullDayDesc',
      xpReward: 25,
      icon: Icons.star_outline,
    ),
    AchievementDefinition(
      key: 'streak_3',
      titleKey: 'achievementStreak3Title',
      descriptionKey: 'achievementStreak3Desc',
      xpReward: 30,
      icon: Icons.local_fire_department_outlined,
    ),
    AchievementDefinition(
      key: 'streak_7',
      titleKey: 'achievementStreak7Title',
      descriptionKey: 'achievementStreak7Desc',
      xpReward: 50,
      icon: Icons.local_fire_department,
    ),
    AchievementDefinition(
      key: 'streak_14',
      titleKey: 'achievementStreak14Title',
      descriptionKey: 'achievementStreak14Desc',
      xpReward: 75,
      icon: Icons.whatshot,
    ),
    AchievementDefinition(
      key: 'quran_half',
      titleKey: 'achievementQuranHalfTitle',
      descriptionKey: 'achievementQuranHalfDesc',
      xpReward: 40,
      icon: Icons.menu_book_outlined,
    ),
    AchievementDefinition(
      key: 'quran_complete',
      titleKey: 'achievementQuranCompleteTitle',
      descriptionKey: 'achievementQuranCompleteDesc',
      xpReward: 100,
      icon: Icons.menu_book,
    ),
    AchievementDefinition(
      key: 'season_complete',
      titleKey: 'achievementSeasonCompleteTitle',
      descriptionKey: 'achievementSeasonCompleteDesc',
      xpReward: 150,
      icon: Icons.celebration_outlined,
    ),
    AchievementDefinition(
      key: 'first_sunnah',
      titleKey: 'achievementFirstSunnahTitle',
      descriptionKey: 'achievementFirstSunnahDesc',
      xpReward: 20,
      icon: Icons.nightlight_outlined,
    ),
    AchievementDefinition(
      key: 'senin_kamis_4',
      titleKey: 'achievementSeninKamis4Title',
      descriptionKey: 'achievementSeninKamis4Desc',
      xpReward: 40,
      icon: Icons.calendar_view_week,
    ),
    AchievementDefinition(
      key: 'shawwal_complete',
      titleKey: 'achievementShawwalCompleteTitle',
      descriptionKey: 'achievementShawwalCompleteDesc',
      xpReward: 60,
      icon: Icons.auto_awesome,
    ),
    AchievementDefinition(
      key: 'reflection_first',
      titleKey: 'achievementReflectionFirstTitle',
      descriptionKey: 'achievementReflectionFirstDesc',
      xpReward: 15,
      icon: Icons.edit_outlined,
    ),
    AchievementDefinition(
      key: 'last_10_hero',
      titleKey: 'achievementLast10Title',
      descriptionKey: 'achievementLast10Desc',
      xpReward: 35,
      icon: Icons.nights_stay,
    ),
    AchievementDefinition(
      key: 'weekly_perfect',
      titleKey: 'achievementWeeklyPerfectTitle',
      descriptionKey: 'achievementWeeklyPerfectDesc',
      xpReward: 80,
      icon: Icons.verified_outlined,
    ),
    AchievementDefinition(
      key: 'companion_level_5',
      titleKey: 'achievementLevel5Title',
      descriptionKey: 'achievementLevel5Desc',
      xpReward: 0,
      icon: Icons.military_tech_outlined,
    ),
  ];

  static AchievementDefinition? byKey(String key) {
    for (final a in all) {
      if (a.key == key) return a;
    }
    return null;
  }
}
