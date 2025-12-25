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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: value
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value
                ? Theme.of(context).colorScheme.primary
                : Colors.white.withOpacity(0.2),
            width: value ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: value
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 12),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: value
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                ),
              ],
            ),
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              color: value
                  ? Theme.of(context).colorScheme.primary
                  : Colors.white.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

