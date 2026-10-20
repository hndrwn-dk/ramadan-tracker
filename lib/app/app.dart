import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/features/today/today_screen.dart';
import 'package:ramadan_tracker/features/today/widgets/today_checklist_sticky_bar.dart';
import 'package:ramadan_tracker/widgets/floating_pill_nav_bar.dart';
import 'package:ramadan_tracker/features/month/month_screen.dart';
import 'package:ramadan_tracker/features/plan/plan_screen.dart';
import 'package:ramadan_tracker/features/insights/insights_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_screen.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_wrapper.dart';
import 'package:ramadan_tracker/features/today/widgets/fasting_notification_handler.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/features/engagement/achievements_screen.dart';
import 'package:ramadan_tracker/app/root_navigator.dart';
import 'package:ramadan_tracker/app/achievements_navigation.dart';
import 'package:ramadan_tracker/widgets/theme.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/theme_provider.dart';
import 'package:ramadan_tracker/data/providers/locale_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/domain/services/home_widget_service.dart';
import 'package:ramadan_tracker/domain/services/widget_launch_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:ramadan_tracker/app/platform_adaptive.dart';
import 'package:ramadan_tracker/data/providers/support_provider.dart';

class RamadanCompanionApp extends ConsumerStatefulWidget {
  const RamadanCompanionApp({super.key});

  @override
  ConsumerState<RamadanCompanionApp> createState() =>
      _RamadanCompanionAppState();
}

class _RamadanCompanionAppState extends ConsumerState<RamadanCompanionApp> {
  @override
  void initState() {
    super.initState();
    ref.read(supportPurchaseProvider).start();
  }

  @override
  Widget build(BuildContext context) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final localeAsync = ref.watch(localeProvider);

    // Use the theme mode from async value, default to system to avoid flicker
    final themeMode = themeModeAsync.when(
      data: (mode) => mode,
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );

    // Use the locale from async value, default to English
    final locale = localeAsync.when(
      data: (loc) => loc,
      loading: () => const Locale('en', ''),
      error: (_, __) => const Locale('en', ''),
    );

    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      title: 'Ramadan Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const OnboardingWrapper(
        child: CelebrationListener(
          child: NotificationLaunchListener(
            child: MainScreen(),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    TodayScreen(),
    MonthScreen(),
    PlanScreen(),
    SunnahScreen(),
    InsightsScreen(),
  ];

  DateTime? _lastRescheduleTime;
  static const _minRescheduleInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureTodayFastingReminders();
      _rescheduleNotifications();
      WidgetLaunchService.initialize(ref);
    });
  }

  @override
  void dispose() {
    WidgetLaunchService.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(supportMomentProvider);
      _ensureTodayFastingReminders();
      // Reschedule notifications when app resumes, but only if enough time has passed
      _rescheduleNotifications();
    }
  }

  Future<void> _ensureTodayFastingReminders() async {
    try {
      final database = ref.read(databaseProvider);
      final count =
          await NotificationService.ensureTodayFastingRemindersScheduled(
        database,
      );
      if (count > 0 && kDebugMode) {
        debugPrint(
          '=== ensureTodayFastingReminders: queued $count reminder(s) ===',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ensureTodayFastingReminders failed: $e');
      }
    }
  }

  Future<void> _rescheduleNotifications() async {
    const regressionSeed = bool.fromEnvironment('REGRESSION_SEED');
    if (regressionSeed) {
      if (kDebugMode) {
        debugPrint(
            '=== _rescheduleNotifications skipped (REGRESSION_SEED) ===');
      }
      return;
    }

    // Throttle rescheduling to prevent too frequent calls
    final now = DateTime.now();
    if (_lastRescheduleTime != null) {
      final timeSinceLastReschedule = now.difference(_lastRescheduleTime!);
      if (timeSinceLastReschedule < _minRescheduleInterval) {
        if (kDebugMode) {
          debugPrint(
            '=== _rescheduleNotifications skipped (too soon: '
            '${timeSinceLastReschedule.inSeconds}s) ===',
          );
        }
        return;
      }
    }

    // Check if scheduling is already in progress (prevent concurrent calls)
    // This is a safety check - NotificationService also has its own lock
    _lastRescheduleTime = now;
    if (kDebugMode) {
      debugPrint('=== _rescheduleNotifications called ===');
    }

    try {
      final database = ref.read(databaseProvider);

      if (kDebugMode) {
        final hasPermission =
            await NotificationService.checkNotificationPermission();
        debugPrint(
          'Notification permission status before reschedule: $hasPermission',
        );
        try {
          final beforePending =
              await NotificationService.getPendingNotifications();
          debugPrint(
            'Pending notifications BEFORE reschedule: ${beforePending.length}',
          );
        } catch (e) {
          debugPrint('Could not get pending count before reschedule: $e');
        }
      }

      await NotificationService.rescheduleAllNotificationTypes(
          database: database);
      await NotificationService.ensureTodayFastingRemindersScheduled(database);
      await HomeWidgetService.update(database);
      if (kDebugMode) {
        debugPrint('=== _rescheduleNotifications completed ===');
      }

      if (kDebugMode) {
        try {
          await Future.delayed(const Duration(milliseconds: 1000));
          final pending = await NotificationService.getPendingNotifications();
          debugPrint(
            'Total pending notifications AFTER reschedule: ${pending.length}',
          );
          if (pending.length > 500) {
            debugPrint(
              'WARNING: Pending notification count is very high '
              '(${pending.length}). This may indicate duplicates.',
            );
          }
        } catch (e) {
          debugPrint('Error getting pending notifications count: $e');
          debugPrint(
            'Notifications may still be scheduled despite this error',
          );
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('Error rescheduling notifications on startup: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);
    final showAchievements = ref.watch(achievementsVisibleProvider);
    final l10n = AppLocalizations.of(context)!;
    final safeIndex = currentIndex.clamp(0, _screens.length - 1);
    if (safeIndex != currentIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(tabIndexProvider.notifier).state = safeIndex;
      });
    }

    final checklistTarget = ref.watch(todayChecklistTargetProvider);
    final showChecklist =
        safeIndex == 0 && !showAchievements && checklistTarget != null;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: showAchievements
            ? const AchievementsScreen()
            : IndexedStack(
                index: safeIndex,
                children: _screens,
              ),
      ),
      bottomNavigationBar: Material(
        type: MaterialType.transparency,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingChecklistSlot(
              visible: showChecklist,
              child: checklistTarget == null
                  ? const SizedBox.shrink()
                  : TodayChecklistStickyBar(
                      seasonId: checklistTarget.seasonId,
                      dayIndex: checklistTarget.dayIndex,
                    ),
            ),
            FloatingPillNavBar(
              selectedIndex: safeIndex,
              onSelected: (index) {
                if (showAchievements) {
                  closeAchievementsScreen(ref);
                }
                if (safeIndex == 0 && index != 0) {
                  ref.read(selectedDayIndexProvider.notifier).state = null;
                }
                if (index != safeIndex) {
                  PlatformAdaptive.lightHaptic();
                }
                ref.read(tabIndexProvider.notifier).state = index;
              },
              items: [
                FloatingPillNavItem(
                  icon: Icons.today_outlined,
                  selectedIcon: Icons.today,
                  label: l10n.today,
                ),
                FloatingPillNavItem(
                  icon: Icons.calendar_month_outlined,
                  selectedIcon: Icons.calendar_month,
                  label: l10n.month,
                ),
                FloatingPillNavItem(
                  icon: Icons.auto_awesome_outlined,
                  selectedIcon: Icons.auto_awesome,
                  label: l10n.plan,
                ),
                FloatingPillNavItem(
                  icon: Icons.nightlight_outlined,
                  selectedIcon: Icons.nightlight,
                  label: l10n.sunnah,
                ),
                FloatingPillNavItem(
                  icon: Icons.insights_outlined,
                  selectedIcon: Icons.insights,
                  label: l10n.insights,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingChecklistSlot extends StatefulWidget {
  final bool visible;
  final Widget child;

  const _FloatingChecklistSlot({
    required this.visible,
    required this.child,
  });

  @override
  State<_FloatingChecklistSlot> createState() => _FloatingChecklistSlotState();
}

class _FloatingChecklistSlotState extends State<_FloatingChecklistSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: widget.visible ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant _FloatingChecklistSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Align(
          alignment: Alignment.bottomCenter,
          heightFactor: t,
          child: Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * 18),
              child: child,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: FloatingPillNavBar.accessoryGap),
        child: widget.child,
      ),
    );
  }
}
