import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';

class SunnahMonthLegend extends StatelessWidget {
  final bool showTypeCodes;

  const SunnahMonthLegend({super.key, this.showTypeCodes = true});

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _chip(context, scheme.primary, scheme.onPrimary, s.legendFasted),
            _chip(context, scheme.tertiary.withValues(alpha: 0.35),
                scheme.onSurface, s.legendExcused),
            _chip(context, scheme.primary.withValues(alpha: 0.12),
                scheme.onSurface, s.legendSunnahDay,
                border: scheme.primary.withValues(alpha: 0.4)),
            _chip(context, scheme.primaryContainer.withValues(alpha: 0.45),
                scheme.onSurface, s.legendToday,
                border: scheme.primary, borderWidth: 2),
          ],
        ),
        if (showTypeCodes) ...[
          const SizedBox(height: 12),
          Text(
            s.legendTypeCodesTitle,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: s.calendarTypeCodeLegend
                .map(
                  (entry) => Text(
                    s.typeCodeEntry(entry.$1, entry.$2),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _chip(
    BuildContext context,
    Color bg,
    Color fg,
    String label, {
    Color? border,
    double borderWidth = 1,
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
            border: border != null
                ? Border.all(color: border, width: borderWidth)
                : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
