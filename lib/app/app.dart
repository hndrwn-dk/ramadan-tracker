import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/features/today/today_screen.dart';
import 'package:ramadan_tracker/features/month/month_screen.dart';
import 'package:ramadan_tracker/features/plan/plan_screen.dart';
import 'package:ramadan_tracker/features/insights/insights_screen.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_wrapper.dart';
import 'package:ramadan_tracker/widgets/theme.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';

class RamadanCompanionApp extends ConsumerWidget {
  const RamadanCompanionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Ramadan Tracker',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const OnboardingWrapper(child: MainScreen()),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final List<Widget> _screens = const [
    TodayScreen(),
    MonthScreen(),
    PlanScreen(),
    InsightsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(tabIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          ref.read(tabIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Month',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Insights',
          ),
        ],
      ),
    );
  }
}

