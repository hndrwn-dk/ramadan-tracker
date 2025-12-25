import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/app.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
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
  final PageController _pageController = PageController();

  OnboardingData _data = OnboardingData();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() {
        _currentStep++;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OnboardingStep1Welcome(
                    data: _data,
                    onNext: _nextStep,
                  ),
                  OnboardingStep2Season(
                    data: _data,
                    onNext: _nextStep,
                    onPrevious: _previousStep,
                  ),
                  OnboardingStep3Habits(
                    data: _data,
                    onNext: _nextStep,
                    onPrevious: _previousStep,
                  ),
                  OnboardingStep4Goals(
                    data: _data,
                    onNext: _nextStep,
                    onPrevious: _previousStep,
                  ),
                  OnboardingStep5Reminders(
                    data: _data,
                    onPrevious: _previousStep,
                    onFinish: () async {
                      await _data.save(ref);
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MainScreen(),
                          ),
                        );
                      }
                    },
                  ),
                ],
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
  String sedekahCurrency = 'Rp';
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
    
    if (selectedHabits.contains('sedekah')) {
      await database.kvSettingsDao.setValue('sedekah_currency', sedekahCurrency);
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
    }
  }
}


