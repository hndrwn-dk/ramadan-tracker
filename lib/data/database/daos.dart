part of 'app_database.dart';

@DriftAccessor(tables: [RamadanSeasons])
class RamadanSeasonsDao extends DatabaseAccessor<AppDatabase>
    with _$RamadanSeasonsDaoMixin {
  RamadanSeasonsDao(AppDatabase db) : super(db);

  Future<List<RamadanSeason>> getAllSeasons() {
    return (select(ramadanSeasons)..orderBy([(s) => OrderingTerm.desc(s.createdAt)])).get();
  }

  Future<RamadanSeason?> getSeasonById(int id) {
    return (select(ramadanSeasons)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<int> createSeason({
    required String label,
    required DateTime startDate,
    required int days,
  }) {
    return into(ramadanSeasons).insert(
      RamadanSeasonsCompanion.insert(
        label: label,
        startDate: startDate.toIso8601String().split('T')[0],
        days: days,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateSeason(RamadanSeason season) {
    return update(ramadanSeasons).replace(season);
  }

  Future<int> deleteSeason(int id) {
    return (delete(ramadanSeasons)..where((s) => s.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [Habits])
class HabitsDao extends DatabaseAccessor<AppDatabase> with _$HabitsDaoMixin {
  HabitsDao(AppDatabase db) : super(db);

  Future<List<Habit>> getAllHabits() {
    return (select(habits)..orderBy([(h) => OrderingTerm.asc(h.sortOrder)])).get();
  }

  Future<Habit?> getHabitByKey(String key) {
    return (select(habits)..where((h) => h.key.equals(key))).getSingleOrNull();
  }

  Future<Habit?> getHabitById(int id) {
    return (select(habits)..where((h) => h.id.equals(id))).getSingleOrNull();
  }
}

@DriftAccessor(tables: [SeasonHabits])
class SeasonHabitsDao extends DatabaseAccessor<AppDatabase>
    with _$SeasonHabitsDaoMixin {
  SeasonHabitsDao(AppDatabase db) : super(db);

  Future<List<SeasonHabit>> getSeasonHabits(int seasonId) {
    return (select(seasonHabits)
          ..where((sh) => sh.seasonId.equals(seasonId)))
        .get();
  }

  Future<SeasonHabit?> getSeasonHabit(int seasonId, int habitId) {
    return (select(seasonHabits)
          ..where((sh) => sh.seasonId.equals(seasonId) & sh.habitId.equals(habitId)))
        .getSingleOrNull();
  }

  Future<void> setSeasonHabit(SeasonHabit seasonHabit) async {
    await into(seasonHabits).insertOnConflictUpdate(seasonHabit);
  }

  Future<void> initializeSeasonHabits(int seasonId, List<Habit> allHabits) async {
    for (final habit in allHabits) {
      final existing = await getSeasonHabit(seasonId, habit.id);
      if (existing == null) {
        await into(seasonHabits).insert(
          SeasonHabitsCompanion.insert(
            seasonId: seasonId,
            habitId: habit.id,
            isEnabled: habit.isActiveDefault,
            targetValue: Value(habit.defaultTarget),
            reminderEnabled: false,
          ),
        );
      }
    }
  }
}

@DriftAccessor(tables: [DailyEntries])
class DailyEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$DailyEntriesDaoMixin {
  DailyEntriesDao(AppDatabase db) : super(db);

  Future<List<DailyEntry>> getDayEntries(int seasonId, int dayIndex) {
    return (select(dailyEntries)
          ..where((e) =>
              e.seasonId.equals(seasonId) & e.dayIndex.equals(dayIndex)))
        .get();
  }

  Future<DailyEntry?> getEntry(int seasonId, int dayIndex, int habitId) {
    return (select(dailyEntries)
          ..where((e) =>
              e.seasonId.equals(seasonId) &
              e.dayIndex.equals(dayIndex) &
              e.habitId.equals(habitId)))
        .getSingleOrNull();
  }

  Future<void> setEntry(DailyEntry entry) async {
    await into(dailyEntries).insertOnConflictUpdate(entry);
  }

  Future<void> setBoolValue(
    int seasonId,
    int dayIndex,
    int habitId,
    bool value,
  ) {
    return into(dailyEntries).insertOnConflictUpdate(
      DailyEntriesCompanion.insert(
        seasonId: seasonId,
        dayIndex: dayIndex,
        habitId: habitId,
        valueBool: Value(value),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> setIntValue(
    int seasonId,
    int dayIndex,
    int habitId,
    int value,
  ) {
    return into(dailyEntries).insertOnConflictUpdate(
      DailyEntriesCompanion.insert(
        seasonId: seasonId,
        dayIndex: dayIndex,
        habitId: habitId,
        valueInt: Value(value),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> setNote(
    int seasonId,
    int dayIndex,
    int habitId,
    String? note,
  ) {
    return into(dailyEntries).insertOnConflictUpdate(
      DailyEntriesCompanion.insert(
        seasonId: seasonId,
        dayIndex: dayIndex,
        habitId: habitId,
        note: Value(note),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<DailyEntry>> getAllSeasonEntries(int seasonId) {
    return (select(dailyEntries)
          ..where((e) => e.seasonId.equals(seasonId))
          ..orderBy([(e) => OrderingTerm.asc(e.dayIndex)]))
        .get();
  }
}

@DriftAccessor(tables: [QuranPlan])
class QuranPlanDao extends DatabaseAccessor<AppDatabase>
    with _$QuranPlanDaoMixin {
  QuranPlanDao(AppDatabase db) : super(db);

  Future<QuranPlanData?> getPlan(int seasonId) {
    return (select(quranPlan)..where((p) => p.seasonId.equals(seasonId)))
        .getSingleOrNull();
  }

  Future<void> setPlan(QuranPlanData plan) async {
    await into(quranPlan).insertOnConflictUpdate(plan);
  }
}

@DriftAccessor(tables: [QuranDaily])
class QuranDailyDao extends DatabaseAccessor<AppDatabase>
    with _$QuranDailyDaoMixin {
  QuranDailyDao(AppDatabase db) : super(db);

  Future<QuranDailyData?> getDaily(int seasonId, int dayIndex) {
    return (select(quranDaily)
          ..where((d) =>
              d.seasonId.equals(seasonId) & d.dayIndex.equals(dayIndex)))
        .getSingleOrNull();
  }

  Future<void> setPages(int seasonId, int dayIndex, int pages) async {
    await into(quranDaily).insertOnConflictUpdate(
      QuranDailyCompanion.insert(
        seasonId: seasonId,
        dayIndex: dayIndex,
        pagesRead: Value(pages),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<List<QuranDailyData>> getAllDaily(int seasonId) {
    return (select(quranDaily)
          ..where((d) => d.seasonId.equals(seasonId))
          ..orderBy([(d) => OrderingTerm.asc(d.dayIndex)]))
        .get();
  }
}

@DriftAccessor(tables: [DhikrPlan])
class DhikrPlanDao extends DatabaseAccessor<AppDatabase>
    with _$DhikrPlanDaoMixin {
  DhikrPlanDao(AppDatabase db) : super(db);

  Future<DhikrPlanData?> getPlan(int seasonId) {
    return (select(dhikrPlan)..where((p) => p.seasonId.equals(seasonId)))
        .getSingleOrNull();
  }

  Future<void> setPlan(DhikrPlanData plan) async {
    await into(dhikrPlan).insertOnConflictUpdate(plan);
  }
}

@DriftAccessor(tables: [Notes])
class NotesDao extends DatabaseAccessor<AppDatabase> with _$NotesDaoMixin {
  NotesDao(AppDatabase db) : super(db);

  Future<List<Note>> getDayNotes(int seasonId, int? dayIndex) {
    final query = select(notes)
      ..where((n) => n.seasonId.equals(seasonId));
    if (dayIndex != null) {
      query.where((n) => n.dayIndex.equals(dayIndex));
    }
    return (query..orderBy([(n) => OrderingTerm.desc(n.createdAt)])).get();
  }

  Future<int> createNote({
    required int seasonId,
    int? dayIndex,
    String? title,
    required String body,
    String? mood,
  }) {
    return into(notes).insert(
      NotesCompanion.insert(
        seasonId: seasonId,
        dayIndex: Value(dayIndex),
        title: Value(title),
        body: body,
        mood: Value(mood),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<bool> updateNote(Note note) {
    return update(notes).replace(note);
  }

  Future<int> deleteNote(int id) {
    return (delete(notes)..where((n) => n.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [KvSettings])
class KvSettingsDao extends DatabaseAccessor<AppDatabase>
    with _$KvSettingsDaoMixin {
  KvSettingsDao(AppDatabase db) : super(db);

  Future<String?> getValue(String key) async {
    final setting = await (select(kvSettings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return setting?.value;
  }

  Future<void> setValue(String key, String value) async {
    await into(kvSettings).insertOnConflictUpdate(
      KvSettingsCompanion.insert(key: key, value: value),
    );
  }

  Future<void> deleteValue(String key) async {
    await (delete(kvSettings)..where((s) => s.key.equals(key))).go();
  }
}

@DriftAccessor(tables: [PrayerTimesCache])
class PrayerTimesCacheDao extends DatabaseAccessor<AppDatabase>
    with _$PrayerTimesCacheDaoMixin {
  PrayerTimesCacheDao(AppDatabase db) : super(db);

  Future<PrayerTimesCacheData?> getCachedTime(int seasonId, String dateYyyyMmDd) {
    return (select(prayerTimesCache)
          ..where((p) =>
              p.seasonId.equals(seasonId) & p.dateYyyyMmDd.equals(dateYyyyMmDd)))
        .getSingleOrNull();
  }

  Future<void> cacheTime(PrayerTimesCacheData cache) async {
    await into(prayerTimesCache).insertOnConflictUpdate(cache);
  }

  Future<void> clearCacheForSeason(int seasonId) async {
    await (delete(prayerTimesCache)..where((p) => p.seasonId.equals(seasonId))).go();
  }
}

@DriftAccessor(tables: [PrayerDetails])
class PrayerDetailsDao extends DatabaseAccessor<AppDatabase>
    with _$PrayerDetailsDaoMixin {
  PrayerDetailsDao(AppDatabase db) : super(db);

  Future<PrayerDetail?> getPrayerDetails(int seasonId, int dayIndex) {
    return (select(prayerDetails)
          ..where((p) =>
              p.seasonId.equals(seasonId) & p.dayIndex.equals(dayIndex)))
        .getSingleOrNull();
  }

  Future<void> setPrayer(
    int seasonId,
    int dayIndex,
    String prayerName,
    bool completed,
  ) async {
    final existing = await getPrayerDetails(seasonId, dayIndex);
    final now = DateTime.now().millisecondsSinceEpoch;

    if (existing == null) {
      await into(prayerDetails).insert(
        PrayerDetailsCompanion.insert(
          seasonId: seasonId,
          dayIndex: dayIndex,
          fajr: Value(prayerName == 'fajr' ? completed : false),
          dhuhr: Value(prayerName == 'dhuhr' ? completed : false),
          asr: Value(prayerName == 'asr' ? completed : false),
          maghrib: Value(prayerName == 'maghrib' ? completed : false),
          isha: Value(prayerName == 'isha' ? completed : false),
          updatedAt: now,
        ),
      );
    } else {
      final companion = PrayerDetailsCompanion(
        seasonId: Value(seasonId),
        dayIndex: Value(dayIndex),
        fajr: Value(prayerName == 'fajr' ? completed : existing.fajr),
        dhuhr: Value(prayerName == 'dhuhr' ? completed : existing.dhuhr),
        asr: Value(prayerName == 'asr' ? completed : existing.asr),
        maghrib: Value(prayerName == 'maghrib' ? completed : existing.maghrib),
        isha: Value(prayerName == 'isha' ? completed : existing.isha),
        updatedAt: Value(now),
      );
      await update(prayerDetails).replace(
        PrayerDetail(
          seasonId: seasonId,
          dayIndex: dayIndex,
          fajr: companion.fajr.value ?? existing.fajr,
          dhuhr: companion.dhuhr.value ?? existing.dhuhr,
          asr: companion.asr.value ?? existing.asr,
          maghrib: companion.maghrib.value ?? existing.maghrib,
          isha: companion.isha.value ?? existing.isha,
          updatedAt: companion.updatedAt.value ?? existing.updatedAt,
        ),
      );
    }
  }

  Future<void> setPrayerDetails(PrayerDetail details) async {
    await into(prayerDetails).insertOnConflictUpdate(details);
  }

  Future<List<PrayerDetail>> getPrayerDetailsRange(
    int seasonId,
    int startDayIndex,
    int endDayIndex,
  ) {
    return (select(prayerDetails)
          ..where((p) =>
              p.seasonId.equals(seasonId) &
              p.dayIndex.isBiggerOrEqualValue(startDayIndex) &
              p.dayIndex.isSmallerOrEqualValue(endDayIndex))
          ..orderBy([(p) => OrderingTerm.asc(p.dayIndex)]))
        .get();
  }
}

