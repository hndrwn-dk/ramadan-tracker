import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/root_navigator.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_quest_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/notification_launch_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/services/fasting_intent_service.dart';
import 'package:ramadan_tracker/domain/services/goal_reminder_service.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';
import 'package:ramadan_tracker/domain/services/notification_launch_service.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/data/providers/engagement_providers.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';
import 'package:ramadan_tracker/features/today/today_checklist_navigation.dart';
import 'package:ramadan_tracker/features/today/widgets/ramadan_iftar_confirm_sheet.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_iftar_confirm_sheet.dart';
import 'package:ramadan_tracker/features/today/widgets/sahur_intention_sheet.dart';
import 'package:ramadan_tracker/features/today/widgets/ramadan_fasting_status_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Opens fasting sheets in response to notification taps.
class FastingNotificationHandler {
  FastingNotificationHandler._();

  static Future<void> handle(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
  ) async {
    if (kDebugMode) {
      debugPrint('[NOTIF-LAUNCH] handle ${request.kind}');
    }
    switch (request.kind) {
      case FastingNotificationKind.ramadanSahur:
        await _handleRamadanSahur(context, ref, request);
      case FastingNotificationKind.ramadanIftar:
        await _handleRamadanIftar(context, ref, request);
      case FastingNotificationKind.sunnahSahur:
        await _handleSunnahSahur(context, ref, request);
      case FastingNotificationKind.sunnahIftar:
        await _handleSunnahIftar(context, ref, request);
    }
  }

  static Future<void> _handleRamadanSahur(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
  ) async {
    final seasonId = request.seasonId;
    final dayIndex = request.dayIndex;
    if (seasonId == null || dayIndex == null) {
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] ramadan sahur missing season/day');
      }
      return;
    }

    final db = ref.read(databaseProvider);
    final fastingHabit = await db.habitsDao.getHabitByKey('fasting');
    if (fastingHabit == null || !context.mounted) {
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] ramadan sahur: no fasting habit');
      }
      return;
    }

    final entry = await db.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final existing = entry.where((e) => e.habitId == fastingHabit.id).firstOrNull;
    final currentStatus = existing != null
        ? FastingStatus.fromEntry(existing.valueInt, existing.valueBool)
        : null;

    if (currentStatus != null &&
        currentStatus != FastingStatus.notDone &&
        currentStatus != FastingStatus.intentPendingFast) {
      if (!context.mounted) return;
      await showRamadanFastingStatusSheet(
        context,
        dayIndex: dayIndex,
        date: await _ramadanDate(ref, seasonId, dayIndex),
        currentStatus: currentStatus,
        currentNote: existing?.note,
      );
      return;
    }

    if (!context.mounted) return;
    final date = await _ramadanDate(ref, seasonId, dayIndex);
    final result = await showSahurIntentionSheet(
      context,
      date: date,
      dayLabel: SunnahStrings.of(context).id
          ? 'Hari $dayIndex'
          : 'Day $dayIndex',
    );
    if (result == null || !context.mounted) return;

    if (result.status == FastingStatus.intentPendingFast) {
      await FastingIntentService.setRamadanIntent(
        db,
        seasonId: seasonId,
        dayIndex: dayIndex,
        status: FastingStatus.intentPendingFast,
      );
      _showSnack(context, AppLocalizations.of(context)!.fastingIntentPendingSaved);
      return;
    }

    if (result.status == FastingStatus.notDone) {
      await FastingIntentService.clearRamadanIntent(
        db,
        seasonId: seasonId,
        dayIndex: dayIndex,
      );
      return;
    }

    await db.dailyEntriesDao.setFastingStatus(
      seasonId,
      dayIndex,
      fastingHabit.id,
      result.status,
      note: result.note,
    );
    await FastingIntentService.clearRamadanIntent(
      db,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    await _onEngagementUpdate(ref, seasonId, dayIndex);
    final message = ramadanFastingSavedMessage(SunnahStrings.of(context), result.status);
    if (message != null) _showSnack(context, message);
  }

  static Future<void> _handleRamadanIftar(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
  ) async {
    final seasonId = request.seasonId;
    final dayIndex = request.dayIndex;
    if (seasonId == null || dayIndex == null) return;

    final db = ref.read(databaseProvider);
    final fastingHabit = await db.habitsDao.getHabitByKey('fasting');
    if (fastingHabit == null || !context.mounted) return;

    final entries = await db.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final existing = entries.where((e) => e.habitId == fastingHabit.id).firstOrNull;
    final currentStatus = existing != null
        ? FastingStatus.fromEntry(existing.valueInt, existing.valueBool)
        : FastingStatus.notDone;

    if (FastingStatus.isExcused(currentStatus)) {
      if (!context.mounted) return;
      await showRamadanIftarSummarySheet(
        context,
        dayIndex: dayIndex,
        date: await _ramadanDate(ref, seasonId, dayIndex),
        status: currentStatus,
        note: existing?.note,
      );
      return;
    }

    if (currentStatus == FastingStatus.fasted) {
      if (!context.mounted) return;
      final pendingGoals = await _pendingGoalsForRamadanDay(
        db,
        ref,
        seasonId,
        dayIndex,
      );
      final locale =
          await db.kvSettingsDao.getValue('app_language') ?? 'en';
      if (!context.mounted) return;
      await showRamadanIftarSummarySheet(
        context,
        dayIndex: dayIndex,
        date: await _ramadanDate(ref, seasonId, dayIndex),
        status: currentStatus,
        pendingGoalTypes: pendingGoals,
        locale: locale,
        onOpenChecklist: pendingGoals.isNotEmpty
            ? () => openDayChecklist(
                  context,
                  ref,
                  dayIndex: dayIndex,
                  switchToTodayTab: true,
                )
            : null,
      );
      return;
    }

    final pending = await FastingIntentService.hasPendingRamadanIntent(
      db,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );

    if (!context.mounted) return;

    if (pending) {
      final pendingGoals = await _pendingGoalsForRamadanDay(
        db,
        ref,
        seasonId,
        dayIndex,
      );
      final locale =
          await db.kvSettingsDao.getValue('app_language') ?? 'en';

      if (!context.mounted) return;

      final confirmed = await showRamadanIftarConfirmSheet(
        context,
        dayIndex: dayIndex,
        pendingGoalTypes: pendingGoals,
        locale: locale,
        onConfirmFast: () async {
          await db.dailyEntriesDao.setFastingStatus(
            seasonId,
            dayIndex,
            fastingHabit.id,
            FastingStatus.fasted,
          );
          await FastingIntentService.clearRamadanIntent(
            db,
            seasonId: seasonId,
            dayIndex: dayIndex,
          );
          ref.invalidate(
            dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)),
          );
          await _onEngagementUpdate(ref, seasonId, dayIndex);
        },
        onOpenChecklist: pendingGoals.isNotEmpty
            ? () => openDayChecklist(
                  context,
                  ref,
                  dayIndex: dayIndex,
                  switchToTodayTab: true,
                )
            : null,
      );
      if (confirmed == null || !context.mounted) return;

      if (confirmed) {
        _showSnack(context, SunnahStrings.of(context).ramadanSavedFasted);
      } else {
        await db.dailyEntriesDao.setFastingStatus(
          seasonId,
          dayIndex,
          fastingHabit.id,
          FastingStatus.notDone,
        );
        await FastingIntentService.clearRamadanIntent(
          db,
          seasonId: seasonId,
          dayIndex: dayIndex,
        );
        ref.invalidate(
          dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)),
        );
      }
      return;
    }

    final result = await showRamadanFastingStatusSheet(
      context,
      dayIndex: dayIndex,
      date: await _ramadanDate(ref, seasonId, dayIndex),
      currentStatus: currentStatus == FastingStatus.notDone ? null : currentStatus,
      currentNote: existing?.note,
    );
    if (result == null || !context.mounted) return;

    if (result.status == FastingStatus.notDone && existing == null) return;

    await db.dailyEntriesDao.setFastingStatus(
      seasonId,
      dayIndex,
      fastingHabit.id,
      result.status,
      note: result.note,
    );
    await FastingIntentService.clearRamadanIntent(
      db,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    await _onEngagementUpdate(ref, seasonId, dayIndex);
    final message = ramadanFastingSavedMessage(SunnahStrings.of(context), result.status);
    if (message != null) _showSnack(context, message);
  }

  static Future<void> _handleSunnahSahur(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
  ) async {
    final date = request.sunnahDate;
    if (date == null) return;

    final db = ref.read(databaseProvider);
    final existing = await db.sunnahFastsDao.getByDate(date);
    if (!context.mounted) return;

    final result = await showSahurIntentionSheet(context, date: date);
    if (result == null || !context.mounted) return;

    if (result.status == FastingStatus.intentPendingFast) {
      await FastingIntentService.setSunnahIntent(
        db,
        date: date,
        status: FastingStatus.intentPendingFast,
      );
      _showSnack(context, AppLocalizations.of(context)!.fastingIntentPendingSaved);
      return;
    }

    final types = SunnahFastingRules.typesFor(date);
    final defaultType = types.isNotEmpty ? types.first.key : 'custom';

    await db.sunnahFastsDao.upsert(
      date,
      status: result.status,
      type: existing?.type ?? defaultType,
      isQadha: false,
    );
    await FastingIntentService.clearSunnahIntent(db, date: date);
    ref.read(sunnahRefreshProvider.notifier).state++;
    ref.invalidate(sunnahMonthlyChallengeProvider);
    ref.invalidate(preRamadanQuestProgressProvider);
    await HomeWidgetService.update(db);
    await evaluateAchievements(ref);

    final s = SunnahStrings.of(context);
    String? message;
    if (result.status == FastingStatus.excusedSick) {
      message = s.savedExcused(s.excusedSickShort);
    } else if (result.status == FastingStatus.excusedHaid) {
      message = s.savedExcused(s.excusedHaidShort);
    } else if (result.status == FastingStatus.excusedNifas) {
      message = s.savedExcused(s.excusedNifasShort);
    } else if (result.status == FastingStatus.excusedOther) {
      message = s.savedExcused(s.excusedOtherShort);
    }
    if (message != null) _showSnack(context, message);
  }

  static Future<void> _handleSunnahIftar(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
  ) async {
    final date = request.sunnahDate;
    if (date == null) return;
    await showSunnahIftarConfirmFlow(context, ref, date);
  }

  static Future<List<String>> _pendingGoalsForRamadanDay(
    AppDatabase db,
    WidgetRef ref,
    int seasonId,
    int dayIndex,
  ) async {
    final digestOn = await GoalReminderService.isDigestReminderEnabled(db);
    if (!digestOn) return [];
    final ramadanDate = await _ramadanDate(ref, seasonId, dayIndex);
    if (ramadanDate == null) return [];
    return GoalReminderService.getPendingGoalTypesForDate(
      database: db,
      seasonId: seasonId,
      date: ramadanDate,
    );
  }

  static Future<DateTime?> _ramadanDate(
    WidgetRef ref,
    int seasonId,
    int dayIndex,
  ) async {
    final season = await ref.read(currentSeasonProvider.future);
    if (season == null || season.id != seasonId) {
      final db = ref.read(databaseProvider);
      final row = await db.ramadanSeasonsDao.getSeasonById(seasonId);
      if (row == null) return null;
      return SeasonModel.fromDb(row).getDateForDay(dayIndex);
    }
    return season.getDateForDay(dayIndex);
  }

  static Future<void> _onEngagementUpdate(
    WidgetRef ref,
    int seasonId,
    int dayIndex,
  ) async {
    await evaluateAchievements(ref, seasonId: seasonId, dayIndex: dayIndex);
    await refreshDailyQuests(ref, seasonId: seasonId, dayIndex: dayIndex);
    await HomeWidgetService.update(ref.read(databaseProvider));
  }

  static void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
    );
  }
}

/// Listens for [notificationLaunchProvider] and opens fasting sheets.
class NotificationLaunchListener extends ConsumerStatefulWidget {
  final Widget child;

  const NotificationLaunchListener({super.key, required this.child});

  @override
  ConsumerState<NotificationLaunchListener> createState() =>
      _NotificationLaunchListenerState();
}

class _NotificationLaunchListenerState extends ConsumerState<NotificationLaunchListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationLaunchBridge.setHandler((request) {
      if (!mounted) return;
      NotificationLaunchBridge.consumePending();
      NotificationLaunchService.dispatch(ref, request);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationLaunchService.checkInitialLaunch(ref);
      }
    });
  }

  @override
  void dispose() {
    NotificationLaunchBridge.setHandler(null);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      NotificationLaunchService.checkInitialLaunch(ref);
    }
  }

  Future<void> _openSheet(NotificationLaunchRequest request) async {
    // Wait for navigator + onboarding gate to finish mounting.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;

    final sheetContext = rootNavigatorKey.currentContext ?? context;
    if (!sheetContext.mounted) {
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] no navigator context for sheet');
      }
      return;
    }

    await FastingNotificationHandler.handle(sheetContext, ref, request);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<NotificationLaunchRequest?>(notificationLaunchProvider, (prev, next) {
      if (next == null) return;
      if (prev == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _openSheet(next);
        if (mounted) {
          ref.read(notificationLaunchProvider.notifier).state = null;
        }
      });
    });

    return widget.child;
  }
}
