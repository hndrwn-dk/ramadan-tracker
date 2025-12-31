import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/domain/services/goal_reminder_service.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    // Initialize timezone database first
    tz_data.initializeTimeZones();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _createChannels();
    await _setTimezone();
  }

  static Future<void> _createChannels() async {
    const ramadanChannel = AndroidNotificationChannel(
      'ramadan_reminders',
      'Ramadan Reminders',
      description: 'Sahur and Iftar reminders',
      importance: Importance.high,
    );

    const gentleChannel = AndroidNotificationChannel(
      'gentle_reminders',
      'Gentle Reminders',
      description: 'Quran, Dhikr, and other gentle reminders',
      importance: Importance.defaultImportance,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(ramadanChannel);

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(gentleChannel);
  }

  static Future<void> _setTimezone() async {
    String timezoneName = 'UTC';
    try {
      if (Platform.isAndroid) {
        final tzData = await _getLocalTimezone();
        timezoneName = tzData;
      } else if (Platform.isIOS) {
        // For iOS, use UTC as default or implement platform channel if needed
        timezoneName = 'UTC';
      }
    } catch (e) {
      timezoneName = 'UTC';
    }
    
    try {
      tz.setLocalLocation(tz.getLocation(timezoneName));
    } catch (e) {
      // Fallback to UTC if location not found
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  static Future<String> _getLocalTimezone() async {
    if (Platform.isAndroid) {
      final result = await Process.run('getprop', ['persist.sys.timezone']);
      if (result.exitCode == 0) {
        return result.stdout.toString().trim();
      }
    }
    return 'UTC';
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  static Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> scheduleSahurReminder({
    required DateTime fajrTime,
    required int offsetMinutes,
    required String title,
    required String body,
  }) async {
    var reminderTime = fajrTime.subtract(Duration(minutes: offsetMinutes));
    final now = DateTime.now();
    
    // If reminder time has passed today, schedule for tomorrow
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
      debugPrint('Sahur reminder time passed, scheduling for tomorrow: $reminderTime');
    }
    
    debugPrint('Scheduling Sahur reminder for: $reminderTime (Fajr: $fajrTime, offset: $offsetMinutes)');

    try {
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
      debugPrint('Scheduling Sahur notification at: $scheduledTime (local timezone)');
      await _notifications.zonedSchedule(
        _getNotificationId('sahur', reminderTime),
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ramadan_reminders',
            'Ramadan Reminders',
            channelDescription: 'Sahur and Iftar reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('Error scheduling Sahur notification (exact): $e');
      // Fallback to inexact scheduling if exact alarms not permitted
      if (e.toString().contains('exact_alarms_not_permitted')) {
        try {
          final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
          await _notifications.zonedSchedule(
            _getNotificationId('sahur', reminderTime),
            title,
            body,
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'ramadan_reminders',
                'Ramadan Reminders',
                channelDescription: 'Sahur and Iftar reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
          );
          debugPrint('Sahur notification scheduled (inexact allowWhileIdle)');
        } catch (e2) {
          debugPrint('Error scheduling Sahur notification (inexact allowWhileIdle): $e2');
          // If still fails, use inexact without allowWhileIdle
          try {
            final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
            await _notifications.zonedSchedule(
              _getNotificationId('sahur', reminderTime),
              title,
              body,
              scheduledTime,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ramadan_reminders',
                  'Ramadan Reminders',
                  channelDescription: 'Sahur and Iftar reminders',
                  importance: Importance.high,
                  priority: Priority.high,
                ),
                iOS: DarwinNotificationDetails(),
              ),
              androidScheduleMode: AndroidScheduleMode.inexact,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
            );
            debugPrint('Sahur notification scheduled (inexact)');
          } catch (e3) {
            debugPrint('Error scheduling Sahur notification (inexact): $e3');
          }
        }
      } else {
        rethrow;
      }
    }
  }

  static Future<void> scheduleIftarReminder({
    required DateTime maghribTime,
    required int offsetMinutes,
    required String title,
    required String body,
  }) async {
    var reminderTime = maghribTime.add(Duration(minutes: offsetMinutes));
    final now = DateTime.now();
    
    // Check if reminder time is very close (within 15 minutes) - schedule it anyway
    final timeUntilReminder = reminderTime.difference(now);
    final isVeryClose = timeUntilReminder.inMinutes >= 0 && timeUntilReminder.inMinutes <= 15;
    
    // If reminder time has passed today (more than 1 minute), schedule for tomorrow
    // But if it's within 1 minute, keep it for today so we can send immediate notification
    if (reminderTime.isBefore(now) && timeUntilReminder.inMinutes < -1) {
      reminderTime = reminderTime.add(const Duration(days: 1));
      debugPrint('Iftar reminder time passed, scheduling for tomorrow: $reminderTime');
    }
    
    debugPrint('Scheduling Iftar reminder for: $reminderTime (Maghrib: $maghribTime, offset: $offsetMinutes)');
    debugPrint('  Time until reminder: ${timeUntilReminder.inMinutes} minutes');
    debugPrint('  Is very close: $isVeryClose');
    
    // If reminder time is very close (within 1 minute), send immediate notification as backup
    // This ensures notification appears even if scheduled notification is delayed
    if (timeUntilReminder.inMinutes >= 0 && timeUntilReminder.inMinutes <= 1) {
      debugPrint('  Iftar is very close (${timeUntilReminder.inMinutes} min), will send immediate backup at exact time');
      // Don't send immediately, but schedule a backup notification at exact time
      try {
        final backupTime = reminderTime;
        final backupScheduledTime = tz.TZDateTime.from(backupTime, tz.local);
        await _notifications.zonedSchedule(
          _getNotificationId('iftar_backup_exact', backupTime),
          title,
          body,
          backupScheduledTime,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'ramadan_reminders',
              'Ramadan Reminders',
              channelDescription: 'Sahur and Iftar reminders',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: null, // Exact time, no recurring
        );
        debugPrint('  ✓ Backup notification scheduled for exact Iftar time: $backupScheduledTime');
      } catch (e) {
        debugPrint('  ✗ Error scheduling backup notification: $e');
      }
    }

    try {
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
      debugPrint('Scheduling Iftar notification at: $scheduledTime (local timezone)');
      
      // Use matchDateTimeComponents only if scheduling for future days (tomorrow or later)
      // For today's notification, use absolute time (null = no recurring)
      final daysUntilReminder = reminderTime.difference(now).inDays;
      final useTimeMatch = daysUntilReminder > 0;
      debugPrint('  Days until reminder: $daysUntilReminder, useTimeMatch: $useTimeMatch');
      
      await _notifications.zonedSchedule(
        _getNotificationId('iftar', reminderTime),
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'ramadan_reminders',
            'Ramadan Reminders',
            channelDescription: 'Sahur and Iftar reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: useTimeMatch ? DateTimeComponents.time : null,
      );
      debugPrint('✓ Iftar notification scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling Iftar notification (exact): $e');
      // Fallback to inexact scheduling if exact alarms not permitted
      if (e.toString().contains('exact_alarms_not_permitted')) {
        try {
          final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
          final daysUntilReminder = reminderTime.difference(now).inDays;
          final useTimeMatch = daysUntilReminder > 0;
          await _notifications.zonedSchedule(
            _getNotificationId('iftar', reminderTime),
            title,
            body,
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'ramadan_reminders',
                'Ramadan Reminders',
                channelDescription: 'Sahur and Iftar reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: useTimeMatch ? DateTimeComponents.time : null,
          );
          debugPrint('Iftar notification scheduled (inexact allowWhileIdle)');
        } catch (e2) {
          debugPrint('Error scheduling Iftar notification (inexact allowWhileIdle): $e2');
          // If still fails, use inexact without allowWhileIdle
          try {
            final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
            final daysUntilReminder = reminderTime.difference(now).inDays;
            final useTimeMatch = daysUntilReminder > 0;
            await _notifications.zonedSchedule(
              _getNotificationId('iftar', reminderTime),
              title,
              body,
              scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'ramadan_reminders',
                'Ramadan Reminders',
                channelDescription: 'Sahur and Iftar reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexact,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: useTimeMatch ? DateTimeComponents.time : null,
            );
            debugPrint('Iftar notification scheduled (inexact)');
          } catch (e3) {
            debugPrint('Error scheduling Iftar notification (inexact): $e3');
          }
        }
      } else {
        rethrow;
      }
    }
  }

  static Future<void> scheduleNightPlanReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _getNotificationId('night_plan', reminderTime),
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gentle_reminders',
          'Gentle Reminders',
          channelDescription: 'Quran, Dhikr, and other gentle reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleHabitReminder({
    required int hour,
    required int minute,
    required String habitName,
    required String channelId,
  }) async {
    final now = DateTime.now();
    var reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
    
    if (reminderTime.isBefore(now)) {
      reminderTime = reminderTime.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      _getNotificationId('habit_$habitName', reminderTime),
      'Ramadan Reminder',
      'Time for $habitName',
      tz.TZDateTime.from(reminderTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Gentle Reminders',
          channelDescription: 'Quran, Dhikr, and other gentle reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static int _getNotificationId(String type, DateTime time) {
    return '$type${time.millisecondsSinceEpoch}'.hashCode.abs() % 2147483647;
  }

  static Future<void> scheduleAllReminders({
    required AppDatabase database,
    required int seasonId,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String highLatRule,
    required bool sahurEnabled,
    required int sahurOffsetMinutes,
    required bool iftarEnabled,
    required int iftarOffsetMinutes,
    required bool nightPlanEnabled,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) async {
    await NotificationService.requestPermissions();
    
    await PrayerTimeService.ensureTodayAndTomorrowCached(
      database: database,
      seasonId: seasonId,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      method: method,
      highLatRule: highLatRule,
      fajrAdjust: fajrAdjust,
      maghribAdjust: maghribAdjust,
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    debugPrint('=== Scheduling reminders ===');
    debugPrint('Current time: $now');
    debugPrint('Today: $today, Tomorrow: $tomorrow');

    for (final date in [today, tomorrow]) {
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

      debugPrint('Prayer times for ${date.toIso8601String().split('T')[0]}:');
      debugPrint('  Fajr: ${times['fajr']}');
      debugPrint('  Maghrib: ${times['maghrib']}');

      if (sahurEnabled) {
        await scheduleSahurReminder(
          fajrTime: times['fajr']!,
          offsetMinutes: sahurOffsetMinutes,
          title: 'Sahur Reminder',
          body: 'Time to prepare for Sahur',
        );
      } else {
        debugPrint('Sahur reminder disabled');
      }

      if (iftarEnabled) {
        await scheduleIftarReminder(
          maghribTime: times['maghrib']!,
          offsetMinutes: iftarOffsetMinutes,
          title: 'Iftar Reminder',
          body: 'Time for Iftar',
        );
        
        // For today's Iftar, also set up a backup immediate notification if very close
        if (date == today && times['maghrib'] != null) {
          final iftarTime = times['maghrib']!.add(Duration(minutes: iftarOffsetMinutes));
          final timeUntilIftar = iftarTime.difference(now);
          // If Iftar is within 10 minutes, also schedule an immediate notification as backup
          if (timeUntilIftar.inMinutes <= 10 && timeUntilIftar.inMinutes > 0) {
            debugPrint('Iftar is very close (${timeUntilIftar.inMinutes} min), scheduling backup immediate notification');
            // Schedule immediate notification to fire at Iftar time
            try {
              final scheduledTime = tz.TZDateTime.from(iftarTime, tz.local);
              await _notifications.zonedSchedule(
                _getNotificationId('iftar_backup', iftarTime),
                'Iftar Reminder',
                'Time for Iftar',
                scheduledTime,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'ramadan_reminders',
                    'Ramadan Reminders',
                    channelDescription: 'Sahur and Iftar reminders',
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                  iOS: DarwinNotificationDetails(),
                ),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                matchDateTimeComponents: null, // No recurring for backup
              );
              debugPrint('Backup Iftar notification scheduled for: $scheduledTime');
            } catch (e) {
              debugPrint('Error scheduling backup Iftar notification: $e');
            }
          }
        }
      } else {
        debugPrint('Iftar reminder disabled');
      }
    }
    
    // Check if we should send immediate notification for today's missed times
    final todayTimes = await PrayerTimeService.getCachedOrCalculate(
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
    
    // Send immediate notification if iftar time passed recently (within last 2 hours)
    // OR if Iftar time is very close (within 1 minute) - send immediately to ensure it appears
    if (iftarEnabled && todayTimes['maghrib'] != null) {
      final iftarTime = todayTimes['maghrib']!.add(Duration(minutes: iftarOffsetMinutes));
      final timeSinceIftar = now.difference(iftarTime);
      final timeUntilIftar = iftarTime.difference(now);
      
      debugPrint('=== Checking immediate Iftar notification ===');
      debugPrint('  Current time: $now');
      debugPrint('  Maghrib time: ${todayTimes['maghrib']}');
      debugPrint('  Iftar offset: $iftarOffsetMinutes minutes');
      debugPrint('  Iftar time (maghrib + offset): $iftarTime');
      debugPrint('  Time since Iftar: ${timeSinceIftar.inMinutes} minutes (${timeSinceIftar.inHours} hours)');
      debugPrint('  Time until Iftar: ${timeUntilIftar.inMinutes} minutes');
      debugPrint('  Iftar passed: ${iftarTime.isBefore(now)}');
      debugPrint('  Within 2 hours: ${timeSinceIftar.inHours < 2}');
      
      // Send notification if:
      // 1. Iftar time has passed and it's within last 2 hours, OR
      // 2. Iftar time is very close (within 1 minute) - send immediately to ensure it appears
      final shouldSendImmediate = (iftarTime.isBefore(now) && 
                                  timeSinceIftar.inHours < 2 && 
                                  timeSinceIftar.inMinutes >= 0) ||
                                  (iftarTime.isAfter(now) && 
                                  timeUntilIftar.inMinutes <= 1 && 
                                  timeUntilIftar.inMinutes >= 0);
      
      if (shouldSendImmediate) {
        debugPrint('Iftar time condition met, sending immediate notification');
        debugPrint('  - Time until Iftar: ${timeUntilIftar.inMinutes} minutes');
        try {
          // Send immediate notification now
          await _notifications.show(
            _getNotificationId('iftar_immediate', now),
            'Iftar Reminder',
            'Time for Iftar',
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'ramadan_reminders',
                'Ramadan Reminders',
                channelDescription: 'Sahur and Iftar reminders',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
          );
          debugPrint('✓ Immediate Iftar notification sent successfully');
          
          // Also schedule a backup notification at exact Iftar time if still in future (within 1 minute)
          if (iftarTime.isAfter(now) && timeUntilIftar.inMinutes > 0 && timeUntilIftar.inMinutes <= 1) {
            debugPrint('  Scheduling backup notification at exact Iftar time');
            try {
              final backupScheduledTime = tz.TZDateTime.from(iftarTime, tz.local);
              await _notifications.zonedSchedule(
                _getNotificationId('iftar_immediate_backup', iftarTime),
                'Iftar Reminder',
                'Time for Iftar',
                backupScheduledTime,
                const NotificationDetails(
                  android: AndroidNotificationDetails(
                    'ramadan_reminders',
                    'Ramadan Reminders',
                    channelDescription: 'Sahur and Iftar reminders',
                    importance: Importance.high,
                    priority: Priority.high,
                  ),
                  iOS: DarwinNotificationDetails(),
                ),
                androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
                uiLocalNotificationDateInterpretation:
                    UILocalNotificationDateInterpretation.absoluteTime,
                matchDateTimeComponents: null,
              );
              debugPrint('  ✓ Backup notification scheduled for: $backupScheduledTime');
            } catch (e) {
              debugPrint('  ✗ Error scheduling backup: $e');
            }
          }
        } catch (e) {
          debugPrint('✗ Error showing immediate iftar notification: $e');
        }
      } else {
        debugPrint('Iftar notification not sent: conditions not met');
        debugPrint('  - Iftar passed: ${iftarTime.isBefore(now)}');
        debugPrint('  - Time since: ${timeSinceIftar.inMinutes} min');
        debugPrint('  - Time until: ${timeUntilIftar.inMinutes} min');
        debugPrint('  - Within 2h: ${timeSinceIftar.inHours < 2}');
      }
    } else {
      debugPrint('Iftar immediate notification check skipped:');
      debugPrint('  - Iftar enabled: $iftarEnabled');
      debugPrint('  - Maghrib time: ${todayTimes['maghrib']}');
    }

    if (nightPlanEnabled) {
      await scheduleNightPlanReminder(
        hour: 21,
        minute: 0,
        title: 'Night Plan',
        body: 'Review your plan for tonight',
      );
    }
  }

  static Future<void> testNotification() async {
    await _notifications.show(
      999999,
      'Test Notification',
      'This is a test notification from Ramadan Offline',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'gentle_reminders',
          'Gentle Reminders',
          channelDescription: 'Test notifications',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  static Future<List<NotificationInfo>> getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    return pending.map((p) => NotificationInfo(
      id: p.id,
      title: p.title,
      body: p.body,
    )).toList();
  }

  static Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  /// Schedule a goal reminder notification
  /// Note: This method uses hardcoded strings. For localization, 
  /// we would need to pass AppLocalizations, but since this is a static method,
  /// we'll use English for now. Can be improved later.
  static Future<void> scheduleGoalReminder({
    required DateTime reminderTime,
    required String type, // 'quran', 'dhikr', 'sedekah', 'taraweeh'
    required int current,
    required int target,
  }) async {
    String title;
    String body;

    switch (type) {
      case 'quran':
        title = 'Quran Goal Reminder';
        body = 'Haven\'t reached today\'s Quran target ($current/$target pages). Keep going!';
        break;
      case 'dhikr':
        title = 'Dhikr Goal Reminder';
        body = 'Dhikr target not reached ($current/$target). Keep it up!';
        break;
      case 'sedekah':
        title = 'Sedekah Goal Reminder';
        body = 'Today\'s Sedekah target not reached. Don\'t forget to share goodness!';
        break;
      case 'taraweeh':
        title = 'Taraweeh Reminder';
        body = 'Taraweeh time is approaching! Prepare yourself for night prayer.';
        break;
      default:
        return;
    }

    try {
      await _notifications.zonedSchedule(
        _getNotificationId('goal_$type', reminderTime),
        title,
        body,
        tz.TZDateTime.from(reminderTime, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gentle_reminders',
            'Gentle Reminders',
            channelDescription: 'Quran, Dhikr, and other gentle reminders',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      // Fallback to inexact if exact not permitted
      try {
        await _notifications.zonedSchedule(
          _getNotificationId('goal_$type', reminderTime),
          title,
          body,
          tz.TZDateTime.from(reminderTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'gentle_reminders',
              'Gentle Reminders',
              channelDescription: 'Quran, Dhikr, and other gentle reminders',
              importance: Importance.defaultImportance,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (e2) {
        debugPrint('Failed to schedule goal reminder: $e2');
      }
    }
  }

  /// Reschedule all reminders for today and tomorrow
  /// This should be called daily (e.g., on app startup or after Maghrib)
  static Future<void> rescheduleAllReminders({
    required AppDatabase database,
  }) async {
    debugPrint('=== rescheduleAllReminders called ===');
    try {
      // Get current season
      final seasons = await database.ramadanSeasonsDao.getAllSeasons();
      if (seasons.isEmpty) {
        debugPrint('No seasons found, cannot reschedule reminders');
        return;
      }

      final currentSeason = seasons.first; // Use first season for now
      final seasonId = currentSeason.id;
      debugPrint('Using season ID: $seasonId');

      // Get location and settings
      final latitudeStr = await database.kvSettingsDao.getValue('prayer_latitude');
      final longitudeStr = await database.kvSettingsDao.getValue('prayer_longitude');
      final timezone = await database.kvSettingsDao.getValue('prayer_timezone') ?? 'Asia/Jakarta';
      final method = await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl';
      final highLatRule = await database.kvSettingsDao.getValue('prayer_high_lat_rule') ?? 'middle_of_night';
      final fajrAdjust = int.tryParse(await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0') ?? 0;
      final maghribAdjust = int.tryParse(await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0') ?? 0;

      if (latitudeStr == null || longitudeStr == null) {
        debugPrint('Location not set, cannot reschedule reminders');
        return;
      }

      final latitude = double.tryParse(latitudeStr);
      final longitude = double.tryParse(longitudeStr);

      if (latitude == null || longitude == null) {
        debugPrint('Invalid location coordinates: lat=$latitudeStr, lon=$longitudeStr');
        return;
      }
      
      debugPrint('Location: lat=$latitude, lon=$longitude, timezone=$timezone');

      // Get reminder settings
      final sahurEnabled = await database.kvSettingsDao.getValue('sahur_enabled') ?? 'true';
      final sahurOffset = int.tryParse(await database.kvSettingsDao.getValue('sahur_offset') ?? '30') ?? 30;
      final iftarEnabled = await database.kvSettingsDao.getValue('iftar_enabled') ?? 'true';
      final iftarOffset = int.tryParse(await database.kvSettingsDao.getValue('iftar_offset') ?? '0') ?? 0;
      final nightPlanEnabled = await database.kvSettingsDao.getValue('night_plan_enabled') ?? 'true';
      
      debugPrint('Reminder settings: sahur=$sahurEnabled (offset=$sahurOffset), iftar=$iftarEnabled (offset=$iftarOffset)');

      // Cancel old notifications
      await cancelAll();

      // Reschedule all reminders
      await scheduleAllReminders(
        database: database,
        seasonId: seasonId,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        method: method,
        highLatRule: highLatRule,
        sahurEnabled: sahurEnabled == 'true',
        sahurOffsetMinutes: sahurOffset,
        iftarEnabled: iftarEnabled == 'true',
        iftarOffsetMinutes: iftarOffset,
        nightPlanEnabled: nightPlanEnabled == 'true',
        fajrAdjust: fajrAdjust,
        maghribAdjust: maghribAdjust,
      );

      // Schedule goal reminders
      await GoalReminderService.scheduleGoalReminders(
        database: database,
        seasonId: seasonId,
        latitude: latitude,
        longitude: longitude,
        timezone: timezone,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdjust,
        maghribAdjust: maghribAdjust,
      );

      debugPrint('All reminders rescheduled successfully');
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }
}

class NotificationInfo {
  final int id;
  final String? title;
  final String? body;

  NotificationInfo({
    required this.id,
    this.title,
    this.body,
  });
}

