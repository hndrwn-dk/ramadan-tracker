import 'package:drift/drift.dart';

class RamadanSeasons extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get label => text()();
  TextColumn get startDate => text()();
  IntColumn get days => integer()();
  IntColumn get createdAt => integer()();
}

class Habits extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  IntColumn get defaultTarget => integer().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isActiveDefault => boolean()();
}

class SeasonHabits extends Table {
  IntColumn get seasonId => integer()();
  IntColumn get habitId => integer()();
  BoolColumn get isEnabled => boolean()();
  IntColumn get targetValue => integer().nullable()();
  BoolColumn get reminderEnabled => boolean()();
  TextColumn get reminderTime => text().nullable()();

  @override
  Set<Column> get primaryKey => {seasonId, habitId};
}

class DailyEntries extends Table {
  IntColumn get seasonId => integer()();
  IntColumn get dayIndex => integer()();
  IntColumn get habitId => integer()();
  BoolColumn get valueBool => boolean().nullable()();
  IntColumn get valueInt => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {seasonId, dayIndex, habitId};
}

class QuranPlan extends Table {
  IntColumn get seasonId => integer()();
  IntColumn get pagesPerJuz => integer().withDefault(const Constant(20))();
  IntColumn get juzTargetPerDay => integer().withDefault(const Constant(1))();
  IntColumn get dailyTargetPages => integer()();
  IntColumn get totalJuz => integer().withDefault(const Constant(30))();
  IntColumn get totalPages => integer().withDefault(const Constant(600))();
  IntColumn get catchupCapPages => integer().withDefault(const Constant(5))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {seasonId};
}

class QuranDaily extends Table {
  IntColumn get seasonId => integer()();
  IntColumn get dayIndex => integer()();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {seasonId, dayIndex};
}

class DhikrPlan extends Table {
  IntColumn get seasonId => integer()();
  IntColumn get dailyTarget => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {seasonId};
}

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get seasonId => integer()();
  IntColumn get dayIndex => integer().nullable()();
  TextColumn get title => text().nullable()();
  TextColumn get body => text()();
  IntColumn get createdAt => integer()();
}

class KvSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class PrayerTimesCache extends Table {
  IntColumn get seasonId => integer()();
  TextColumn get dateYyyyMmDd => text()();
  TextColumn get fajrIso => text()();
  TextColumn get maghribIso => text()();
  TextColumn get method => text()();
  RealColumn get lat => real()();
  RealColumn get lon => real()();
  TextColumn get timezone => text()();
  IntColumn get fajrAdj => integer().withDefault(const Constant(0))();
  IntColumn get maghribAdj => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {seasonId, dateYyyyMmDd};
}

