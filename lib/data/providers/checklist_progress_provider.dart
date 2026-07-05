import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';

typedef ChecklistProgressParams = ({int seasonId, int dayIndex});

final checklistProgressProvider =
    FutureProvider.family<({int completed, int total}), ChecklistProgressParams>((ref, params) async {
  final database = ref.watch(databaseProvider);

  final entriesAsync = ref.watch(
    dailyEntriesProvider((seasonId: params.seasonId, dayIndex: params.dayIndex)),
  );
  ref.watch(quranDailyProvider((seasonId: params.seasonId, dayIndex: params.dayIndex)));
  final seasonHabitsAsync = ref.watch(seasonHabitsProvider(params.seasonId));
  final habitsAsync = ref.watch(habitsProvider);

  final entries = entriesAsync.requireValue;
  final seasonHabits = seasonHabitsAsync.requireValue;
  final habits = habitsAsync.requireValue;

  final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();

  return CompletionService.calculateCompletedCount(
    seasonId: params.seasonId,
    dayIndex: params.dayIndex,
    enabledHabits: enabledHabits,
    entries: entries,
    database: database,
    allHabits: habits,
  );
});
