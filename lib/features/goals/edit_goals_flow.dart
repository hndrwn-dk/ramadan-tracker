import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step3_habits.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step4_goals.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

class EditGoalsFlow extends ConsumerStatefulWidget {
  final int seasonId;
  
  const EditGoalsFlow({
    super.key,
    required this.seasonId,
  });

  @override
  ConsumerState<EditGoalsFlow> createState() => _EditGoalsFlowState();
}

class _EditGoalsFlowState extends ConsumerState<EditGoalsFlow> {
  int _currentStep = 0;
  int? _lastStep;
  late OnboardingData _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentGoals();
  }

  Future<void> _loadCurrentGoals() async {
    final database = ref.read(databaseProvider);
    final season = await database.ramadanSeasonsDao.getSeasonById(widget.seasonId);
    
    if (season == null) {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    // Load current habits
    final allHabits = await database.habitsDao.getAllHabits();
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(widget.seasonId);
    final enabledHabitIds = seasonHabits.where((sh) => sh.isEnabled).map((sh) => sh.habitId).toSet();
    final selectedHabits = allHabits.where((h) => enabledHabitIds.contains(h.id)).map((h) => h.key).toSet();
    
    // Load Quran plan
    final quranPlan = await database.quranPlanDao.getPlan(widget.seasonId);
    int quranPages = 20;
    String quranGoal = '1_khatam';
    if (quranPlan != null) {
      quranPages = quranPlan.dailyTargetPages;
      if (quranPages == 20) {
        quranGoal = '1_khatam';
      } else if (quranPages == 40) {
        quranGoal = '2_khatam';
      } else {
        quranGoal = 'custom';
      }
    }
    
    // Load Dhikr plan
    final dhikrPlan = await database.dhikrPlanDao.getPlan(widget.seasonId);
    int dhikrTarget = 100;
    if (dhikrPlan != null) {
      dhikrTarget = dhikrPlan.dailyTarget;
    }
    
    // Load Sedekah goal
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final sedekahCurrency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'SGD';
    
    _data = OnboardingData()
      ..selectedHabits = selectedHabits
      ..quranGoal = quranGoal
      ..customQuranPages = quranPages
      ..dhikrTarget = dhikrTarget
      ..sedekahGoalEnabled = sedekahGoalEnabled == 'true'
      ..sedekahAmount = int.tryParse(sedekahGoalAmount ?? '0') ?? 0
      ..sedekahCurrency = sedekahCurrency
      ..days = season.days
      ..startDate = DateTime.parse(season.startDate);
    
    setState(() {
      _isLoading = false;
    });
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return OnboardingStep3Habits(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
          onPrevious: () => Navigator.pop(context),
        );
      case 1:
        return OnboardingStep4Goals(
          key: const ValueKey(1),
          data: _data,
          onNext: () async {
            await _saveGoals();
            if (mounted) {
              Navigator.pop(context);
            }
          },
          onPrevious: _previousStep,
        );
      default:
        return OnboardingStep3Habits(
          key: const ValueKey(0),
          data: _data,
          onNext: _nextStep,
          onPrevious: () => Navigator.pop(context),
        );
    }
  }

  void _nextStep() {
    if (_currentStep < 1) {
      setState(() {
        _lastStep = _currentStep;
        _currentStep = _currentStep + 1;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _lastStep = _currentStep;
        _currentStep = _currentStep - 1;
      });
    }
  }

  Future<void> _saveGoals() async {
    final database = ref.read(databaseProvider);
    
    // Update habits
    final allHabits = await database.habitsDao.getAllHabits();
    for (final habit in allHabits) {
      final seasonHabit = await database.seasonHabitsDao.getSeasonHabit(widget.seasonId, habit.id);
      final shouldEnable = _data.selectedHabits.contains(habit.key);
      
      if (seasonHabit != null) {
        if (seasonHabit.isEnabled != shouldEnable) {
          await database.seasonHabitsDao.setSeasonHabit(
            SeasonHabit(
              seasonId: widget.seasonId,
              habitId: habit.id,
              isEnabled: shouldEnable,
              targetValue: seasonHabit.targetValue,
              reminderEnabled: seasonHabit.reminderEnabled,
              reminderTime: seasonHabit.reminderTime,
            ),
          );
        }
      } else if (shouldEnable) {
        // Create new season habit if it doesn't exist
        await database.seasonHabitsDao.setSeasonHabit(
          SeasonHabit(
            seasonId: widget.seasonId,
            habitId: habit.id,
            isEnabled: true,
            targetValue: habit.defaultTarget,
            reminderEnabled: false,
            reminderTime: null,
          ),
        );
      }
    }
    
    // Update Quran plan
    int dailyPages = 20;
    int pagesPerJuz = 20;
    int juzTargetPerDay = 1;
    int totalJuz = 30;
    int totalPages = 600;
    
    if (_data.quranGoal == '1_khatam') {
      dailyPages = 20;
      totalPages = 600;
    } else if (_data.quranGoal == '2_khatam') {
      dailyPages = 40;
      totalPages = 1200;
    } else {
      dailyPages = _data.customQuranPages;
      totalPages = dailyPages * _data.days;
      totalJuz = (totalPages / pagesPerJuz).ceil();
    }
    
    await database.quranPlanDao.setPlan(
      QuranPlanData(
        seasonId: widget.seasonId,
        pagesPerJuz: pagesPerJuz,
        juzTargetPerDay: juzTargetPerDay,
        dailyTargetPages: dailyPages,
        totalJuz: totalJuz,
        totalPages: totalPages,
        catchupCapPages: 5,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    
    // Update Dhikr plan
    await database.dhikrPlanDao.setPlan(
      DhikrPlanData(
        seasonId: widget.seasonId,
        dailyTarget: _data.dhikrTarget,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    
    // Update Sedekah goal
    await database.kvSettingsDao.setValue('sedekah_goal_enabled', _data.sedekahGoalEnabled ? 'true' : 'false');
    await database.kvSettingsDao.setValue('sedekah_goal_amount', _data.sedekahAmount.toString());
    await database.kvSettingsDao.setValue('sedekah_currency', _data.sedekahCurrency);
    
    // Invalidate providers
    ref.invalidate(seasonHabitsProvider(widget.seasonId));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Goals'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Goals'),
      ),
      body: ClipRect(
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

            final Animation<double> slideAnim =
                isIncoming ? animation : ReverseAnimation(animation);

            final Offset inBegin = Offset(isForward ? 0.15 : -0.15, 0.0);
            final Offset outEnd = Offset(isForward ? -0.15 : 0.15, 0.0);

            final Tween<Offset> tween = isIncoming
                ? Tween<Offset>(begin: inBegin, end: Offset.zero)
                : Tween<Offset>(begin: Offset.zero, end: outEnd);

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
    );
  }
}

