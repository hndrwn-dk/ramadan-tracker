import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class _GoalProgress {
  const _GoalProgress({
    required this.quranProgress,
    required this.quranTarget,
    required this.quranHabitEnabled,
    required this.dhikrProgress,
    required this.dhikrTarget,
    required this.dhikrHabitEnabled,
    required this.sedekahProgress,
    required this.sedekahTarget,
    required this.sedekahHabitEnabled,
  });

  final int quranProgress;
  final int quranTarget;
  final bool quranHabitEnabled;
  final int dhikrProgress;
  final int dhikrTarget;
  final bool dhikrHabitEnabled;
  final double sedekahProgress;
  final double sedekahTarget;
  final bool sedekahHabitEnabled;
}

class GoalReminderService {
  /// Goal reminders only apply on days inside an active Ramadan season window.
  static bool isActiveSeasonDay(RamadanSeason season, DateTime date) {
    final model = SeasonModel.fromDb(season);
    final rawIndex = model.getRawDayIndex(date);
    return rawIndex >= 1 && rawIndex <= season.days;
  }

  /// Shared gate for Quran / dhikr / sedekah goal reminders (habit + baseline + incomplete).
  static bool shouldScheduleNumericGoal({
    required bool habitEnabled,
    required num target,
    required num progress,
  }) {
    return habitEnabled && target > 0 && progress < target;
  }

  /// Digest reminders enabled (new key with legacy OR fallback).
  static Future<bool> isDigestReminderEnabled(AppDatabase database) async {
    final digest =
        await database.kvSettingsDao.getValue('goal_reminder_digest_enabled');
    if (digest != null) return _parseBoolSetting(digest);

    final quran =
        await database.kvSettingsDao.getValue('goal_reminder_quran_enabled') ??
            'true';
    final dhikr =
        await database.kvSettingsDao.getValue('goal_reminder_dhikr_enabled') ??
            'true';
    final sedekah = await database.kvSettingsDao.getValue(
          'goal_reminder_sedekah_enabled',
        ) ??
        'true';
    return _parseBoolSetting(quran) ||
        _parseBoolSetting(dhikr) ||
        _parseBoolSetting(sedekah);
  }

  static Future<bool> isIftarReminderEnabled(AppDatabase database) async {
    final value =
        await database.kvSettingsDao.getValue('iftar_enabled') ?? 'true';
    return _parseBoolSetting(value);
  }

  /// Pending numeric goal habit keys for a season day (quran, dhikr, sedekah).
  static Future<List<String>> getPendingGoalTypesForDate({
    required AppDatabase database,
    required int seasonId,
    required DateTime date,
  }) async {
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    if (season == null) return [];

    final dateOnly = DateTime(date.year, date.month, date.day);
    if (!isActiveSeasonDay(season, dateOnly)) return [];

    final seasonStart = DateTime.parse(season.startDate);
    final dayIndex = dateOnly.difference(seasonStart).inDays + 1;
    final progress = await _loadGoalProgress(database, seasonId, dayIndex);
    return _pendingTypesFromProgress(progress);
  }

  static List<String> _pendingTypesFromProgress(_GoalProgress progress) {
    final pending = <String>[];
    if (shouldScheduleNumericGoal(
      habitEnabled: progress.quranHabitEnabled,
      target: progress.quranTarget,
      progress: progress.quranProgress,
    )) {
      pending.add('quran');
    }
    if (shouldScheduleNumericGoal(
      habitEnabled: progress.dhikrHabitEnabled,
      target: progress.dhikrTarget,
      progress: progress.dhikrProgress,
    )) {
      pending.add('dhikr');
    }
    if (shouldScheduleNumericGoal(
      habitEnabled: progress.sedekahHabitEnabled,
      target: progress.sedekahTarget,
      progress: progress.sedekahProgress,
    )) {
      pending.add('sedekah');
    }
    return pending;
  }

  static Future<_GoalProgress> _loadGoalProgress(
    AppDatabase database,
    int seasonId,
    int dayIndex,
  ) async {
    final allHabits = await database.habitsDao.getAllHabits();
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
    final dailyEntries =
        await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);

    int quranProgress = 0;
    int quranTarget = 0;
    bool quranHabitEnabled = false;
    try {
      final quranHabitDb = allHabits.firstWhere((h) => h.key == 'quran_pages');
      final quranSeasonHabit =
          seasonHabits.firstWhere((sh) => sh.habitId == quranHabitDb.id);
      if (quranPlan != null) {
        quranProgress = quranDaily?.pagesRead ?? 0;
        quranTarget = quranPlan.dailyTargetPages;
        quranHabitEnabled = quranSeasonHabit.isEnabled;
      }
    } catch (_) {}

    int dhikrProgress = 0;
    int dhikrTarget = 0;
    bool dhikrHabitEnabled = false;
    try {
      final dhikrHabitDb = allHabits.firstWhere((h) => h.key == 'dhikr');
      final dhikrSeasonHabit =
          seasonHabits.firstWhere((sh) => sh.habitId == dhikrHabitDb.id);
      if (dhikrPlan != null) {
        final dhikrEntry = dailyEntries
            .where((e) => e.habitId == dhikrHabitDb.id)
            .toList()
            .firstOrNull;
        dhikrProgress = dhikrEntry?.valueInt ?? 0;
        dhikrTarget = dhikrPlan.dailyTarget;
        dhikrHabitEnabled = dhikrSeasonHabit.isEnabled;
      }
    } catch (_) {}

    double sedekahProgress = 0;
    double sedekahTarget = 0;
    bool sedekahHabitEnabled = false;
    try {
      final sedekahHabitDb = allHabits.firstWhere((h) => h.key == 'sedekah');
      final sedekahSeasonHabit =
          seasonHabits.firstWhere((sh) => sh.habitId == sedekahHabitDb.id);
      final sedekahEntry = dailyEntries
          .where((e) => e.habitId == sedekahHabitDb.id)
          .toList()
          .firstOrNull;
      sedekahProgress = sedekahEntry?.valueInt?.toDouble() ?? 0;
      final sedekahGoalAmount =
          await database.kvSettingsDao.getValue('sedekah_goal_amount');
      final sedekahGoalEnabled =
          await database.kvSettingsDao.getValue('sedekah_goal_enabled') ??
              'false';
      sedekahTarget = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null
          ? double.tryParse(sedekahGoalAmount) ?? 0
          : 0;
      sedekahHabitEnabled = sedekahSeasonHabit.isEnabled;
    } catch (_) {}

    return _GoalProgress(
      quranProgress: quranProgress,
      quranTarget: quranTarget,
      quranHabitEnabled: quranHabitEnabled,
      dhikrProgress: dhikrProgress,
      dhikrTarget: dhikrTarget,
      dhikrHabitEnabled: dhikrHabitEnabled,
      sedekahProgress: sedekahProgress,
      sedekahTarget: sedekahTarget,
      sedekahHabitEnabled: sedekahHabitEnabled,
    );
  }

  /// Schedule goal tracking reminders for today.
  static Future<void> scheduleGoalReminders({
    required AppDatabase database,
    required int seasonId,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    required tz.Location location,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await scheduleGoalRemindersForDate(
      database: database,
      seasonId: seasonId,
      date: today,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      method: method,
      highLatRule: highLatRule,
      location: location,
      fajrAdjust: fajrAdjust,
      maghribAdjust: maghribAdjust,
    );
  }

  /// Schedule goal reminders for a specific date (season-wide scheduling).
  static Future<void> scheduleGoalRemindersForDate({
    required AppDatabase database,
    required int seasonId,
    required DateTime date,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    required tz.Location location,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) async {
    try {
      final digestEnabled = await isDigestReminderEnabled(database);
      final iftarReminderEnabled = await isIftarReminderEnabled(database);
      final locale =
          await database.kvSettingsDao.getValue('app_language') ?? 'en';

      final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
      if (season == null) return;

      final dateOnly = DateTime(date.year, date.month, date.day);
      if (!isActiveSeasonDay(season, dateOnly)) return;

      final seasonStart = DateTime.parse(season.startDate);
      final dayIndex = dateOnly.difference(seasonStart).inDays + 1;

      final times = await PrayerTimeService.getCachedOrCalculate(
        database: database,
        seasonId: seasonId,
        date: date,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdjust,
        maghribAdjust: maghribAdjust,
      );

      final progress = await _loadGoalProgress(database, seasonId, dayIndex);
      final pending = digestEnabled ? _pendingTypesFromProgress(progress) : <String>[];

      if (digestEnabled &&
          !iftarReminderEnabled &&
          pending.isNotEmpty &&
          times['maghrib'] != null) {
        await NotificationService.scheduleDigestGoalReminder(
          date: dateOnly,
          maghribTime: times['maghrib']!,
          pendingTypes: pending,
          location: location,
          locale: locale,
        );
      }
    } catch (e) {
      debugPrint('Error scheduling goal reminders for date $date: $e');
    }
  }

  /// Parse boolean setting from string (treat "true", "1", yes as enabled).
  static bool _parseBoolSetting(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase().trim();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
}
