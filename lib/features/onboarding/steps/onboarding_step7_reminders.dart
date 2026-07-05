import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Step 8 of 9 — compact reminder toggles; timing via bottom sheets.
class OnboardingStep7Reminders extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStep7Reminders({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  State<OnboardingStep7Reminders> createState() =>
      _OnboardingStep7RemindersState();
}

class _OnboardingStep7RemindersState extends State<OnboardingStep7Reminders> {
  bool _showGoalDetails = false;

  bool get _anyGoalReminderOn =>
      widget.data.quranReminderEnabled ||
      widget.data.dhikrReminderEnabled ||
      widget.data.sedekahReminderEnabled ||
      widget.data.taraweehReminderEnabled;

  double get _nightPlanSliderValue {
    final h = widget.data.nightPlanHour.clamp(2, 4);
    final m = widget.data.nightPlanMinute;
    return ((h - 2) * 2 + (m >= 30 ? 1 : 0)).toDouble().clamp(0, 4);
  }

  String _formatNightPlanTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _setAllGoalReminders(bool value) {
    setState(() {
      widget.data.quranReminderEnabled = value;
      widget.data.dhikrReminderEnabled = value;
      widget.data.sedekahReminderEnabled = value;
      widget.data.taraweehReminderEnabled = value;
    });
  }

  Future<void> _showSahurTimingSheet() async {
    final l10n = AppLocalizations.of(context)!;
    var minutes = widget.data.sahurOffsetMinutes.clamp(1, 45);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.sahurReminder,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.minBeforeFajr(minutes),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: minutes.toDouble(),
                    min: 1,
                    max: 45,
                    divisions: 44,
                    label: l10n.minBeforeFajr(minutes),
                    onChanged: (value) {
                      setSheetState(() => minutes = value.round());
                      setState(() {
                        widget.data.sahurOffsetMinutes = value.round();
                      });
                    },
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.continueButton),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNightWorshipTimingSheet() async {
    final l10n = AppLocalizations.of(context)!;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final label = _formatNightPlanTime(
              widget.data.nightPlanHour,
              widget.data.nightPlanMinute,
            );
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.nightPlanReminder,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(label, style: Theme.of(ctx).textTheme.bodyMedium),
                  Row(
                    children: [
                      Text('2:00', style: Theme.of(ctx).textTheme.bodySmall),
                      Expanded(
                        child: Slider(
                          value: _nightPlanSliderValue,
                          min: 0,
                          max: 4,
                          divisions: 4,
                          label: label,
                          onChanged: (value) {
                            setSheetState(() {});
                            setState(() {
                              final index = value.round();
                              widget.data.nightPlanHour = 2 + index ~/ 2;
                              widget.data.nightPlanMinute = (index % 2) * 30;
                            });
                          },
                        ),
                      ),
                      Text('4:00', style: Theme.of(ctx).textTheme.bodySmall),
                    ],
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(l10n.continueButton),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _compactReminderRow({
    required String title,
    required String hint,
    required bool value,
    required ValueChanged<bool> onChanged,
    VoidCallback? onAdjust,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: value && onAdjust != null ? onAdjust : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                  ),
                ],
              ),
            ),
            if (value && onAdjust != null) ...[
              TextButton(
                onPressed: onAdjust,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(AppLocalizations.of(context)!.onboardingRemindersAdjustTiming),
              ),
            ],
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Divider(
      height: 1,
      color: AppSurface.borderColor(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    l10n.smartReminders,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.getNotifiedForSahurIftar,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.onboardingRemindersFastingSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Column(
                      children: [
                        _compactReminderRow(
                          title: l10n.sahurReminder,
                          hint: l10n.minBeforeFajr(
                            widget.data.sahurOffsetMinutes.clamp(1, 45),
                          ),
                          value: widget.data.sahurEnabled,
                          onChanged: (v) =>
                              setState(() => widget.data.sahurEnabled = v),
                          onAdjust: _showSahurTimingSheet,
                        ),
                        _divider(),
                        _compactReminderRow(
                          title: l10n.iftarReminder,
                          hint: l10n.atMaghrib,
                          value: widget.data.iftarEnabled,
                          onChanged: (v) =>
                              setState(() => widget.data.iftarEnabled = v),
                        ),
                        _divider(),
                        _compactReminderRow(
                          title: l10n.nightPlanReminder,
                          hint: _formatNightPlanTime(
                            widget.data.nightPlanHour,
                            widget.data.nightPlanMinute,
                          ),
                          value: widget.data.nightPlanEnabled,
                          onChanged: (v) =>
                              setState(() => widget.data.nightPlanEnabled = v),
                          onAdjust: _showNightWorshipTimingSheet,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.onboardingRemindersGoalsSection,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  AppSurface(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Column(
                      children: [
                        _compactReminderRow(
                          title: l10n.onboardingRemindersGoalsMaster,
                          hint: l10n.onboardingRemindersGoalsMasterHint,
                          value: _anyGoalReminderOn,
                          onChanged: _setAllGoalReminders,
                        ),
                        _divider(),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => setState(
                              () => _showGoalDetails = !_showGoalDetails,
                            ),
                            child: Text(l10n.onboardingRemindersCustomizeGoals),
                          ),
                        ),
                        if (_showGoalDetails) ...[
                          _divider(),
                          _goalDetailRow(
                            l10n.goalReminderQuran,
                            widget.data.quranReminderEnabled,
                            (v) => setState(
                              () => widget.data.quranReminderEnabled = v,
                            ),
                          ),
                          _divider(),
                          _goalDetailRow(
                            l10n.goalReminderDhikr,
                            widget.data.dhikrReminderEnabled,
                            (v) => setState(
                              () => widget.data.dhikrReminderEnabled = v,
                            ),
                          ),
                          _divider(),
                          _goalDetailRow(
                            l10n.goalReminderSedekah,
                            widget.data.sedekahReminderEnabled,
                            (v) => setState(
                              () => widget.data.sedekahReminderEnabled = v,
                            ),
                          ),
                          _divider(),
                          _goalDetailRow(
                            l10n.goalReminderTaraweeh,
                            widget.data.taraweehReminderEnabled,
                            (v) => setState(
                              () => widget.data.taraweehReminderEnabled = v,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
                child: FilledButton(
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

  Widget _goalDetailRow(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
