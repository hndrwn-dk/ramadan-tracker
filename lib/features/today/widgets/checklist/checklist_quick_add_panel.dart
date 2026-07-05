import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Chips-only quick add row for numeric checklist habits (no steppers).
class ChecklistQuickAddPanel extends StatefulWidget {
  final int currentValue;
  final List<int> chips;
  final ValueChanged<int> onAdd;
  final ValueChanged<int>? onSetValue;
  final Future<int?> Function(int current)? onManualEdit;

  const ChecklistQuickAddPanel({
    super.key,
    required this.currentValue,
    required this.chips,
    required this.onAdd,
    this.onSetValue,
    this.onManualEdit,
  });

  @override
  State<ChecklistQuickAddPanel> createState() => _ChecklistQuickAddPanelState();
}

class _ChecklistQuickAddPanelState extends State<ChecklistQuickAddPanel> {
  int? _lastSelectedChip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onManualEdit != null)
          Center(
            child: GestureDetector(
              onTap: () async {
                final next = await widget.onManualEdit!(widget.currentValue);
                if (next != null) {
                  if (widget.onSetValue != null) {
                    widget.onSetValue!(next);
                  } else {
                    widget.onAdd(next - widget.currentValue);
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${widget.currentValue}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                ),
              ),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.chips.map((chip) {
            final isSelected = _lastSelectedChip == chip;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _lastSelectedChip = chip);
                  widget.onAdd(chip);
                  Future.delayed(const Duration(seconds: 1), () {
                    if (mounted) setState(() => _lastSelectedChip = null);
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.12)
                        : AppSurface.fillColor(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? scheme.primary : AppSurface.borderColor(context),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    '+$chip',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
