import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/engagement_providers.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/domain/services/fasting_intent_service.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/features/today/widgets/ramadan_iftar_confirm_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
/// Iftar confirmation flow for sunnah fast days.
Future<void> showSunnahIftarConfirmFlow(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
) async {
  final db = ref.read(databaseProvider);
  final existing = await db.sunnahFastsDao.getByDate(date);
  final l10n = AppLocalizations.of(context)!;
  final s = SunnahStrings.of(context);

  if (!context.mounted) return;

  if (existing != null && FastingStatus.isExcused(existing.status)) {
    await showRamadanIftarSummarySheet(
      context,
      dayIndex: 0,
      date: date,
      status: existing.status,
    );
    return;
  }

  if (existing?.status == FastingStatus.fasted) {
    await showRamadanIftarSummarySheet(
      context,
      dayIndex: 0,
      date: date,
      status: FastingStatus.fasted,
    );
    return;
  }

  final pending = await FastingIntentService.hasPendingSunnahIntent(db, date: date);
  if (!context.mounted) return;

  if (pending) {
    final confirmed = await showRamadanIftarConfirmSheet(context, dayIndex: 0);
    if (confirmed == null || !context.mounted) return;

    if (confirmed) {
      await db.sunnahFastsDao.upsert(date, status: FastingStatus.fasted);
      _showSnack(context, s.savedSunnahFast);
    } else {
      await db.sunnahFastsDao.remove(date);
    }
    await FastingIntentService.clearSunnahIntent(db, date: date);
    ref.read(sunnahRefreshProvider.notifier).state++;
    ref.invalidate(sunnahMonthlyChallengeProvider);
    ref.invalidate(preRamadanQuestProgressProvider);
    await HomeWidgetService.update(db);
    await evaluateAchievements(ref);
    return;
  }

  await showSunnahStatusSheet(context, ref, date);
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}
