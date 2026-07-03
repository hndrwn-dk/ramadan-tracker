import 'package:flutter/material.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// @deprecated Use [AppSurface] directly. Kept for gradual migration.
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: padding ?? const EdgeInsets.all(20),
      onTap: onTap,
      child: child,
    );
  }
}
