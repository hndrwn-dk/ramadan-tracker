import 'package:flutter/material.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Sticky segmented control for Insights ranges (extracted from monolith screen).
class InsightsRangeSelector extends StatelessWidget {
  final InsightsRange selectedRange;
  final bool sunnahTab;
  final SeasonState seasonState;
  final ValueChanged<InsightsRange> onRangeChanged;
  final VoidCallback onSunnahTabSelected;

  const InsightsRangeSelector({
    super.key,
    required this.selectedRange,
    required this.sunnahTab,
    required this.seasonState,
    required this.onRangeChanged,
    required this.onSunnahTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (seasonState == SeasonState.active) {
      final s = SunnahStrings.of(context);
      final labels = [
        l10n.today,
        l10n.sevenDays,
        l10n.insightsSeasonTab,
        s.sunnahInsightsTabLabel,
      ];
      final selectedIndex = sunnahTab ? 3 : selectedRange.index;
      return _ScrollablePillTabs(
        labels: labels,
        selectedIndex: selectedIndex,
        onSelected: (index) {
          if (index == 3) {
            onSunnahTabSelected();
          } else {
            onRangeChanged(InsightsRange.values[index]);
          }
        },
      );
    }

    return SegmentedButton<InsightsRange>(
      segments: [
        ButtonSegment(value: InsightsRange.today, label: Text(l10n.today)),
        ButtonSegment(value: InsightsRange.sevenDays, label: Text(l10n.sevenDays)),
        ButtonSegment(value: InsightsRange.season, label: Text(l10n.insightsSeasonTab)),
      ],
      selected: {selectedRange},
      onSelectionChanged: (selection) => onRangeChanged(selection.first),
    );
  }
}

class _ScrollablePillTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _ScrollablePillTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelLarge;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(labels.length, (index) {
        final selected = index == selectedIndex;
        return Material(
          color: selected ? scheme.secondaryContainer : scheme.surface,
          elevation: 0,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected
                  ? scheme.secondaryContainer
                  : AppSurface.borderColor(context),
            ),
          ),
          child: InkWell(
            onTap: () => onSelected(index),
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                labels[index],
                style: textStyle?.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? scheme.onSecondaryContainer : scheme.onSurface,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
