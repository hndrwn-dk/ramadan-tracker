import 'package:flutter/material.dart';

/// Circular back control used on tab sub-screens and pushed routes.
class AppBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.arrow_back_ios_new,
          size: 18,
          color: scheme.onSurface,
        ),
      ),
      onPressed: onPressed ?? () => Navigator.maybePop(context),
    );
  }
}
