import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Step 6 of 9 — Quran and Dhikr daily goals (always shown).
class OnboardingStep5GoalsQuranDhikr extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep5GoalsQuranDhikr({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep5GoalsQuranDhikr> createState() =>
      _OnboardingStep5GoalsQuranDhikrState();
}

class _OnboardingStep5GoalsQuranDhikrState
    extends State<OnboardingStep5GoalsQuranDhikr> {
  late TextEditingController _customPagesController;

  @override
  void initState() {
    super.initState();
    _customPagesController = TextEditingController(
      text: widget.data.customQuranPages.toString(),
    );
  }

  @override
  void dispose() {
    _customPagesController.dispose();
    super.dispose();
  }

  int _calculateTotalPages() {
    if (widget.data.quranGoal == '1_khatam') {
      return 20 * widget.data.days;
    } else if (widget.data.quranGoal == '2_khatam') {
      return 40 * widget.data.days;
    }
    return widget.data.customQuranPages * widget.data.days;
  }

  int _getDailyPages() {
    if (widget.data.quranGoal == '1_khatam') {
      return 20;
    } else if (widget.data.quranGoal == '2_khatam') {
      return 40;
    }
    return widget.data.customQuranPages;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingGoalsQuranDhikrTitle,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.gentleGoalsBeatPerfectStreaks,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Text(
            l10n.quranGoal,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          RadioListTile<String>(
            title: Text(l10n.oneKhatam20Pages),
            value: '1_khatam',
            groupValue: widget.data.quranGoal,
            onChanged: (value) {
              setState(() => widget.data.quranGoal = value!);
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.twoKhatam40Pages),
            value: '2_khatam',
            groupValue: widget.data.quranGoal,
            onChanged: (value) {
              setState(() => widget.data.quranGoal = value!);
            },
          ),
          RadioListTile<String>(
            title: Text(l10n.custom),
            value: 'custom',
            groupValue: widget.data.quranGoal,
            onChanged: (value) {
              setState(() => widget.data.quranGoal = value!);
            },
          ),
          if (widget.data.quranGoal == 'custom') ...[
            Padding(
              padding: const EdgeInsets.only(left: 48, top: 8, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.pagesPerDayLabel,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _customPagesController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: l10n.enterPages,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      widget.data.customQuranPages = int.tryParse(value) ?? 20;
                      setState(() {});
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 16),
              child: Text(
                l10n.totalPagesCalculation(
                  _calculateTotalPages(),
                  _getDailyPages(),
                  widget.data.days,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            l10n.dhikrTarget,
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
                    setState(() => widget.data.dhikrTarget = preset);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  child: Text(l10n.back),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: widget.onNext,
                  child: Text(l10n.continueButton),
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
