import 'dart:convert';

import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Prep micro-goals before Ramadan starts (KV only, no active season day).
class PreRamadanQuestService {
  PreRamadanQuestService._();

  static const int questsPerDay = 2;
  static const int questXp = 10;

  static String _questKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return 'pre_ramadan_quests_${d.year}_${d.month}_${d.day}';
  }

  static String _progressKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return 'pre_ramadan_quest_progress_${d.year}_${d.month}_${d.day}';
  }

  static const _catalog = <String, DailyQuest>{
    'prep_review_plan': DailyQuest(
      id: 'prep_review_plan',
      titleKey: 'preRamadanQuestReviewPlan',
      xpReward: questXp,
    ),
    'prep_log_sunnah': DailyQuest(
      id: 'prep_log_sunnah',
      titleKey: 'preRamadanQuestLogSunnah',
      xpReward: questXp,
    ),
    'prep_setup_reminders': DailyQuest(
      id: 'prep_setup_reminders',
      titleKey: 'preRamadanQuestReminders',
      xpReward: questXp,
    ),
    'prep_create_season': DailyQuest(
      id: 'prep_create_season',
      titleKey: 'preRamadanQuestCreateSeason',
      xpReward: questXp,
    ),
  };

  static Future<List<DailyQuest>> questsForToday(AppDatabase database) async {
    final today = DateTime.now();
    final stored = await database.kvSettingsDao.getValue(_questKey(today));
    if (stored != null && stored.isNotEmpty) {
      final ids = (jsonDecode(stored) as List).cast<String>();
      return ids.map((id) => _catalog[id]).whereType<DailyQuest>().toList();
    }

    final pool = _catalog.values.toList()..sort((a, b) => a.id.compareTo(b.id));
    final offset = today.day % pool.length;
    final selected = pool.skip(offset).take(questsPerDay).toList();
    if (selected.length < questsPerDay) {
      selected.addAll(pool.take(questsPerDay - selected.length));
    }

    await database.kvSettingsDao.setValue(
      _questKey(today),
      jsonEncode(selected.map((q) => q.id).toList()),
    );
    return selected;
  }

  static Future<List<DailyQuestProgress>> evaluateProgress(
    AppDatabase database,
  ) async {
    final today = DateTime.now();
    final quests = await questsForToday(database);
    final raw = await database.kvSettingsDao.getValue(_progressKey(today));
    final completed = raw == null || raw.isEmpty
        ? <String>{}
        : (jsonDecode(raw) as List).cast<String>().toSet();

    final seasons = await database.ramadanSeasonsDao.getAllSeasons();
    final todayNorm = DateTime(today.year, today.month, today.day);
    final hasUpcomingSeason = seasons.any((s) {
      final start = DateTime.parse(s.startDate);
      final startNorm = DateTime(start.year, start.month, start.day);
      return startNorm.isAfter(todayNorm);
    });
    final planReviewed =
        await database.kvSettingsDao.getValue('plan_review_ack') == 'true';
    final sunnahRows = await database.sunnahFastsDao.getAll();
    final loggedSunnahToday = sunnahRows.any((r) {
      final parts = r.dateYmd.split('-');
      if (parts.length != 3) return false;
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      return y == today.year &&
          m == today.month &&
          d == today.day &&
          r.status == FastingStatus.fasted;
    });
    final remindersOn =
        await database.kvSettingsDao.getValue('sahur_reminder_enabled');
    final remindersConfigured = remindersOn == 'true';

    final newlyDone = <String>[];
    for (final q in quests) {
      if (completed.contains(q.id)) continue;
      final done = switch (q.id) {
        'prep_review_plan' => planReviewed,
        'prep_log_sunnah' => loggedSunnahToday,
        'prep_setup_reminders' => remindersConfigured,
        'prep_create_season' => hasUpcomingSeason,
        _ => false,
      };
      if (done) newlyDone.add(q.id);
    }

    if (newlyDone.isNotEmpty) {
      final all = {...completed, ...newlyDone};
      await database.kvSettingsDao.setValue(
        _progressKey(today),
        jsonEncode(all.toList()),
      );
      for (final _ in newlyDone) {
        await database.userEngagementDao.addXp(questXp);
      }
    }

    final finalDone = {...completed, ...newlyDone};
    return quests
        .map((q) => DailyQuestProgress(
              questId: q.id,
              completed: finalDone.contains(q.id),
            ))
        .toList();
  }
}
