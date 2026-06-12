import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';

class SunnahMonthLegend extends StatelessWidget {
  const SunnahMonthLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          _chip(context, scheme.primary, scheme.onPrimary, s.legendFasted),
          _chip(context, scheme.tertiary.withValues(alpha: 0.35),
              scheme.onSurface, s.legendExcused),
          _chip(context, scheme.primary.withValues(alpha: 0.12),
              scheme.onSurface, s.legendSunnahDay,
              border: scheme.primary.withValues(alpha: 0.4)),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context,
    Color bg,
    Color fg,
    String label, {
    Color? border,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
            border: border != null ? Border.all(color: border) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
