import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Days 1..10 (or through [throughDay] when earlier) with at least one habit
/// completed by [CompletionService].
Future<int> countFilledChecklistDays({
  required AppDatabase database,
  required int seasonId,
  required int throughDay,
}) async {
  final last = throughDay < 10 ? throughDay : 10;
  if (last < 1) return 0;

  final habits =
      (await database.habitsDao.getAllHabits()).map(HabitModel.fromDb).toList();
  final enabled = (await database.seasonHabitsDao.getSeasonHabits(seasonId))
      .map(SeasonHabitModel.fromDb)
      .where((habit) => habit.isEnabled)
      .toList();
  final rows = await database.dailyEntriesDao.getAllSeasonEntries(seasonId);

  var filled = 0;
  for (var day = 1; day <= last; day++) {
    final entries = rows
        .where((row) => row.dayIndex == day)
        .map(
          (row) => DailyEntryModel(
            seasonId: row.seasonId,
            dayIndex: row.dayIndex,
            habitId: row.habitId,
            valueBool: row.valueBool,
            valueInt: row.valueInt,
            note: row.note,
            updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
          ),
        )
        .toList();
    final progress = await CompletionService.calculateCompletedCount(
      seasonId: seasonId,
      dayIndex: day,
      enabledHabits: enabled,
      entries: entries,
      database: database,
      allHabits: habits,
    );
    if (progress.completed >= 1) filled++;
  }
  return filled;
}

/// Logged sunnah fasts. Excused rows and qadha make-up days stay out.
int countRecordedSunnahFasts(Iterable<SunnahFast> rows) {
  return rows
      .where((row) => row.status == FastingStatus.fasted && !row.isQadha)
      .length;
}
