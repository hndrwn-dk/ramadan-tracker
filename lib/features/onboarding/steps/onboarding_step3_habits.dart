import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class OnboardingStep3Habits extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep3Habits({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep3Habits> createState() => _OnboardingStep3HabitsState();
}

class _OnboardingStep3HabitsState extends State<OnboardingStep3Habits> {
  String _getQuranLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Just return "Al-Quran" without page details - details will be shown in next step
    return l10n.habitQuran;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.chooseWhatToTrack,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.trackOnlyWhatHelps,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _buildHabitCheckbox(context, 'fasting', l10n.habitFasting, Icons.wb_sunny),
          _buildHabitCheckbox(context, 'quran_pages', _getQuranLabel(context), Icons.menu_book),
          _buildHabitCheckbox(context, 'dhikr', l10n.habitDhikr, Icons.favorite),
          _buildHabitCheckbox(context, 'taraweeh', l10n.habitTaraweeh, Icons.nights_stay),
          _buildHabitCheckbox(context, 'sedekah', l10n.habitSedekah, Icons.volunteer_activism),
          const SizedBox(height: 24),
          ExpansionTile(
            title: Text(l10n.advanced),
            initiallyExpanded: false,
            children: [
              _buildHabitCheckbox(context, 'prayers', l10n.habitPrayers, Icons.mosque),
              _buildHabitCheckbox(context, 'itikaf', l10n.habitItikaf, Icons.mosque),
            ],
          ),
          const Spacer(),
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
                child: ElevatedButton(
                  onPressed: widget.onNext,
                  child: Text(l10n.continueButton),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHabitCheckbox(BuildContext context, String key, String label, IconData icon) {
    final isSelected = widget.data.selectedHabits.contains(key);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            widget.data.selectedHabits.add(key);
            if (key == 'sedekah') {
              widget.data.sedekahGoalEnabled = true;
            }
          } else {
            widget.data.selectedHabits.remove(key);
            if (key == 'sedekah') {
              widget.data.sedekahGoalEnabled = false;
            }
          }
        });
      },
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

