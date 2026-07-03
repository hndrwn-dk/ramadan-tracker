import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Platform helpers for iOS/Android adaptive behavior.
class PlatformAdaptive {
  PlatformAdaptive._();

  static bool get isIOS => !kIsWeb && Platform.isIOS;

  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  static void lightHaptic() {
    if (isIOS) {
      HapticFeedback.lightImpact();
    } else if (isAndroid) {
      HapticFeedback.selectionClick();
    }
  }

  static void mediumHaptic() {
    if (isIOS) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
  }
}
