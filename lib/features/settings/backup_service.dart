import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';

class BackupService {
  static const int schemaVersion = 1;

  static Future<String> exportBackup(AppDatabase database) async {
    final backup = <String, dynamic>{
      'schema_version': schemaVersion,
      'exported_at': DateTime.now().toIso8601String(),
      'seasons': [],
      'habits': [],
      'season_habits': [],
      'daily_entries': [],
      'quran_plans': [],
      'quran_daily': [],
      'dhikr_plans': [],
      'notes': [],
      'settings': [],
    };

    final seasons = await database.ramadanSeasonsDao.getAllSeasons();
    backup['seasons'] = seasons.map((s) => {
      'id': s.id,
      'label': s.label,
      'start_date': s.startDate,
      'days': s.days,
      'created_at': s.createdAt,
    }).toList();

    final habits = await database.habitsDao.getAllHabits();
    backup['habits'] = habits.map((h) => {
      'id': h.id,
      'key': h.key,
      'name': h.name,
      'type': h.type,
      'default_target': h.defaultTarget,
      'sort_order': h.sortOrder,
      'is_active_default': h.isActiveDefault,
    }).toList();

    for (final season in seasons) {
      final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(season.id);
      backup['season_habits'].addAll(seasonHabits.map((sh) => {
        'season_id': sh.seasonId,
        'habit_id': sh.habitId,
        'is_enabled': sh.isEnabled,
        'target_value': sh.targetValue,
        'reminder_enabled': sh.reminderEnabled,
        'reminder_time': sh.reminderTime,
      }));

      for (int day = 1; day <= season.days; day++) {
        final entries = await database.dailyEntriesDao.getDayEntries(season.id, day);
        backup['daily_entries'].addAll(entries.map((e) => {
          'season_id': e.seasonId,
          'day_index': e.dayIndex,
          'habit_id': e.habitId,
          'value_bool': e.valueBool,
          'value_int': e.valueInt,
          'note': e.note,
          'updated_at': e.updatedAt,
        }));

        final quranDaily = await database.quranDailyDao.getDaily(season.id, day);
        if (quranDaily != null) {
          backup['quran_daily'].add({
            'season_id': quranDaily.seasonId,
            'day_index': quranDaily.dayIndex,
            'pages_read': quranDaily.pagesRead,
            'updated_at': quranDaily.updatedAt,
          });
        }
      }

      final quranPlan = await database.quranPlanDao.getPlan(season.id);
      if (quranPlan != null) {
        backup['quran_plans'].add({
          'season_id': quranPlan.seasonId,
          'pages_per_juz': quranPlan.pagesPerJuz,
          'juz_target_per_day': quranPlan.juzTargetPerDay,
          'daily_target_pages': quranPlan.dailyTargetPages,
          'total_juz': quranPlan.totalJuz,
          'total_pages': quranPlan.totalPages,
          'catchup_cap_pages': quranPlan.catchupCapPages,
          'created_at': quranPlan.createdAt,
        });
      }

      final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
      if (dhikrPlan != null) {
        backup['dhikr_plans'].add({
          'season_id': dhikrPlan.seasonId,
          'daily_target': dhikrPlan.dailyTarget,
          'created_at': dhikrPlan.createdAt,
        });
      }
    }

      final allNotes = <Note>[];
      for (final season in seasons) {
        final notes = await database.notesDao.getDayNotes(season.id, null);
        allNotes.addAll(notes);
      }
      backup['notes'] = allNotes.map((n) => {
      'id': n.id,
      'season_id': n.seasonId,
      'day_index': n.dayIndex,
      'title': n.title,
      'body': n.body,
      'created_at': n.createdAt,
    }).toList();

    return const JsonEncoder.withIndent('  ').convert(backup);
  }

  static Future<void> importBackup(AppDatabase database, String jsonContent) async {
    final backup = jsonDecode(jsonContent) as Map<String, dynamic>;

    if (backup['schema_version'] != schemaVersion) {
      throw Exception('Unsupported backup version');
    }

    await database.transaction(() async {
      await database.delete(database.ramadanSeasons).go();
      await database.delete(database.habits).go();
      await database.delete(database.seasonHabits).go();
      await database.delete(database.dailyEntries).go();
      await database.delete(database.quranPlan).go();
      await database.delete(database.quranDaily).go();
      await database.delete(database.dhikrPlan).go();
      await database.delete(database.notes).go();
      await database.delete(database.kvSettings).go();

      final seasons = backup['seasons'] as List;
      for (final s in seasons) {
        await database.ramadanSeasonsDao.createSeason(
          label: s['label'] as String,
          startDate: DateTime.parse(s['start_date'] as String),
          days: s['days'] as int,
        );
      }

      final habits = backup['habits'] as List;
      for (final h in habits) {
        await database.into(database.habits).insert(
          HabitsCompanion.insert(
            key: h['key'] as String,
            name: h['name'] as String,
            type: h['type'] as String,
            defaultTarget: Value(h['default_target'] as int?),
            sortOrder: h['sort_order'] as int,
            isActiveDefault: h['is_active_default'] as bool,
          ),
        );
      }

      final seasonHabits = backup['season_habits'] as List;
      for (final sh in seasonHabits) {
        await database.into(database.seasonHabits).insert(
          SeasonHabitsCompanion.insert(
            seasonId: sh['season_id'] as int,
            habitId: sh['habit_id'] as int,
            isEnabled: sh['is_enabled'] as bool,
            targetValue: Value(sh['target_value'] as int?),
            reminderEnabled: sh['reminder_enabled'] as bool,
            reminderTime: Value(sh['reminder_time'] as String?),
          ),
        );
      }

      final dailyEntries = backup['daily_entries'] as List;
      for (final e in dailyEntries) {
        await database.into(database.dailyEntries).insert(
          DailyEntriesCompanion.insert(
            seasonId: e['season_id'] as int,
            dayIndex: e['day_index'] as int,
            habitId: e['habit_id'] as int,
            valueBool: Value(e['value_bool'] as bool?),
            valueInt: Value(e['value_int'] as int?),
            note: Value(e['note'] as String?),
            updatedAt: e['updated_at'] as int,
          ),
        );
      }

      final quranPlans = backup['quran_plans'] as List;
      for (final p in quranPlans) {
        await database.into(database.quranPlan).insert(
          QuranPlanData(
            seasonId: p['season_id'] as int,
            pagesPerJuz: p['pages_per_juz'] as int? ?? 20,
            juzTargetPerDay: p['juz_target_per_day'] as int? ?? 1,
            dailyTargetPages: p['daily_target_pages'] as int,
            totalJuz: p['total_juz'] as int? ?? 30,
            totalPages: p['total_pages'] as int,
            catchupCapPages: p['catchup_cap_pages'] as int,
            createdAt: p['created_at'] as int,
          ),
        );
      }

      final quranDaily = backup['quran_daily'] as List;
      for (final d in quranDaily) {
        await database.into(database.quranDaily).insert(
          QuranDailyCompanion.insert(
            seasonId: d['season_id'] as int,
            dayIndex: d['day_index'] as int,
            pagesRead: Value(d['pages_read'] as int),
            updatedAt: d['updated_at'] as int,
          ),
        );
      }

      final dhikrPlans = backup['dhikr_plans'] as List;
      for (final p in dhikrPlans) {
        await database.into(database.dhikrPlan).insert(
          DhikrPlanData(
            seasonId: p['season_id'] as int,
            dailyTarget: p['daily_target'] as int,
            createdAt: p['created_at'] as int,
          ),
        );
      }

      final notes = backup['notes'] as List;
      for (final n in notes) {
        await database.into(database.notes).insert(
          NotesCompanion.insert(
            seasonId: n['season_id'] as int,
            dayIndex: Value(n['day_index'] as int?),
            title: Value(n['title'] as String?),
            body: n['body'] as String,
            createdAt: n['created_at'] as int,
          ),
        );
      }
    });
  }
}

