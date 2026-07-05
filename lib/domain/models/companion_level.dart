/// Companion level tiers from cumulative XP.
class CompanionLevel {
  CompanionLevel._();

  static const List<int> xpThresholds = [
    0,
    100,
    250,
    500,
    900,
    1400,
    2000,
    2800,
    3800,
    5000,
  ];

  static int levelFromXp(int totalXp) {
    var level = 1;
    for (var i = 1; i < xpThresholds.length; i++) {
      if (totalXp >= xpThresholds[i]) {
        level = i + 1;
      } else {
        break;
      }
    }
    return level.clamp(1, xpThresholds.length);
  }

  static int xpForNextLevel(int currentLevel) {
    if (currentLevel >= xpThresholds.length) {
      return xpThresholds.last;
    }
    return xpThresholds[currentLevel];
  }

  /// Localized display name key suffix: companionLevelName1 .. companionLevelName10
  static String nameKeyForLevel(int level) =>
      'companionLevelName${level.clamp(1, 10)}';

  /// Tier group key for localized companion names (Mubtadi / Mumayyiz / Mujahid).
  static String tierKeyForLevel(int level) {
    if (level <= 3) return 'companionTierMubtadi';
    if (level <= 6) return 'companionTierMumayyiz';
    return 'companionTierMujahid';
  }
}
