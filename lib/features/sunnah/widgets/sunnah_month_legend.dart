import 'package:flutter/material.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';

class SunnahMonthLegend extends StatefulWidget {
  final bool showTypeCodes;
  final bool defaultExpanded;

  const SunnahMonthLegend({
    super.key,
    this.showTypeCodes = true,
    this.defaultExpanded = false,
  });

  @override
  State<SunnahMonthLegend> createState() => _SunnahMonthLegendState();
}

class _SunnahMonthLegendState extends State<SunnahMonthLegend> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.defaultExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final chips = Wrap(
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
    );

    final dotPrimaryEntry = s.calendarTypeCodeLegend.first;
    final dotSecondaryEntry = s.calendarTypeCodeLegend[1];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.showTypeCodes
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.legend,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (widget.showTypeCodes) ...[
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (!_isExpanded) ...[
          const SizedBox(height: 8),
          chips,
        ] else ...[
          const SizedBox(height: 8),
          chips,
          if (widget.showTypeCodes) ...[
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
              spacing: 12,
              runSpacing: 8,
              children: [
                _dotLegendItem(
                  context,
                  dotColor: scheme.primary,
                  label: s.typeCodeEntry(
                    dotPrimaryEntry.$1,
                    dotPrimaryEntry.$2,
                  ),
                ),
                _dotLegendItem(
                  context,
                  dotColor: scheme.onSurface.withValues(alpha: 0.55),
                  label: s.typeCodeEntry(
                    dotSecondaryEntry.$1,
                    dotSecondaryEntry.$2,
                  ),
                ),
                _dotLegendItem(
                  context,
                  dotColor: scheme.primary.withValues(alpha: 0.7),
                  label: s.legendSunnahDay,
                ),
              ],
            ),
          ],
        ],
      ],
    );
  }

  Widget _dotLegendItem(
    BuildContext context, {
    required Color dotColor,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.65),
                fontWeight: FontWeight.w500,
              ),
        ),
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
