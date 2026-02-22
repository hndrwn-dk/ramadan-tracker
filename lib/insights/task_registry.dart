import 'package:flutter/material.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/insights/models.dart';

class TaskDefinition {
  final TaskKey key;
  final String title;
  final IconData icon;
  final Color? colorHint;
  final TaskType type;
  final String habitKey; // matches DB habit.key

  TaskDefinition({
    required this.key,
    required this.title,
    required this.icon,
    this.colorHint,
    required this.type,
    required this.habitKey,
  });

  double calculateProgress(
    DailyEntryModel? entry,
    SeasonHabitModel? seasonHabit,
    HabitModel? habit,
  ) {
    if (entry == null) return 0.0;

    switch (type) {
      case TaskType.boolean:
        return entry.isCompleted ? 1.0 : 0.0;

      case TaskType.counter:
      case TaskType.amount:
        final target = seasonHabit?.targetValue ?? habit?.defaultTarget ?? 0;
        if (target > 0) {
          final value = entry.valueInt ?? 0;
          return (value / target).clamp(0.0, 1.0);
        } else {
          return (entry.valueInt ?? 0) > 0 ? 1.0 : 0.0;
        }

      case TaskType.composite:
        return 0.0; // Handled separately
    }
  }

  int? getTarget(SeasonHabitModel? seasonHabit, HabitModel? habit) {
    return seasonHabit?.targetValue ?? habit?.defaultTarget;
  }
}

class TaskRegistry {
  static final Map<TaskKey, TaskDefinition> _registry = {
    TaskKey.fasting: TaskDefinition(
      key: TaskKey.fasting,
      title: 'Fasting',
      icon: Icons.no_meals,
      type: TaskType.boolean,
      habitKey: 'fasting',
    ),
    TaskKey.quran: TaskDefinition(
      key: TaskKey.quran,
      title: 'Quran',
      icon: Icons.menu_book,
      type: TaskType.counter,
      habitKey: 'quran_pages',
    ),
    TaskKey.dhikr: TaskDefinition(
      key: TaskKey.dhikr,
      title: 'Dhikr',
      icon: Icons.favorite,
      type: TaskType.counter,
      habitKey: 'dhikr',
    ),
    TaskKey.taraweeh: TaskDefinition(
      key: TaskKey.taraweeh,
      title: 'Taraweeh',
      icon: Icons.nights_stay,
      type: TaskType.boolean,
      habitKey: 'taraweeh',
    ),
    TaskKey.sedekah: TaskDefinition(
      key: TaskKey.sedekah,
      title: 'Sedekah',
      icon: Icons.volunteer_activism,
      type: TaskType.amount,
      habitKey: 'sedekah',
    ),
    TaskKey.prayers5: TaskDefinition(
      key: TaskKey.prayers5,
      title: '5 Prayers',
      icon: Icons.mosque,
      type: TaskType.composite,
      habitKey: 'prayers', // May not exist in DB yet
    ),
    TaskKey.itikaf: TaskDefinition(
      key: TaskKey.itikaf,
      title: 'I\'tikaf',
      icon: Icons.mosque,
      type: TaskType.boolean,
      habitKey: 'itikaf',
    ),
  };

  static TaskDefinition? getTask(TaskKey key) {
    return _registry[key];
  }

  static TaskDefinition? getTaskByHabitKey(String habitKey) {
    try {
      return _registry.values.firstWhere(
        (task) => task.habitKey == habitKey,
      );
    } catch (e) {
      return null;
    }
  }

  static List<TaskDefinition> getAllTasks() {
    return _registry.values.toList();
  }

  static TaskKey? getTaskKeyByHabitKey(String habitKey) {
    try {
      return getTaskByHabitKey(habitKey)?.key;
    } catch (e) {
      return null;
    }
  }
}

