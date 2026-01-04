import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:ramadan_tracker/data/database/tables.dart';

part 'app_database.g.dart';
part 'daos.dart';

  @DriftDatabase(tables: [
    RamadanSeasons,
    Habits,
    SeasonHabits,
    DailyEntries,
    QuranPlan,
    QuranDaily,
    DhikrPlan,
    Notes,
    PrayerDetails,
    KvSettings,
    PrayerTimesCache,
  ], daos: [
    RamadanSeasonsDao,
    HabitsDao,
    SeasonHabitsDao,
    DailyEntriesDao,
    QuranPlanDao,
    QuranDailyDao,
    DhikrPlanDao,
    NotesDao,
    PrayerDetailsDao,
    KvSettingsDao,
    PrayerTimesCacheDao,
  ])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(quranPlan, quranPlan.pagesPerJuz);
          await migrator.addColumn(quranPlan, quranPlan.juzTargetPerDay);
          await migrator.addColumn(quranPlan, quranPlan.totalJuz);
        }
        if (from < 3) {
          await migrator.createTable(prayerTimesCache);
        }
        if (from < 4) {
          // Remove old goal_type column if it exists
          try {
            await customStatement('ALTER TABLE quran_plan DROP COLUMN goal_type');
          } catch (e) {
            // Column might not exist, ignore
          }
        }
        if (from < 5) {
          // Add mood column to Notes table
          await migrator.addColumn(notes, notes.mood);
          // Create PrayerDetails table
          await migrator.createTable(prayerDetails);
        }
      },
    );
  }

  Future<void> initialize() async {
    await _seedDefaultHabits();
    // Don't auto-create season - let onboarding handle it
    // await _ensureCurrentSeason();
  }

  Future<void> _seedDefaultHabits() async {
    final existingHabits = await habitsDao.getAllHabits();
    final existingKeys = existingHabits.map((h) => h.key).toSet();

    final defaultHabits = [
      HabitsCompanion.insert(
        key: 'fasting',
        name: 'Fasting',
        type: 'bool',
        sortOrder: 1,
        isActiveDefault: true,
      ),
      HabitsCompanion.insert(
        key: 'quran_pages',
        name: 'Quran',
        type: 'count',
        defaultTarget: const Value(20),
        sortOrder: 2,
        isActiveDefault: true,
      ),
      HabitsCompanion.insert(
        key: 'dhikr',
        name: 'Dhikr',
        type: 'count',
        defaultTarget: const Value(100),
        sortOrder: 3,
        isActiveDefault: true,
      ),
      HabitsCompanion.insert(
        key: 'taraweeh',
        name: 'Taraweeh',
        type: 'bool',
        sortOrder: 4,
        isActiveDefault: true,
      ),
      HabitsCompanion.insert(
        key: 'sedekah',
        name: 'Sedekah',
        type: 'money',
        defaultTarget: const Value(0),
        sortOrder: 5,
        isActiveDefault: true,
      ),
      HabitsCompanion.insert(
        key: 'itikaf',
        name: 'I\'tikaf',
        type: 'bool',
        sortOrder: 6,
        isActiveDefault: false,
      ),
      HabitsCompanion.insert(
        key: 'prayers',
        name: '5 Prayers',
        type: 'bool',
        sortOrder: 7,
        isActiveDefault: false,
      ),
    ];

    // Only insert habits that don't exist yet
    for (final habit in defaultHabits) {
      if (!existingKeys.contains(habit.key.value)) {
        await into(habits).insert(habit);
      }
    }
  }

  Future<void> _ensureCurrentSeason() async {
    final seasons = await ramadanSeasonsDao.getAllSeasons();
    if (seasons.isEmpty) {
      final now = DateTime.now();
      await ramadanSeasonsDao.createSeason(
        label: 'Ramadan ${now.year}',
        startDate: now,
        days: 30,
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'ramadan.db'));
    return NativeDatabase(file);
  });
}

