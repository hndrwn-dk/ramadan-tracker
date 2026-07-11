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

  static final Set<NotificationLaunchRequest> _handledThisSession = {};

  @visibleForTesting
  static void resetHandledForTest() {
    _handledThisSession.clear();
  }

  /// KV key — one fasting notification flow per day is enough.
  @visibleForTesting
  static String? handledKvKey(NotificationLaunchRequest request) {
    switch (request.kind) {
      case FastingNotificationKind.ramadanSahur:
      case FastingNotificationKind.ramadanIftar:
        final seasonId = request.seasonId;
        final dayIndex = request.dayIndex;
        if (seasonId == null || dayIndex == null) return null;
        return 'notif_handled_${request.kind.name}_${seasonId}_$dayIndex';
      case FastingNotificationKind.sunnahSahur:
      case FastingNotificationKind.sunnahIftar:
        final date = request.sunnahDate;
        if (date == null) return null;
        final y = date.year;
        final m = date.month.toString().padLeft(2, '0');
        final d = date.day.toString().padLeft(2, '0');
        return 'notif_handled_${request.kind.name}_$y$m$d';
    }
  }

  static Future<bool> _alreadyHandled(
    AppDatabase db,
    NotificationLaunchRequest request,
  ) async {
    if (_handledThisSession.contains(request)) return true;
    final key = handledKvKey(request);
    if (key == null) return false;
    return await db.kvSettingsDao.getValue(key) == 'true';
  }

  static Future<void> _markHandled(
    AppDatabase db,
    NotificationLaunchRequest request,
  ) async {
    _handledThisSession.add(request);
    final key = handledKvKey(request);
    if (key != null) {
      await db.kvSettingsDao.setValue(key, 'true');
    }
  }

  static Future<void> handle(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
  ) async {
    if (kDebugMode) {
      debugPrint('[NOTIF-LAUNCH] handle ${request.kind}');
    }

    final db = ref.read(databaseProvider);
    if (await _alreadyHandled(db, request)) {
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] skip already-handled ${request.kind}');
      }
      return;
    }

    switch (request.kind) {
      case FastingNotificationKind.ramadanSahur:
        await _handleRamadanSahur(context, ref, request, db);
      case FastingNotificationKind.ramadanIftar:
        await _handleRamadanIftar(context, ref, request, db);
      case FastingNotificationKind.sunnahSahur:
        await _handleSunnahSahur(context, ref, request, db);
      case FastingNotificationKind.sunnahIftar:
        await _handleSunnahIftar(context, ref, request, db);
    }
  }

  static Future<void> _handleRamadanSahur(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
    AppDatabase db,
  ) async {
    final seasonId = request.seasonId;
    final dayIndex = request.dayIndex;
    if (seasonId == null || dayIndex == null) {
      if (kDebugMode) {
        debugPrint('[NOTIF-LAUNCH] ramadan sahur missing season/day');
      }
      return;
    }

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

    final pendingIntent = await FastingIntentService.hasPendingRamadanIntent(
      db,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );
    if (pendingIntent) {
      await _markHandled(db, request);
      if (!context.mounted) return;
      _showSnack(context, AppLocalizations.of(context)!.fastingIntentAlreadySet);
      return;
    }

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
      await _markHandled(db, request);
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
      await _markHandled(db, request);
      _showSnack(context, AppLocalizations.of(context)!.fastingIntentPendingSaved);
      return;
    }

    if (result.status == FastingStatus.notDone) {
      await FastingIntentService.clearRamadanIntent(
        db,
        seasonId: seasonId,
        dayIndex: dayIndex,
      );
      await _markHandled(db, request);
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
    await _markHandled(db, request);
    final message = ramadanFastingSavedMessage(SunnahStrings.of(context), result.status);
    if (message != null) _showSnack(context, message);
  }

  static Future<void> _handleRamadanIftar(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
    AppDatabase db,
  ) async {
    final seasonId = request.seasonId;
    final dayIndex = request.dayIndex;
    if (seasonId == null || dayIndex == null) return;

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
      await _markHandled(db, request);
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
      await _markHandled(db, request);
      return;
    }

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

    await _markHandled(db, request);
    if (confirmed) {
      await _onEngagementUpdate(ref, seasonId, dayIndex);
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
  }

  static Future<void> _handleSunnahSahur(
    BuildContext context,
    WidgetRef ref,
    NotificationLaunchRequest request,
    AppDatabase db,
  ) async {
    final date = request.sunnahDate;
    if (date == null) return;

    final existing = await db.sunnahFastsDao.getByDate(date);
    if (!context.mounted) return;

    final pendingIntent = await FastingIntentService.hasPendingSunnahIntent(
      db,
      date: date,
    );
    if (pendingIntent) {
      await _markHandled(db, request);
      _showSnack(context, AppLocalizations.of(context)!.fastingIntentAlreadySet);
      return;
    }

    final result = await showSahurIntentionSheet(context, date: date);
    if (result == null || !context.mounted) return;

    if (result.status == FastingStatus.intentPendingFast) {
      await FastingIntentService.setSunnahIntent(
        db,
        date: date,
        status: FastingStatus.intentPendingFast,
      );
      await _markHandled(db, request);
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
    await _markHandled(db, request);

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
    AppDatabase db,
  ) async {
    final date = request.sunnahDate;
    if (date == null) return;
    await showSunnahIftarConfirmFlow(context, ref, date);
    await _markHandled(db, request);
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
      NotificationLaunchService.checkResumedLaunch(ref);
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
