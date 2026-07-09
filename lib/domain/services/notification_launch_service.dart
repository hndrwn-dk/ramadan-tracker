import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/notification_launch_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/utils/log_service.dart';

abstract final class FastingNotificationPayload {
  static String ramadanSahur(int seasonId, int dayIndex) =>
      'ramadan_sahur:$seasonId:$dayIndex';

  static String ramadanIftar(int seasonId, int dayIndex) =>
      'ramadan_iftar:$seasonId:$dayIndex';

  static String sunnahSahur(DateTime date) =>
      'sunnah_sahur:${_ymd(date)}';

  static String sunnahIftar(DateTime date) =>
      'sunnah_iftar:${_ymd(date)}';

  static int _ymd(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  static DateTime? _dateFromYmd(int ymd) {
    final year = ymd ~/ 10000;
    final month = (ymd % 10000) ~/ 100;
    final day = ymd % 100;
    return DateTime(year, month, day);
  }

  static NotificationLaunchRequest? parse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split(':');
    if (parts.length < 2) return null;

    switch (parts[0]) {
      case 'ramadan_sahur':
      case 'ramadan_imsak':
        if (parts.length < 3) return null;
        final seasonId = int.tryParse(parts[1]);
        final dayIndex = int.tryParse(parts[2]);
        if (seasonId == null || dayIndex == null) return null;
        return NotificationLaunchRequest(
          kind: FastingNotificationKind.ramadanSahur,
          seasonId: seasonId,
          dayIndex: dayIndex,
        );
      case 'ramadan_iftar':
        if (parts.length < 3) return null;
        final seasonId = int.tryParse(parts[1]);
        final dayIndex = int.tryParse(parts[2]);
        if (seasonId == null || dayIndex == null) return null;
        return NotificationLaunchRequest(
          kind: FastingNotificationKind.ramadanIftar,
          seasonId: seasonId,
          dayIndex: dayIndex,
        );
      case 'sunnah_sahur':
      case 'sunnah_imsak':
        final ymd = int.tryParse(parts[1]);
        final date = ymd != null ? _dateFromYmd(ymd) : null;
        if (date == null) return null;
        return NotificationLaunchRequest(
          kind: FastingNotificationKind.sunnahSahur,
          sunnahDate: date,
        );
      case 'sunnah_iftar':
        final ymd = int.tryParse(parts[1]);
        final date = ymd != null ? _dateFromYmd(ymd) : null;
        if (date == null) return null;
        return NotificationLaunchRequest(
          kind: FastingNotificationKind.sunnahIftar,
          sunnahDate: date,
        );
      default:
        return null;
    }
  }
}

/// Static bridge so [NotificationService] can forward taps without a [WidgetRef].
abstract final class NotificationLaunchBridge {
  static NotificationLaunchRequest? _pending;
  static void Function(NotificationLaunchRequest request)? _onRequest;

  static void setHandler(void Function(NotificationLaunchRequest request)? handler) {
    _onRequest = handler;
  }

  static void onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    final request = FastingNotificationPayload.parse(payload);
    LogService.log(
      '[NOTIF-LAUNCH] tap id=${response.id} payload=$payload parsed=${request?.kind}',
    );
    if (kDebugMode) {
      debugPrint(
        '[NOTIF-LAUNCH] tap id=${response.id} payload=$payload parsed=${request?.kind}',
      );
    }
    if (request == null) return;

    _pending = request;
    final handler = _onRequest;
    if (handler != null) {
      handler(request);
    }
  }

  static NotificationLaunchRequest? consumePending() {
    final pending = _pending;
    _pending = null;
    return pending;
  }
}

class NotificationLaunchService {
  NotificationLaunchService._();

  static void dispatch(WidgetRef ref, NotificationLaunchRequest request) {
    ref.read(notificationLaunchProvider.notifier).state = request;
  }

  static void handlePayload(WidgetRef ref, String? payload) {
    final request = FastingNotificationPayload.parse(payload);
    if (request != null) {
      dispatch(ref, request);
    } else if (payload != null && payload.isNotEmpty) {
      LogService.log('[NOTIF-LAUNCH] unhandled payload: $payload');
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] unhandled payload: $payload');
      }
    }
  }

  static void handleResponse(WidgetRef ref, NotificationResponse response) {
    handlePayload(ref, response.payload);
  }

  static Future<void> checkInitialLaunch(WidgetRef ref) async {
    final bridged = NotificationLaunchBridge.consumePending();
    if (bridged != null) {
      LogService.log('[NOTIF-LAUNCH] consumed bridge: ${bridged.kind}');
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] consumed bridge: ${bridged.kind}');
      }
      dispatch(ref, bridged);
      return;
    }

    final details = await NotificationService.getLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      final payload = details?.notificationResponse?.payload;
      LogService.log(
        '[NOTIF-LAUNCH] cold start payload=$payload id=${details?.notificationResponse?.id}',
      );
      if (kDebugMode) {
        debugPrint(
          '[NOTIF-LAUNCH] cold start payload=$payload id=${details?.notificationResponse?.id}',
        );
      }
      handlePayload(ref, payload);
    }
  }
}
