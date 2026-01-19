import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';

final completionScoreProvider = FutureProvider.family<double, ({int seasonId, int dayIndex})>((ref, params) async {
  final database = ref.watch(databaseProvider);
  
  // Watch all dependencies to trigger rebuild when they change
  // Using ref.watch ensures the provider rebuilds when any dependency changes
  // This provider will automatically rebuild whenever:
  // - dailyEntriesProvider is invalidated (mark/unmark habits)
  // - quranDailyProvider is invalidated (update quran pages)
  // - seasonHabitsProvider is invalidated (enable/disable habits)
  // - habitsProvider is invalidated (habit definitions change)
  final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: params.seasonId, dayIndex: params.dayIndex)));
  final quranDailyAsync = ref.watch(quranDailyProvider((seasonId: params.seasonId, dayIndex: params.dayIndex)));
  final seasonHabitsAsync = ref.watch(seasonHabitsProvider(params.seasonId));
  final habitsAsync = ref.watch(habitsProvider);
  
  // Wait for all data to be available - this will rebuild when any dependency changes
  // Using .requireValue to get the value, which will throw if not loaded (provider will retry)
  // This ensures the provider rebuilds immediately when dependencies are invalidated
  final entries = entriesAsync.requireValue;
  final quranDaily = quranDailyAsync.value; // Can be null, that's OK
  final seasonHabits = seasonHabitsAsync.requireValue;
  final habits = habitsAsync.requireValue;
  
  final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();
  
  // Calculate score - this will be recalculated whenever entries, quranDaily, or habits change
  // The provider will automatically rebuild and recalculate when any watched dependency changes
  return await CompletionService.calculateCompletionScore(
    seasonId: params.seasonId,
    dayIndex: params.dayIndex,
    enabledHabits: enabledHabits,
    entries: entries,
    database: database,
    allHabits: habits,
  );
});
