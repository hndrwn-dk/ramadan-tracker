import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/engagement_providers.dart';
import 'package:ramadan_tracker/domain/services/fasting_intent_service.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_option_cards.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Bottom sheet with 3 clear choices for a sunnah day:
/// 1) Sunnah fast  2) Qadha make-up fast  3) Did not fast (excused).
Future<void> showSunnahStatusSheet(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
) async {
  final db = ref.read(databaseProvider);
  final existing = await db.sunnahFastsDao.getByDate(date);
  final types = SunnahFastingRules.typesFor(date);
  final defaultType = types.isNotEmpty ? types.first.key : 'custom';

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) => _SunnahStatusSheetBody(
      date: date,
      initialExisting: existing,
      defaultType: defaultType,
      snackbarContext: context,
    ),
  );
}

class _SunnahStatusSheetBody extends ConsumerStatefulWidget {
  const _SunnahStatusSheetBody({
    required this.date,
    required this.initialExisting,
    required this.defaultType,
    required this.snackbarContext,
  });

  final DateTime date;
  final SunnahFast? initialExisting;
  final String defaultType;
  final BuildContext snackbarContext;

  @override
  ConsumerState<_SunnahStatusSheetBody> createState() =>
      _SunnahStatusSheetBodyState();
}

class _SunnahStatusSheetBodyState extends ConsumerState<_SunnahStatusSheetBody> {
  int? _pendingStatus;
  bool _pendingQadha = false;
  bool _saving = false;

  SunnahFast? get _existing => widget.initialExisting;

  bool get _isSunnahSelected {
    if (_pendingStatus != null) {
      return _pendingStatus == FastingStatus.fasted && !_pendingQadha;
    }
    return _existing?.status == FastingStatus.fasted &&
        !(_existing?.isQadha ?? false);
  }

  bool get _isQadhaSelected {
    if (_pendingStatus != null) {
      return _pendingStatus == FastingStatus.fasted && _pendingQadha;
    }
    return _existing?.status == FastingStatus.fasted &&
        (_existing?.isQadha ?? false);
  }

  int? get _activeStatus => _pendingStatus ?? _existing?.status;

  bool _isExcusedSelected(int status) {
    if (_pendingStatus != null) return _pendingStatus == status;
    return _existing?.status == status;
  }

  bool get _isAnyExcusedSelected {
    final status = _activeStatus;
    return status != null && FastingStatus.isExcused(status);
  }

  Future<void> _apply(int status, {bool qadha = false}) async {
    if (_saving) return;

    if (status == FastingStatus.notDone && _existing == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      _pendingStatus = status;
      _pendingQadha = qadha;
      _saving = true;
    });

    final strings = SunnahStrings.of(context);
    final db = ref.read(databaseProvider);
    final existing = _existing;
    final isQadha = status == FastingStatus.fasted && qadha;
    final wasQadha = existing?.isQadha ?? false;
    final dateKey = SunnahFastsDao.dateKey(widget.date);

    try {
      await db.sunnahFastsDao.upsert(
        widget.date,
        status: status,
        type: existing?.type ?? widget.defaultType,
        isQadha: isQadha,
      );
      if (isQadha) {
        await db.qadhaLedgerDao.ensureAutoSunnahPaidEntry(dateKey);
        ref.read(qadhaRefreshProvider.notifier).state++;
      } else if (wasQadha) {
        await db.qadhaLedgerDao.removeAutoSunnahEntriesForDate(dateKey);
        ref.read(qadhaRefreshProvider.notifier).state++;
      }

      ref.read(sunnahRefreshProvider.notifier).state++;
      ref.invalidate(sunnahMonthlyChallengeProvider);
      ref.invalidate(preRamadanQuestProgressProvider);
      await FastingIntentService.clearSunnahIntent(db, date: widget.date);
      await HomeWidgetService.update(db);

      final message = _savedMessage(
        strings,
        status,
        qadha: qadha,
      );

      if (!mounted) return;
      Navigator.pop(context);

      await evaluateAchievements(ref);

      if (message != null && widget.snackbarContext.mounted) {
        ScaffoldMessenger.of(widget.snackbarContext).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingStatus = null;
          _pendingQadha = false;
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat(
      s.id ? 'EEEE, d MMM yyyy' : 'EEEE, MMM d, yyyy',
      s.id ? 'id_ID' : 'en_US',
    ).format(widget.date);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.setStatus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              s.statusSheetHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
            ),
            const SizedBox(height: 16),
            FastingOptionCard(
              number: 1,
              title: s.markSunnahFast,
              subtitle: s.option1Subtitle,
              icon: Icons.event_available_outlined,
              iconColor: scheme.primary,
              selected: _isSunnahSelected,
              onTap: _saving ? null : () => _apply(FastingStatus.fasted),
            ),
            const SizedBox(height: 10),
            FastingOptionCard(
              number: 2,
              title: s.markQadhaFast,
              subtitle: s.option2Subtitle,
              icon: Icons.event_repeat,
              iconColor: scheme.secondary,
              selected: _isQadhaSelected,
              onTap: _saving
                  ? null
                  : () => _apply(FastingStatus.fasted, qadha: true),
            ),
            const SizedBox(height: 10),
            FastingOptionCard(
              number: 3,
              title: s.notFastingExcusedSection,
              subtitle: s.excusedSectionHint,
              icon: Icons.block,
              iconColor: scheme.tertiary,
              selected: _isAnyExcusedSelected,
              onTap: null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text(
                    s.option3PickReason,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
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
                        selected: _isExcusedSelected(FastingStatus.excusedSick),
                        onTap: _saving
                            ? () {}
                            : () => _apply(FastingStatus.excusedSick),
                      ),
                      FastingExcuseChip(
                        label: s.excusedHaidShort,
                        icon: Icons.water_drop,
                        selected: _isExcusedSelected(FastingStatus.excusedHaid),
                        onTap: _saving
                            ? () {}
                            : () => _apply(FastingStatus.excusedHaid),
                      ),
                      FastingExcuseChip(
                        label: s.excusedNifasShort,
                        icon: Icons.child_friendly,
                        selected:
                            _isExcusedSelected(FastingStatus.excusedNifas),
                        onTap: _saving
                            ? () {}
                            : () => _apply(FastingStatus.excusedNifas),
                      ),
                      FastingExcuseChip(
                        label: s.excusedOtherShort,
                        icon: Icons.more_horiz,
                        selected:
                            _isExcusedSelected(FastingStatus.excusedOther),
                        onTap: _saving
                            ? () {}
                            : () => _apply(FastingStatus.excusedOther),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_saving) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _saving
                  ? null
                  : () => _apply(FastingStatus.notDone),
              icon: const Icon(Icons.close),
              label: Text(_existing == null ? s.cancel : s.clear),
            ),
          ],
        ),
      ),
    );
  }
}

String? _savedMessage(SunnahStrings s, int status, {bool qadha = false}) {
  if (status == FastingStatus.notDone) return s.savedCleared;
  if (status == FastingStatus.fasted && qadha) return s.savedQadhaFast;
  if (status == FastingStatus.fasted) return s.savedSunnahFast;
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
