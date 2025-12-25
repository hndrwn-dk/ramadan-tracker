import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';

final dailyEntriesProvider = FutureProvider.family<List<DailyEntryModel>, ({int seasonId, int dayIndex})>((ref, params) async {
  final database = ref.watch(databaseProvider);
  final entries = await database.dailyEntriesDao.getDayEntries(params.seasonId, params.dayIndex);
  return entries.map((e) => DailyEntryModel(
    seasonId: e.seasonId,
    dayIndex: e.dayIndex,
    habitId: e.habitId,
    valueBool: e.valueBool,
    valueInt: e.valueInt,
    note: e.note,
    updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
  )).toList();
});

