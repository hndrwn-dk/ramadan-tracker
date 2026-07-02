import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/domain/services/achievement_service.dart';

/// Pending celebration queue (shown one at a time).
final pendingCelebrationsProvider =
    StateProvider<List<AchievementUnlock>>((ref) => []);

final unlockedAchievementsProvider = FutureProvider<List<UserAchievement>>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.userAchievementsDao.getAll();
});

final userEngagementProvider = FutureProvider<UserEngagementData>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.userEngagementDao.getOrCreate();
});

/// Evaluate achievements and enqueue any new unlocks for celebration UI.
Future<void> evaluateAchievements(
  WidgetRef ref, {
  int? seasonId,
  int? dayIndex,
}) async {
  final db = ref.read(databaseProvider);
  final unlocks = await AchievementService.evaluateAfterActivity(
    database: db,
    seasonId: seasonId,
    dayIndex: dayIndex,
  );
  if (unlocks.isEmpty) return;
  ref.invalidate(unlockedAchievementsProvider);
  ref.invalidate(userEngagementProvider);
  final pending = [...ref.read(pendingCelebrationsProvider), ...unlocks];
  ref.read(pendingCelebrationsProvider.notifier).state = pending;
}

void dismissCelebration(WidgetRef ref) {
  final pending = [...ref.read(pendingCelebrationsProvider)];
  if (pending.isEmpty) return;
  pending.removeAt(0);
  ref.read(pendingCelebrationsProvider.notifier).state = pending;
}
