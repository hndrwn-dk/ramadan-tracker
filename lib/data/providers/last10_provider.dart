import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';

final last10StartProvider = Provider<int>((ref) {
  final seasonAsync = ref.watch(currentSeasonProvider);
  return seasonAsync.when(
    data: (season) {
      if (season == null) return 0;
      return season.days - 9;
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

final isInLast10DaysProvider = Provider<bool>((ref) {
  final dayIndex = ref.watch(currentDayIndexProvider);
  final last10Start = ref.watch(last10StartProvider);
  return dayIndex >= last10Start && dayIndex > 0;
});

final showItikafProvider = Provider<bool>((ref) {
  final isInLast10 = ref.watch(isInLast10DaysProvider);
  // TODO: Add setting for "show itikaf early"
  return isInLast10;
});

