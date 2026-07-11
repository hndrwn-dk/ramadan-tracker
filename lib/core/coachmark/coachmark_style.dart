import 'package:flutter/material.dart';

/// Layout and animation tokens for coachmark overlays.
abstract final class CoachmarkStyle {
  static const double tooltipWidth = 250;
  static const double tooltipBorderRadius = 16;
  static const double spotlightPadding = 6;
  static const double spotlightBorderRadius = 12;
  static const Duration fadeDuration = Duration(milliseconds: 400);
  static const Duration tooltipDelay = Duration(milliseconds: 200);
  static const Duration pulseDuration = Duration(milliseconds: 2400);
}

/// Theme-aware colors derived from [ColorScheme] so coachmarks match the app.
class CoachmarkColors {
  const CoachmarkColors({
    required this.overlay,
    required this.tooltipBackground,
    required this.tooltipTitle,
    required this.tooltipBody,
    required this.tooltipDismiss,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.pulseRing,
    required this.tooltipShadow,
    required this.tooltipBorder,
  });

  final Color overlay;
  final Color tooltipBackground;
  final Color tooltipTitle;
  final Color tooltipBody;
  final Color tooltipDismiss;
  final Color ctaBackground;
  final Color ctaForeground;
  final Color pulseRing;
  final Color tooltipShadow;
  final Color tooltipBorder;

  factory CoachmarkColors.of(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return CoachmarkColors(
      overlay: scheme.scrim.withValues(alpha: isDark ? 0.62 : 0.42),
      tooltipBackground: scheme.surface,
      tooltipTitle: scheme.onSurface,
      tooltipBody: scheme.onSurface.withValues(alpha: 0.72),
      tooltipDismiss: scheme.onSurface.withValues(alpha: 0.62),
      ctaBackground: scheme.primary,
      ctaForeground: scheme.onPrimary,
      pulseRing: scheme.primary.withValues(alpha: isDark ? 0.9 : 0.55),
      tooltipShadow: isDark
          ? const Color(0x66000000)
          : scheme.shadow.withValues(alpha: 0.18),
      tooltipBorder: scheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
    );
  }
}
