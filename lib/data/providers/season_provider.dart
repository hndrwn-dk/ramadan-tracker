import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/repositories/season_repository.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

final seasonRepositoryProvider = Provider<SeasonRepository>((ref) {
  final database = ref.watch(databaseProvider);
  return SeasonRepository(database);
});

final currentSeasonProvider = FutureProvider<SeasonModel?>((ref) async {
  final repository = ref.watch(seasonRepositoryProvider);
  return await repository.getCurrentSeason();
});

final allSeasonsProvider = FutureProvider<List<SeasonModel>>((ref) async {
  final repository = ref.watch(seasonRepositoryProvider);
  return await repository.getAllSeasons();
});

final currentDayIndexProvider = Provider<int>((ref) {
  final seasonAsync = ref.watch(currentSeasonProvider);
  return seasonAsync.when(
    data: (season) {
      if (season == null) return 1;
      final now = DateTime.now();
      return season.getDayIndex(now);
    },
    loading: () => 1,
    error: (_, __) => 1,
  );
});

