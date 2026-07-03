import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';

/// Day indices (1-based) in the current season that have at least one achievement unlock.
final achievementDayIndicesProvider = FutureProvider<Set<int>>((ref) async {
  final season = await ref.watch(currentSeasonProvider.future);
  if (season == null) return {};

  final db = ref.watch(databaseProvider);
  final achievements = await db.userAchievementsDao.getAll();
  if (achievements.isEmpty) return {};

  final start = DateTime(season.startDate.year, season.startDate.month, season.startDate.day);
  final indices = <int>{};

  for (final a in achievements) {
    final unlocked = DateTime.fromMillisecondsSinceEpoch(a.unlockedAt);
    final day = DateTime(unlocked.year, unlocked.month, unlocked.day);
    final diff = day.difference(start).inDays + 1;
    if (diff >= 1 && diff <= season.days) {
      indices.add(diff);
    }
  }
  return indices;
});

/// Achievement keys unlocked within the last 7 calendar days (device local).
final recentWeeklyAchievementKeysProvider = FutureProvider<List<String>>((ref) async {
  final db = ref.watch(databaseProvider);
  final achievements = await db.userAchievementsDao.getAll();
  final cutoff = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
  return achievements
      .where((a) => a.unlockedAt >= cutoff)
      .map((a) => a.achievementKey)
      .toList();
});
