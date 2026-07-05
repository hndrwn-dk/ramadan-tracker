import 'dart:convert';

import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

/// Generates and tracks 3 daily quests per active season day.
class DailyQuestService {
  DailyQuestService._();

  static const int questsPerDay = 3;
  static const int questXp = 15;

  static String _storageKey(int seasonId, int dayIndex) =>
      'daily_quests_s${seasonId}_d$dayIndex';

  static Future<List<DailyQuest>> questsForDay({
    required AppDatabase database,
    required int seasonId,
    required int dayIndex,
  }) async {
    final stored = await database.kvSettingsDao.getValue(_storageKey(seasonId, dayIndex));
    if (stored != null && stored.isNotEmpty) {
      final ids = (jsonDecode(stored) as List).cast<String>();
      return ids.map((id) => _questForId(id)).whereType<DailyQuest>().toList();
    }

    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
    final habits = await database.habitsDao.getAllHabits();
    final enabledKeys = <String>{};
    for (final sh in seasonHabits.where((s) => s.isEnabled)) {
      final h = habits.where((habit) => habit.id == sh.habitId).firstOrNull;
      if (h != null) enabledKeys.add(h.key);
    }

    final pool = <DailyQuest>[];
    if (enabledKeys.contains('fasting')) {
      pool.add(const DailyQuest(id: 'log_fasting', titleKey: 'questLogFasting', xpReward: questXp));
    }
    if (enabledKeys.contains('quran_pages')) {
      pool.add(const DailyQuest(id: 'log_quran', titleKey: 'questLogQuran', xpReward: questXp));
    }
    if (enabledKeys.contains('prayers')) {
      pool.add(const DailyQuest(id: 'log_prayers', titleKey: 'questLogPrayers', xpReward: questXp));
    }
    if (enabledKeys.contains('dhikr')) {
      pool.add(const DailyQuest(id: 'log_dhikr', titleKey: 'questLogDhikr', xpReward: questXp));
    }
    if (enabledKeys.contains('taraweeh')) {
      pool.add(const DailyQuest(id: 'log_taraweeh', titleKey: 'questLogTaraweeh', xpReward: questXp));
    }
    pool.add(const DailyQuest(id: 'score_60', titleKey: 'questScore60', xpReward: questXp));

    pool.sort((a, b) => a.id.compareTo(b.id));
    final offset = dayIndex % (pool.length > questsPerDay ? pool.length - questsPerDay + 1 : 1);
    final selected = pool.skip(offset).take(questsPerDay).toList();
    if (selected.length < questsPerDay && pool.isNotEmpty) {
      selected.addAll(pool.take(questsPerDay - selected.length));
    }

    await database.kvSettingsDao.setValue(
      _storageKey(seasonId, dayIndex),
      jsonEncode(selected.map((q) => q.id).toList()),
    );
    return selected;
  }

  static DailyQuest? _questForId(String id) {
    const catalog = {
      'log_fasting': DailyQuest(id: 'log_fasting', titleKey: 'questLogFasting', xpReward: questXp),
      'log_quran': DailyQuest(id: 'log_quran', titleKey: 'questLogQuran', xpReward: questXp),
      'log_prayers': DailyQuest(id: 'log_prayers', titleKey: 'questLogPrayers', xpReward: questXp),
      'log_dhikr': DailyQuest(id: 'log_dhikr', titleKey: 'questLogDhikr', xpReward: questXp),
      'log_taraweeh': DailyQuest(id: 'log_taraweeh', titleKey: 'questLogTaraweeh', xpReward: questXp),
      'score_60': DailyQuest(id: 'score_60', titleKey: 'questScore60', xpReward: questXp),
    };
    return catalog[id];
  }

  static String _progressKey(int seasonId, int dayIndex) =>
      'daily_quest_progress_s${seasonId}_d$dayIndex';

  static Future<Set<String>> completedQuestIds({
    required AppDatabase database,
    required int seasonId,
    required int dayIndex,
  }) async {
    final raw = await database.kvSettingsDao.getValue(_progressKey(seasonId, dayIndex));
    if (raw == null || raw.isEmpty) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  static Future<List<DailyQuestProgress>> evaluateProgress({
    required AppDatabase database,
    required int seasonId,
    required int dayIndex,
  }) async {
    final quests = await questsForDay(database: database, seasonId: seasonId, dayIndex: dayIndex);
    final completed = await completedQuestIds(
      database: database,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );

    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final habits = await database.habitsDao.getAllHabits();
    final habitById = {for (final h in habits) h.id: h.key};

    final score = await _dayScore(database, seasonId, dayIndex);
    final newlyCompleted = <String>[];

    for (final quest in quests) {
      if (completed.contains(quest.id)) continue;
      final done = await _isQuestDone(
        quest.id,
        entries: entries,
        habitById: habitById,
        score: score,
        database: database,
        seasonId: seasonId,
        dayIndex: dayIndex,
      );
      if (done) newlyCompleted.add(quest.id);
    }

    if (newlyCompleted.isNotEmpty) {
      final all = {...completed, ...newlyCompleted};
      await database.kvSettingsDao.setValue(
        _progressKey(seasonId, dayIndex),
        jsonEncode(all.toList()),
      );
      for (final _ in newlyCompleted) {
        await database.userEngagementDao.addXp(questXp);
      }
    }

    final finalCompleted = {...completed, ...newlyCompleted};
    return quests
        .map((q) => DailyQuestProgress(
              questId: q.id,
              completed: finalCompleted.contains(q.id),
            ))
        .toList();
  }

  static Future<bool> _isQuestDone(
    String questId, {
    required List<DailyEntry> entries,
    required Map<int, String> habitById,
    required double score,
    required AppDatabase database,
    required int seasonId,
    required int dayIndex,
  }) async {
    switch (questId) {
      case 'log_fasting':
        return entries.any((e) {
          final key = habitById[e.habitId];
          return key == 'fasting' &&
              FastingStatus.isCompletedForDay(e.valueInt, e.valueBool);
        });
      case 'log_quran':
        final daily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
        return (daily?.pagesRead ?? 0) > 0;
      case 'log_prayers':
        return entries.any((e) {
          final key = habitById[e.habitId];
          return key == 'prayers' && (e.valueBool == true || (e.valueInt ?? 0) > 0);
        });
      case 'log_dhikr':
        return entries.any((e) {
          final key = habitById[e.habitId];
          return key == 'dhikr' && (e.valueInt ?? 0) > 0;
        });
      case 'log_taraweeh':
        return entries.any((e) {
          final key = habitById[e.habitId];
          return key == 'taraweeh' && e.valueBool == true;
        });
      case 'score_60':
        return score >= 60;
      default:
        return false;
    }
  }

  static Future<double> _dayScore(
    AppDatabase database,
    int seasonId,
    int dayIndex,
  ) async {
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
    final enabled = seasonHabits.where((sh) => sh.isEnabled).toList();
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final habits = await database.habitsDao.getAllHabits();
    final entryModels = entries
        .map((e) => DailyEntryModel(
              seasonId: e.seasonId,
              dayIndex: e.dayIndex,
              habitId: e.habitId,
              valueBool: e.valueBool,
              valueInt: e.valueInt,
              note: e.note,
              updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
            ))
        .toList();
    return CompletionService.calculateCompletionScore(
      seasonId: seasonId,
      dayIndex: dayIndex,
      enabledHabits: enabled,
      entries: entryModels,
      database: database,
      allHabits: habits,
    );
  }

  /// Quest completion totals for the last 7 season days ending at [endDayIndex].
  static Future<WeeklyQuestSummary> weeklySummary({
    required AppDatabase database,
    required int seasonId,
    required int endDayIndex,
  }) async {
    var completed = 0;
    var total = 0;
    final start = (endDayIndex - 6).clamp(1, endDayIndex);
    for (var day = start; day <= endDayIndex; day++) {
      final progress = await evaluateProgress(
        database: database,
        seasonId: seasonId,
        dayIndex: day,
      );
      total += progress.length;
      completed += progress.where((p) => p.completed).length;
    }
    return WeeklyQuestSummary(completed: completed, total: total);
  }
}

class WeeklyQuestSummary {
  final int completed;
  final int total;

  const WeeklyQuestSummary({required this.completed, required this.total});
}
