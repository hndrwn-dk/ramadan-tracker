import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/widget_launch_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Handles Android home widget deep links (e.g. quick-log sunnah fast).
class WidgetLaunchService {
  WidgetLaunchService._();

  static const String logSunnahUri = 'ramadantracker://log_sunnah';
  static const String openTodayUri = 'ramadantracker://open_today';

  static StreamSubscription<Uri?>? _subscription;

  static Future<void> initialize(WidgetRef ref) async {
    await _subscription?.cancel();
    _subscription = HomeWidget.widgetClicked.listen((uri) {
      _handleUri(ref, uri);
    });
    final initial = await HomeWidget.initiallyLaunchedFromHomeWidget();
    _handleUri(ref, initial);
  }

  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  static void _handleUri(WidgetRef ref, Uri? uri) {
    if (uri == null) return;
    if (kDebugMode) debugPrint('[WidgetLaunch] uri=$uri');
    if (uri.host == 'open_today' || uri.toString().contains('open_today')) {
      ref.read(tabIndexProvider.notifier).state = 0;
      return;
    }
    if (uri.host == 'log_sunnah' || uri.toString().contains('log_sunnah')) {
      ref.read(tabIndexProvider.notifier).state = 3;
      ref.read(widgetQuickLogSunnahProvider.notifier).state = true;
    }
  }
}
