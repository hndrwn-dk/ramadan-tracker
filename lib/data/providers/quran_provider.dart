import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';

final quranPlanProvider = FutureProvider.family<QuranPlanData?, int>((ref, seasonId) async {
  final database = ref.watch(databaseProvider);
  return await database.quranPlanDao.getPlan(seasonId);
});

final quranDailyProvider = FutureProvider.family<QuranDailyData?, ({int seasonId, int dayIndex})>((ref, params) async {
  final database = ref.watch(databaseProvider);
  return await database.quranDailyDao.getDaily(params.seasonId, params.dayIndex);
});

