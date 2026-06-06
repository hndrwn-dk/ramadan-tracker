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
  TextColumn get mood => text().nullable()(); // 'excellent', 'good', 'ok', 'difficult'
  IntColumn get createdAt => integer()();
}

class PrayerDetails extends Table {
  IntColumn get seasonId => integer()();
  IntColumn get dayIndex => integer()();
  BoolColumn get fajr => boolean().withDefault(const Constant(false))();
  BoolColumn get dhuhr => boolean().withDefault(const Constant(false))();
  BoolColumn get asr => boolean().withDefault(const Constant(false))();
  BoolColumn get maghrib => boolean().withDefault(const Constant(false))();
  BoolColumn get isha => boolean().withDefault(const Constant(false))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {seasonId, dayIndex};
}

class KvSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Year-round sunnah fasting log, keyed by Gregorian date (not by season).
/// status reuses FastingStatus: 0 notDone, 1 fasted, 2..5 excused.
class SunnahFasts extends Table {
  TextColumn get dateYmd => text()(); // 'YYYY-MM-DD' (local date)
  IntColumn get status => integer().withDefault(const Constant(1))();
  TextColumn get type => text().nullable()(); // SunnahType.key or 'custom'
  BoolColumn get isQadha => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {dateYmd};
}

/// Qadha (make-up fasts) and Fidyah ledger. Each row is a debit ('owed') or
/// credit ('paid') so the balance stays auditable.
class QadhaLedger extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => text()(); // 'qadha' | 'fidyah'
  TextColumn get direction => text()(); // 'owed' | 'paid'
  IntColumn get days => integer().withDefault(const Constant(0))();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  TextColumn get dateYmd => text().nullable()();
  IntColumn get sourceSeasonId => integer().nullable()();
  TextColumn get note => text().nullable()();
  IntColumn get createdAt => integer()();
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

