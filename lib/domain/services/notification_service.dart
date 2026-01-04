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

    debugPrint('Calling _notifications.initialize()...');
    final initialized = await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    debugPrint('NotificationService initialized: $initialized');

    debugPrint('Creating notification channels...');
    await _createChannels();
    debugPrint('Notification channels created');
    
    debugPrint('Setting timezone...');
    await _setTimezone();
    debugPrint('Timezone set');
    
    // Immediately request permissions and test
    if (Platform.isAndroid) {
      debugPrint('Platform is Android, checking permissions...');
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        debugPrint('Android implementation found, requesting permission...');
        final permissionGranted = await androidImpl.requestNotificationsPermission();
        debugPrint('Initial permission check result: $permissionGranted');
        
        // Check current permission status
        final hasPermission = await androidImpl.areNotificationsEnabled();
        debugPrint('Current notification permission status: $hasPermission');
        
        // Check exact alarms
        try {
          debugPrint('Checking exact alarms permission...');
          final canExact = await androidImpl.canScheduleExactNotifications();
          debugPrint('Can schedule exact alarms: $canExact');
        } catch (e, stackTrace) {
          debugPrint('Error checking exact alarms: $e');
          debugPrint('Stack trace: $stackTrace');
        }
      } else {
        debugPrint('WARNING: Android implementation is NULL!');
      }
    } else {
      debugPrint('Platform is not Android, skipping Android-specific checks');
    }
    
    debugPrint('=== NotificationService.initialize() FINISHED ===');
  }

  static Future<void> _createChannels() async {
    const ramadanChannel = AndroidNotificationChannel(
      'ramadan_reminders',
      'Ramadan Reminders',
      description: 'Sahur and Iftar reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    const gentleChannel = AndroidNotificationChannel(
      'gentle_reminders',
      'Gentle Reminders',
      description: 'Quran, Dhikr, and other gentle reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      await androidImpl.createNotificationChannel(ramadanChannel);
      debugPrint('✓ Ramadan channel created (importance: high)');
      
      await androidImpl.createNotificationChannel(gentleChannel);
      debugPrint('✓ Gentle channel created (importance: high)');
    } else {
      debugPrint('ERROR: Android implementation is NULL when creating channels!');
    }
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

  static Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        // Check current permission status
        final granted = await androidImplementation.requestNotificationsPermission();
        debugPrint('Notification permission requested. Granted: $granted');
        
        // Check exact alarms permission (Android 12+)
        if (Platform.isAndroid) {
          try {
            final canScheduleExactAlarms = await androidImplementation.canScheduleExactNotifications();
            debugPrint('Can schedule exact alarms: $canScheduleExactAlarms');
            if (canScheduleExactAlarms != true) {
              debugPrint('WARNING: Exact alarms permission not granted. Notifications may be delayed.');
            }
          } catch (e) {
            debugPrint('Error checking exact alarms permission: $e');
          }
        }
        
        return granted ?? false;
      }
    }
    return false;
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
    final timeUntilReminder = reminderTime.difference(now);
    
    // Iftar notification hanya muncul 1 kali sehari di waktu Maghrib
    // Jika waktu Iftar hari ini sudah lewat lebih dari 1 menit, schedule untuk besok
    // Jika waktu Iftar belum lewat atau baru lewat ≤1 menit, schedule untuk hari ini
    if (reminderTime.isBefore(now) && timeUntilReminder.inMinutes < -1) {
      reminderTime = reminderTime.add(const Duration(days: 1));
      debugPrint('Iftar reminder time passed today (${timeUntilReminder.inMinutes.abs()} min ago), scheduling for tomorrow: $reminderTime');
    } else {
      debugPrint('Iftar reminder time is in the future today or just passed (${timeUntilReminder.inMinutes} min), scheduling for today: $reminderTime');
    }
    
    final finalTimeUntilReminder = reminderTime.difference(now);
    debugPrint('Scheduling Iftar reminder for: $reminderTime (Maghrib: $maghribTime, offset: $offsetMinutes)');
    debugPrint('  Time until reminder: ${finalTimeUntilReminder.inMinutes} minutes');

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
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: useTimeMatch ? DateTimeComponents.time : null,
      );
      debugPrint('✓ Iftar notification scheduled successfully at $scheduledTime');
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
    String? sahurTitle,
    String? sahurBody,
    String? iftarTitle,
    String? iftarBody,
    String? nightPlanTitle,
    String? nightPlanBody,
  }) async {
    final permissionGranted = await NotificationService.requestPermissions();
    if (!permissionGranted) {
      debugPrint('WARNING: Notification permission not granted. Notifications may not appear.');
    }
    
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
          title: sahurTitle ?? 'Sahur Reminder',
          body: sahurBody ?? 'Time to prepare for Sahur',
        );
      } else {
        debugPrint('Sahur reminder disabled');
      }

      if (iftarEnabled) {
        await scheduleIftarReminder(
          maghribTime: times['maghrib']!,
          offsetMinutes: iftarOffsetMinutes,
          title: iftarTitle ?? 'Iftar Reminder',
          body: iftarBody ?? 'Time for Iftar',
        );
        
      } else {
        debugPrint('Iftar reminder disabled');
      }
    }
    
    // Check today's Iftar time (for logging only, no immediate notification)
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
    
    // Iftar notification hanya muncul 1 kali sehari di waktu Maghrib
    // Jika waktu Iftar sudah lewat atau sangat dekat (≤1 menit), kirim immediate notification
    // Jika sudah lewat lebih dari 1 menit, skip (besok sudah di-schedule)
    if (iftarEnabled && todayTimes['maghrib'] != null) {
      final iftarTime = todayTimes['maghrib']!.add(Duration(minutes: iftarOffsetMinutes));
      final timeUntilIftar = iftarTime.difference(now);
      final timeSinceIftar = now.difference(iftarTime);
      
      debugPrint('=== Checking today\'s Iftar notification ===');
      debugPrint('  Current time: $now');
      debugPrint('  Iftar time: $iftarTime');
      debugPrint('  Time until Iftar: ${timeUntilIftar.inMinutes} minutes');
      debugPrint('  Time since Iftar: ${timeSinceIftar.inMinutes} minutes');
      debugPrint('  Iftar passed: ${iftarTime.isBefore(now)}');
      
      // Kirim immediate notification jika:
      // 1. Waktu Iftar sudah lewat tapi masih dalam 1 menit (baru lewat), ATAU
      // 2. Waktu Iftar sangat dekat (≤1 menit dari sekarang)
      // Ini untuk memastikan notification muncul meskipun scheduled notification tidak trigger tepat waktu
      final shouldSendImmediate = (iftarTime.isBefore(now) && timeSinceIftar.inMinutes <= 1) ||
                                  (iftarTime.isAfter(now) && timeUntilIftar.inMinutes <= 1);
      
      if (shouldSendImmediate) {
        debugPrint('Iftar time is very close or just passed (${timeUntilIftar.inMinutes} min until, ${timeSinceIftar.inMinutes} min since), sending immediate notification');
        try {
          await _notifications.show(
            _getNotificationId('iftar_immediate', now),
            iftarTitle ?? 'Iftar Reminder',
            iftarBody ?? 'Time for Iftar',
            NotificationDetails(
              android: AndroidNotificationDetails(
                'ramadan_reminders',
                'Ramadan Reminders',
                channelDescription: 'Sahur and Iftar reminders',
                importance: Importance.max,
                priority: Priority.max,
                showWhen: true,
                enableVibration: true,
                playSound: true,
                visibility: NotificationVisibility.public,
                channelAction: AndroidNotificationChannelAction.createIfNotExists,
              ),
              iOS: const DarwinNotificationDetails(
                presentAlert: true,
                presentBadge: true,
                presentSound: true,
              ),
            ),
          );
          debugPrint('✓ Immediate Iftar notification sent successfully');
        } catch (e) {
          debugPrint('✗ Error showing immediate Iftar notification: $e');
        }
      } else if (iftarTime.isAfter(now)) {
        debugPrint('Iftar time is in the future today (${timeUntilIftar.inMinutes} min), scheduled notification will handle it');
      } else {
        debugPrint('Iftar time has passed more than 1 minute ago (${timeSinceIftar.inMinutes} min), skipping (will use tomorrow\'s scheduled notification)');
      }
    } else {
      debugPrint('Iftar notification check skipped:');
      debugPrint('  - Iftar enabled: $iftarEnabled');
      debugPrint('  - Maghrib time: ${todayTimes['maghrib']}');
    }

    if (nightPlanEnabled) {
      await scheduleNightPlanReminder(
        hour: 21,
        minute: 0,
        title: nightPlanTitle ?? 'Night Plan',
        body: nightPlanBody ?? 'Review your plan for tonight',
      );
    }
  }

  static Future<void> testNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('=== TEST NOTIFICATION START ===');
    debugPrint('Title: $title');
    debugPrint('Body: $body');
    
    // Check permission first
    if (Platform.isAndroid) {
      debugPrint('Checking Android notification permission...');
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final hasPermission = await androidImpl.areNotificationsEnabled();
        debugPrint('Has notification permission: $hasPermission');
        
        if (hasPermission != true) {
          debugPrint('Permission not granted, requesting...');
          final granted = await androidImpl.requestNotificationsPermission();
          debugPrint('Permission request result: $granted');
        } else {
          debugPrint('Permission already granted');
        }
      } else {
        debugPrint('ERROR: Android implementation is NULL!');
      }
    }
    
    try {
      debugPrint('Calling _notifications.show()...');
      // Use a unique ID each time to ensure notification appears
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      debugPrint('Notification ID: $notificationId');
      debugPrint('Channel: gentle_reminders');
      
      // Try to show notification with maximum visibility
      await _notifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'gentle_reminders',
            'Gentle Reminders',
            channelDescription: 'Test notifications',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            ticker: 'Test notification',
            styleInformation: const BigTextStyleInformation(''),
            visibility: NotificationVisibility.public,
            fullScreenIntent: false,
            ongoing: false,
            autoCancel: true,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            category: AndroidNotificationCategory.alarm, // Use alarm category for maximum priority
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.timeSensitive,
          ),
        ),
      );
      
      debugPrint('✓ _notifications.show() completed without error');
      
      // Wait a bit to ensure notification is processed
      await Future.delayed(const Duration(milliseconds: 500));
      
      debugPrint('✓ TEST NOTIFICATION SENT SUCCESSFULLY');
      debugPrint('=== TEST NOTIFICATION END ===');
    } catch (e, stackTrace) {
      debugPrint('✗ ERROR showing test notification: $e');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=== TEST NOTIFICATION FAILED ===');
      rethrow;
    }
  }

  static Future<List<NotificationInfo>> getPendingNotifications() async {
    final pending = await _notifications.pendingNotificationRequests();
    debugPrint('=== Pending Notifications: ${pending.length} ===');
    for (final p in pending) {
      debugPrint('  ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
    }
    return pending.map((p) => NotificationInfo(
      id: p.id,
      title: p.title,
      body: p.body,
    )).toList();
  }
  
  static Future<bool> checkNotificationPermission() async {
    if (Platform.isAndroid) {
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        final granted = await androidImplementation.areNotificationsEnabled();
        debugPrint('Notification permission status: $granted');
        return granted ?? false;
      }
    }
    return false;
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
      final scheduledTime = tz.TZDateTime.from(reminderTime, tz.local);
      debugPrint('Scheduling $type goal reminder at: $scheduledTime');
      await _notifications.zonedSchedule(
        _getNotificationId('goal_$type', reminderTime),
        title,
        body,
        scheduledTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'gentle_reminders',
            'Gentle Reminders',
            channelDescription: 'Quran, Dhikr, and other gentle reminders',
            importance: Importance.high,
            priority: Priority.high,
            showWhen: true,
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('✓ $type goal reminder scheduled successfully');
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
    String? sahurTitle,
    String? sahurBody,
    String? iftarTitle,
    String? iftarBody,
    String? nightPlanTitle,
    String? nightPlanBody,
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

      // Check notification permission status
      final permissionStatus = await checkNotificationPermission();
      debugPrint('Notification permission status: $permissionStatus');

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
        sahurTitle: sahurTitle,
        sahurBody: sahurBody,
        iftarTitle: iftarTitle,
        iftarBody: iftarBody,
        nightPlanTitle: nightPlanTitle,
        nightPlanBody: nightPlanBody,
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
      
      // Log pending notifications after rescheduling
      await getPendingNotifications();
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

