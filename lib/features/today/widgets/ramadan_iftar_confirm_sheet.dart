import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/goal_reminder_strings.dart';

/// Shows iftar fast confirmation; after Yes may show pending goal targets on the same sheet.
Future<bool?> showRamadanIftarConfirmSheet(
  BuildContext context, {
  required int dayIndex,
  List<String> pendingGoalTypes = const [],
  Future<void> Function()? onConfirmFast,
  VoidCallback? onOpenChecklist,
  String locale = 'en',
}) {
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _IftarConfirmSheetBody(
      dayIndex: dayIndex,
      pendingGoalTypes: pendingGoalTypes,
      onConfirmFast: onConfirmFast,
      onOpenChecklist: onOpenChecklist,
      locale: locale,
    ),
  );
}

enum _IftarConfirmPhase { confirm, successWithGoals }

class _IftarConfirmSheetBody extends StatefulWidget {
  const _IftarConfirmSheetBody({
    required this.dayIndex,
    required this.pendingGoalTypes,
    this.onConfirmFast,
    this.onOpenChecklist,
    required this.locale,
  });

  final int dayIndex;
  final List<String> pendingGoalTypes;
  final Future<void> Function()? onConfirmFast;
  final VoidCallback? onOpenChecklist;
  final String locale;

  @override
  State<_IftarConfirmSheetBody> createState() => _IftarConfirmSheetBodyState();
}

class _IftarConfirmSheetBodyState extends State<_IftarConfirmSheetBody> {
  _IftarConfirmPhase _phase = _IftarConfirmPhase.confirm;
  bool _saving = false;

  Future<void> _onYes() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (widget.onConfirmFast != null) {
        await widget.onConfirmFast!();
      }
      if (!mounted) return;

      final showGoals = widget.pendingGoalTypes.isNotEmpty;
      if (showGoals) {
        setState(() {
          _phase = _IftarConfirmPhase.successWithGoals;
          _saving = false;
        });
      } else {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (_phase == _IftarConfirmPhase.successWithGoals) {
      final digest =
          GoalReminderStrings.forDigest(widget.pendingGoalTypes, widget.locale);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.iftarFastRecordedTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.iftarFastRecordedBody,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.75),
                    ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        digest.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        digest.body,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (widget.onOpenChecklist != null)
                FilledButton(
                  onPressed: () {
                    widget.onOpenChecklist!();
                    Navigator.pop(context, true);
                  },
                  child: Text(l10n.openTodayChecklist),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.sahurIntentionLater),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.iftarConfirmTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.iftarConfirmBody,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _onYes,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.iftarConfirmYes),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => Navigator.pop(context, false),
              child: Text(l10n.iftarConfirmNo),
            ),
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(context),
              child: Text(s.cancel),
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only summary when fasting status is already set (excused or fasted).
Future<void> showRamadanIftarSummarySheet(
  BuildContext context, {
  required int dayIndex,
  DateTime? date,
  required int status,
  String? note,
  List<String> pendingGoalTypes = const [],
  VoidCallback? onOpenChecklist,
  String locale = 'en',
}) {
  final l10n = AppLocalizations.of(context)!;
  final s = SunnahStrings.of(context);
  final scheme = Theme.of(context).colorScheme;
  final dateLabel = date != null
      ? DateFormat(
          s.id ? 'EEEE, d MMM yyyy' : 'EEEE, MMM d, yyyy',
          s.id ? 'id_ID' : 'en_US',
        ).format(date)
      : (s.id ? 'Hari $dayIndex' : 'Day $dayIndex');

  String statusLabel;
  if (status == FastingStatus.fasted) {
    statusLabel = s.ramadanFastedTitle;
  } else if (status == FastingStatus.excusedHaid) {
    statusLabel = s.excusedHaidShort;
  } else if (status == FastingStatus.excusedNifas) {
    statusLabel = s.excusedNifasShort;
  } else if (status == FastingStatus.excusedSick) {
    statusLabel = s.excusedSickShort;
  } else {
    statusLabel = s.excusedOtherShort;
  }

  final showGoals =
      status == FastingStatus.fasted && pendingGoalTypes.isNotEmpty;
  final digest = showGoals
      ? GoalReminderStrings.forDigest(pendingGoalTypes, locale)
      : null;

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.iftarSummaryTitle, style: Theme.of(ctx).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(dateLabel, style: Theme.of(ctx).textTheme.bodySmall),
            const SizedBox(height: 12),
            Text(l10n.iftarSummaryStatus(statusLabel)),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(note, style: Theme.of(ctx).textTheme.bodySmall),
            ],
            if (showGoals && digest != null) ...[
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        digest.title,
                        style: Theme.of(ctx).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        digest.body,
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (showGoals && onOpenChecklist != null)
              FilledButton(
                onPressed: () {
                  onOpenChecklist();
                  Navigator.pop(ctx);
                },
                child: Text(l10n.openTodayChecklist),
              ),
            if (showGoals && onOpenChecklist != null) const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(showGoals ? l10n.sahurIntentionLater : l10n.close),
            ),
          ],
        ),
      ),
    ),
  );
}
