import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

final seasonStateProvider = Provider<SeasonState>((ref) {
  final seasonAsync = ref.watch(currentSeasonProvider);
  return seasonAsync.when(
    data: (season) {
      if (season == null) return SeasonState.preRamadan;
      return season.getState(DateTime.now());
    },
    loading: () => SeasonState.preRamadan,
    error: (_, __) => SeasonState.preRamadan,
  );
});

final activeDayIndexForUIProvider = Provider<int>((ref) {
  final seasonAsync = ref.watch(currentSeasonProvider);
  final state = ref.watch(seasonStateProvider);
  
  return seasonAsync.when(
    data: (season) {
      if (season == null) return 1;
      final dayIndex = season.getDayIndex(DateTime.now());
      
      if (state == SeasonState.postRamadan) {
        return season.days;
      }
      
      return dayIndex;
    },
    loading: () => 1,
    error: (_, __) => 1,
  );
});

