import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CounterWidget extends StatefulWidget {
  final String label;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final List<int> quickAddChips;
  final ValueChanged<int>? onQuickAdd;
  final IconData? icon;
  final int? target;
  final String? targetLabel;

  const CounterWidget({
    super.key,
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
    this.quickAddChips = const [],
    this.onQuickAdd,
    this.icon,
    this.target,
    this.targetLabel,
  });

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int? _lastSelectedChip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 20,
              ),
              const SizedBox(width: 12),
            ],
            Text(
              widget.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              onPressed: widget.onDecrement,
              icon: const Icon(Icons.remove_circle_outline),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${widget.value}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  if (widget.target != null)
                    Text(
                      widget.targetLabel ?? 'of ${widget.target}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              onPressed: widget.onIncrement,
              icon: const Icon(Icons.add_circle_outline),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).cardColor,
              ),
            ),
          ],
        ),
        if (widget.quickAddChips.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: widget.quickAddChips.map((chip) {
              final isSelected = _lastSelectedChip == chip;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _lastSelectedChip = chip;
                    });
                    // Use onQuickAdd if provided, otherwise fallback to multiple increments
                    if (widget.onQuickAdd != null) {
                      widget.onQuickAdd!(chip);
                    } else {
                      // Fallback: increment multiple times (less efficient)
                      for (int i = 0; i < chip; i++) {
                        widget.onIncrement();
                      }
                    }
                    // Reset selection after 1 second
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          _lastSelectedChip = null;
                        });
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                          : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '+$chip',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 6),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

