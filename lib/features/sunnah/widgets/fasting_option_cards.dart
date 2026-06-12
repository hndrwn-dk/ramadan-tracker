import 'package:flutter/material.dart';

/// Numbered option card used in sunnah and Ramadan fasting bottom sheets.
class FastingOptionCard extends StatelessWidget {
  final int number;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? child;

  const FastingOptionCard({
    super.key,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.selected,
    this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor =
        selected ? scheme.primary : scheme.outline.withValues(alpha: 0.25);
    final bgColor = selected
        ? scheme.primaryContainer.withValues(alpha: 0.35)
        : scheme.surface;

    final content = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: iconColor.withValues(alpha: 0.15),
                child: Text(
                  '$number',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.65),
                          ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: scheme.primary, size: 20),
            ],
          ),
          if (child != null) child!,
        ],
      ),
    );

    return Material(
      color: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: selected ? 1.5 : 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap != null
          ? InkWell(onTap: onTap, child: content)
          : content,
    );
  }
}

class FastingExcuseChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const FastingExcuseChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FilterChip(
      label: Text(label),
      avatar: Icon(icon, size: 16),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: scheme.tertiaryContainer,
    );
  }
}
