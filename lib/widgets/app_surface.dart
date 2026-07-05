import 'package:flutter/material.dart';

/// Unified bordered surface for premium UI (20px radius).
class AppSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  static const double radius = 20;
  static const double nestedRadius = 16;

  /// Theme-aware stroke so cards stay visible in dark mode.
  static Color borderColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return scheme.onSurface.withValues(alpha: 0.22);
    }
    return scheme.outline.withValues(alpha: 0.14);
  }

  /// Slightly elevated fill in dark mode (surface == scaffold otherwise).
  static Color fillColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      // Tinted lift — avoids flat neutral grey (surfaceContainerLow) on dark scaffold.
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.12),
        scheme.surface,
      );
    }
    return scheme.surface;
  }

  /// Compact grid/chip fill — closer to scaffold, border carries structure.
  static Color cellFillColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return Color.alphaBlend(
        scheme.primary.withValues(alpha: 0.07),
        scheme.surface,
      );
    }
    return scheme.surfaceContainerHighest.withValues(alpha: 0.35);
  }

  /// Standard bordered decoration for outer cards (20px radius).
  static BoxDecoration decoration(
    BuildContext context, {
    Color? color,
    double borderRadius = radius,
    Color? border,
    double borderWidth = 1,
  }) {
    return BoxDecoration(
      color: color ?? fillColor(context),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: border ?? borderColor(context),
        width: borderWidth,
      ),
    );
  }

  /// Bordered decoration for nested/inset blocks (16px radius).
  static BoxDecoration nestedDecoration(
    BuildContext context, {
    Color? color,
    double borderRadius = nestedRadius,
    Color? border,
    double borderWidth = 1,
  }) {
    return decoration(
      context,
      color: color,
      borderRadius: borderRadius,
      border: border,
      borderWidth: borderWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    final border = borderColor(context);
    final fill = fillColor(context);

    final card = Card(
      elevation: 0,
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: border, width: 1),
      ),
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          color: fill,
        ),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      );
    }
    return card;
  }
}
