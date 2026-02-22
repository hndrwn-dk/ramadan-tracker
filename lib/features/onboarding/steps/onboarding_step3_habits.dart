import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';

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
    final isSmallScreen = MediaQuery.sizeOf(context).height < 600;
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
          SizedBox(height: isSmallScreen ? 4 : 8),
          Text(
            l10n.trackOnlyWhatHelps,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHabitCheckbox(context, 'fasting', l10n.habitFasting, Icons.no_meals),
                  _buildHabitCheckbox(context, 'quran_pages', _getQuranLabel(context), Icons.menu_book, iconWidget: const QuranIcon(size: 20)),
                  _buildHabitCheckbox(context, 'dhikr', l10n.habitDhikr, Icons.favorite, iconWidget: const DhikrIcon(size: 20)),
                  _buildHabitCheckbox(context, 'taraweeh', l10n.habitTaraweeh, Icons.nights_stay, iconWidget: const TaraweehIcon(size: 20)),
                  if (widget.data.selectedHabits.contains('taraweeh')) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 48, top: 4, bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            l10n.taraweehRakaatPerDayLabel,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 12),
                          _buildRakaatChip(context, 11),
                          const SizedBox(width: 8),
                          _buildRakaatChip(context, 23),
                        ],
                      ),
                    ),
                  ],
                  _buildHabitCheckbox(context, 'sedekah', l10n.habitSedekah, Icons.volunteer_activism, iconWidget: const SedekahIcon(size: 20)),
                  SizedBox(height: isSmallScreen ? 12 : 20),
                  ExpansionTile(
                    title: Text(l10n.advanced),
                    initiallyExpanded: false,
                    visualDensity: isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
                    children: [
                      _buildHabitCheckbox(context, 'prayers', l10n.habitPrayers, Icons.mosque, iconWidget: const PrayersIcon(size: 20)),
                      _buildHabitCheckbox(context, 'tahajud', l10n.habitTahajud, Icons.self_improvement, iconWidget: const TahajudIcon(size: 20)),
                      _buildHabitCheckbox(context, 'itikaf', l10n.habitItikaf, Icons.mosque, iconWidget: const ItikafIcon(size: 20)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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

  Widget _buildRakaatChip(BuildContext context, int rakaat) {
    final l10n = AppLocalizations.of(context)!;
    final label = rakaat == 11 ? l10n.taraweehRakaat11 : l10n.taraweehRakaat23;
    final isSelected = widget.data.taraweehRakaatPerDay == rakaat;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (value) {
        if (value == true) {
          setState(() => widget.data.taraweehRakaatPerDay = rakaat);
        }
      },
    );
  }

  Widget _buildHabitCheckbox(BuildContext context, String key, String label, IconData icon, {Widget? iconWidget}) {
    final isSelected = widget.data.selectedHabits.contains(key);
    final isSmallScreen = MediaQuery.sizeOf(context).height < 600;
    final iconSize = isSmallScreen ? 18.0 : 20.0;
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
      visualDensity: isSmallScreen ? VisualDensity.compact : VisualDensity.standard,
      contentPadding: isSmallScreen ? const EdgeInsets.symmetric(horizontal: 0, vertical: 0) : null,
      title: Row(
        children: [
          iconWidget ?? Icon(icon, size: iconSize),
          SizedBox(width: isSmallScreen ? 8 : 12),
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

