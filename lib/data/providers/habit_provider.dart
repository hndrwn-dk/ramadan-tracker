import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';

final habitsProvider = FutureProvider<List<HabitModel>>((ref) async {
  final database = ref.watch(databaseProvider);
  final habits = await database.habitsDao.getAllHabits();
  return habits.map((h) => HabitModel.fromDb(h)).toList();
});

final seasonHabitsProvider = FutureProvider.family<List<SeasonHabitModel>, int>((ref, seasonId) async {
  final database = ref.watch(databaseProvider);
  final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
  return seasonHabits.map((sh) => SeasonHabitModel.fromDb(sh)).toList();
});

