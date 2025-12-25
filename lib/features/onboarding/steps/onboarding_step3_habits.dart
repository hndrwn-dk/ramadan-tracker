import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

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
  String _getQuranLabel() {
    if (widget.data.quranGoal == '1_khatam') {
      return 'Qur\'an (20 pages/day)';
    } else if (widget.data.quranGoal == '2_khatam') {
      return 'Qur\'an (40 pages/day)';
    } else {
      return 'Qur\'an (${widget.data.customQuranPages} pages/day)';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose What to Track',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track only what helps. You can change anytime.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          _buildHabitCheckbox('fasting', 'Fasting', Icons.wb_sunny),
          _buildHabitCheckbox('quran_pages', _getQuranLabel(), Icons.menu_book),
          _buildHabitCheckbox('dhikr', 'Dhikr', Icons.favorite),
          _buildHabitCheckbox('taraweeh', 'Taraweeh', Icons.nights_stay),
          _buildHabitCheckbox('sedekah', 'Sedekah', Icons.volunteer_activism),
          const SizedBox(height: 24),
          ExpansionTile(
            title: const Text('Advanced'),
            initiallyExpanded: false,
            children: [
              _buildHabitCheckbox('prayers', '5 Prayers (simple)', Icons.mosque),
              _buildHabitCheckbox('itikaf', 'I\'tikaf', Icons.mosque),
            ],
          ),
          const Spacer(),
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
        ],
      ),
    );
  }

  Widget _buildHabitCheckbox(String key, String label, IconData icon) {
    final isSelected = widget.data.selectedHabits.contains(key);
    return CheckboxListTile(
      value: isSelected,
      onChanged: (value) {
        setState(() {
          if (value == true) {
            widget.data.selectedHabits.add(key);
          } else {
            widget.data.selectedHabits.remove(key);
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

