import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_option_cards.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

class RamadanFastingSheetResult {
  final int status;
  final String? note;

  const RamadanFastingSheetResult({required this.status, this.note});
}

/// Ramadan obligatory fasting sheet — same card UX as sunnah status sheet.
Future<RamadanFastingSheetResult?> showRamadanFastingStatusSheet(
  BuildContext context, {
  required int dayIndex,
  DateTime? date,
  int? currentStatus,
  String? currentNote,
}) async {
  final s = SunnahStrings.of(context);
  final l10n = AppLocalizations.of(context)!;
  final selected = currentStatus ?? FastingStatus.notDone;
  final hasEntry = currentStatus != null &&
      currentStatus != FastingStatus.notDone &&
      currentStatus != FastingStatus.intentPendingFast;

  return showModalBottomSheet<RamadanFastingSheetResult>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final dateLabel = date != null
          ? DateFormat(
              s.id ? 'EEEE, d MMM yyyy' : 'EEEE, MMM d, yyyy',
              s.id ? 'id_ID' : 'en_US',
            ).format(date)
          : (s.id ? 'Hari $dayIndex' : 'Day $dayIndex');

      Future<void> pickOtherReason() async {
        final note = await _showOtherNoteDialog(ctx, initialNote: currentNote);
        if (note == null) return;
        if (ctx.mounted) {
          Navigator.pop(
            ctx,
            RamadanFastingSheetResult(
              status: FastingStatus.excusedOther,
              note: note.isEmpty ? null : note,
            ),
          );
        }
      }

      void apply(int status) {
        Navigator.pop(
          ctx,
          RamadanFastingSheetResult(status: status),
        );
      }

      final isFastedSelected = selected == FastingStatus.fasted;
      final isExcusedSelected = FastingStatus.isExcused(selected);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.habitFasting,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                s.ramadanStatusSheetHint,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 16),
              FastingOptionCard(
                number: 1,
                title: s.ramadanFastedTitle,
                subtitle: s.ramadanFastedSubtitle,
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                selected: isFastedSelected,
                onTap: () => apply(FastingStatus.fasted),
              ),
              const SizedBox(height: 10),
              FastingOptionCard(
                number: 2,
                title: s.notFastingExcusedSection,
                subtitle: s.ramadanExcusedHint,
                icon: Icons.block,
                iconColor: scheme.tertiary,
                selected: isExcusedSelected,
                onTap: null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      s.option3PickReason,
                      style: Theme.of(ctx).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FastingExcuseChip(
                          label: s.excusedSickShort,
                          icon: Icons.healing,
                          selected:
                              selected == FastingStatus.excusedSick,
                          onTap: () => apply(FastingStatus.excusedSick),
                        ),
                        FastingExcuseChip(
                          label: s.excusedHaidShort,
                          icon: Icons.water_drop,
                          selected:
                              selected == FastingStatus.excusedHaid,
                          onTap: () => apply(FastingStatus.excusedHaid),
                        ),
                        FastingExcuseChip(
                          label: s.excusedNifasShort,
                          icon: Icons.child_friendly,
                          selected:
                              selected == FastingStatus.excusedNifas,
                          onTap: () => apply(FastingStatus.excusedNifas),
                        ),
                        FastingExcuseChip(
                          label: s.excusedOtherShort,
                          icon: Icons.more_horiz,
                          selected:
                              selected == FastingStatus.excusedOther,
                          onTap: pickOtherReason,
                        ),
                      ],
                    ),
                    if (selected == FastingStatus.excusedOther &&
                        currentNote != null &&
                        currentNote.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        currentNote,
                        style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.6),
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: hasEntry
                    ? () => apply(FastingStatus.notDone)
                    : () => Navigator.pop(ctx),
                icon: Icon(hasEntry ? Icons.close : Icons.arrow_back),
                label: Text(hasEntry ? s.clear : s.cancel),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<String?> _showOtherNoteDialog(
  BuildContext context, {
  String? initialNote,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final controller = TextEditingController(text: initialNote ?? '');
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

String? ramadanFastingSavedMessage(SunnahStrings s, int status) {
  if (status == FastingStatus.notDone) return s.savedCleared;
  if (status == FastingStatus.fasted) return s.ramadanSavedFasted;
  if (status == FastingStatus.excusedSick) {
    return s.savedExcused(s.excusedSickShort);
  }
  if (status == FastingStatus.excusedHaid) {
    return s.savedExcused(s.excusedHaidShort);
  }
  if (status == FastingStatus.excusedNifas) {
    return s.savedExcused(s.excusedNifasShort);
  }
  if (status == FastingStatus.excusedOther) {
    return s.savedExcused(s.excusedOtherShort);
  }
  return null;
}
