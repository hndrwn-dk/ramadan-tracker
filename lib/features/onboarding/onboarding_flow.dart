import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/app.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step1_welcome.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step2_season.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step3_habits.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step4_goals.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step5_reminders.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  int _currentStep = 0;
  int? _lastStep;

  OnboardingData _data = OnboardingData();

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return OnboardingStep1Welcome(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
        );
      case 1:
        return OnboardingStep2Season(
          key: const ValueKey(1),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 2:
        return OnboardingStep3Habits(
          key: const ValueKey(2),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 3:
        return OnboardingStep4Goals(
          key: const ValueKey(3),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 4:
        return OnboardingStep5Reminders(
          key: const ValueKey(4),
          data: _data,
          onPrevious: _previousStep,
          onFinish: () async {
            // Save data first (fast operations)
            await _data.saveWithoutScheduling(ref);
            ref.invalidate(shouldShowOnboardingProvider);
            
            // Navigate immediately (don't wait for scheduling)
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const MainScreen(),
                ),
                (route) => false,
              );
            }
            
            // Schedule notifications in background (non-blocking)
            // This prevents UI freeze from Android rate limiting
            _data.scheduleNotificationsInBackground(ref);
          },
        );
      default:
        return OnboardingStep1Welcome(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
        );
    }
  }

  void _nextStep() {
    if (_currentStep < 4) {
      final nextStep = _currentStep + 1;
      // Update state - AnimatedSwitcher will handle the transition smoothly
      setState(() {
        _lastStep = _currentStep;
        _currentStep = nextStep;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      final prevStep = _currentStep - 1;
      // Update state - AnimatedSwitcher will handle the transition smoothly
      setState(() {
        _lastStep = _currentStep;
        _currentStep = prevStep;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (_currentStep > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: _previousStep,
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: _currentStep / 4,
                        backgroundColor: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (currentChild, previousChildren) {
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.hardEdge,
                      children: [
                        ...previousChildren,
                        if (currentChild != null) currentChild,
                      ],
                    );
                  },
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final int? childStep = (child.key is ValueKey<int>)
                        ? (child.key as ValueKey<int>).value
                        : null;

                    final bool isForward = _lastStep == null || _currentStep > _lastStep!;
                    final bool isIncoming = childStep == _currentStep;

                    // Very subtle slide - just enough to feel smooth, not dramatic
                    final Animation<double> slideAnim =
                        isIncoming ? animation : ReverseAnimation(animation);

                    // Reduced offset for more subtle movement
                    final Offset inBegin = Offset(isForward ? 0.15 : -0.15, 0.0);
                    final Offset outEnd = Offset(isForward ? -0.15 : 0.15, 0.0);

                    final Tween<Offset> tween = isIncoming
                        ? Tween<Offset>(begin: inBegin, end: Offset.zero)
                        : Tween<Offset>(begin: Offset.zero, end: outEnd);

                    // Fast fade + minimal slide for instant feel
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: tween.animate(CurvedAnimation(
                          parent: slideAnim,
                          curve: Curves.easeOut,
                        )),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  String seasonLabel = '';
  DateTime? startDate;
  int days = 30;
  int hijriAdjustment = 0;
  
  Set<String> selectedHabits = {'fasting', 'quran_pages', 'dhikr', 'taraweeh', 'sedekah'};
  
  String quranGoal = '1_khatam';
  int customQuranPages = 20;
  int dhikrTarget = 100;
  bool sedekahGoalEnabled = false;
  int sedekahAmount = 0;
  String sedekahCurrency = 'IDR';
  String autopilotIntensity = 'balanced';
  
  bool sahurEnabled = true;
  int sahurOffsetMinutes = 30;
  bool iftarEnabled = true;
  int iftarOffsetMinutes = 0;
  bool nightPlanEnabled = true;
  bool quranReminderEnabled = false;
  bool dhikrReminderEnabled = false;
  
  double? latitude;
  double? longitude;
  String timezone = 'UTC';
  String calculationMethod = 'mwl';
  String highLatRule = 'middle_of_night';
  int fajrAdjust = 0;
  int maghribAdjust = 0;

  // Save data without scheduling (fast, non-blocking)
  Future<void> saveWithoutScheduling(WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final now = DateTime.now();
    
    final seasonId = await database.ramadanSeasonsDao.createSeason(
      label: seasonLabel.isEmpty ? 'Ramadan ${now.year}' : seasonLabel,
      startDate: startDate ?? now,
      days: days,
    );

    await database.kvSettingsDao.setValue('onboarding_done_season_$seasonId', 'true');
    
    if (latitude != null && longitude != null) {
      await database.kvSettingsDao.setValue('prayer_latitude', latitude!.toString());
      await database.kvSettingsDao.setValue('prayer_longitude', longitude!.toString());
      await database.kvSettingsDao.setValue('prayer_timezone', timezone);
      await database.kvSettingsDao.setValue('prayer_method', calculationMethod);
      await database.kvSettingsDao.setValue('prayer_high_lat_rule', highLatRule);
      await database.kvSettingsDao.setValue('prayer_fajr_adj', fajrAdjust.toString());
      await database.kvSettingsDao.setValue('prayer_maghrib_adj', maghribAdjust.toString());
    }

    await database.kvSettingsDao.setValue('sahur_enabled', sahurEnabled.toString());
    await database.kvSettingsDao.setValue('sahur_offset', sahurOffsetMinutes.toString());
    await database.kvSettingsDao.setValue('iftar_enabled', iftarEnabled.toString());
    await database.kvSettingsDao.setValue('iftar_offset', iftarOffsetMinutes.toString());
    await database.kvSettingsDao.setValue('night_plan_enabled', nightPlanEnabled.toString());
    
    // Set prayers to detailed mode by default (track all prayers individually)
    await database.kvSettingsDao.setValue('prayers_detailed_mode', 'true');
    
    if (selectedHabits.contains('sedekah')) {
      await database.kvSettingsDao.setValue('sedekah_currency', sedekahCurrency);
      await database.kvSettingsDao.setValue('sedekah_goal_enabled', sedekahGoalEnabled.toString());
      if (sedekahGoalEnabled && sedekahAmount > 0) {
        await database.kvSettingsDao.setValue('sedekah_goal_amount', sedekahAmount.toString());
      } else {
        await database.kvSettingsDao.deleteValue('sedekah_goal_amount');
      }
    }

    final habits = await database.habitsDao.getAllHabits();
    for (final habit in habits) {
      final isEnabled = selectedHabits.contains(habit.key);
      await database.seasonHabitsDao.setSeasonHabit(
        SeasonHabit(
          seasonId: seasonId,
          habitId: habit.id,
          isEnabled: isEnabled,
          targetValue: habit.defaultTarget,
          reminderEnabled: false,
          reminderTime: null,
        ),
      );
    }

    int pagesPerJuz = 20;
    int juzTargetPerDay = 1;
    int dailyTargetPages = 20;
    int totalJuz = 30;
    int totalPages = 600;

    if (quranGoal == '2_khatam') {
      dailyTargetPages = 40;
      totalPages = 1200;
    } else if (quranGoal == 'custom') {
      dailyTargetPages = customQuranPages;
      totalPages = dailyTargetPages * days;
      totalJuz = (totalPages / pagesPerJuz).ceil();
    }

    await database.quranPlanDao.setPlan(
      QuranPlanData(
        seasonId: seasonId,
        pagesPerJuz: pagesPerJuz,
        juzTargetPerDay: juzTargetPerDay,
        dailyTargetPages: dailyTargetPages,
        totalJuz: totalJuz,
        totalPages: totalPages,
        catchupCapPages: 5,
        createdAt: now.millisecondsSinceEpoch,
      ),
    );

    await database.dhikrPlanDao.setPlan(
      DhikrPlanData(
        seasonId: seasonId,
        dailyTarget: dhikrTarget,
        createdAt: now.millisecondsSinceEpoch,
      ),
    );
    
    // Note: Notification scheduling is done separately in background to prevent UI blocking
  }

  // Schedule notifications in background (non-blocking)
  void scheduleNotificationsInBackground(WidgetRef ref) {
    // Run in background isolate to prevent UI blocking
    Future.microtask(() async {
      try {
        final database = ref.read(databaseProvider);
        debugPrint('=== ONBOARDING: Scheduling notifications in background ===');
        
        // Use rescheduleAllReminders which properly cancels existing notifications first
        await NotificationService.rescheduleAllReminders(database: database);
        
        debugPrint('=== ONBOARDING: Background scheduling completed ===');
      } catch (e, stackTrace) {
        debugPrint('=== ONBOARDING: Background scheduling failed ===');
        debugPrint('  Error: $e');
        debugPrint('  Stack trace: $stackTrace');
        // Don't show error to user - notifications can be scheduled later from settings
      }
    });
  }

  Future<void> save(WidgetRef ref) async {
    final database = ref.read(databaseProvider);
    final now = DateTime.now();
    
    final seasonId = await database.ramadanSeasonsDao.createSeason(
      label: seasonLabel.isEmpty ? 'Ramadan ${now.year}' : seasonLabel,
      startDate: startDate ?? now,
      days: days,
    );

    await database.kvSettingsDao.setValue('onboarding_done_season_$seasonId', 'true');
    
    if (latitude != null && longitude != null) {
      await database.kvSettingsDao.setValue('prayer_latitude', latitude!.toString());
      await database.kvSettingsDao.setValue('prayer_longitude', longitude!.toString());
      await database.kvSettingsDao.setValue('prayer_timezone', timezone);
      await database.kvSettingsDao.setValue('prayer_method', calculationMethod);
      await database.kvSettingsDao.setValue('prayer_high_lat_rule', highLatRule);
      await database.kvSettingsDao.setValue('prayer_fajr_adj', fajrAdjust.toString());
      await database.kvSettingsDao.setValue('prayer_maghrib_adj', maghribAdjust.toString());
    }

    await database.kvSettingsDao.setValue('sahur_enabled', sahurEnabled.toString());
    await database.kvSettingsDao.setValue('sahur_offset', sahurOffsetMinutes.toString());
    await database.kvSettingsDao.setValue('iftar_enabled', iftarEnabled.toString());
    await database.kvSettingsDao.setValue('iftar_offset', iftarOffsetMinutes.toString());
    await database.kvSettingsDao.setValue('night_plan_enabled', nightPlanEnabled.toString());
    
    // Set prayers to detailed mode by default (track all prayers individually)
    await database.kvSettingsDao.setValue('prayers_detailed_mode', 'true');
    
    if (selectedHabits.contains('sedekah')) {
      await database.kvSettingsDao.setValue('sedekah_currency', sedekahCurrency);
      await database.kvSettingsDao.setValue('sedekah_goal_enabled', sedekahGoalEnabled.toString());
      if (sedekahGoalEnabled && sedekahAmount > 0) {
        await database.kvSettingsDao.setValue('sedekah_goal_amount', sedekahAmount.toString());
      } else {
        await database.kvSettingsDao.deleteValue('sedekah_goal_amount');
      }
    }

    final habits = await database.habitsDao.getAllHabits();
    for (final habit in habits) {
      final isEnabled = selectedHabits.contains(habit.key);
      await database.seasonHabitsDao.setSeasonHabit(
        SeasonHabit(
          seasonId: seasonId,
          habitId: habit.id,
          isEnabled: isEnabled,
          targetValue: habit.defaultTarget,
          reminderEnabled: false,
          reminderTime: null,
        ),
      );
    }

    int pagesPerJuz = 20;
    int juzTargetPerDay = 1;
    int dailyTargetPages = 20;
    int totalJuz = 30;
    int totalPages = 600;

    if (quranGoal == '2_khatam') {
      dailyTargetPages = 40;
      totalPages = 1200;
    } else if (quranGoal == 'custom') {
      dailyTargetPages = customQuranPages;
      totalPages = dailyTargetPages * days;
      totalJuz = (totalPages / pagesPerJuz).ceil();
    }

    await database.quranPlanDao.setPlan(
      QuranPlanData(
        seasonId: seasonId,
        pagesPerJuz: pagesPerJuz,
        juzTargetPerDay: juzTargetPerDay,
        dailyTargetPages: dailyTargetPages,
        totalJuz: totalJuz,
        totalPages: totalPages,
        catchupCapPages: 5,
        createdAt: now.millisecondsSinceEpoch,
      ),
    );

    await database.dhikrPlanDao.setPlan(
      DhikrPlanData(
        seasonId: seasonId,
        dailyTarget: dhikrTarget,
        createdAt: now.millisecondsSinceEpoch,
      ),
    );

    if (latitude != null && longitude != null) {
      try {
        debugPrint('=== ONBOARDING: Scheduling all reminders ===');
        debugPrint('  Season ID: $seasonId');
        debugPrint('  Location: $latitude, $longitude');
        debugPrint('  Timezone: $timezone');
        debugPrint('  Sahur enabled: $sahurEnabled, offset: $sahurOffsetMinutes');
        debugPrint('  Iftar enabled: $iftarEnabled, offset: $iftarOffsetMinutes');
        debugPrint('  Night plan enabled: $nightPlanEnabled');
        
        await NotificationService.scheduleAllReminders(
          database: database,
          seasonId: seasonId,
          latitude: latitude!,
          longitude: longitude!,
          timezone: timezone,
          method: calculationMethod,
          highLatRule: highLatRule,
          sahurEnabled: sahurEnabled,
          sahurOffsetMinutes: sahurOffsetMinutes,
          iftarEnabled: iftarEnabled,
          iftarOffsetMinutes: iftarOffsetMinutes,
          nightPlanEnabled: nightPlanEnabled,
          fajrAdjust: fajrAdjust,
          maghribAdjust: maghribAdjust,
        );
        
        // Verify notifications were scheduled
        final pending = await NotificationService.getPendingNotifications();
        debugPrint('=== ONBOARDING: Reminders scheduled successfully ===');
        debugPrint('  Total pending notifications: ${pending.length}');
        if (pending.isNotEmpty) {
          debugPrint('  First few notifications:');
          for (var i = 0; i < pending.length && i < 5; i++) {
            final notif = pending[i];
            debugPrint('    - ${notif.title}: ${notif.body} (ID: ${notif.id})');
          }
        }
      } catch (e, stackTrace) {
        // Log error but don't block onboarding completion
        // Notifications can be set up later from settings
        debugPrint('=== ONBOARDING: Failed to schedule reminders ===');
        debugPrint('  Error: $e');
        debugPrint('  Stack trace: $stackTrace');
      }
    } else {
      debugPrint('=== ONBOARDING: Skipping reminder scheduling (no location) ===');
    }
  }
}


