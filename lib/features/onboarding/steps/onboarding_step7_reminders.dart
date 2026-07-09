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
  bool get _anyGoalReminderOn =>
      widget.data.quranReminderEnabled ||
      widget.data.dhikrReminderEnabled ||
      widget.data.sedekahReminderEnabled;

  void _setAllGoalReminders(bool value) {
    setState(() {
      widget.data.quranReminderEnabled = value;
      widget.data.dhikrReminderEnabled = value;
      widget.data.sedekahReminderEnabled = value;
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
                          hint: l10n.iftarConfirmNotificationBody,
                          value: widget.data.iftarEnabled,
                          onChanged: (v) => setState(() {
                            widget.data.iftarEnabled = v;
                            widget.data.iftarConfirmEnabled = v;
                          }),
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
                    child: _compactReminderRow(
                      title: l10n.onboardingRemindersGoalsMaster,
                      hint: l10n.onboardingRemindersGoalsMasterHint,
                      value: _anyGoalReminderOn,
                      onChanged: _setAllGoalReminders,
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
}
