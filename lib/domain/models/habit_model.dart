import 'package:ramadan_tracker/data/database/app_database.dart';

class HabitModel {
  final int id;
  final String key;
  final String name;
  final HabitType type;
  final int? defaultTarget;
  final int sortOrder;
  final bool isActiveDefault;

  HabitModel({
    required this.id,
    required this.key,
    required this.name,
    required this.type,
    this.defaultTarget,
    required this.sortOrder,
    required this.isActiveDefault,
  });

  factory HabitModel.fromDb(Habit habit) {
    return HabitModel(
      id: habit.id,
      key: habit.key,
      name: habit.name,
      type: habit.type == 'bool' ? HabitType.bool : HabitType.count,
      defaultTarget: habit.defaultTarget,
      sortOrder: habit.sortOrder,
      isActiveDefault: habit.isActiveDefault,
    );
  }
}

enum HabitType {
  bool,
  count,
}

class SeasonHabitModel {
  final int seasonId;
  final int habitId;
  final bool isEnabled;
  final int? targetValue;
  final bool reminderEnabled;
  final String? reminderTime;

  SeasonHabitModel({
    required this.seasonId,
    required this.habitId,
    required this.isEnabled,
    this.targetValue,
    required this.reminderEnabled,
    this.reminderTime,
  });

  factory SeasonHabitModel.fromDb(SeasonHabit sh) {
    return SeasonHabitModel(
      seasonId: sh.seasonId,
      habitId: sh.habitId,
      isEnabled: sh.isEnabled,
      targetValue: sh.targetValue,
      reminderEnabled: sh.reminderEnabled,
      reminderTime: sh.reminderTime,
    );
  }
}

