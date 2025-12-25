import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
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
    final reminderTime = fajrTime.subtract(Duration(minutes: offsetMinutes));
    
    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    await _notifications.zonedSchedule(
      _getNotificationId('sahur', reminderTime),
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
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
  }

  static Future<void> scheduleIftarReminder({
    required DateTime maghribTime,
    required int offsetMinutes,
    required String title,
    required String body,
  }) async {
    final reminderTime = maghribTime.add(Duration(minutes: offsetMinutes));
    
    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    await _notifications.zonedSchedule(
      _getNotificationId('iftar', reminderTime),
      title,
      body,
      tz.TZDateTime.from(reminderTime, tz.local),
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

      if (sahurEnabled) {
        await scheduleSahurReminder(
          fajrTime: times['fajr']!,
          offsetMinutes: sahurOffsetMinutes,
          title: 'Sahur Reminder',
          body: 'Time to prepare for Sahur',
        );
      }

      if (iftarEnabled) {
        await scheduleIftarReminder(
          maghribTime: times['maghrib']!,
          offsetMinutes: iftarOffsetMinutes,
          title: 'Iftar Reminder',
          body: 'Time for Iftar',
        );
      }
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

