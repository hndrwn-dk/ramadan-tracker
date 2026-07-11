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

  /// Set both valueBool and valueInt (e.g. Taraweeh: done + rakaat 11 or 23).
  Future<void> setBoolAndIntValue(
    int seasonId,
    int dayIndex,
    int habitId,
    bool boolVal,
    int? intVal,
  ) {
    return into(dailyEntries).insertOnConflictUpdate(
      DailyEntriesCompanion.insert(
        seasonId: seasonId,
        dayIndex: dayIndex,
        habitId: habitId,
        valueBool: Value(boolVal),
        valueInt: Value(intVal),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Fasting status: 0=notDone, 1=fasted, 2=excusedSick, 3=excusedNifas, 4=excusedHaid, 5=excusedOther.
  /// valueBool is true only for fasted (1); excused days do not extend streak.
  /// Optional [note] for excusedOther (stored in DailyEntry.note).
  Future<void> setFastingStatus(
    int seasonId,
    int dayIndex,
    int habitId,
    int status, {
    String? note,
  }) {
    final valueBool = status == 1;
    return into(dailyEntries).insertOnConflictUpdate(
      DailyEntriesCompanion.insert(
        seasonId: seasonId,
        dayIndex: dayIndex,
        habitId: habitId,
        valueBool: Value(valueBool),
        valueInt: Value(status),
        note: note != null && note.isNotEmpty ? Value(note) : const Value.absent(),
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

  Future<List<Note>> getAllNotes() {
    return select(notes).get();
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

@DriftAccessor(tables: [SunnahFasts])
class SunnahFastsDao extends DatabaseAccessor<AppDatabase>
    with _$SunnahFastsDaoMixin {
  SunnahFastsDao(AppDatabase db) : super(db);

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<SunnahFast?> getByDate(DateTime date) {
    return (select(sunnahFasts)..where((s) => s.dateYmd.equals(dateKey(date))))
        .getSingleOrNull();
  }

  Future<List<SunnahFast>> getRange(DateTime start, DateTime end) {
    return (select(sunnahFasts)
          ..where((s) =>
              s.dateYmd.isBiggerOrEqualValue(dateKey(start)) &
              s.dateYmd.isSmallerOrEqualValue(dateKey(end)))
          ..orderBy([(s) => OrderingTerm.asc(s.dateYmd)]))
        .get();
  }

  Future<List<SunnahFast>> getAll() {
    return (select(sunnahFasts)
          ..orderBy([(s) => OrderingTerm.asc(s.dateYmd)]))
        .get();
  }

  Future<void> upsert(
    DateTime date, {
    required int status,
    String? type,
    bool isQadha = false,
    String? note,
  }) async {
    await into(sunnahFasts).insertOnConflictUpdate(
      SunnahFastsCompanion.insert(
        dateYmd: dateKey(date),
        status: Value(status),
        type: Value(type),
        isQadha: Value(isQadha),
        note: Value(note),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> remove(DateTime date) async {
    await (delete(sunnahFasts)..where((s) => s.dateYmd.equals(dateKey(date))))
        .go();
  }
}

@DriftAccessor(tables: [QadhaLedger])
class QadhaLedgerDao extends DatabaseAccessor<AppDatabase>
    with _$QadhaLedgerDaoMixin {
  QadhaLedgerDao(AppDatabase db) : super(db);

  static const autoSunnahNote = 'Auto from sunnah log';

  Future<List<QadhaLedgerData>> getAll() {
    return (select(qadhaLedger)
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)]))
        .get();
  }

  Future<bool> hasAutoSunnahPaidForDate(String dateYmd) async {
    final row = await (select(qadhaLedger)
          ..where((q) =>
              q.kind.equals('qadha') &
              q.direction.equals('paid') &
              q.dateYmd.equals(dateYmd) &
              q.note.equals(autoSunnahNote)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> ensureAutoSunnahPaidEntry(String dateYmd) async {
    if (await hasAutoSunnahPaidForDate(dateYmd)) return;
    await addEntry(
      kind: 'qadha',
      direction: 'paid',
      days: 1,
      dateYmd: dateYmd,
      note: autoSunnahNote,
    );
  }

  Future<int> removeAutoSunnahEntriesForDate(String dateYmd) {
    return (delete(qadhaLedger)..where((q) =>
          q.kind.equals('qadha') &
          q.direction.equals('paid') &
          q.dateYmd.equals(dateYmd) &
          q.note.equals(autoSunnahNote))).go();
  }

  /// Keeps at most one auto sunnah qadha row per [dateYmd].
  Future<int> dedupeAutoSunnahEntries() async {
    final rows = await (select(qadhaLedger)
          ..where((q) =>
              q.kind.equals('qadha') &
              q.direction.equals('paid') &
              q.note.equals(autoSunnahNote) &
              q.dateYmd.isNotNull())
          ..orderBy([(q) => OrderingTerm.desc(q.createdAt)]))
        .get();

    final seen = <String>{};
    var deleted = 0;
    for (final row in rows) {
      final date = row.dateYmd!;
      if (seen.contains(date)) {
        deleted += await deleteEntry(row.id);
      } else {
        seen.add(date);
      }
    }
    return deleted;
  }

  /// Aligns auto ledger rows with sunnah fast qadha flags.
  Future<void> reconcileAutoSunnahQadhaLedger() async {
    await dedupeAutoSunnahEntries();

    final autoRows = await (select(qadhaLedger)
          ..where((q) =>
              q.kind.equals('qadha') &
              q.direction.equals('paid') &
              q.note.equals(autoSunnahNote) &
              q.dateYmd.isNotNull()))
        .get();

    for (final row in autoRows) {
      final fast =
          await attachedDatabase.sunnahFastsDao.getByDate(_parseYmd(row.dateYmd!));
      final stillQadha = fast != null &&
          fast.status == FastingStatus.fasted &&
          fast.isQadha;
      if (!stillQadha) {
        await deleteEntry(row.id);
      }
    }

    final allFasts = await attachedDatabase.sunnahFastsDao.getAll();
    for (final fast in allFasts) {
      if (fast.status == FastingStatus.fasted && fast.isQadha) {
        await ensureAutoSunnahPaidEntry(fast.dateYmd);
      }
    }
  }

  static DateTime _parseYmd(String ymd) {
    final parts = ymd.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  Future<int> addEntry({
    required String kind,
    required String direction,
    int days = 0,
    int amount = 0,
    String? dateYmd,
    int? sourceSeasonId,
    String? note,
  }) {
    return into(qadhaLedger).insert(
      QadhaLedgerCompanion.insert(
        kind: kind,
        direction: direction,
        days: Value(days),
        amount: Value(amount),
        dateYmd: Value(dateYmd),
        sourceSeasonId: Value(sourceSeasonId),
        note: Value(note),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  Future<int> deleteEntry(int id) {
    return (delete(qadhaLedger)..where((q) => q.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [UserAchievements])
class UserAchievementsDao extends DatabaseAccessor<AppDatabase>
    with _$UserAchievementsDaoMixin {
  UserAchievementsDao(AppDatabase db) : super(db);

  Future<List<UserAchievement>> getAll() {
    return (select(userAchievements)
          ..orderBy([(a) => OrderingTerm.desc(a.unlockedAt)]))
        .get();
  }

  Future<bool> isUnlocked(String key) async {
    final row = await (select(userAchievements)
          ..where((a) => a.achievementKey.equals(key)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> unlock({
    required String achievementKey,
    int? seasonId,
  }) async {
    final existing = await isUnlocked(achievementKey);
    if (existing) return;
    await into(userAchievements).insert(
      UserAchievementsCompanion.insert(
        achievementKey: achievementKey,
        unlockedAt: DateTime.now().millisecondsSinceEpoch,
        seasonId: Value(seasonId),
      ),
    );
  }
}

@DriftAccessor(tables: [UserEngagement])
class UserEngagementDao extends DatabaseAccessor<AppDatabase>
    with _$UserEngagementDaoMixin {
  UserEngagementDao(AppDatabase db) : super(db);

  Future<UserEngagementData> getOrCreate() async {
    final row = await (select(userEngagement)..where((e) => e.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    await into(userEngagement).insert(
      UserEngagementCompanion.insert(
        id: const Value(1),
        totalXp: const Value(0),
        companionLevel: const Value(1),
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    return (select(userEngagement)..where((e) => e.id.equals(1))).getSingle();
  }

  Future<void> addXp(int amount) async {
    final row = await getOrCreate();
    final newXp = row.totalXp + amount;
    final newLevel = CompanionLevel.levelFromXp(newXp);
    await (update(userEngagement)..where((e) => e.id.equals(1))).write(
      UserEngagementCompanion(
        totalXp: Value(newXp),
        companionLevel: Value(newLevel),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }
}

