import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/domain/services/daily_quest_service.dart';

typedef DailyQuestState = ({List<DailyQuest> quests, List<DailyQuestProgress> progress});

final dailyQuestsProvider = FutureProvider.family<DailyQuestState, ({int seasonId, int dayIndex})>(
  (ref, params) async {
    final db = ref.watch(databaseProvider);
    final quests = await DailyQuestService.questsForDay(
      database: db,
      seasonId: params.seasonId,
      dayIndex: params.dayIndex,
    );
    final progress = await DailyQuestService.evaluateProgress(
      database: db,
      seasonId: params.seasonId,
      dayIndex: params.dayIndex,
    );
    return (quests: quests, progress: progress);
  },
);

Future<void> refreshDailyQuests(
  WidgetRef ref, {
  required int seasonId,
  required int dayIndex,
}) async {
  ref.invalidate(dailyQuestsProvider((seasonId: seasonId, dayIndex: dayIndex)));
  ref.invalidate(userEngagementProvider);
}
