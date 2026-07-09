import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_option_cards.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

class SahurIntentionSheetResult {
  final int status;
  final String? note;

  const SahurIntentionSheetResult({required this.status, this.note});
}

/// Proposed A: 2-step Sahur intention — primary CTA, uzur on second step.
Future<SahurIntentionSheetResult?> showSahurIntentionSheet(
  BuildContext context, {
  DateTime? date,
  String? dayLabel,
}) {
  return showModalBottomSheet<SahurIntentionSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _SahurIntentionSheetBody(date: date, dayLabel: dayLabel),
  );
}

class _SahurIntentionSheetBody extends StatefulWidget {
  final DateTime? date;
  final String? dayLabel;

  const _SahurIntentionSheetBody({this.date, this.dayLabel});

  @override
  State<_SahurIntentionSheetBody> createState() =>
      _SahurIntentionSheetBodyState();
}

class _SahurIntentionSheetBodyState extends State<_SahurIntentionSheetBody> {
  bool _showExcusedStep = false;

  String _dateLabel(SunnahStrings s) {
    final date = widget.date;
    if (date != null) {
      return DateFormat(
        s.id ? 'EEEE, d MMM yyyy' : 'EEEE, MMM d, yyyy',
        s.id ? 'id_ID' : 'en_US',
      ).format(date);
    }
    return widget.dayLabel ?? '';
  }

  Future<void> _pickOtherReason() async {
    final note = await _showOtherNoteDialog(context);
    if (note == null || !mounted) return;
    Navigator.pop(
      context,
      SahurIntentionSheetResult(
        status: FastingStatus.excusedOther,
        note: note.isEmpty ? null : note,
      ),
    );
  }

  void _popExcused(int status) {
    Navigator.pop(context, SahurIntentionSheetResult(status: status));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = _dateLabel(s);

    if (_showExcusedStep) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sahurIntentionExcusedTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (dateLabel.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ],
              const SizedBox(height: 16),
              Text(
                s.option3PickReason,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FastingExcuseChip(
                    label: s.excusedSickShort,
                    icon: Icons.healing,
                    selected: false,
                    onTap: () => _popExcused(FastingStatus.excusedSick),
                  ),
                  FastingExcuseChip(
                    label: s.excusedHaidShort,
                    icon: Icons.water_drop,
                    selected: false,
                    onTap: () => _popExcused(FastingStatus.excusedHaid),
                  ),
                  FastingExcuseChip(
                    label: s.excusedNifasShort,
                    icon: Icons.child_friendly,
                    selected: false,
                    onTap: () => _popExcused(FastingStatus.excusedNifas),
                  ),
                  FastingExcuseChip(
                    label: s.excusedOtherShort,
                    icon: Icons.more_horiz,
                    selected: false,
                    onTap: _pickOtherReason,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.sahurIntentionExcusedFootnote,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() => _showExcusedStep = false),
                icon: const Icon(Icons.arrow_back),
                label: Text(l10n.sahurIntentionBack),
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
              l10n.sahurReminder,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (dateLabel.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.imsakIntentionHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.imsakConfirmAtIftarHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                const SahurIntentionSheetResult(
                  status: FastingStatus.intentPendingFast,
                ),
              ),
              child: Text(l10n.sahurIntentionYes),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => setState(() => _showExcusedStep = true),
              child: Text(l10n.sahurIntentionExcused),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.sahurIntentionLater),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String?> _showOtherNoteDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.fastingStatusExcusedOther),
      content: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: l10n.fastingNoteHint,
          border: const OutlineInputBorder(),
        ),
        maxLines: 2,
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}
