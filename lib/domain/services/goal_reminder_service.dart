import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class GoalReminderService {
  /// Schedule goal tracking reminders for today
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
    debugPrint('=== scheduleGoalReminders called ===');
    try {
      // Get settings
      final quranReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_quran_enabled') ?? 'true';
      final dhikrReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_dhikr_enabled') ?? 'true';
      final sedekahReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_sedekah_enabled') ?? 'true';
      final taraweehReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_taraweeh_enabled') ?? 'true';
      
      debugPrint('Goal reminder settings:');
      debugPrint('  Quran: $quranReminderEnabled');
      debugPrint('  Dhikr: $dhikrReminderEnabled');
      debugPrint('  Sedekah: $sedekahReminderEnabled');
      debugPrint('  Taraweeh: $taraweehReminderEnabled');

      // Get today's date and day index
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Get current season to find day index
      final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
      if (season == null) return;

      // Parse startDate from ISO string format (YYYY-MM-DD)
      final seasonStart = DateTime.parse(season.startDate);
      final dayIndex = today.difference(seasonStart).inDays + 1;
      
      if (dayIndex < 1 || dayIndex > season.days) {
        // Outside season, don't schedule
        return;
      }

      // Get prayer times for today
      final times = await PrayerTimeService.getCachedOrCalculate(
        database: database,
        seasonId: seasonId,
        date: today,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdjust,
        maghribAdjust: maghribAdjust,
      );

      // Get habits and plans
      final allHabits = await database.habitsDao.getAllHabits();
      final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
      final quranPlan = await database.quranPlanDao.getPlan(seasonId);
      final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
      final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
      final dailyEntries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);

      // Check current progress - handle missing habits gracefully
      // Need to get habit keys from Habits table
      int quranProgress = 0;
      int quranTarget = 0;
      bool quranHabitEnabled = false;
      try {
        final quranHabitDb = allHabits.firstWhere((h) => h.key == 'quran_pages');
        final quranSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == quranHabitDb.id);
        if (quranPlan != null) {
          quranProgress = quranDaily?.pagesRead ?? 0;
          quranTarget = quranPlan.dailyTargetPages;
          quranHabitEnabled = quranSeasonHabit.isEnabled;
        }
      } catch (e) {
        // Quran habit not found or not enabled
      }

      int dhikrProgress = 0;
      int dhikrTarget = 0;
      bool dhikrHabitEnabled = false;
      try {
        final dhikrHabitDb = allHabits.firstWhere((h) => h.key == 'dhikr');
        final dhikrSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == dhikrHabitDb.id);
        if (dhikrPlan != null) {
          final dhikrEntry = dailyEntries.where((e) => e.habitId == dhikrHabitDb.id).toList().firstOrNull;
          if (dhikrEntry != null) {
            dhikrProgress = dhikrEntry.valueInt ?? 0;
            dhikrTarget = dhikrPlan.dailyTarget;
            dhikrHabitEnabled = dhikrSeasonHabit.isEnabled;
          }
        }
      } catch (e) {
        // Dhikr habit not found or not enabled
      }

      double sedekahProgress = 0;
      double sedekahTarget = 0;
      bool sedekahHabitEnabled = false;
      try {
        final sedekahHabitDb = allHabits.firstWhere((h) => h.key == 'sedekah');
        final sedekahSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == sedekahHabitDb.id);
        final sedekahEntry = dailyEntries.where((e) => e.habitId == sedekahHabitDb.id).toList().firstOrNull;
        if (sedekahEntry != null) {
          sedekahProgress = (sedekahEntry.valueInt ?? 0).toDouble();
          final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
          final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled') ?? 'false';
          sedekahTarget = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null
              ? double.tryParse(sedekahGoalAmount) ?? 0
              : 0;
          sedekahHabitEnabled = sedekahSeasonHabit.isEnabled;
        }
      } catch (e) {
        // Sedekah habit not found or not enabled
      }

      bool isTaraweehDone = false;
      bool taraweehHabitEnabled = false;
      try {
        final taraweehHabitDb = allHabits.firstWhere((h) => h.key == 'taraweeh');
        final taraweehSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == taraweehHabitDb.id);
        final taraweehEntry = dailyEntries.where((e) => e.habitId == taraweehHabitDb.id).toList().firstOrNull;
        if (taraweehEntry != null) {
          isTaraweehDone = taraweehEntry.valueBool ?? false;
          taraweehHabitEnabled = taraweehSeasonHabit.isEnabled;
        }
      } catch (e) {
        // Taraweeh habit not found or not enabled
      }

      // Schedule Quran reminder if enabled, habit enabled, has target, and not completed
      // Parse reminder enabled setting robustly (treat "true", "1", true as enabled)
      final quranReminderEnabledParsed = _parseBoolSetting(quranReminderEnabled);
      
      if (kDebugMode) {
        debugPrint('=== Checking Quran Reminder Conditions ===');
        debugPrint('  quranReminderEnabled: $quranReminderEnabled (parsed: $quranReminderEnabledParsed)');
        debugPrint('  quranHabitEnabled: $quranHabitEnabled');
        debugPrint('  quranTarget: $quranTarget');
        debugPrint('  quranProgress: $quranProgress');
      }
      
      if (quranReminderEnabledParsed && 
          quranHabitEnabled && 
          quranTarget > 0 && 
          quranProgress < quranTarget) {
        if (kDebugMode) {
          debugPrint('  All conditions met, scheduling Quran reminders');
        }
        await _scheduleQuranReminders(now, quranProgress, quranTarget, location);
      } else {
        if (kDebugMode) {
          debugPrint('  ✗ Conditions not met, skipping Quran reminders');
          if (!quranReminderEnabledParsed) debugPrint('    - Reminder disabled');
          if (!quranHabitEnabled) debugPrint('    - Habit disabled');
          if (quranTarget <= 0) debugPrint('    - No target set');
          if (quranProgress >= quranTarget) debugPrint('    - Already completed');
        }
      }

      // Schedule Dhikr reminder if enabled, habit enabled, has target, and not completed
      final dhikrReminderEnabledParsed = _parseBoolSetting(dhikrReminderEnabled);
      
      if (kDebugMode) {
        debugPrint('=== Checking Dhikr Reminder Conditions ===');
        debugPrint('  dhikrReminderEnabled: $dhikrReminderEnabled (parsed: $dhikrReminderEnabledParsed)');
        debugPrint('  dhikrHabitEnabled: $dhikrHabitEnabled');
        debugPrint('  dhikrTarget: $dhikrTarget');
        debugPrint('  dhikrProgress: $dhikrProgress');
      }
      
      if (dhikrReminderEnabledParsed && 
          dhikrHabitEnabled && 
          dhikrTarget > 0 && 
          dhikrProgress < dhikrTarget) {
        if (kDebugMode) {
          debugPrint('  All conditions met, scheduling Dhikr reminders');
        }
        await _scheduleDhikrReminders(now, dhikrProgress, dhikrTarget, location);
      } else {
        if (kDebugMode) {
          debugPrint('  ✗ Conditions not met, skipping Dhikr reminders');
          if (!dhikrReminderEnabledParsed) debugPrint('    - Reminder disabled');
          if (!dhikrHabitEnabled) debugPrint('    - Habit disabled');
          if (dhikrTarget <= 0) debugPrint('    - No target set');
          if (dhikrProgress >= dhikrTarget) debugPrint('    - Already completed');
        }
      }

      // Schedule Sedekah reminder if enabled, habit enabled, has target, and not completed
      final sedekahReminderEnabledParsed = _parseBoolSetting(sedekahReminderEnabled);
      if (sedekahReminderEnabledParsed && 
          sedekahHabitEnabled && 
          sedekahTarget > 0 && 
          sedekahProgress < sedekahTarget) {
        await _scheduleSedekahReminder(now, sedekahProgress, sedekahTarget, location);
      }

      // Schedule Taraweeh reminder if enabled, habit enabled, and not done
      final taraweehReminderEnabledParsed = _parseBoolSetting(taraweehReminderEnabled);
      if (taraweehReminderEnabledParsed && 
          taraweehHabitEnabled && 
          !isTaraweehDone &&
          times['isha'] != null) {
        await _scheduleTaraweehReminder(times['isha']!, location);
      }
    } catch (e) {
      debugPrint('Error scheduling goal reminders: $e');
    }
  }

  static Future<void> _scheduleQuranReminders(DateTime now, int current, int target, tz.Location location) async {
    // Schedule reminders at 2 PM, 6 PM, and 8 PM if not completed
    final reminderTimes = [
      DateTime(now.year, now.month, now.day, 14, 0), // 2 PM
      DateTime(now.year, now.month, now.day, 18, 0), // 6 PM
      DateTime(now.year, now.month, now.day, 20, 0), // 8 PM
    ];

    debugPrint('=== Scheduling Quran Reminders ===');
    debugPrint('Timezone: ${location.name}');
    debugPrint('Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    debugPrint('Progress: $current/$target');

    for (final reminderTime in reminderTimes) {
      final timeUntilReminder = reminderTime.difference(now);
      final minutesPassed = timeUntilReminder.inMinutes.abs();
      debugPrint('  Reminder time: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
      debugPrint('  Time until reminder: ${timeUntilReminder.inMinutes} minutes');
      
      if (reminderTime.isAfter(now)) {
        debugPrint('  Scheduling Quran reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
        try {
          await NotificationService.scheduleGoalReminder(
            reminderTime: reminderTime,
            type: 'quran',
            current: current,
            target: target,
            location: location,
          );
          debugPrint('  Quran reminder scheduled successfully for ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
        } catch (e, stackTrace) {
          debugPrint('  ✗ Error scheduling Quran reminder: $e');
          debugPrint('  Stack trace: $stackTrace');
        }
      } else {
        debugPrint('  ✗ Skipping Quran reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')} (time passed ${minutesPassed} minutes ago)');
      }
    }
  }

  static Future<void> _scheduleDhikrReminders(DateTime now, int current, int target, tz.Location location) async {
    // Schedule reminders at 2 PM, 6 PM, and 8 PM if not completed
    final reminderTimes = [
      DateTime(now.year, now.month, now.day, 14, 0), // 2 PM
      DateTime(now.year, now.month, now.day, 18, 0), // 6 PM
      DateTime(now.year, now.month, now.day, 20, 0), // 8 PM
    ];

    debugPrint('=== Scheduling Dhikr Reminders ===');
    debugPrint('Timezone: ${location.name}');
    debugPrint('Current time: ${now.hour}:${now.minute.toString().padLeft(2, '0')}');
    debugPrint('Progress: $current/$target');

    for (final reminderTime in reminderTimes) {
      final timeUntilReminder = reminderTime.difference(now);
      final minutesPassed = timeUntilReminder.inMinutes.abs();
      debugPrint('  Reminder time: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
      debugPrint('  Time until reminder: ${timeUntilReminder.inMinutes} minutes');
      
      if (reminderTime.isAfter(now)) {
        debugPrint('  Scheduling Dhikr reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
        try {
          await NotificationService.scheduleGoalReminder(
            reminderTime: reminderTime,
            type: 'dhikr',
            current: current,
            target: target,
            location: location,
          );
          debugPrint('  Dhikr reminder scheduled successfully for ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
        } catch (e, stackTrace) {
          debugPrint('  ✗ Error scheduling Dhikr reminder: $e');
          debugPrint('  Stack trace: $stackTrace');
        }
      } else {
        debugPrint('  ✗ Skipping Dhikr reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')} (time passed ${minutesPassed} minutes ago)');
      }
    }
  }

  static Future<void> _scheduleSedekahReminder(DateTime now, double current, double target, tz.Location location) async {
    // Schedule reminder at 4 PM if not completed
    final reminderTime = DateTime(now.year, now.month, now.day, 16, 0); // 4 PM

    if (reminderTime.isAfter(now)) {
      debugPrint('  Scheduling Sedekah reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
      await NotificationService.scheduleGoalReminder(
        reminderTime: reminderTime,
        type: 'sedekah',
        current: current.toInt(),
        target: target.toInt(),
        location: location,
      );
    } else {
      debugPrint('  Skipping Sedekah reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')} (time passed)');
    }
  }

  static Future<void> _scheduleTaraweehReminder(DateTime ishaTime, tz.Location location) async {
    // Schedule reminder 15 minutes after Isha
    final reminderTime = ishaTime.add(const Duration(minutes: 15));
    final now = DateTime.now();

    debugPrint('  Isha time: ${ishaTime.hour}:${ishaTime.minute.toString().padLeft(2, '0')}');
    debugPrint('  Taraweeh reminder time: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
    
    if (reminderTime.isAfter(now)) {
      debugPrint('  Scheduling Taraweeh reminder at ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
      await NotificationService.scheduleGoalReminder(
        reminderTime: reminderTime,
        type: 'taraweeh',
        current: 0,
        target: 0,
        location: location,
      );
    } else {
      if (kDebugMode) {
        debugPrint('  Skipping Taraweeh reminder (time passed)');
      }
    }
  }
  
  /// Schedule goal reminders for a specific date (season-wide scheduling)
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
      // Get settings
      final quranReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_quran_enabled') ?? 'true';
      final dhikrReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_dhikr_enabled') ?? 'true';
      final sedekahReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_sedekah_enabled') ?? 'true';
      final taraweehReminderEnabled = await database.kvSettingsDao.getValue('goal_reminder_taraweeh_enabled') ?? 'true';
      
      // Get season info
      final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
      if (season == null) return;
      
      final seasonStart = DateTime.parse(season.startDate);
      final dayIndex = date.difference(seasonStart).inDays + 1;
      
      if (dayIndex < 1 || dayIndex > season.days) {
        // Outside season, don't schedule
        return;
      }
      
      // Get prayer times for this date
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
      
      // Get habits and plans
      final allHabits = await database.habitsDao.getAllHabits();
      final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
      final quranPlan = await database.quranPlanDao.getPlan(seasonId);
      final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
      final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
      final dailyEntries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
      
      // Check current progress
      int quranProgress = 0;
      int quranTarget = 0;
      bool quranHabitEnabled = false;
      try {
        final quranHabitDb = allHabits.firstWhere((h) => h.key == 'quran_pages');
        final quranSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == quranHabitDb.id);
        if (quranPlan != null) {
          quranProgress = quranDaily?.pagesRead ?? 0;
          quranTarget = quranPlan.dailyTargetPages;
          quranHabitEnabled = quranSeasonHabit.isEnabled;
        }
      } catch (e) {
        // Quran habit not found
      }
      
      int dhikrProgress = 0;
      int dhikrTarget = 0;
      bool dhikrHabitEnabled = false;
      try {
        final dhikrHabitDb = allHabits.firstWhere((h) => h.key == 'dhikr');
        final dhikrSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == dhikrHabitDb.id);
        if (dhikrPlan != null) {
          final dhikrEntry = dailyEntries.where((e) => e.habitId == dhikrHabitDb.id).toList().firstOrNull;
          if (dhikrEntry != null) {
            dhikrProgress = dhikrEntry.valueInt ?? 0;
          }
          dhikrTarget = dhikrPlan.dailyTarget;
          dhikrHabitEnabled = dhikrSeasonHabit.isEnabled;
        }
      } catch (e) {
        // Dhikr habit not found
      }
      
      double sedekahProgress = 0;
      double sedekahTarget = 0;
      bool sedekahHabitEnabled = false;
      try {
        final sedekahHabitDb = allHabits.firstWhere((h) => h.key == 'sedekah');
        final sedekahSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == sedekahHabitDb.id);
        final sedekahEntry = dailyEntries.where((e) => e.habitId == sedekahHabitDb.id).toList().firstOrNull;
        if (sedekahEntry != null) {
          sedekahProgress = sedekahEntry.valueInt?.toDouble() ?? 0;
        }
        sedekahTarget = sedekahSeasonHabit.targetValue?.toDouble() ?? 0;
        sedekahHabitEnabled = sedekahSeasonHabit.isEnabled;
      } catch (e) {
        // Sedekah habit not found
      }
      
      bool isTaraweehDone = false;
      bool taraweehHabitEnabled = false;
      try {
        final taraweehHabitDb = allHabits.firstWhere((h) => h.key == 'taraweeh');
        final taraweehSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == taraweehHabitDb.id);
        final taraweehEntry = dailyEntries.where((e) => e.habitId == taraweehHabitDb.id).toList().firstOrNull;
        isTaraweehDone = taraweehEntry?.valueBool ?? false;
        taraweehHabitEnabled = taraweehSeasonHabit.isEnabled;
      } catch (e) {
        // Taraweeh habit not found
      }
      
      // Schedule reminders based on conditions
      final quranReminderEnabledParsed = _parseBoolSetting(quranReminderEnabled);
      if (quranReminderEnabledParsed && quranHabitEnabled && quranTarget > 0 && quranProgress < quranTarget) {
        await _scheduleQuranRemindersForDate(date, quranProgress, quranTarget, location);
      }
      
      final dhikrReminderEnabledParsed = _parseBoolSetting(dhikrReminderEnabled);
      if (dhikrReminderEnabledParsed && dhikrHabitEnabled && dhikrTarget > 0 && dhikrProgress < dhikrTarget) {
        await _scheduleDhikrRemindersForDate(date, dhikrProgress, dhikrTarget, location);
      }
      
      final sedekahReminderEnabledParsed = _parseBoolSetting(sedekahReminderEnabled);
      if (sedekahReminderEnabledParsed && sedekahHabitEnabled && sedekahTarget > 0 && sedekahProgress < sedekahTarget) {
        await _scheduleSedekahReminderForDate(date, sedekahProgress, sedekahTarget, location);
      }
      
      final taraweehReminderEnabledParsed = _parseBoolSetting(taraweehReminderEnabled);
      if (taraweehReminderEnabledParsed && taraweehHabitEnabled && !isTaraweehDone && times['isha'] != null) {
        await _scheduleTaraweehReminderForDate(date, times['isha']!, location);
      }
    } catch (e) {
      debugPrint('Error scheduling goal reminders for date $date: $e');
    }
  }
  
  static Future<void> _scheduleQuranRemindersForDate(DateTime date, int current, int target, tz.Location location) async {
    final reminderTimes = [
      DateTime(date.year, date.month, date.day, 14, 0),
      DateTime(date.year, date.month, date.day, 18, 0),
      DateTime(date.year, date.month, date.day, 20, 0),
    ];
    
    for (final reminderTime in reminderTimes) {
      final tzNow = tz.TZDateTime.now(location);
      final scheduledTime = tz.TZDateTime(
        location,
        reminderTime.year,
        reminderTime.month,
        reminderTime.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      
      if (scheduledTime.isAfter(tzNow.add(const Duration(seconds: 1)))) {
        await NotificationService.scheduleGoalReminder(
          reminderTime: reminderTime,
          type: 'quran',
          current: current,
          target: target,
          location: location,
        );
      }
    }
  }
  
  static Future<void> _scheduleDhikrRemindersForDate(DateTime date, int current, int target, tz.Location location) async {
    final reminderTimes = [
      DateTime(date.year, date.month, date.day, 14, 0),
      DateTime(date.year, date.month, date.day, 18, 0),
      DateTime(date.year, date.month, date.day, 20, 0),
    ];
    
    for (final reminderTime in reminderTimes) {
      final tzNow = tz.TZDateTime.now(location);
      final scheduledTime = tz.TZDateTime(
        location,
        reminderTime.year,
        reminderTime.month,
        reminderTime.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      
      if (scheduledTime.isAfter(tzNow.add(const Duration(seconds: 1)))) {
        await NotificationService.scheduleGoalReminder(
          reminderTime: reminderTime,
          type: 'dhikr',
          current: current,
          target: target,
          location: location,
        );
      }
    }
  }
  
  static Future<void> _scheduleSedekahReminderForDate(DateTime date, double current, double target, tz.Location location) async {
    final reminderTime = DateTime(date.year, date.month, date.day, 16, 0);
    final tzNow = tz.TZDateTime.now(location);
    final scheduledTime = tz.TZDateTime(
      location,
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    
    if (scheduledTime.isAfter(tzNow.add(const Duration(seconds: 1)))) {
      await NotificationService.scheduleGoalReminder(
        reminderTime: reminderTime,
        type: 'sedekah',
        current: current.toInt(),
        target: target.toInt(),
        location: location,
      );
    }
  }
  
  static Future<void> _scheduleTaraweehReminderForDate(DateTime date, DateTime ishaTime, tz.Location location) async {
    final reminderTime = ishaTime.add(const Duration(minutes: 15));
    final tzNow = tz.TZDateTime.now(location);
    final scheduledTime = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    
    if (scheduledTime.isAfter(tzNow.add(const Duration(seconds: 1)))) {
      await NotificationService.scheduleGoalReminder(
        reminderTime: reminderTime,
        type: 'taraweeh',
        current: 0,
        target: 0,
        location: location,
      );
    }
  }

  /// Parse boolean setting from string (treat "true", "1", true as enabled)
  static bool _parseBoolSetting(String? value) {
    if (value == null) return false;
    final lower = value.toLowerCase().trim();
    return lower == 'true' || lower == '1' || lower == 'yes';
  }
}

