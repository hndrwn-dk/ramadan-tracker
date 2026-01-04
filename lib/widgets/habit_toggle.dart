import 'package:flutter/material.dart';

class HabitToggle extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onTap;
  final IconData? icon;

  const HabitToggle({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? Theme.of(context).colorScheme.primary
                : (isDark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.3)),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: value
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    const SizedBox(width: 12),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: value
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : null,
                            fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: value
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: value
                    ? null
                    : Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.5),
                        width: 2,
                      ),
              ),
              child: Icon(
                value ? Icons.check : Icons.circle,
                size: 18,
                color: value
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

