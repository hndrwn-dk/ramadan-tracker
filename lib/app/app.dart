import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:ramadan_tracker/features/today/today_screen.dart';
import 'package:ramadan_tracker/features/month/month_screen.dart';
import 'package:ramadan_tracker/features/plan/plan_screen.dart';
import 'package:ramadan_tracker/features/insights/insights_screen.dart';
import 'package:ramadan_tracker/features/settings/settings_screen.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_wrapper.dart';
import 'package:ramadan_tracker/widgets/theme.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/theme_provider.dart';
import 'package:ramadan_tracker/data/providers/locale_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';

class RamadanCompanionApp extends ConsumerWidget {
  const RamadanCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeModeAsync = ref.watch(themeModeProvider);
    final localeAsync = ref.watch(localeProvider);
    
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Create fallback schemes with neutral colors to avoid green flash during hot restart
        final lightScheme = lightDynamic ?? ColorScheme.light(
          primary: const Color(0xFF6750A4), // Neutral purple
          surface: Colors.white,
          background: Colors.white,
        );
        final darkScheme = darkDynamic ?? ColorScheme.dark(
          primary: const Color(0xFF6750A4), // Neutral purple
          surface: const Color(0xFF121212),
          background: const Color(0xFF121212),
        );
        
        // Use the theme mode from async value, default to system to avoid flicker
        final themeMode = themeModeAsync.when(
          data: (mode) => mode,
          loading: () => ThemeMode.system, // Default to system while loading to avoid flicker
          error: (_, __) => ThemeMode.system, // Default to system on error
        );
        
        // Use the locale from async value, default to English
        final locale = localeAsync.when(
          data: (loc) => loc,
          loading: () => const Locale('en', ''), // Default to English while loading
          error: (_, __) => const Locale('en', ''), // Default to English on error
        );
        
        return MaterialApp(
          title: 'Ramadan Tracker',
          theme: AppTheme.lightThemeWithDynamic(lightScheme),
          darkTheme: AppTheme.darkThemeWithDynamic(darkScheme),
          themeMode: themeMode,
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const OnboardingWrapper(child: MainScreen()),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    TodayScreen(),
    MonthScreen(),
    PlanScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  DateTime? _lastRescheduleTime;
  static const _minRescheduleInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reschedule notifications on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rescheduleNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reschedule notifications when app resumes, but only if enough time has passed
      _rescheduleNotifications();
    }
  }

  Future<void> _rescheduleNotifications() async {
    // Throttle rescheduling to prevent too frequent calls
    final now = DateTime.now();
    if (_lastRescheduleTime != null) {
      final timeSinceLastReschedule = now.difference(_lastRescheduleTime!);
      if (timeSinceLastReschedule < _minRescheduleInterval) {
        debugPrint('=== _rescheduleNotifications skipped (too soon: ${timeSinceLastReschedule.inSeconds}s) ===');
        return;
      }
    }
    
    _lastRescheduleTime = now;
    debugPrint('=== _rescheduleNotifications called ===');
    try {
      final database = ref.read(databaseProvider);
      await NotificationService.rescheduleAllReminders(database: database);
      debugPrint('=== _rescheduleNotifications completed ===');
    } catch (e, stackTrace) {
      debugPrint('Error rescheduling notifications on startup: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // Reset selected day index when navigating away from Today screen (index 0)
          if (currentIndex == 0 && index != 0) {
            ref.read(selectedDayIndexProvider.notifier).state = null;
          }
          ref.read(tabIndexProvider.notifier).state = index;
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.today,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: l10n.month,
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome),
            label: l10n.plan,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            selectedIcon: const Icon(Icons.insights),
            label: l10n.insights,
          ),
          NavigationDestination(
            icon: const Icon(Icons.tune_outlined),
            selectedIcon: const Icon(Icons.tune),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}

