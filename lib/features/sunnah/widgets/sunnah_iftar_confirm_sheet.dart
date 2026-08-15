import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/engagement_providers.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/domain/services/fasting_intent_service.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/features/today/widgets/ramadan_iftar_confirm_sheet.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Iftar confirmation flow for sunnah fast days.
/// Returns `true`/`false` after confirm/decline or already-final summary;
/// `null` if dismissed so the notification can re-open the flow.
Future<bool?> showSunnahIftarConfirmFlow(
  BuildContext context,
  WidgetRef ref,
  DateTime date,
) async {
  final db = ref.read(databaseProvider);
  final existing = await db.sunnahFastsDao.getByDate(date);
  if (!context.mounted) return null;
  final s = SunnahStrings.of(context);

  if (existing != null && FastingStatus.isExcused(existing.status)) {
    await showRamadanIftarSummarySheet(
      context,
      dayIndex: 0,
      date: date,
      status: existing.status,
    );
    return true;
  }

  if (existing?.status == FastingStatus.fasted) {
    await showRamadanIftarSummarySheet(
      context,
      dayIndex: 0,
      date: date,
      status: FastingStatus.fasted,
    );
    return true;
  }

  final pending = await FastingIntentService.hasPendingSunnahIntent(db, date: date);
  if (!context.mounted) return null;

  if (pending) {
    final confirmed = await showRamadanIftarConfirmSheet(context, dayIndex: 0);
    if (confirmed == null || !context.mounted) return null;

    if (confirmed) {
      await db.sunnahFastsDao.upsert(date, status: FastingStatus.fasted);
      if (context.mounted) _showSnack(context, s.savedSunnahFast);
    } else {
      await db.sunnahFastsDao.remove(date);
    }
    await FastingIntentService.clearSunnahIntent(db, date: date);
    ref.read(sunnahRefreshProvider.notifier).state++;
    ref.invalidate(sunnahMonthlyChallengeProvider);
    ref.invalidate(preRamadanQuestProgressProvider);
    await HomeWidgetService.update(db);
    await evaluateAchievements(ref);
    return confirmed;
  }

  await showSunnahStatusSheet(context, ref, date);
  return null;
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
  );
}
