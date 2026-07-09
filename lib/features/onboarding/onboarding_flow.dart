import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/app.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step0_language.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step1_welcome.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step2_season.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step_location.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step3_habits.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step5_goals_quran_dhikr.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step6_goals_sedekah.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step7_reminders.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step8_summary.dart';
import 'package:ramadan_tracker/features/onboarding/widgets/onboarding_shared_widgets.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/device_timezone.dart';

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({super.key});

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  static const int _totalSteps = 9;

  final PageController _pageController = PageController();
  int _currentStep = 0;

  OnboardingData _data = OnboardingData();

  bool get _languageChosen => _data.selectedLanguageCode != null;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildStepAt(int index) {
    switch (index) {
      case 0:
        return OnboardingStep0Language(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
        );
      case 1:
        return OnboardingStep1Welcome(
          key: const ValueKey(1),
          data: _data,
          onNext: _nextStep,
        );
      case 2:
        return OnboardingStep2Season(
          key: const ValueKey(2),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 3:
        return OnboardingStepLocation(
          key: const ValueKey(3),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 4:
        return OnboardingStep3Habits(
          key: const ValueKey(4),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 5:
        return OnboardingStep5GoalsQuranDhikr(
          key: const ValueKey(5),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 6:
        return OnboardingStep6GoalsSedekah(
          key: const ValueKey(6),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 7:
        return OnboardingStep7Reminders(
          key: const ValueKey(7),
          data: _data,
          onNext: _nextStep,
          onPrevious: _previousStep,
        );
      case 8:
        return OnboardingStep8Summary(
          key: const ValueKey(8),
          data: _data,
          onPrevious: _previousStep,
          onFinish: () async {
            debugPrint('=== Onboarding Finish Started ===');
            try {
              debugPrint('Saving onboarding data...');
              await _data.saveWithoutScheduling(ref);
              debugPrint('Onboarding data saved successfully');

              ref.invalidate(shouldShowOnboardingProvider);
              ref.invalidate(allSeasonsProvider);
              ref.invalidate(currentSeasonProvider);

              await Future.delayed(const Duration(milliseconds: 100));

              if (mounted) {
                ref.read(tabIndexProvider.notifier).state = 0;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const MainScreen()),
                  (route) => false,
                );
              }

              _data.scheduleNotificationsInBackground(ref);
            } catch (e, stackTrace) {
              debugPrint('=== ERROR in Onboarding Finish ===');
              debugPrint('Error: $e');
              debugPrint('Stack: $stackTrace');
            }
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _goToStep(int step) {
    if (step < 0 || step >= _totalSteps) return;
    if (step > 0 && !_languageChosen) return;
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _goToStep(_currentStep + 1);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    }
  }

  void _onPageChanged(int index) {
    if (index > 0 && !_languageChosen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
      return;
    }
    setState(() => _currentStep = index);
  }

  Future<void> _skipSetup() async {
    try {
      final database = ref.read(databaseProvider);
      await database.kvSettingsDao.setValue('onboarding_skipped', 'true');
      ref.invalidate(shouldShowOnboardingProvider);
      if (!mounted) return;
      ref.read(tabIndexProvider.notifier).state = 0;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Skip setup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final showSkip = _currentStep >= 1 && _currentStep < _totalSteps - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            OnboardingFlowHeader(
              currentStep: _currentStep,
              totalSteps: _totalSteps,
              onBack: _currentStep > 0 ? _previousStep : null,
              onSkip: showSkip ? _skipSetup : null,
              skipLabel: showSkip ? l10n.onboardingSkipForNow : null,
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: _onPageChanged,
                itemCount: _totalSteps,
                itemBuilder: (context, index) => _buildStepAt(index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  String? selectedLanguageCode;

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

  bool sahurEnabled = true;
  int sahurOffsetMinutes = 30;
  bool iftarEnabled = true;
  int iftarOffsetMinutes = 0;
  bool iftarConfirmEnabled = true;
  bool nightPlanEnabled = true;
  int nightPlanHour = 2;
  int nightPlanMinute = 30;
  bool quranReminderEnabled = true;
  bool dhikrReminderEnabled = true;
  bool sedekahReminderEnabled = true;
  bool taraweehReminderEnabled = true;
  int taraweehRakaatPerDay = 11;

  double? latitude;
  double? longitude;
  String timezone = 'UTC';
  String calculationMethod = 'mwl';
  String highLatRule = 'middle_of_night';
  int fajrAdjust = 0;
  int maghribAdjust = 0;

  Future<void> ensureLocalTimezone() async {
    if (timezone == 'UTC' || timezone.isEmpty) {
      timezone = await resolveDeviceTimezone();
    }
  }

  // Save data without scheduling (fast, non-blocking)
  Future<void> saveWithoutScheduling(WidgetRef ref) async {
    await ensureLocalTimezone();
    debugPrint('=== saveWithoutScheduling Started ===');
    final database = ref.read(databaseProvider);
    final now = DateTime.now();

    debugPrint('Creating season: label=$seasonLabel, startDate=$startDate, days=$days');
    final seasonId = await database.ramadanSeasonsDao.createSeason(
      label: seasonLabel.isEmpty ? 'Ramadan ${now.year}' : seasonLabel,
      startDate: startDate ?? now,
      days: days,
    );
    debugPrint('Season created with ID: $seasonId');

    final flagKey = 'onboarding_done_season_$seasonId';
    debugPrint('Setting onboarding flag: $flagKey');
    await database.kvSettingsDao.setValue(flagKey, 'true');
    debugPrint('Onboarding flag set to true');

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
    await database.kvSettingsDao.setValue('sahur_offset', sahurOffsetMinutes.clamp(1, 45).toString());
    await database.kvSettingsDao.setValue('iftar_enabled', iftarEnabled.toString());
    await database.kvSettingsDao.setValue('iftar_offset', iftarOffsetMinutes.toString());
    await database.kvSettingsDao.setValue('iftar_confirm_enabled', iftarEnabled.toString());
    await database.kvSettingsDao.setValue('night_plan_enabled', 'false');
    await database.kvSettingsDao.setValue('night_plan_hour', nightPlanHour.clamp(2, 4).toString());
    await database.kvSettingsDao.setValue('night_plan_minute', nightPlanMinute.clamp(0, 59).toString());

    await database.kvSettingsDao.setValue('goal_reminder_quran_enabled', quranReminderEnabled.toString());
    await database.kvSettingsDao.setValue('goal_reminder_dhikr_enabled', dhikrReminderEnabled.toString());
    await database.kvSettingsDao.setValue('goal_reminder_sedekah_enabled', sedekahReminderEnabled.toString());
    final digestEnabled =
        quranReminderEnabled || dhikrReminderEnabled || sedekahReminderEnabled;
    await database.kvSettingsDao.setValue(
      'goal_reminder_digest_enabled',
      digestEnabled.toString(),
    );
    await database.kvSettingsDao.setValue('goal_reminder_taraweeh_enabled', 'false');
    await database.kvSettingsDao.setValue('taraweeh_rakaat_per_day', taraweehRakaatPerDay.toString());

    await database.kvSettingsDao.setValue('prayers_detailed_mode', 'true');

    await database.kvSettingsDao.setValue('sedekah_currency', sedekahCurrency);
    await database.kvSettingsDao.setValue('sedekah_goal_enabled', sedekahGoalEnabled.toString());
    if (sedekahGoalEnabled && sedekahAmount > 0) {
      await database.kvSettingsDao.setValue('sedekah_goal_amount', sedekahAmount.toString());
    } else {
      await database.kvSettingsDao.deleteValue('sedekah_goal_amount');
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

    debugPrint('=== saveWithoutScheduling Completed ===');
  }

  void scheduleNotificationsInBackground(WidgetRef ref) {
    Future.microtask(() async {
      try {
        final database = ref.read(databaseProvider);
        await NotificationService.rescheduleAllNotificationTypes(database: database);
      } catch (e, stackTrace) {
        debugPrint('Background scheduling failed: $e');
        debugPrint('$stackTrace');
      }
    });
  }

  Future<void> save(WidgetRef ref) async {
    await ensureLocalTimezone();
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
    await database.kvSettingsDao.setValue('sahur_offset', sahurOffsetMinutes.clamp(1, 45).toString());
    await database.kvSettingsDao.setValue('iftar_enabled', iftarEnabled.toString());
    await database.kvSettingsDao.setValue('iftar_offset', iftarOffsetMinutes.toString());
    await database.kvSettingsDao.setValue('iftar_confirm_enabled', iftarEnabled.toString());
    await database.kvSettingsDao.setValue('night_plan_enabled', 'false');
    await database.kvSettingsDao.setValue('night_plan_hour', nightPlanHour.clamp(2, 4).toString());
    await database.kvSettingsDao.setValue('night_plan_minute', nightPlanMinute.clamp(0, 59).toString());

    await database.kvSettingsDao.setValue('goal_reminder_quran_enabled', quranReminderEnabled.toString());
    await database.kvSettingsDao.setValue('goal_reminder_dhikr_enabled', dhikrReminderEnabled.toString());
    await database.kvSettingsDao.setValue('goal_reminder_sedekah_enabled', sedekahReminderEnabled.toString());
    final digestEnabled =
        quranReminderEnabled || dhikrReminderEnabled || sedekahReminderEnabled;
    await database.kvSettingsDao.setValue(
      'goal_reminder_digest_enabled',
      digestEnabled.toString(),
    );
    await database.kvSettingsDao.setValue('goal_reminder_taraweeh_enabled', 'false');
    await database.kvSettingsDao.setValue('taraweeh_rakaat_per_day', taraweehRakaatPerDay.toString());

    await database.kvSettingsDao.setValue('prayers_detailed_mode', 'true');

    await database.kvSettingsDao.setValue('sedekah_currency', sedekahCurrency);
    await database.kvSettingsDao.setValue('sedekah_goal_enabled', sedekahGoalEnabled.toString());
    if (sedekahGoalEnabled && sedekahAmount > 0) {
      await database.kvSettingsDao.setValue('sedekah_goal_amount', sedekahAmount.toString());
    } else {
      await database.kvSettingsDao.deleteValue('sedekah_goal_amount');
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
          iftarConfirmEnabled: iftarConfirmEnabled,
          nightPlanEnabled: nightPlanEnabled,
          fajrAdjust: fajrAdjust,
          maghribAdjust: maghribAdjust,
        );
      } catch (e, stackTrace) {
        debugPrint('Failed to schedule reminders: $e');
        debugPrint('$stackTrace');
      }
    }
  }
}
