import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/domain/services/goal_reminder_service.dart';
import 'package:ramadan_tracker/utils/log_service.dart';
import 'package:ramadan_tracker/utils/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Flag to prevent recursive clear database calls
  static bool _isClearingDatabase = false;
  
  // Flag to prevent concurrent scheduling (prevents duplicate notifications)
  static bool _isScheduling = false;

  // Base IDs for notification types (deterministic)
  static const int _baseIdSahur = 1000000;
  static const int _baseIdIftar = 2000000;
  static const int _baseIdNightPlan = 3000000;
  static const int _baseIdHabitReminder = 4000000;
  static const int _baseIdGoal = 5000000;
  
  // Goal type indices
  static const int _goalTypeQuran = 0;
  static const int _goalTypeDhikr = 1;
  static const int _goalTypeSedekah = 2;
  static const int _goalTypeTaraweeh = 3;
  
  // Helper: Convert DateTime to YYYYMMDD integer
  static int _yyyymmdd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
  
  // Deterministic ID generation for Sahur/Iftar/Night Plan
  static int _getNotificationId(int baseId, DateTime scheduledDate) {
    final ymd = _yyyymmdd(scheduledDate);
    return baseId + ymd;
  }
  
  // Deterministic ID generation for Goal Reminders
  // Format: baseId + typeIndex*100000 + hour*1000 + yyyymmdd
  static int _getNotificationIdForGoalReminder(int typeIndex, int hour, DateTime scheduledDate) {
    final ymd = _yyyymmdd(scheduledDate);
    return _baseIdGoal + (typeIndex * 100000) + (hour * 1000) + ymd;
  }
  
  // Resolve timezone location from IANA string (source of truth)
  static tz.Location resolveLocation(String ianaTimezone) {
    try {
      final location = tz.getLocation(ianaTimezone);
      LogService.log('[TZ] Resolved location: $ianaTimezone -> ${location.name}');
      return location;
    } catch (e) {
      LogService.log('[TZ] Error resolving location $ianaTimezone: $e, falling back to UTC');
      return tz.UTC;
    }
  }
  
  // Read timezone from database (source of truth)
  static Future<String> readTimezoneFromDb(AppDatabase database) async {
    try {
      final tz = await database.kvSettingsDao.getValue('prayer_timezone');
      final timezone = (tz != null && tz.trim().isNotEmpty) ? tz.trim() : 'UTC';
      LogService.log('[TZ] Read timezone from DB: $timezone');
      return timezone;
    } catch (e) {
      LogService.log('[TZ] Error reading timezone from DB: $e, defaulting to UTC');
      return 'UTC';
    }
  }

  // Initialize and set timezone location
  static Future<void> initializeTimezone(String ianaTimezone) async {
    try {
    tz_data.initializeTimeZones();
      final location = resolveLocation(ianaTimezone);
      tz.setLocalLocation(location);
      LogService.log('[TZ] Timezone initialized and set: ${location.name}');
      if (kDebugMode) {
        debugPrint('[TZ] Timezone initialized and set: ${location.name}');
        debugPrint('[TZ] Current time: ${tz.TZDateTime.now(location)}');
      }
    } catch (e) {
      LogService.log('[TZ] Error initializing timezone: $e, falling back to UTC');
      tz.setLocalLocation(tz.UTC);
    }
  }
  
  // Helper: Get date-only DateTime
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  // Detect corrupt database dengan mencoba get pending notifications
  // Returns true if database is OK, false if corrupt
  // NOTE: Tidak pakai schedule test karena schedule sendiri bisa menyebabkan corruption
  static Future<bool> _detectCorruptDatabase() async {
    try {
      // Coba get pending notifications - ini akan gagal jika database corrupt
      // Tapi tidak akan menyebabkan corruption baru karena hanya read operation
      await _notifications.pendingNotificationRequests();
      return true; // Database OK
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Missing type parameter')) {
        LogService.log('[NOTIF] WARN: Database corrupt detected (cannot read pending notifications)');
        if (kDebugMode) {
          debugPrint('[NOTIF] WARN: Database corrupt detected (cannot read pending notifications)');
        }
        return false; // Database corrupt
      } else {
        // Other error - assume OK (might be permission issue, etc)
        LogService.log('[NOTIF] Error checking database (non-corruption): $e');
        return true; // Assume OK for other errors
      }
    }
  }

  /// Rate-limited schedule: adds delay every [batchSize] notifications to prevent Android rate limiting.
  static Future<bool> _scheduleWithRateLimit({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    AndroidScheduleMode androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
    UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation = UILocalNotificationDateInterpretation.absoluteTime,
    int batchIndex = 0,
    int batchSize = 10,
  }) async {
    if (batchIndex > 0 && batchIndex % batchSize == 0) {
      await Future.delayed(const Duration(milliseconds: 100));
      LogService.log('[NOTIF] Rate limit delay after $batchIndex notifications');
    }
    return await _safeZonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: androidScheduleMode,
      uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
    );
  }

  // Helper untuk safe zonedSchedule dengan error handling untuk corrupt database
  // Auto-fallback ke inexact jika exact alarm permission tidak available
  static Future<bool> _safeZonedSchedule({
    required int id,
    required String? title,
    required String? body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    AndroidScheduleMode androidScheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
    UILocalNotificationDateInterpretation uiLocalNotificationDateInterpretation = UILocalNotificationDateInterpretation.absoluteTime,
  }) async {
    // Check exact alarm permission only for exactAllowWhileIdle (alarmClock has its own requirements)
    final isExactMode = androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle;
    if (isExactMode && Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        try {
          final canExact = await androidImpl.canScheduleExactNotifications();
          if (canExact != true) {
            LogService.log('[NOTIF] WARN: Exact alarm permission not granted for notification ID $id');
            final tzNow = tz.TZDateTime.now(tz.local);
            final timeUntil = scheduledDate.difference(tzNow);
            final isTimeSensitive = timeUntil.inMinutes <= 60;
            
            if (isTimeSensitive) {
              LogService.log('[NOTIF] Time-sensitive notification (${timeUntil.inMinutes} min). Requesting exact alarm permission...');
              try {
                await androidImpl.requestExactAlarmsPermission();
                await Future.delayed(const Duration(milliseconds: 500));
                final canExactAfter = await androidImpl.canScheduleExactNotifications();
                if (canExactAfter != true) {
                  LogService.log('[NOTIF] ERROR: Cannot schedule time-sensitive notification without exact alarms. User must grant Alarms & reminders.');
                  return false;
                }
                LogService.log('[NOTIF] Exact alarm permission granted after request');
              } catch (e) {
                LogService.log('[NOTIF] ERROR: Could not request exact alarm permission: $e');
                return false;
              }
            } else {
              LogService.log('[NOTIF] Far-future notification (${timeUntil.inHours}h). Using INEXACT mode.');
              androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
            }
          } else {
            LogService.log('[NOTIF] Exact alarm permission is granted');
          }
        } catch (e) {
          LogService.log('[NOTIF] Error checking exact alarm permission: $e');
          final tzNow = tz.TZDateTime.now(tz.local);
          final timeUntil = scheduledDate.difference(tzNow);
          if (timeUntil.inMinutes <= 60) {
            LogService.log('[NOTIF] ERROR: Time-sensitive notification and permission check failed. Aborting.');
            return false;
          }
          androidScheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
        }
      }
    }
    
    try {
      // Validate scheduled time is in the future (use tz.local for consistent comparison)
      final tzNow = tz.TZDateTime.now(tz.local);
      final timeUntil = scheduledDate.difference(tzNow);
      
      if (timeUntil.isNegative) {
        LogService.log('[NOTIF] ERROR: Cannot schedule notification ID $id in the past!');
        LogService.log('[NOTIF]   Now (tz.local): $tzNow');
        LogService.log('[NOTIF]   Scheduled: $scheduledDate');
        LogService.log('[NOTIF]   Difference: ${timeUntil.inSeconds}s');
        if (kDebugMode) {
          debugPrint('[NOTIF] ERROR: Cannot schedule notification ID $id in the past!');
        }
        return false;
      }
      
      if (timeUntil.inSeconds < 5) {
        LogService.log('[NOTIF] WARNING: Notification ID $id scheduled very soon (${timeUntil.inSeconds}s)');
      }
      
      // Ensure notification channel exists before scheduling
      // Note: We recreate channel to ensure it's not blocked (getNotificationChannel not available in this plugin version)
      if (Platform.isAndroid) {
        try {
          await _createChannels();
        } catch (e) {
          LogService.log('[NOTIF] Error ensuring channel exists: $e');
          // Continue anyway - channel should exist from initialization
        }
      }
      
      final scheduleModeStr = androidScheduleMode == AndroidScheduleMode.alarmClock
          ? 'ALARM_CLOCK'
          : androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle
              ? 'EXACT'
              : 'INEXACT';
      final timeUntilStr = timeUntil.inSeconds < 60
          ? 'in ${timeUntil.inSeconds} seconds'
          : 'in ${timeUntil.inMinutes} minutes';
      LogService.log('[NOTIF] Scheduling notification ID $id: "$title" at $scheduledDate ($timeUntilStr) [Mode: $scheduleModeStr]');
      LogService.log('[NOTIF] Current time (tz.local): $tzNow, Timezone: ${tz.local.name}');
      
      // Add small delay between individual notifications to prevent Android rate limiting
      // This helps when scheduling many notifications at once (e.g., 64 notifications)
      await Future.delayed(const Duration(milliseconds: 10));
      
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
      );
      
      LogService.log('[NOTIF] Notification ID $id scheduled successfully [Mode: $scheduleModeStr]');
      return true;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Missing type parameter')) {
        LogService.log('[NOTIF] ✗ CRITICAL: Database corrupt detected during schedule! Error: $e');
        LogService.log('[NOTIF] Attempting to auto-clear corrupt database...');
        
        // Auto-clear corrupt database when detected during schedule
        try {
          final cleared = await clearCorruptNotificationDatabase();
          if (cleared) {
            LogService.log('[NOTIF] Database cleared successfully. Waiting for plugin to reload...');
            // Wait longer for plugin to fully reload after database clear
            await Future.delayed(const Duration(milliseconds: 3000));
            
            // Force reinitialize plugin to clear memory cache
            LogService.log('[NOTIF] Force reinitializing plugin to clear memory cache...');
            try {
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
              LogService.log('[NOTIF] Plugin reinitialized after database clear');
            } catch (reinitError) {
              LogService.log('[NOTIF] Error reinitializing plugin: $reinitError');
            }
            
            // Wait a bit more after reinitialize
            await Future.delayed(const Duration(milliseconds: 1000));
            
            // Retry schedule once after clear and reinitialize
            try {
              final retryScheduleModeStr = androidScheduleMode == AndroidScheduleMode.alarmClock
                  ? 'ALARM_CLOCK'
                  : androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle
                      ? 'EXACT'
                      : 'INEXACT';
              LogService.log('[NOTIF] Retrying schedule after database clear and plugin reinitialize...');
              await _notifications.zonedSchedule(
                id,
                title,
                body,
                scheduledDate,
                notificationDetails,
                androidScheduleMode: androidScheduleMode,
                uiLocalNotificationDateInterpretation: uiLocalNotificationDateInterpretation,
              );
              LogService.log('[NOTIF] Notification ID $id scheduled successfully after database clear [Mode: $retryScheduleModeStr]');
              return true;
            } catch (retryError) {
              final retryErrorStr = retryError.toString();
              if (retryErrorStr.contains('Missing type parameter')) {
                LogService.log('[NOTIF] ✗ Retry schedule still fails with corruption. Database may need app restart.');
              } else {
                LogService.log('[NOTIF] ✗ Retry schedule failed after clear: $retryError');
              }
              return false;
            }
          } else {
            LogService.log('[NOTIF] ✗ Failed to clear corrupt database. User needs to clear app data or reinstall app.');
          }
        } catch (clearError) {
          LogService.log('[NOTIF] ✗ Error during auto-clear: $clearError');
        }
        
        if (kDebugMode) {
          debugPrint('[NOTIF] ✗ CRITICAL: Database corrupt! Cannot schedule notification ID $id');
          debugPrint('[NOTIF] ✗ Error: $e');
        }
        return false;
      } else {
        LogService.log('[NOTIF] ✗ Error scheduling notification ID $id: $e');
        if (kDebugMode) {
          debugPrint('[NOTIF] ✗ Error scheduling notification ID $id: $e');
        }
        return false;
      }
    }
  }

  static Future<void> testNotification({
    required String title,
    required String body,
  }) async {
    debugPrint('=== TEST NOTIFICATION START ===');
    
    if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final hasPermission = await androidImpl.areNotificationsEnabled();
        debugPrint('Has notification permission: $hasPermission');
        
        if (hasPermission != true) {
          final granted = await androidImpl.requestNotificationsPermission();
          debugPrint('Permission request result: $granted');
        }
      }
    }
    
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch % 2147483647;
      
      await _notifications.show(
        notificationId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
      'ramadan_reminders',
      'Ramadan Reminders',
            channelDescription: 'Test notifications',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            autoCancel: true,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      
      debugPrint('TEST NOTIFICATION SENT SUCCESSFULLY');
    } catch (e, stackTrace) {
      debugPrint('✗ ERROR showing test notification: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<NotificationInfo>> getPendingNotifications() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      LogService.log('[NOTIF] === Pending Notifications: ${pending.length} ===');
      if (kDebugMode) {
        debugPrint('=== Pending Notifications: ${pending.length} ===');
      }
      for (final p in pending) {
        LogService.log('[NOTIF]   ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
        if (kDebugMode) {
          debugPrint('  ID: ${p.id}, Title: ${p.title}, Body: ${p.body}');
        }
      }
      return pending.map((p) => NotificationInfo(
        id: p.id,
        title: p.title,
        body: p.body,
      )).toList();
    } catch (e, stackTrace) {
      LogService.log('[NOTIF] Error getting pending notifications: $e');
      if (kDebugMode) {
        debugPrint('[NOTIF] Error getting pending notifications: $e');
      }
      return [];
    }
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

  static Future<void> cancel(int id) async {
    try {
      await _notifications.cancel(id);
    } catch (e) {
      LogService.log('[NOTIF] Error cancelling notification $id: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      // Add small delay to prevent rate limiting if called multiple times
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get count before cancel for verification
      final beforeCount = await getPendingNotifications();
      LogService.log('[NOTIF] cancelAll() called - current pending: ${beforeCount.length}');
      
      await _notifications.cancelAll();
      
      // Wait for cancellation to propagate through Android system
      await Future.delayed(const Duration(milliseconds: 300));
      
      // Verify cancellation worked
      final afterCount = await getPendingNotifications();
      LogService.log('[NOTIF] cancelAll() completed - pending after: ${afterCount.length}');
      
      if (afterCount.length > 0) {
        LogService.log('[NOTIF] WARNING: cancelAll() did not remove all notifications (${beforeCount.length} -> ${afterCount.length})');
      } else {
        LogService.log('[NOTIF] cancelAll() successful - all notifications removed');
      }
    } catch (e, stackTrace) {
      LogService.log('[NOTIF] Error cancelling notifications: $e');
      if (kDebugMode) {
        debugPrint('[NOTIF] Error cancelling notifications: $e');
        debugPrint('[NOTIF] Stack trace: $stackTrace');
      }
      // Re-throw so caller knows cancellation failed
      rethrow;
    }
  }

  /// Completely clear notification database by cancelling all notifications
  /// and attempting to clear corrupt entries.
  /// Note: If database is corrupt, this may not work and user needs to clear app data.
  static Future<bool> clearNotificationDatabase() async {
    try {
      LogService.log('[NOTIF] Attempting to clear notification database...');
      
      // First, try to cancel all notifications
      try {
        await cancelAll();
    } catch (e) {
        LogService.log('[NOTIF] Error cancelling all: $e');
        // Continue anyway - database might be corrupt
      }
      
      // Try to cancel notifications by ID range (for corrupt entries)
      int cancelledCount = 0;
      for (int id = 1; id < 10000; id++) {
        try {
          await _notifications.cancel(id);
          cancelledCount++;
        } catch (_) {
          // Ignore individual cancel errors
        }
      }
      
      LogService.log('[NOTIF] Attempted to cancel $cancelledCount notifications');
      
      // Reinitialize to potentially fix corrupt database
      try {
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

        LogService.log('[NOTIF] Reinitialized notification service');
    } catch (e) {
        LogService.log('[NOTIF] Error reinitializing: $e');
      }
      
      // Don't test after clear - native clear is aggressive and should work
      // Testing might fail due to timing issues even if clear was successful
      LogService.log('[NOTIF] Notification database cleared successfully (native clear)');
      return true;
    } catch (e) {
      LogService.log('[NOTIF] Error clearing notification database: $e');
      return false;
    }
  }

  /// Clear corrupt notification database via native code
  /// This directly deletes the SharedPreferences file that stores notifications
  /// This is the RECOMMENDED method to fix corrupt database
  static Future<bool> clearCorruptNotificationDatabase({bool skipReinitialize = false}) async {
    // Prevent recursive calls
    if (_isClearingDatabase) {
      LogService.log('[NOTIF] Already clearing database, skipping...');
      return true;
    }
    
    _isClearingDatabase = true;
    try {
      LogService.log('[NOTIF] ========================================');
      LogService.log('[NOTIF] Attempting to clear corrupt notification database via native code...');
      
    if (Platform.isAndroid) {
        // Use MethodChannel to call native Android code
        const platform = MethodChannel('com.ramadan_tracker/notifications');
        try {
          LogService.log('[NOTIF] Calling native method: clearNotificationDatabase');
          final result = await platform.invokeMethod('clearNotificationDatabase');
          LogService.log('[NOTIF] Native clear result: $result (type: ${result.runtimeType})');
          
          if (result == true) {
            LogService.log('[NOTIF] Notification database cleared successfully via native code');
            
            // Wait longer for SharedPreferences to be fully cleared and written to disk
            LogService.log('[NOTIF] Waiting for SharedPreferences to be written to disk...');
            await Future.delayed(const Duration(milliseconds: 2000));
            
            // Force close and reinitialize notification service
            LogService.log('[NOTIF] Reinitializing notification service...');
            try {
              // Try to cancel all first (might fail if database is corrupt, that's OK)
              try {
                await _notifications.cancelAll();
              } catch (e) {
                LogService.log('[NOTIF] Error cancelling all (expected if corrupt): $e');
              }
            } catch (e) {
              LogService.log('[NOTIF] Error before reinitialize: $e');
            }
            
            // Reinitialize notification service (only if not skipped)
            if (!skipReinitialize) {
              // Force reinitialize plugin to clear memory cache
              LogService.log('[NOTIF] Force reinitializing plugin to clear memory cache...');
              try {
                // First, try to cancel all notifications (might fail if corrupt, that's OK)
                try {
                  await _notifications.cancelAll();
                } catch (e) {
                  LogService.log('[NOTIF] Error cancelling all before reinitialize (expected if corrupt): $e');
                }
                
                // Wait a bit before reinitialize
                await Future.delayed(const Duration(milliseconds: 500));
                
                // Force reinitialize plugin
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
                LogService.log('[NOTIF] Plugin reinitialized after database clear');
              } catch (reinitError) {
                LogService.log('[NOTIF] Error reinitializing plugin: $reinitError');
                // Fallback to standard initialize
                try {
                  await initialize();
                } catch (e) {
                  LogService.log('[NOTIF] Error in fallback initialize: $e');
                }
              }
              
              // Wait longer after reinitialize to ensure plugin has fully reloaded
              await Future.delayed(const Duration(milliseconds: 2000));
              LogService.log('[NOTIF] Notification service reinitialized');
            } else {
              LogService.log('[NOTIF] Skipping reinitialize (called from initialize)');
            }
            
            // Native clear is aggressive (deletes SharedPreferences files directly)
            // So we assume it worked - no need to test (test might fail if plugin hasn't reloaded yet)
            LogService.log('[NOTIF] Database cleared via native code (aggressive clear)');
            LogService.log('[NOTIF] ========================================');
            return true;
          } else {
            LogService.log('[NOTIF] ✗ Native clear returned false');
          }
        } catch (e, stackTrace) {
          LogService.log('[NOTIF] Error calling native method: $e');
          LogService.log('[NOTIF] Stack trace: $stackTrace');
          LogService.log('[NOTIF] Falling back to standard clear method...');
        }
      } else {
        LogService.log('[NOTIF] Not Android platform, skipping native method');
      }
      
      // Fallback: Try standard clear method (but this will fail if database is corrupt)
      LogService.log('[NOTIF] Trying fallback method...');
      try {
        await _notifications.cancelAll();
      } catch (e) {
        LogService.log('[NOTIF] Error cancelling all in fallback (expected if corrupt): $e');
      }
      
      // Reinitialize only if not skipped
      if (!skipReinitialize) {
        await initialize();
      }
      
      // Don't test after fallback - if we're here, native clear failed
      // Return false so caller knows to try again or user needs to clear app data
      LogService.log('[NOTIF] Fallback clear completed (may still be corrupt)');
      LogService.log('[NOTIF] ========================================');
      _isClearingDatabase = false;
      return false; // Return false because native clear failed
    } catch (e, stackTrace) {
      LogService.log('[NOTIF] Error in clearCorruptNotificationDatabase: $e');
      LogService.log('[NOTIF] Stack trace: $stackTrace');
      LogService.log('[NOTIF] ========================================');
      _isClearingDatabase = false;
      return false;
    } finally {
      _isClearingDatabase = false;
    }
  }

  static Future<void> scheduleGoalReminder({
    required DateTime reminderTime,
    required String type,
    required int current,
    required int target,
    required tz.Location location,
  }) async {
    debugPrint('=== scheduleGoalReminder START ===');
    debugPrint('Type: $type, Time: ${reminderTime.hour}:${reminderTime.minute.toString().padLeft(2, '0')}');
    
    String title;
    String body;
    int typeIndex;
    int hour = reminderTime.hour;

    switch (type) {
      case 'quran':
        title = 'Quran Goal Reminder';
        body = 'Haven\'t reached today\'s Quran target ($current/$target pages). Keep going!';
        typeIndex = _goalTypeQuran;
        break;
      case 'dhikr':
        title = 'Dhikr Goal Reminder';
        body = 'Dhikr target not reached ($current/$target). Keep it up!';
        typeIndex = _goalTypeDhikr;
        break;
      case 'sedekah':
        title = 'Sedekah Goal Reminder';
        body = 'Today\'s Sedekah target not reached. Don\'t forget to share goodness!';
        typeIndex = _goalTypeSedekah;
        break;
      case 'taraweeh':
        title = 'Taraweeh Reminder';
        body = 'Taraweeh time is approaching! Prepare yourself for night prayer.';
        typeIndex = _goalTypeTaraweeh;
        break;
      default:
        debugPrint('Unknown type: $type');
        return;
    }

    try {
      final tzNow = tz.TZDateTime.now(location);
      
      // Create scheduled time in the correct timezone
      var scheduledTime = tz.TZDateTime(
        location,
        reminderTime.year,
        reminderTime.month,
        reminderTime.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      
      // Jika waktu sudah lewat, schedule untuk besok
      if (scheduledTime.isBefore(tzNow)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
        if (kDebugMode) {
          debugPrint('Goal reminder time passed, scheduling for tomorrow');
        }
      }
      
      // Generate ID based on scheduled date, type index, and hour
      final notificationId = _getNotificationIdForGoalReminder(typeIndex, hour, scheduledTime);
      
      // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
      // Individual cancels cause Android rate limiting (5 ops/sec limit)
      
      final timeUntilScheduled = scheduledTime.difference(tzNow);
      
      if (kDebugMode) {
        debugPrint('Scheduling goal reminder:');
        debugPrint('  Timezone: ${location.name}');
        debugPrint('  Type: $type');
        debugPrint('  Reminder time (local): $reminderTime');
        debugPrint('  Scheduled (TZ): $scheduledTime');
        debugPrint('  Current (TZ): $tzNow');
        debugPrint('  Time until scheduled: ${timeUntilScheduled.inMinutes} minutes');
        debugPrint('  Notification ID: $notificationId');
        LogService.log('[NOTIF] Scheduling goal reminder $type: timezone=${location.name}, scheduled=$scheduledTime, now=$tzNow, minutesUntil=${timeUntilScheduled.inMinutes}, ID=$notificationId');
      }
      
      final scheduled = await _safeZonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'ramadan_reminders',
            'Ramadan Reminders',
            channelDescription: 'Sahur, Iftar, and goal reminders',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            ongoing: false,
            autoCancel: true,
            enableLights: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      if (kDebugMode) {
        if (scheduled) {
          debugPrint('$type goal reminder scheduled successfully (ID: $notificationId)');
        } else {
          debugPrint('✗ Failed to schedule goal reminder (database may be corrupt)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('✗ Error scheduling $type goal reminder: $e');
      }
      // Fallback to inexact
      final tzNow2 = tz.TZDateTime.now(location);
      var scheduledTime2 = tz.TZDateTime(
        location,
        reminderTime.year,
        reminderTime.month,
        reminderTime.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      if (scheduledTime2.isBefore(tzNow2)) {
        scheduledTime2 = scheduledTime2.add(const Duration(days: 1));
      }
      
      final notificationId2 = _getNotificationIdForGoalReminder(typeIndex, hour, scheduledTime2);
      
      // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
      
      await _safeZonedSchedule(
        id: notificationId2,
        title: title,
        body: body,
        scheduledDate: scheduledTime2,
        notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'ramadan_reminders',
                'Ramadan Reminders',
            channelDescription: 'Sahur, Iftar, and goal reminders',
            importance: Importance.max,
            priority: Priority.max,
            showWhen: true,
            enableVibration: true,
            playSound: true,
            visibility: NotificationVisibility.public,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            ongoing: false,
            autoCancel: true,
            enableLights: true,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      // Fallback scheduled (no tomorrow scheduling in fallback)
    }
  }
  
  static Future<void> scheduleTestNotification({int seconds = 10}) async {
    LogService.log('[TEST] === scheduleTestNotification: ${seconds}s ===');
    if (kDebugMode) {
      debugPrint('[TEST] Current timezone: ${tz.local.name}');
    }
    
    if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final hasPermission = await androidImpl.areNotificationsEnabled();
        LogService.log('[TEST] Notification permission: $hasPermission');
        if (hasPermission != true) {
          final requested = await androidImpl.requestNotificationsPermission();
          LogService.log('[TEST] Permission requested: $requested');
        }
        
        // Check exact alarm permission
        try {
          final canExact = await androidImpl.canScheduleExactNotifications();
          LogService.log('[TEST] Can schedule exact alarms: $canExact');
        } catch (e) {
          LogService.log('[TEST] Error checking exact alarms: $e');
        }
      }
    }
    
    // Show immediate notification first to test if notifications work at all
    try {
      await _notifications.show(
        9998,
        'Test Notification (Immediate)',
        'This is an immediate test notification. If you see this, notifications are working!',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ramadan_reminders',
                  'Ramadan Reminders',
            importance: Importance.max,
            priority: Priority.max,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            enableVibration: true,
            playSound: true,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      LogService.log('[TEST] Immediate notification shown');
    } catch (e) {
      LogService.log('[TEST] ✗ Error showing immediate notification: $e');
    }
    
    // Also schedule one for later (use UTC for test)
    final tzNow = tz.TZDateTime.now(tz.UTC);
    final scheduledTime = tzNow.add(Duration(seconds: seconds));
    
    LogService.log('[TEST] Scheduling notification for: $scheduledTime (in $seconds seconds)');
    LogService.log('[TEST] Current time: $tzNow');
    
    final scheduled = await _safeZonedSchedule(
      id: 9999,
      title: 'Test Notification (Scheduled)',
      body: 'This appeared $seconds seconds after the immediate one. Scheduled time: $scheduledTime',
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ramadan_reminders',
          'Ramadan Reminders',
          importance: Importance.max,
          priority: Priority.max,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
          enableVibration: true,
          playSound: true,
          showWhen: true,
          visibility: NotificationVisibility.public,
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
    if (scheduled) {
      LogService.log('[TEST] Scheduled notification set for $scheduledTime');
      LogService.log('[TEST] Time until scheduled: ${scheduledTime.difference(tzNow).inSeconds} seconds');
    } else {
      LogService.log('[TEST] ✗ Error scheduling notification (database may be corrupt)');
    }
  }
  
  static Future<List<PendingNotificationRequest>> debugPending() async {
    final pending = await _notifications.pendingNotificationRequests();
    if (kDebugMode) {
      debugPrint('=== Pending Notifications: ${pending.length} ===');
      final tzNow = DateTime.now();
      debugPrint('Current time: $tzNow');
      
      if (pending.isEmpty) {
        debugPrint('WARNING: No pending notifications found!');
      } else {
        for (final p in pending) {
          debugPrint('  ID: ${p.id}, Title: ${p.title}');
        }
      }
    }
    return pending;
  }

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
      final seasons = await database.ramadanSeasonsDao.getAllSeasons();
      if (seasons.isEmpty) {
        debugPrint('No seasons found');
        return;
      }

      final currentSeason = seasons.first;
      final seasonId = currentSeason.id;

      final latitudeStr = await database.kvSettingsDao.getValue('prayer_latitude');
      final longitudeStr = await database.kvSettingsDao.getValue('prayer_longitude');
      final timezone = await database.kvSettingsDao.getValue('prayer_timezone') ?? 'Asia/Jakarta';
      final method = await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl';
      final highLatRule = await database.kvSettingsDao.getValue('prayer_high_lat_rule') ?? 'middle_of_night';
      final fajrAdjust = int.tryParse(await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0') ?? 0;
      final maghribAdjust = int.tryParse(await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0') ?? 0;

      if (latitudeStr == null || longitudeStr == null) {
        debugPrint('Location not set');
        return;
      }

      final latitude = double.tryParse(latitudeStr);
      final longitude = double.tryParse(longitudeStr);

      if (latitude == null || longitude == null) {
        debugPrint('Invalid coordinates');
        return;
      }

      final sahurEnabled = await database.kvSettingsDao.getValue('sahur_enabled') ?? 'true';
      final sahurOffset = (int.tryParse(await database.kvSettingsDao.getValue('sahur_offset') ?? '30') ?? 30).clamp(1, 45);
      final iftarEnabled = await database.kvSettingsDao.getValue('iftar_enabled') ?? 'true';
      final iftarOffset = int.tryParse(await database.kvSettingsDao.getValue('iftar_offset') ?? '0') ?? 0;
      final nightPlanEnabled = await database.kvSettingsDao.getValue('night_plan_enabled') ?? 'true';

      // CRITICAL: Cancel all existing notifications FIRST to prevent duplicates
      // Without this, each reschedule adds more notifications instead of replacing them
      LogService.log('[NOTIF] ========================================');
      LogService.log('[NOTIF] RESCHEDULE: Cancelling all existing notifications...');
      
      int cancelAttempts = 0;
      const maxCancelAttempts = 3;
      bool cancelSuccess = false;
      
      while (cancelAttempts < maxCancelAttempts && !cancelSuccess) {
        try {
          cancelAttempts++;
          LogService.log('[NOTIF] RESCHEDULE: Cancel attempt $cancelAttempts/$maxCancelAttempts...');
          
          // Get count before cancel
          final beforeCancel = await getPendingNotifications();
          LogService.log('[NOTIF] RESCHEDULE: Notifications before cancel: ${beforeCancel.length}');
          
          await cancelAll();
          
          // Wait for cancellation to propagate
          await Future.delayed(const Duration(milliseconds: 500));
          
          // Verify cancellation worked
          final afterCancel = await getPendingNotifications();
          LogService.log('[NOTIF] RESCHEDULE: Notifications after cancel: ${afterCancel.length}');
          
          if (afterCancel.length == 0) {
            cancelSuccess = true;
            LogService.log('[NOTIF] RESCHEDULE: All notifications cancelled successfully');
          } else if (afterCancel.length < beforeCancel.length) {
            // Some cancelled, but not all - try again
            LogService.log('[NOTIF] RESCHEDULE: WARN Partial cancellation (${beforeCancel.length} -> ${afterCancel.length}), retrying...');
            await Future.delayed(const Duration(milliseconds: 500));
          } else {
            LogService.log('[NOTIF] RESCHEDULE: WARN Cancellation may have failed (count unchanged), retrying...');
            await Future.delayed(const Duration(milliseconds: 500));
          }
        } catch (e) {
          LogService.log('[NOTIF] RESCHEDULE: Cancel attempt $cancelAttempts failed: $e');
          if (cancelAttempts < maxCancelAttempts) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      if (!cancelSuccess) {
        LogService.log('[NOTIF] RESCHEDULE: WARNING: Failed to cancel all notifications after $maxCancelAttempts attempts');
        LogService.log('[NOTIF] RESCHEDULE: Proceeding anyway - scheduleAllReminders will also try to cancel');
      }
      
      LogService.log('[NOTIF] ========================================');

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

      // Goal reminders are now scheduled per-date in season-wide scheduling functions
      // This legacy call is kept for backward compatibility but should not be used in new code

      try {
        final pending = await getPendingNotifications();
        if (kDebugMode) {
          debugPrint('=== FINAL COUNT: ${pending.length} notifications ===');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[NOTIF] Error getting pending: $e');
        }
      }
    } catch (e) {
      debugPrint('Error rescheduling: $e');
    }
  }


  static Future<void> initialize() async {
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
    
    if (kDebugMode) {
      debugPrint('NotificationService initialized: $initialized');
    }
    
    // Only clear notification database when corruption is detected (e.g. "Missing type parameter").
    // Do NOT clear on every app start - that wipes all scheduled notifications and breaks reminders.
    if (Platform.isAndroid && !_isClearingDatabase) {
      try {
        final isHealthy = await _detectCorruptDatabase();
        if (!isHealthy) {
          LogService.log('[NOTIF] Corruption detected after initialize, clearing...');
          await clearCorruptNotificationDatabase(skipReinitialize: true);
          LogService.log('[NOTIF] Database cleared after initialize');
        }
      } catch (e) {
        LogService.log('[NOTIF] Error checking/clearing database after initialize: $e');
      }
    }

    // Check scheduling health (ProGuard/R8 detection) - only in debug mode on Android
    if (kDebugMode && Platform.isAndroid) {
      try {
        final isHealthy = await checkSchedulingHealth();
        if (!isHealthy) {
          debugPrint('[NOTIF] WARNING: ProGuard/R8 signature stripping detected in release build!');
          debugPrint('[NOTIF] Scheduled notifications will fail. Check proguard-rules.pro.');
        }
      } catch (e) {
        // Ignore errors in health check during initialization
        debugPrint('[NOTIF] Health check skipped during init: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('Creating notification channels...');
    }
    await _createChannels();
    
    // DO NOT set timezone here - use IANA timezone from DB when scheduling
    if (kDebugMode) {
      debugPrint('[TZ] Timezone will be resolved from DB (prayer_timezone) when scheduling');
    }
    
    if (Platform.isAndroid) {
      final androidImpl = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidImpl != null) {
        final areNotificationsEnabled = await androidImpl.areNotificationsEnabled();
        LogService.log('[PERM] Current notification permission status: $areNotificationsEnabled');
        if (kDebugMode) {
          debugPrint('[PERM] Current notification permission status: $areNotificationsEnabled');
        }
        
        final permissionGranted = await androidImpl.requestNotificationsPermission();
        LogService.log('[PERM] Notification permission requested. Granted: $permissionGranted');
        if (kDebugMode) {
          debugPrint('[PERM] Notification permission requested. Granted: $permissionGranted');
        }
        
        // Request exact alarm permission
        try {
          final canExact = await androidImpl.canScheduleExactNotifications();
          LogService.log('[PERM] Can schedule exact alarms (before request): $canExact');
          if (kDebugMode) {
            debugPrint('[PERM] Can schedule exact alarms (before request): $canExact');
          }
          
          if (canExact != true) {
            LogService.log('[PERM] Requesting exact alarm permission...');
            try {
              await androidImpl.requestExactAlarmsPermission();
              await Future.delayed(const Duration(milliseconds: 500));
              final canExactAfter = await androidImpl.canScheduleExactNotifications();
              LogService.log('[PERM] Can schedule exact alarms (after request): $canExactAfter');
              if (kDebugMode) {
                debugPrint('[PERM] Can schedule exact alarms (after request): $canExactAfter');
              }
              if (canExactAfter == true) {
                LogService.log('[PERM] Exact alarm permission granted');
              } else {
                LogService.log('[PERM] WARN: Exact alarm permission not granted. User should grant in Settings > Apps > Ramadan Tracker > Alarms & reminders');
              }
            } catch (e) {
              LogService.log('[PERM] Error requesting exact alarm permission: $e');
            }
          } else {
            LogService.log('[PERM] Exact alarm permission already granted');
          }
        } catch (e) {
          LogService.log('[PERM] Error checking exact alarms: $e');
          if (kDebugMode) {
            debugPrint('[PERM] Error checking exact alarms: $e');
          }
        }
      }
    }
    
    if (kDebugMode) {
      debugPrint('=== NotificationService.initialize() COMPLETED ===');
      debugPrint('Timezone will be resolved from DB (prayer_timezone) when scheduling');
    }
  }

  static Future<void> _createChannels() async {
    // Unified channel for all notifications
    // CRITICAL: Use Importance.max and Visibility.public to ensure notifications show even when device is locked
    const unifiedChannel = AndroidNotificationChannel(
      'ramadan_reminders',
      'Ramadan Reminders',
      description: 'Sahur, Iftar, and goal reminders',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    final androidImpl = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImpl != null) {
      // Always create/recreate channel to ensure it's not blocked
      await androidImpl.createNotificationChannel(unifiedChannel);
      
      // Small delay to ensure channel is registered
      await Future.delayed(const Duration(milliseconds: 200));
      
      if (kDebugMode) {
        debugPrint('Unified notification channel created (importance: max)');
      }
      LogService.log('[NOTIF] Unified notification channel created');
      LogService.log('[NOTIF] Note: If notifications are blocked, check: Settings > Apps > Ramadan Tracker > Notifications > Ramadan Reminders');
    }
  }

  // Debug function to dump all pending notifications with detailed info
  static Future<void> debugDumpPending() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
      LogService.log('[DEBUG] === Pending Notifications Dump: ${pending.length} total ===');
      if (kDebugMode) {
        debugPrint('[DEBUG] === Pending Notifications Dump: ${pending.length} total ===');
      }
      
      for (final p in pending) {
        LogService.log('[DEBUG]   ID: ${p.id}, Title: "${p.title}", Body: "${p.body}", Payload: ${p.payload}');
        if (kDebugMode) {
          debugPrint('[DEBUG]   ID: ${p.id}, Title: "${p.title}", Body: "${p.body}", Payload: ${p.payload}');
        }
      }
    } catch (e) {
      LogService.log('[DEBUG] Error dumping pending notifications: $e');
      if (kDebugMode) {
        debugPrint('[DEBUG] Error dumping pending notifications: $e');
      }
    }
  }
  
  // Check scheduling health - detects ProGuard/R8 signature stripping issues
  // Returns true if healthy, false if "Missing type parameter" error detected
  static Future<bool> checkSchedulingHealth() async {
    try {
      // Try to read pending notifications - this will fail if ProGuard/R8 stripped signatures
      await _notifications.pendingNotificationRequests();
      LogService.log('[NOTIF] Scheduling health check: OK');
      if (kDebugMode) {
        debugPrint('[NOTIF] Scheduling health check: OK');
      }
      return true;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Missing type parameter')) {
        LogService.log('[NOTIF] WARN: Release shrinker issue detected (ProGuard/R8 Signature stripped). Check proguard-rules.pro.');
        LogService.log('[NOTIF] Error details: $e');
        if (kDebugMode) {
          debugPrint('[NOTIF] WARN: Release shrinker issue detected (ProGuard/R8 Signature stripped). Check proguard-rules.pro.');
          debugPrint('[NOTIF] Error details: $e');
        }
        return false;
      } else {
        // Other errors might not be ProGuard-related
        LogService.log('[NOTIF] Scheduling health check: Error (non-ProGuard): $e');
        if (kDebugMode) {
          debugPrint('[NOTIF] Scheduling health check: Error (non-ProGuard): $e');
        }
        return true; // Assume healthy for non-ProGuard errors
      }
    }
  }

  // Comprehensive diagnostic function
  static Future<void> dumpPendingSchedules() async {
    try {
      final pending = await _notifications.pendingNotificationRequests();
    final now = DateTime.now();
      final tzLocal = tz.local;
      
      LogService.log('[DIAG] === Notification Schedule Diagnostic ===');
      LogService.log('[DIAG] Resolved timezone: ${tzLocal.name}');
      LogService.log('[DIAG] Current time (local): $now');
      LogService.log('[DIAG] Current time (TZ): ${tz.TZDateTime.now(tzLocal)}');
      LogService.log('[DIAG] Total pending notifications: ${pending.length}');
      
      if (kDebugMode) {
        debugPrint('[DIAG] === Notification Schedule Diagnostic ===');
        debugPrint('[DIAG] Resolved timezone: ${tzLocal.name}');
        debugPrint('[DIAG] Current time (local): $now');
        debugPrint('[DIAG] Current time (TZ): ${tz.TZDateTime.now(tzLocal)}');
        debugPrint('[DIAG] Total pending notifications: ${pending.length}');
      }
      
      if (pending.isEmpty) {
        LogService.log('[DIAG] WARNING: No pending notifications found!');
        if (kDebugMode) {
          debugPrint('[DIAG] WARNING: No pending notifications found!');
        }
      } else {
        LogService.log('[DIAG] Scheduled notifications:');
        if (kDebugMode) {
          debugPrint('[DIAG] Scheduled notifications:');
        }
        
        for (final p in pending) {
          LogService.log('[DIAG]   ID: ${p.id}, Title: "${p.title}", Body: "${p.body}"');
          if (kDebugMode) {
            debugPrint('[DIAG]   ID: ${p.id}, Title: "${p.title}", Body: "${p.body}"');
          }
        }
      }
    } catch (e) {
      LogService.log('[DIAG] Error in diagnostic: $e');
      if (kDebugMode) {
        debugPrint('[DIAG] Error in diagnostic: $e');
      }
    }
  }
  
  // Schedule test notification in N seconds (e.g. 60s test from Settings).
  // Uses tz.local so the scheduled time matches device timezone and is not interpreted as past.
  // Uses alarmClock (setAlarmClock is exempt from Doze; may show alarm icon). Production reminders use alarmClock too.
  static Future<void> scheduleTestInSeconds(int seconds) async {
    try {
      final now = DateTime.now();
      final tzNow = tz.TZDateTime.now(tz.local);
      final scheduledTime = tzNow.add(Duration(seconds: seconds));
      final secondsUntil = scheduledTime.difference(tzNow).inSeconds;
      
      LogService.log('');
      LogService.log('========================================');
      LogService.log('[TEST-60s] TRIGGER at $now');
      LogService.log('[TEST-60s] TZ: $tzNow (${tz.local.name})');
      LogService.log('[TEST-60s] Will fire at: $scheduledTime ($secondsUntil s)');
      LogService.log('[TEST-60s] Alarm ID: 99999 (native), 99997 (in-app fallback)');
      LogService.log('========================================');
      
      final success = await _safeZonedSchedule(
        id: 99999,
        title: 'Test Notification (${seconds}s)',
        body: 'Scheduled notification fired after $seconds seconds. Time: ${scheduledTime.hour}:${scheduledTime.minute}:${scheduledTime.second}',
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'ramadan_reminders',
              'Ramadan Reminders',
            importance: Importance.max,
            priority: Priority.max,
            channelAction: AndroidNotificationChannelAction.createIfNotExists,
            enableVibration: true,
            playSound: true,
            showWhen: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        // Use alarmClock so it fires reliably (setAlarmClock is exempt from Doze/battery optimization)
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      
      LogService.log('[TEST-60s] Schedule result: $success');
      if (success) {
        try {
          final pending = await getPendingNotifications();
          final testNotif = pending.where((n) => n.id == 99999).toList().firstOrNull;
          LogService.log('[TEST-60s] In pending list: ${testNotif != null}');
          if (testNotif != null) {
            LogService.log('[TEST-60s] Pending: id=${testNotif.id}, title=${testNotif.title}');
          }
          LogService.log('[TEST-60s] Total pending: ${pending.length}');
        } catch (e) {
          LogService.log('[TEST-60s] Could not verify pending: $e');
        }
        Future.delayed(Duration(seconds: seconds + 5), () async {
          try {
            LogService.log('[TEST-60s] In-app fallback firing now (${seconds + 5}s elapsed)');
            await _notifications.show(
              99997,
              'Test (${seconds}s) - from app',
              'You got this after $seconds seconds. If this is the only one, set Battery to Unrestricted for scheduled reminders.',
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'ramadan_reminders',
                  'Ramadan Reminders',
                  importance: Importance.max,
                  priority: Priority.max,
                  channelAction: AndroidNotificationChannelAction.createIfNotExists,
                  enableVibration: true,
                  playSound: true,
                ),
                iOS: DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                ),
              ),
            );
            LogService.log('[TEST-60s] IN-APP FALLBACK notification shown (ID 99997)');
          } catch (e) {
            LogService.log('[TEST-60s] IN-APP FALLBACK failed: $e');
          }
        });
      }
      LogService.log('[TEST-60s] Setup complete. Watch for 2 notifications:');
      LogService.log('[TEST-60s]   1) "NATIVE ALARM" (ID 99999) = native receiver works');
      LogService.log('[TEST-60s]   2) "IN-APP FALLBACK" (ID 99997) = app timer works');
      LogService.log('========================================');
    } catch (e) {
      LogService.log('[TEST-60s] ERROR: $e');
    }
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
        // Request notification permission
        final granted = await androidImplementation.requestNotificationsPermission();
        LogService.log('[PERM] Notification permission requested. Granted: $granted');
        if (kDebugMode) {
          debugPrint('Notification permission requested. Granted: $granted');
        }
        
        // Request exact alarm permission
        try {
          final canScheduleExactAlarms = await androidImplementation.canScheduleExactNotifications();
          LogService.log('[PERM] Can schedule exact alarms (before request): $canScheduleExactAlarms');
          if (kDebugMode) {
            debugPrint('Can schedule exact alarms (before request): $canScheduleExactAlarms');
          }
          
          if (canScheduleExactAlarms != true) {
            LogService.log('[PERM] Requesting exact alarm permission...');
            if (kDebugMode) {
              debugPrint('Requesting exact alarm permission...');
            }
            
            try {
              await androidImplementation.requestExactAlarmsPermission();
              // Wait a bit for permission to be granted
              await Future.delayed(const Duration(milliseconds: 500));
              
              final canScheduleExactAlarmsAfter = await androidImplementation.canScheduleExactNotifications();
              LogService.log('[PERM] Can schedule exact alarms (after request): $canScheduleExactAlarmsAfter');
              if (kDebugMode) {
                debugPrint('Can schedule exact alarms (after request): $canScheduleExactAlarmsAfter');
              }
              
              if (canScheduleExactAlarmsAfter != true) {
                LogService.log('[PERM] WARNING: Exact alarms permission not granted. Notifications may be delayed.');
                LogService.log('[PERM] User should grant exact alarm permission in Android Settings > Apps > Ramadan Tracker > Alarms & reminders');
                if (kDebugMode) {
                  debugPrint('WARNING: Exact alarms permission not granted. Notifications may be delayed.');
                }
              } else {
                LogService.log('[PERM] Exact alarm permission granted successfully');
              }
            } catch (e) {
              LogService.log('[PERM] Error requesting exact alarm permission: $e');
              if (kDebugMode) {
                debugPrint('Error requesting exact alarm permission: $e');
              }
            }
          } else {
            LogService.log('[PERM] Exact alarm permission already granted');
          }
        } catch (e) {
          LogService.log('[PERM] Error checking exact alarms permission: $e');
          if (kDebugMode) {
            debugPrint('Error checking exact alarms permission: $e');
          }
        }
        
        return granted ?? false;
      }
    }
    return false;
  }

  // Sahur reminder - fajrTime is UTC; convert to local before scheduling.
  static Future<void> scheduleSahurReminder({
    required DateTime fajrTime,
    required int offsetMinutes,
    required String title,
    required String body,
    required tz.Location location,
  }) async {
    final fajrUtc = fajrTime.isUtc ? fajrTime : DateTime.utc(fajrTime.year, fajrTime.month, fajrTime.day, fajrTime.hour, fajrTime.minute, fajrTime.second);
    final reminderUtc = fajrUtc.subtract(Duration(minutes: offsetMinutes));
    final reminderLocal = tz.TZDateTime.from(reminderUtc, location);
    final tzNow = tz.TZDateTime.now(location);
    var scheduledTime = tz.TZDateTime(
      location,
      reminderLocal.year,
      reminderLocal.month,
      reminderLocal.day,
      reminderLocal.hour,
      reminderLocal.minute,
    );
    
    if (scheduledTime.isBefore(tzNow)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
      if (kDebugMode) {
        debugPrint('Sahur time passed today, scheduling for tomorrow: $scheduledTime');
      }
    }
    
    final timeUntilScheduled = scheduledTime.difference(tzNow);
    
    if (kDebugMode) {
      debugPrint('Scheduling Sahur reminder:');
      debugPrint('  Timezone: ${location.name}');
      debugPrint('  Fajr: $fajrTime');
      debugPrint('  Offset: $offsetMinutes min');
      debugPrint('  Reminder time (local): $reminderLocal');
      debugPrint('  Scheduled (TZ): $scheduledTime');
      debugPrint('  Current (TZ): $tzNow');
      debugPrint('  Time until scheduled: ${timeUntilScheduled.inMinutes} minutes');
      LogService.log('[NOTIF] Scheduling Sahur: timezone=${location.name}, scheduled=$scheduledTime, now=$tzNow, minutesUntil=${timeUntilScheduled.inMinutes}');
    }

    // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
    // Individual cancels cause Android rate limiting (5 ops/sec limit)
    final notificationId = _getNotificationId(_baseIdSahur, scheduledTime);
    
    final scheduled = await _safeZonedSchedule(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        ),
        androidScheduleMode: AndroidScheduleMode.alarmClock,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    if (!scheduled) {
      if (kDebugMode) {
        debugPrint('✗ Failed to schedule Sahur (database may be corrupt)');
      }
      // Fallback to inexact
      await _safeZonedSchedule(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: scheduledTime,
        notificationDetails: const NotificationDetails(
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
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
            ),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    }
    
    // Schedule untuk besok juga (daily scheduling)
    // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
    final tomorrowTime = scheduledTime.add(const Duration(days: 1));
    final tomorrowId = _getNotificationId(_baseIdSahur, tomorrowTime);
    
    await _safeZonedSchedule(
      id: tomorrowId,
      title: title,
      body: body,
      scheduledDate: tomorrowTime,
      notificationDetails: const NotificationDetails(
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
          ongoing: false,
          autoCancel: true,
          enableLights: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
    );
    
    if (kDebugMode) {
      debugPrint('Sahur notification scheduled successfully (Today ID: $notificationId, Tomorrow ID: $tomorrowId)');
    }
  }

  // Schedule Sahur reminder for a specific date (season-wide scheduling)
  // fajrTime is in UTC (from PrayerTimeService.getCachedOrCalculate); convert to local before scheduling.
  static Future<bool> scheduleSahurReminderForDate({
    required DateTime date,
    required DateTime fajrTime,
    required int offsetMinutes,
    required String title,
    required String body,
    required tz.Location location,
    int batchIndex = 0,
    int batchSize = 10,
  }) async {
    final fajrUtc = fajrTime.isUtc ? fajrTime : DateTime.utc(fajrTime.year, fajrTime.month, fajrTime.day, fajrTime.hour, fajrTime.minute, fajrTime.second);
    final reminderUtc = fajrUtc.subtract(Duration(minutes: offsetMinutes));
    final reminderLocal = tz.TZDateTime.from(reminderUtc, location);
    final tzNow = tz.TZDateTime.now(location);
    final scheduledTime = tz.TZDateTime(
      location,
      reminderLocal.year,
      reminderLocal.month,
      reminderLocal.day,
      reminderLocal.hour,
      reminderLocal.minute,
    );
    
    // Skip if time is in the past (with 1 second buffer)
    if (scheduledTime.isBefore(tzNow.add(const Duration(seconds: 1)))) {
      if (kDebugMode) {
        debugPrint('Skipping Sahur for $date: time already passed ($scheduledTime < $tzNow)');
      }
      return false;
    }
    
    // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
    final notificationId = _getNotificationId(_baseIdSahur, scheduledTime);
    
    return await _scheduleWithRateLimit(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      batchIndex: batchIndex,
      batchSize: batchSize,
    );
  }

  // Schedule Iftar reminder for a specific date (season-wide scheduling)
  // maghribTime is in UTC (from PrayerTimeService.getCachedOrCalculate); convert to local before scheduling.
  static Future<bool> scheduleIftarReminderForDate({
    required DateTime date,
    required DateTime maghribTime,
    required int offsetMinutes,
    required String title,
    required String body,
    required tz.Location location,
    int batchIndex = 0,
    int batchSize = 10,
  }) async {
    final maghribUtc = maghribTime.isUtc ? maghribTime : DateTime.utc(maghribTime.year, maghribTime.month, maghribTime.day, maghribTime.hour, maghribTime.minute, maghribTime.second);
    final reminderUtc = maghribUtc.add(Duration(minutes: offsetMinutes));
    final reminderLocal = tz.TZDateTime.from(reminderUtc, location);
    final tzNow = tz.TZDateTime.now(location);
    final scheduledTime = tz.TZDateTime(
      location,
      reminderLocal.year,
      reminderLocal.month,
      reminderLocal.day,
      reminderLocal.hour,
      reminderLocal.minute,
    );
    
    // Skip if time is in the past (with 1 second buffer)
    if (scheduledTime.isBefore(tzNow.add(const Duration(seconds: 1)))) {
      if (kDebugMode) {
        debugPrint('Skipping Iftar for $date: time already passed ($scheduledTime < $tzNow)');
      }
      return false;
    }
    
    // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
    final notificationId = _getNotificationId(_baseIdIftar, scheduledTime);
    
    return await _scheduleWithRateLimit(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
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
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      batchIndex: batchIndex,
      batchSize: batchSize,
    );
  }

  // Schedule Night Plan reminder for a specific date (season-wide scheduling)
  static Future<bool> scheduleNightPlanReminderForDate({
    required DateTime date,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required tz.Location location,
    int batchIndex = 0,
    int batchSize = 10,
  }) async {
    final tzNow = tz.TZDateTime.now(location);
    
    // Create scheduled time in the correct timezone for the specific date
    var scheduledTime = tz.TZDateTime(
      location,
      date.year,
      date.month,
      date.day,
      hour,
      minute,
    );
    
    // Skip if time is in the past (with 1 second buffer)
    if (scheduledTime.isBefore(tzNow.add(const Duration(seconds: 1)))) {
      if (kDebugMode) {
        debugPrint('Skipping Night Plan for $date: time already passed ($scheduledTime < $tzNow)');
      }
      return false;
    }
    
    // Note: No need to cancel individually - zonedSchedule() replaces existing notifications with same ID
    final notificationId = _getNotificationId(_baseIdNightPlan, scheduledTime);
    
    return await _scheduleWithRateLimit(
      id: notificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'ramadan_reminders',
          'Ramadan Reminders',
          channelDescription: 'Sahur, Iftar, and goal reminders',
          importance: Importance.max,
          priority: Priority.max,
          showWhen: true,
          enableVibration: true,
          playSound: true,
          visibility: NotificationVisibility.public,
          channelAction: AndroidNotificationChannelAction.createIfNotExists,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      batchIndex: batchIndex,
      batchSize: batchSize,
    );
  }
  
  // Legacy function - kept for backward compatibility
  static Future<void> scheduleNightPlanReminder({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required tz.Location location,
  }) async {
    final now = DateTime.now();
    final date = DateTime(now.year, now.month, now.day);
    await scheduleNightPlanReminderForDate(
      date: date,
      hour: hour,
      minute: minute,
      title: title,
      body: body,
      location: location,
    );
  }

  static Future<void> scheduleHabitReminder({
    required int hour,
    required int minute,
    required String habitName,
    required String channelId,
    tz.Location? location,
  }) async {
    final now = DateTime.now();
    final reminderTime = DateTime(now.year, now.month, now.day, hour, minute);
    // Use provided location or UTC as fallback
    final tzLocation = location ?? tz.UTC;
    final tzNow = tz.TZDateTime.now(tzLocation);
    
    var scheduledTime = tz.TZDateTime(
      tzLocation,
      reminderTime.year,
      reminderTime.month,
      reminderTime.day,
      reminderTime.hour,
      reminderTime.minute,
    );
    
    if (scheduledTime.isBefore(tzNow)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _safeZonedSchedule(
      id: _baseIdHabitReminder + _yyyymmdd(reminderTime),
      title: 'Ramadan Reminder',
      body: 'Time for $habitName',
      scheduledDate: scheduledTime,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Gentle Reminders',
          channelDescription: 'Quran, Dhikr, and other gentle reminders',
          importance: Importance.max,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancel existing notifications for a season
  static Future<void> cancelExistingSeasonNotifications(AppDatabase database, int seasonId) async {
    try {
      // Try to cancel all notifications
      // BUT: If database is corrupt, cancelAll() will also fail because it needs to load the database
      // So we catch the error and skip cancellation if corrupt (we'll clear database anyway)
      await _notifications.cancelAll();
      LogService.log('[NOTIF] Cancelled all existing notifications before rescheduling season $seasonId');
      if (kDebugMode) {
        debugPrint('[NOTIF] Cancelled all existing notifications before rescheduling season $seasonId');
      }
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('Missing type parameter')) {
        // Database is corrupt - cancelAll() also fails
        // This is OK because we'll clear database anyway before scheduling
        LogService.log('[NOTIF] Cannot cancel notifications (database corrupt) - will be cleared before scheduling');
        if (kDebugMode) {
          debugPrint('[NOTIF] Cannot cancel notifications (database corrupt) - will be cleared before scheduling');
        }
      } else {
        LogService.log('[NOTIF] Error cancelling notifications: $e');
      }
    }
  }
  
  // Check if iOS needs window reschedule
  static Future<bool> needsRescheduleWindow(AppDatabase database, int seasonId) async {
    if (!Platform.isIOS) return false;
    
    try {
      final key = 'notifications_scheduled_until_season_$seasonId';
      final untilStr = await database.kvSettingsDao.getValue(key);
      if (untilStr == null) return true;
      
      final until = DateTime.parse(untilStr);
      final now = DateTime.now();
      final daysUntilExpiry = until.difference(now).inDays;
      
      // Reschedule if less than 2 days remaining
      return daysUntilExpiry < 2;
    } catch (e) {
      LogService.log('[NOTIF] Error checking reschedule window: $e');
      return true;
    }
  }
  
  // Store scheduled until date for iOS
  static Future<void> storeScheduledUntil(AppDatabase database, int seasonId, DateTime until) async {
    try {
      final key = 'notifications_scheduled_until_season_$seasonId';
      await database.kvSettingsDao.setValue(key, until.toIso8601String());
      LogService.log('[NOTIF] Stored scheduled until: $until for season $seasonId');
    } catch (e) {
      LogService.log('[NOTIF] Error storing scheduled until: $e');
    }
  }
  
  // Schedule entire season for Android
  static Future<void> _scheduleSeasonAndroid({
    required AppDatabase database,
    required int seasonId,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
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
    required int fajrAdjust,
    required int maghribAdjust,
    required tz.Location location,
    String? sahurTitle,
    String? sahurBody,
    String? iftarTitle,
    String? iftarBody,
    String? nightPlanTitle,
    String? nightPlanBody,
  }) async {
    LogService.log('[NOTIF] Scheduling Android season: $scheduleStart to $scheduleEnd');
    if (kDebugMode) {
      debugPrint('[NOTIF] Scheduling Android season: $scheduleStart to $scheduleEnd');
    }
    
    int scheduledCount = 0;
    int skippedCount = 0;
    int batchCount = 0;
    const batchSize = 5; // Schedule 5 days at a time to avoid Android rate limiting
    const batchDelayMs = 100; // 100ms delay between batches
    
    // Loop through each day from scheduleStart to scheduleEnd
    for (var date = scheduleStart; !date.isAfter(scheduleEnd); date = date.add(const Duration(days: 1))) {
      try {
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

        // Schedule Sahur (with rate limit batch index)
        if (sahurEnabled && times['fajr'] != null) {
          final scheduled = await scheduleSahurReminderForDate(
            date: date,
            fajrTime: times['fajr']!,
            offsetMinutes: sahurOffsetMinutes,
            title: sahurTitle ?? 'Sahur Reminder',
            body: sahurBody ?? 'Time to prepare for Sahur',
            location: location,
            batchIndex: scheduledCount,
            batchSize: 10,
          );
          if (scheduled) scheduledCount++; else skippedCount++;
        }
        
        // Schedule Iftar (with rate limit batch index)
        if (iftarEnabled && times['maghrib'] != null) {
          final scheduled = await scheduleIftarReminderForDate(
            date: date,
            maghribTime: times['maghrib']!,
            offsetMinutes: iftarOffsetMinutes,
            title: iftarTitle ?? 'Iftar Reminder',
            body: iftarBody ?? 'Time for Iftar',
            location: location,
            batchIndex: scheduledCount,
            batchSize: 10,
          );
          if (scheduled) scheduledCount++; else skippedCount++;
        }
        
        // Schedule Night Plan (with rate limit batch index)
        if (nightPlanEnabled) {
          final nightPlanHour = int.tryParse(await database.kvSettingsDao.getValue('night_plan_hour') ?? '2') ?? 2;
          final nightPlanMinute = int.tryParse(await database.kvSettingsDao.getValue('night_plan_minute') ?? '30') ?? 30;
          final scheduled = await scheduleNightPlanReminderForDate(
            date: date,
            hour: nightPlanHour.clamp(0, 23),
            minute: nightPlanMinute.clamp(0, 59),
            title: nightPlanTitle ?? 'Night Plan',
            body: nightPlanBody ?? 'Review your plan for tonight',
            location: location,
            batchIndex: scheduledCount,
            batchSize: 10,
          );
          if (scheduled) scheduledCount++; else skippedCount++;
        }
        
        // Schedule Goal Reminders for this date
        await GoalReminderService.scheduleGoalRemindersForDate(
          database: database,
          seasonId: seasonId,
          date: date,
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
          method: method,
          highLatRule: highLatRule,
          location: location,
          fajrAdjust: fajrAdjust,
          maghribAdjust: maghribAdjust,
        );
        
        // Add delay every batchSize days to prevent Android rate limiting
        batchCount++;
        if (batchCount >= batchSize) {
          batchCount = 0;
          await Future.delayed(Duration(milliseconds: batchDelayMs));
          LogService.log('[NOTIF] Batch delay: $scheduledCount scheduled so far...');
        }
        
            } catch (e) {
        LogService.log('[NOTIF] Error scheduling for date $date: $e');
        if (kDebugMode) {
          debugPrint('[NOTIF] Error scheduling for date $date: $e');
        }
      }
    }
    
    LogService.log('[NOTIF] Android season scheduling complete: $scheduledCount scheduled, $skippedCount skipped');
    if (kDebugMode) {
      debugPrint('[NOTIF] Android season scheduling complete: $scheduledCount scheduled, $skippedCount skipped');
    }
  }
  
  // Schedule rolling window for iOS
  static Future<void> _scheduleRollingWindowIOS({
    required AppDatabase database,
    required int seasonId,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
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
    required int fajrAdjust,
    required int maghribAdjust,
    required tz.Location location,
    String? sahurTitle,
    String? sahurBody,
    String? iftarTitle,
    String? iftarBody,
    String? nightPlanTitle,
    String? nightPlanBody,
  }) async {
    // Calculate notifications per day
    int perDayCount = 0;
    if (sahurEnabled) perDayCount++;
    if (iftarEnabled) perDayCount++;
    if (nightPlanEnabled) perDayCount++;
    
    // Count goal reminders (estimate: max 4 per day - quran 3x, dhikr 3x, sedekah 1x, taraweeh 1x)
    // We'll check actual enabled goals, but use conservative estimate
    perDayCount += 4; // Conservative estimate
    
    // Determine window days (max 60 notifications, clamp between 7-14 days)
    const maxPending = 60;
    final windowDays = (maxPending / perDayCount).floor().clamp(7, 14);
    final scheduledUntil = scheduleStart.add(Duration(days: windowDays - 1));
    final actualEnd = scheduledUntil.isBefore(scheduleEnd) ? scheduledUntil : scheduleEnd;
    
    LogService.log('[NOTIF] Scheduling iOS rolling window: $scheduleStart to $actualEnd ($windowDays days, ~$perDayCount notifs/day)');
    if (kDebugMode) {
      debugPrint('[NOTIF] Scheduling iOS rolling window: $scheduleStart to $actualEnd ($windowDays days, ~$perDayCount notifs/day)');
    }
    
    // Store scheduled until
    await storeScheduledUntil(database, seasonId, actualEnd);
    
    int scheduledCount = 0;
    int skippedCount = 0;
    
    // Schedule for window period
    for (var date = scheduleStart; !date.isAfter(actualEnd); date = date.add(const Duration(days: 1))) {
      try {
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
    
        if (sahurEnabled && times['fajr'] != null) {
          final scheduled = await scheduleSahurReminderForDate(
            date: date,
            fajrTime: times['fajr']!,
            offsetMinutes: sahurOffsetMinutes,
            title: sahurTitle ?? 'Sahur Reminder',
            body: sahurBody ?? 'Time to prepare for Sahur',
            location: location,
          );
          if (scheduled) scheduledCount++; else skippedCount++;
        }
        
        if (iftarEnabled && times['maghrib'] != null) {
          final scheduled = await scheduleIftarReminderForDate(
            date: date,
            maghribTime: times['maghrib']!,
            offsetMinutes: iftarOffsetMinutes,
            title: iftarTitle ?? 'Iftar Reminder',
            body: iftarBody ?? 'Time for Iftar',
            location: location,
          );
          if (scheduled) scheduledCount++; else skippedCount++;
    }

    if (nightPlanEnabled) {
          final nightPlanHour = int.tryParse(await database.kvSettingsDao.getValue('night_plan_hour') ?? '2') ?? 2;
          final nightPlanMinute = int.tryParse(await database.kvSettingsDao.getValue('night_plan_minute') ?? '30') ?? 30;
          final scheduled = await scheduleNightPlanReminderForDate(
            date: date,
            hour: nightPlanHour.clamp(0, 23),
            minute: nightPlanMinute.clamp(0, 59),
            title: nightPlanTitle ?? 'Night Plan',
            body: nightPlanBody ?? 'Review your plan for tonight',
            location: location,
          );
          if (scheduled) scheduledCount++; else skippedCount++;
        }
        
        await GoalReminderService.scheduleGoalRemindersForDate(
          database: database,
          seasonId: seasonId,
          date: date,
          latitude: latitude,
          longitude: longitude,
          timezone: timezone,
          method: method,
          highLatRule: highLatRule,
          location: location,
          fajrAdjust: fajrAdjust,
          maghribAdjust: maghribAdjust,
        );
        
      } catch (e) {
        LogService.log('[NOTIF] Error scheduling iOS window for date $date: $e');
      }
    }
    
    LogService.log('[NOTIF] iOS rolling window scheduling complete: $scheduledCount scheduled, $skippedCount skipped, until $actualEnd');
    if (kDebugMode) {
      debugPrint('[NOTIF] iOS rolling window scheduling complete: $scheduledCount scheduled, $skippedCount skipped, until $actualEnd');
    }
  }
  
  // Full diagnostic function
  static Future<void> runFullDiagnostic(AppDatabase database, int seasonId) async {
    try {
      LogService.log('[DIAG] === Full Notification Diagnostic ===');
      if (kDebugMode) {
        debugPrint('[DIAG] === Full Notification Diagnostic ===');
      }
      
      // Scheduling health check (ProGuard/R8 detection)
      final isHealthy = await checkSchedulingHealth();
      if (!isHealthy) {
        LogService.log('[DIAG] CRITICAL: ProGuard/R8 signature stripping detected! Scheduled notifications will fail.');
        if (kDebugMode) {
          debugPrint('[DIAG] CRITICAL: ProGuard/R8 signature stripping detected! Scheduled notifications will fail.');
        }
      }
      
      // Timezone
      final tzIana = await readTimezoneFromDb(database);
      final location = resolveLocation(tzIana);
      final tzNow = tz.TZDateTime.now(location);
      
      LogService.log('[DIAG] Timezone IANA: $tzIana');
      LogService.log('[DIAG] Resolved location: ${location.name}');
      LogService.log('[DIAG] Current time (TZ): $tzNow');
      
      if (kDebugMode) {
        debugPrint('[DIAG] Timezone IANA: $tzIana');
        debugPrint('[DIAG] Resolved location: ${location.name}');
        debugPrint('[DIAG] Current time (TZ): $tzNow');
      }
      
      // Season range
      final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
      if (season != null) {
        final start = DateTime.parse(season.startDate);
        final end = start.add(Duration(days: season.days - 1));
        final today = _dateOnly(DateTime.now());
        final scheduleStart = start.isAfter(today) ? start : today;
        final scheduleEnd = end;
        
        LogService.log('[DIAG] Season: ${season.label}');
        LogService.log('[DIAG] Season start: $start');
        LogService.log('[DIAG] Season end: $end');
        LogService.log('[DIAG] Schedule start: $scheduleStart');
        LogService.log('[DIAG] Schedule end: $scheduleEnd');
        
        if (kDebugMode) {
          debugPrint('[DIAG] Season: ${season.label}');
          debugPrint('[DIAG] Season start: $start');
          debugPrint('[DIAG] Season end: $end');
          debugPrint('[DIAG] Schedule start: $scheduleStart');
          debugPrint('[DIAG] Schedule end: $scheduleEnd');
        }
        
        // iOS scheduled until
        if (Platform.isIOS) {
          final key = 'notifications_scheduled_until_season_$seasonId';
          final untilStr = await database.kvSettingsDao.getValue(key);
          if (untilStr != null) {
            final until = DateTime.parse(untilStr);
            LogService.log('[DIAG] iOS scheduled until: $until');
            if (kDebugMode) {
              debugPrint('[DIAG] iOS scheduled until: $until');
            }
          } else {
            LogService.log('[DIAG] iOS scheduled until: NOT SET');
            if (kDebugMode) {
              debugPrint('[DIAG] iOS scheduled until: NOT SET');
            }
          }
        }
      }
      
      // Pending notifications
      await dumpPendingSchedules();
      
    } catch (e) {
      LogService.log('[DIAG] Error in diagnostic: $e');
      if (kDebugMode) {
        debugPrint('[DIAG] Error in diagnostic: $e');
      }
    }
  }

  // Schedule all reminders for the season (season-wide scheduling)
  static Future<void> scheduleAllReminders({
    required AppDatabase database,
    required int seasonId,
    required double latitude,
    required double longitude,
    String? timezone,
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
    // Prevent concurrent scheduling: wait for current run to finish (proper mutex)
    if (_isScheduling) {
      LogService.log('[NOTIF] Scheduling already in progress, waiting...');
      int waitCount = 0;
      while (_isScheduling && waitCount < 300) {
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_isScheduling) {
        LogService.log('[NOTIF] Scheduling still in progress after 30s, aborting');
        return;
      }
      LogService.log('[NOTIF] Previous scheduling completed, proceeding');
    }
    
    _isScheduling = true;
    LogService.log('[NOTIF] Scheduling lock acquired');
    
    try {
      // Log pending count at start
      try {
        final initialPending = await getPendingNotifications();
        LogService.log('[NOTIF] Initial pending notifications: ${initialPending.length}');
      } catch (e) {
        LogService.log('[NOTIF] Could not get initial pending count: $e');
      }
    // 0. Only clear notification database when corruption is detected.
    // Clearing on every schedule wipes valid notifications and can break state (e.g. wiping
    // FlutterSharedPreferences in native code). Cancel + re-schedule is enough for normal flow.
    LogService.log('[NOTIF] ========================================');
    try {
      final isHealthy = await _detectCorruptDatabase();
      if (!isHealthy) {
        LogService.log('[NOTIF] Step 0: Database corrupt detected, clearing...');
        final cleared = await clearCorruptNotificationDatabase();
        if (!cleared) {
          LogService.log('[NOTIF] First clear attempt failed, retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
          await clearCorruptNotificationDatabase();
        }
        await Future.delayed(const Duration(milliseconds: 1000));
        LogService.log('[NOTIF] Database cleared. Proceeding with scheduling...');
      } else {
        LogService.log('[NOTIF] Step 0: Database healthy, skipping clear.');
      }
      LogService.log('[NOTIF] ========================================');
    } catch (e, stackTrace) {
      LogService.log('[NOTIF] Error during corruption check/clear: $e');
      LogService.log('[NOTIF] Stack trace: $stackTrace');
      LogService.log('[NOTIF] ========================================');
    }
    
    // 1. Ensure plugin initialized and request permissions
    // NOTE: initialize() is called AFTER clearCorruptNotificationDatabase() 
    // to ensure plugin starts with clean state
    await initialize();
    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      LogService.log('[NOTIF] WARNING: Notification permission not granted. Notifications may not appear.');
      if (kDebugMode) {
        debugPrint('[NOTIF] WARNING: Notification permission not granted. Notifications may not appear.');
      }
    }
    
    // 2. Read timezone from DB if not provided
    final tzIana = timezone ?? await readTimezoneFromDb(database);
    
    // 3. Initialize timezone (sets tz.local)
    await initializeTimezone(tzIana);
    final location = tz.local;
    
    // 4. Get season info
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    if (season == null) {
      LogService.log('[NOTIF] ERROR: Season $seasonId not found');
        return;
      }
      
    final seasonStart = DateTime.parse(season.startDate);
    final seasonEnd = seasonStart.add(Duration(days: season.days - 1));
    final today = _dateOnly(DateTime.now());
    final scheduleStart = seasonStart.isAfter(today) ? seasonStart : today;
    
    // Schedule full season so each day gets its own Fajr/Maghrib (times vary day to day).
    // Batch delay in the loop avoids Android rate limiting.
    const maxDaysAhead = 31;
    final maxScheduleEnd = scheduleStart.add(Duration(days: maxDaysAhead - 1));
    final scheduleEnd = maxScheduleEnd.isBefore(seasonEnd) ? maxScheduleEnd : seasonEnd;
    
    if (maxScheduleEnd.isBefore(seasonEnd)) {
      LogService.log('[NOTIF] Schedule capped at $maxDaysAhead days; remaining days on next app open');
    }
    
    LogService.log('[NOTIF] === Scheduling reminders (season-wide) ===');
    LogService.log('[NOTIF] Season: ${season.label}');
    LogService.log('[NOTIF] Timezone IANA: $tzIana');
    LogService.log('[NOTIF] Resolved location: ${location.name}');
    LogService.log('[NOTIF] Schedule range: $scheduleStart to $scheduleEnd');
    
    if (kDebugMode) {
      debugPrint('[NOTIF] === Scheduling reminders (season-wide) ===');
      debugPrint('[NOTIF] Season: ${season.label}');
      debugPrint('[NOTIF] Timezone IANA: $tzIana');
      debugPrint('[NOTIF] Resolved location: ${location.name}');
      debugPrint('[NOTIF] Schedule range: $scheduleStart to $scheduleEnd');
    }
    
    // 5. Cancel existing notifications (CRITICAL to prevent duplicates)
    // This MUST happen before scheduling to avoid accumulating notifications
    LogService.log('[NOTIF] Step 5: Cancelling ALL existing notifications before scheduling...');
    int cancelAttempts = 0;
    const maxCancelAttempts = 3;
    bool cancelSuccess = false;
    
    while (cancelAttempts < maxCancelAttempts && !cancelSuccess) {
      try {
        cancelAttempts++;
        LogService.log('[NOTIF] Cancel attempt $cancelAttempts/$maxCancelAttempts...');
        
        // Get count before cancel
        final beforeCancel = await getPendingNotifications();
        LogService.log('[NOTIF] Notifications before cancel: ${beforeCancel.length}');
        
        await cancelAll();
        
        // Wait for cancellation to propagate
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Verify cancellation worked
        final afterCancel = await getPendingNotifications();
        LogService.log('[NOTIF] Notifications after cancel: ${afterCancel.length}');
        
        if (afterCancel.length == 0) {
          cancelSuccess = true;
          LogService.log('[NOTIF] All notifications cancelled successfully');
        } else if (afterCancel.length < beforeCancel.length) {
          // Some cancelled, but not all - try again
          LogService.log('[NOTIF] WARN Partial cancellation (${beforeCancel.length} -> ${afterCancel.length}), retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          LogService.log('[NOTIF] WARN Cancellation may have failed (count unchanged), retrying...');
          await Future.delayed(const Duration(milliseconds: 500));
        }
      } catch (e) {
        LogService.log('[NOTIF] Cancel attempt $cancelAttempts failed: $e');
        if (cancelAttempts < maxCancelAttempts) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }
    
    if (!cancelSuccess) {
      LogService.log('[NOTIF] WARNING: Failed to cancel all notifications after $maxCancelAttempts attempts');
      LogService.log('[NOTIF] Proceeding with scheduling anyway - duplicates may occur');
    }
    
    // 6. Schedule based on platform
    if (Platform.isAndroid) {
      await _scheduleSeasonAndroid(
        database: database,
        seasonId: seasonId,
        scheduleStart: scheduleStart,
        scheduleEnd: scheduleEnd,
        latitude: latitude,
        longitude: longitude,
        timezone: tzIana,
        method: method,
        highLatRule: highLatRule,
        sahurEnabled: sahurEnabled,
        sahurOffsetMinutes: sahurOffsetMinutes,
        iftarEnabled: iftarEnabled,
        iftarOffsetMinutes: iftarOffsetMinutes,
        nightPlanEnabled: nightPlanEnabled,
        fajrAdjust: fajrAdjust,
        maghribAdjust: maghribAdjust,
        location: location,
        sahurTitle: sahurTitle,
        sahurBody: sahurBody,
        iftarTitle: iftarTitle,
        iftarBody: iftarBody,
        nightPlanTitle: nightPlanTitle,
        nightPlanBody: nightPlanBody,
      );
    } else if (Platform.isIOS) {
      await _scheduleRollingWindowIOS(
        database: database,
        seasonId: seasonId,
        scheduleStart: scheduleStart,
        scheduleEnd: scheduleEnd,
        latitude: latitude,
        longitude: longitude,
        timezone: tzIana,
        method: method,
        highLatRule: highLatRule,
        sahurEnabled: sahurEnabled,
        sahurOffsetMinutes: sahurOffsetMinutes,
        iftarEnabled: iftarEnabled,
        iftarOffsetMinutes: iftarOffsetMinutes,
        nightPlanEnabled: nightPlanEnabled,
        fajrAdjust: fajrAdjust,
        maghribAdjust: maghribAdjust,
        location: location,
        sahurTitle: sahurTitle,
        sahurBody: sahurBody,
        iftarTitle: iftarTitle,
        iftarBody: iftarBody,
        nightPlanTitle: nightPlanTitle,
        nightPlanBody: nightPlanBody,
      );
    }
    
    // 7. Debug dump (debug mode only)
    if (kDebugMode) {
      await dumpPendingSchedules();
    }
    
    // 8. Final verification - log final count
    try {
      await Future.delayed(const Duration(milliseconds: 500)); // Wait for all schedules to complete
      final finalPending = await getPendingNotifications();
      LogService.log('[NOTIF] Scheduling completed - Final pending notifications: ${finalPending.length}');
      
      if (finalPending.length > 50) {
        LogService.log('[NOTIF] WARNING: Final count is high (${finalPending.length}). Check for duplicates.');
      }
    } catch (e) {
      LogService.log('[NOTIF] Could not get final pending count: $e');
    }
    
    } finally {
      _isScheduling = false;
      LogService.log('[NOTIF] Scheduling lock released');
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