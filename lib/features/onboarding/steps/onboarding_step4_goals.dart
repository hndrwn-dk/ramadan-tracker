import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

class OnboardingStep4Goals extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep4Goals({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep4Goals> createState() => _OnboardingStep4GoalsState();
}

class _OnboardingStep4GoalsState extends State<OnboardingStep4Goals> {
  late TextEditingController _customPagesController;
  late TextEditingController _sedekahAmountController;

  @override
  void initState() {
    super.initState();
    _customPagesController = TextEditingController(
      text: widget.data.customQuranPages.toString(),
    );
    _sedekahAmountController = TextEditingController(
      text: widget.data.sedekahAmount > 0 ? widget.data.sedekahAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _customPagesController.dispose();
    _sedekahAmountController.dispose();
    super.dispose();
  }

  int _calculateTotalPages() {
    if (widget.data.quranGoal == '1_khatam') {
      return 20 * widget.data.days;
    } else if (widget.data.quranGoal == '2_khatam') {
      return 40 * widget.data.days;
    } else {
      return widget.data.customQuranPages * widget.data.days;
    }
  }

  int _getDailyPages() {
    if (widget.data.quranGoal == '1_khatam') {
      return 20;
    } else if (widget.data.quranGoal == '2_khatam') {
      return 40;
    } else {
      return widget.data.customQuranPages;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuran = widget.data.selectedHabits.contains('quran_pages');
    final hasDhikr = widget.data.selectedHabits.contains('dhikr');
    final hasSedekah = widget.data.selectedHabits.contains('sedekah');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Goals',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Gentle goals beat perfect streaks.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          if (hasQuran) ...[
            Text(
              'Quran Goal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RadioListTile<String>(
              title: Text('1 Khatam (20 pages/day)'),
              value: '1_khatam',
              groupValue: widget.data.quranGoal,
              onChanged: (value) {
                setState(() {
                  widget.data.quranGoal = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: Text('2 Khatam (40 pages/day)'),
              value: '2_khatam',
              groupValue: widget.data.quranGoal,
              onChanged: (value) {
                setState(() {
                  widget.data.quranGoal = value!;
                });
              },
            ),
            RadioListTile<String>(
              title: const Text('Custom'),
              value: 'custom',
              groupValue: widget.data.quranGoal,
              onChanged: (value) {
                setState(() {
                  widget.data.quranGoal = value!;
                });
              },
            ),
            if (widget.data.quranGoal == 'custom') ...[
              Padding(
                padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
                child: TextField(
                  controller: _customPagesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pages per day',
                  ),
                  onChanged: (value) {
                    final pages = int.tryParse(value) ?? 20;
                    widget.data.customQuranPages = pages;
                    setState(() {});
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48, bottom: 16),
                child: Text(
                  '${_calculateTotalPages()} total pages → ${_getDailyPages()} pages/day for ${widget.data.days} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
          if (hasDhikr) ...[
            Text(
              'Dhikr Target',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [33, 100, 300, 1000].map((preset) {
                return ChoiceChip(
                  label: Text('$preset'),
                  selected: widget.data.dhikrTarget == preset,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        widget.data.dhikrTarget = preset;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],
          if (hasSedekah) ...[
            SwitchListTile(
              title: const Text('Set a daily Sedekah goal'),
              value: widget.data.sedekahGoalEnabled,
              onChanged: (value) {
                setState(() {
                  widget.data.sedekahGoalEnabled = value;
                });
              },
            ),
            if (widget.data.sedekahGoalEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _sedekahAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                      onChanged: (value) {
                        widget.data.sedekahAmount = int.tryParse(value) ?? 0;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: widget.data.sedekahCurrency,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        isDense: true,
                      ),
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'Rp', child: Text('IDR (Rp)')),
                        DropdownMenuItem(value: 'S\$', child: Text('SGD (S\$)')),
                        DropdownMenuItem(value: '\$', child: Text('USD (\$)')),
                        DropdownMenuItem(value: 'RM', child: Text('MYR (RM)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            widget.data.sedekahCurrency = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
          Text(
            'Autopilot Intensity',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'light', label: Text('Light')),
              ButtonSegment(value: 'balanced', label: Text('Balanced')),
              ButtonSegment(value: 'strong', label: Text('Strong')),
            ],
            selected: {widget.data.autopilotIntensity},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                widget.data.autopilotIntensity = newSelection.first;
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            widget.data.autopilotIntensity == 'light'
                ? 'Gentle reminders, minimal pressure'
                : widget.data.autopilotIntensity == 'balanced'
                    ? 'Regular check-ins, steady progress'
                    : 'Frequent reminders, maximum support',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
