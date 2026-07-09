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
  final s = SunnahStrings.of(context);
  final db = ref.read(databaseProvider);
  final existing = await db.sunnahFastsDao.getByDate(date);
  final types = SunnahFastingRules.typesFor(date);
  final defaultType = types.isNotEmpty ? types.first.key : 'custom';

  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final scheme = Theme.of(ctx).colorScheme;
      final dateLabel = DateFormat(
        s.id ? 'EEEE, d MMM yyyy' : 'EEEE, MMM d, yyyy',
        s.id ? 'id_ID' : 'en_US',
      ).format(date);

      Future<void> apply(int status, {bool qadha = false}) async {
        if (status == FastingStatus.notDone && existing == null) {
          if (ctx.mounted) Navigator.pop(ctx);
          return;
        }

        final isQadha = status == FastingStatus.fasted && qadha;
        await db.sunnahFastsDao.upsert(
          date,
          status: status,
          type: existing?.type ?? defaultType,
          isQadha: isQadha,
        );
        if (status == FastingStatus.fasted &&
            isQadha &&
            !(existing?.isQadha ?? false)) {
          await db.qadhaLedgerDao.addEntry(
            kind: 'qadha',
            direction: 'paid',
            days: 1,
            dateYmd: SunnahFastsDao.dateKey(date),
            note: 'Auto from sunnah log',
          );
          ref.read(qadhaRefreshProvider.notifier).state++;
        }
        ref.read(sunnahRefreshProvider.notifier).state++;
        ref.invalidate(sunnahMonthlyChallengeProvider);
        ref.invalidate(preRamadanQuestProgressProvider);
        await FastingIntentService.clearSunnahIntent(db, date: date);
        await HomeWidgetService.update(db);
        await evaluateAchievements(ref);

        final message = _savedMessage(s, status, qadha: qadha);
        if (ctx.mounted) Navigator.pop(ctx);
        if (message != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }

      final isSunnahSelected = existing?.status == FastingStatus.fasted &&
          !(existing?.isQadha ?? false);
      final isQadhaSelected =
          existing?.status == FastingStatus.fasted && (existing?.isQadha ?? false);
      final isExcusedSelected =
          existing != null && FastingStatus.isExcused(existing.status);

      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                s.setStatus,
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
                s.statusSheetHint,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                    ),
              ),
              const SizedBox(height: 16),
              FastingOptionCard(
                number: 1,
                title: s.markSunnahFast,
                subtitle: s.option1Subtitle,
                icon: Icons.check_circle_outline,
                iconColor: Colors.green,
                selected: isSunnahSelected,
                onTap: () => apply(FastingStatus.fasted),
              ),
              const SizedBox(height: 10),
              FastingOptionCard(
                number: 2,
                title: s.markQadhaFast,
                subtitle: s.option2Subtitle,
                icon: Icons.event_repeat,
                iconColor: scheme.primary,
                selected: isQadhaSelected,
                onTap: () => apply(FastingStatus.fasted, qadha: true),
              ),
              const SizedBox(height: 10),
              FastingOptionCard(
                number: 3,
                title: s.notFastingExcusedSection,
                subtitle: s.excusedSectionHint,
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
                          selected: existing?.status == FastingStatus.excusedSick,
                          onTap: () => apply(FastingStatus.excusedSick),
                        ),
                        FastingExcuseChip(
                          label: s.excusedHaidShort,
                          icon: Icons.water_drop,
                          selected: existing?.status == FastingStatus.excusedHaid,
                          onTap: () => apply(FastingStatus.excusedHaid),
                        ),
                        FastingExcuseChip(
                          label: s.excusedNifasShort,
                          icon: Icons.child_friendly,
                          selected:
                              existing?.status == FastingStatus.excusedNifas,
                          onTap: () => apply(FastingStatus.excusedNifas),
                        ),
                        FastingExcuseChip(
                          label: s.excusedOtherShort,
                          icon: Icons.more_horiz,
                          selected:
                              existing?.status == FastingStatus.excusedOther,
                          onTap: () => apply(FastingStatus.excusedOther),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => apply(FastingStatus.notDone),
                icon: const Icon(Icons.close),
                label: Text(existing == null ? s.cancel : s.clear),
              ),
            ],
          ),
        ),
      );
    },
  );
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
