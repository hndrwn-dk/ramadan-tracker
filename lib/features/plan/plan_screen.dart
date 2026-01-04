import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/domain/services/autopilot_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/utils/extensions.dart';
import 'package:ramadan_tracker/features/plan/widgets/today_remaining_card.dart';
import 'package:ramadan_tracker/features/plan/widgets/plan_block_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:intl/intl.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  AutopilotIntensity? _intensity;
  int _morningMinutes = 30;
  int _dayMinutes = 60;
  int _nightMinutes = 60;
  QuranGoalType? _quranGoal;
  int _customPages = 604;
  int _dhikrTarget = 100;
  int _catchupCap = 5;

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => ref.read(tabIndexProvider.notifier).state = 0,
        ),
        title: Text(AppLocalizations.of(context)!.ramadanAutopilot),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return Center(child: Text(AppLocalizations.of(context)!.noSeasonFound));
          }
          return _buildContent(season.id, season.days);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${AppLocalizations.of(context)!.error}: $error')),
      ),
    );
  }

  Widget _buildContent(int seasonId, int totalDays) {
    return FutureBuilder<QuranPlanData?>(
      future: ref.read(databaseProvider).quranPlanDao.getPlan(seasonId),
      builder: (context, quranPlanSnapshot) {
        if (quranPlanSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (quranPlanSnapshot.hasError) {
          return Center(child: Text('${AppLocalizations.of(context)!.error}: ${quranPlanSnapshot.error}'));
        }

        final quranPlan = quranPlanSnapshot.data;
        final isConfigured = quranPlan != null;

        if (!isConfigured) {
          return _buildSetupWizard(seasonId, totalDays);
        }

        return _buildPlanView(seasonId, totalDays, quranPlan!);
      },
    );
  }

  Widget _buildSetupWizard(int seasonId, int totalDays) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.setupRamadanAutopilot,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!.setupRamadanAutopilotSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.intensity,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...AutopilotIntensity.values.map((intensity) {
                    return RadioListTile<AutopilotIntensity>(
                      title: Text(_getIntensityLabel(context, intensity)),
                      value: intensity,
                      groupValue: _intensity,
                      onChanged: (value) {
                        setState(() {
                          _intensity = value;
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.availableTimeMinutes,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSlider(AppLocalizations.of(context)!.planMorning, _morningMinutes, (value) {
                    setState(() {
                      _morningMinutes = value;
                    });
                  }),
                  _buildTimeSlider(AppLocalizations.of(context)!.planDay, _dayMinutes, (value) {
                    setState(() {
                      _dayMinutes = value;
                    });
                  }),
                  _buildTimeSlider(AppLocalizations.of(context)!.planNight, _nightMinutes, (value) {
                    setState(() {
                      _nightMinutes = value;
                    });
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.quranGoal,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...QuranGoalType.values.map((goal) {
                    return RadioListTile<QuranGoalType>(
                      title: Text(_getQuranGoalLabel(context, goal)),
                      value: goal,
                      groupValue: _quranGoal,
                      onChanged: (value) {
                        setState(() {
                          _quranGoal = value;
                        });
                      },
                    );
                  }),
                  if (_quranGoal == QuranGoalType.custom) ...[
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.totalPages,
                        hintText: '604',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _customPages = int.tryParse(value) ?? 604;
                        });
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.dhikrTarget,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.dailyTarget,
                      hintText: '100',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        _dhikrTarget = int.tryParse(value) ?? 100;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
              child: ElevatedButton(
              onPressed: _intensity != null && _quranGoal != null
                  ? () => _savePlan(seasonId, totalDays)
                  : null,
              child: Text(AppLocalizations.of(context)!.savePlan),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlider(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label),
              Text(AppLocalizations.of(context)!.minutes(value)),
            ],
          ),
          Slider(
            value: value.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            onChanged: (newValue) => onChanged(newValue.toInt()),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanView(int seasonId, int totalDays, QuranPlanData quranPlan) {
    // Use currentDayIndexProvider to match Today screen
    final dayIndex = ref.watch(currentDayIndexProvider);
    final seasonState = ref.watch(seasonStateProvider);
    final dhikrPlanAsync = ref.watch(dhikrPlanProvider(seasonId));

    if (seasonState == SeasonState.postRamadan) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.seasonCompleted,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.seasonCompletedMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to new season creation
                    // For now, just show a message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppLocalizations.of(context)!.newSeasonCreationComingSoon)),
                    );
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(AppLocalizations.of(context)!.startNewSeason),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return dhikrPlanAsync.when(
      data: (dhikrPlan) {
        // Use the actual current day index, same as Today screen
        final effectiveDayIndex = dayIndex;
        return FutureBuilder<AutopilotIntensity>(
          future: _getAutopilotIntensity(),
          builder: (context, intensitySnapshot) {
            final intensity = intensitySnapshot.data ?? AutopilotIntensity.balanced;
            
            return FutureBuilder<AutopilotPlan>(
              future: AutopilotService.generatePlan(
                seasonId: seasonId,
                currentDayIndex: effectiveDayIndex,
                totalDays: totalDays,
                intensity: intensity,
                timeBlocks: TimeBlocks(
                  morning: _morningMinutes,
                  day: _dayMinutes,
                  night: _nightMinutes,
                ),
                quranPlan: quranPlan,
                dhikrPlan: dhikrPlan,
                database: ref.read(databaseProvider),
              ),
              builder: (context, planSnapshot) {
                if (planSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (planSnapshot.hasError) {
                  return Center(child: Text('${AppLocalizations.of(context)!.error}: ${planSnapshot.error}'));
                }

                if (!planSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final plan = planSnapshot.data!;

                return FutureBuilder<Map<String, String?>>(
                  future: _getTimeWindows(context, seasonId, effectiveDayIndex),
                  builder: (context, timeWindowsSnapshot) {
                    final timeWindows = timeWindowsSnapshot.data ?? {};

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TodayRemainingCard(
                            seasonId: seasonId,
                            dayIndex: effectiveDayIndex,
                          ),
                          const SizedBox(height: 16),
                          _buildRecommendedPlanCard(context, plan, seasonId, effectiveDayIndex),
                          const SizedBox(height: 16),
                          _buildTodaysPlanCard(context, plan, timeWindows, seasonId, effectiveDayIndex),
                          const SizedBox(height: 16),
                          _buildProgressCard(context, plan, seasonId, effectiveDayIndex),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('${AppLocalizations.of(context)!.error} loading dhikr plan: $error')),
    );
  }

  Widget _buildRecommendedPlanCard(BuildContext context, AutopilotPlan plan, int seasonId, int dayIndex) {
    // Use providers for auto-refresh when data changes
    final quranDailyAsync = ref.watch(quranDailyProvider((seasonId: seasonId, dayIndex: dayIndex)));
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    final quranPlanAsync = ref.watch(quranPlanProvider(seasonId));
    final dhikrPlanAsync = ref.watch(dhikrPlanProvider(seasonId));
    
    return quranDailyAsync.when(
      data: (quranDaily) => entriesAsync.when(
        data: (entries) => quranPlanAsync.when(
          data: (quranPlan) => dhikrPlanAsync.when(
            data: (dhikrPlan) {
              final quranProgress = quranDaily?.pagesRead ?? 0;
              final quranTarget = quranPlan?.dailyTargetPages ?? plan.quranDailyTarget;
              
              // Get dhikr entry - need to await the habit
              return FutureBuilder(
                future: ref.read(databaseProvider).habitsDao.getHabitByKey('dhikr'),
                builder: (context, dhikrHabitSnapshot) {
                  final dhikrHabit = dhikrHabitSnapshot.data;
                  final dhikrEntry = dhikrHabit != null
                      ? entries.where((e) => e.habitId == dhikrHabit.id).firstOrNull
                      : null;
                  final dhikrProgress = dhikrEntry?.valueInt ?? 0;
                  final dhikrTarget = dhikrPlan?.dailyTarget ?? plan.dhikrTarget;
                  
                  final quranCompleted = quranProgress >= quranTarget;
                  final dhikrCompleted = dhikrProgress >= dhikrTarget;

                  return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.recommendedPlan,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                ),
                          ),
                          Text(
                            AppLocalizations.of(context)!.recommendedPlanSubtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.todayTarget,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTargetCard(
                        context,
                        icon: Icons.menu_book,
                        label: getHabitDisplayName(context, 'quran_pages'),
                        current: quranProgress,
                        target: quranTarget,
                        unit: AppLocalizations.of(context)!.pages,
                        isCompleted: quranCompleted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTargetCard(
                        context,
                        icon: Icons.favorite,
                        label: getHabitDisplayName(context, 'dhikr'),
                        current: dhikrProgress,
                        target: dhikrTarget,
                        unit: '',
                        isCompleted: dhikrCompleted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const SizedBox.shrink(),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getIconColor(BuildContext context, int current, bool isCompleted) {
    // Abu-abu: belum ada progress (0)
    if (current == 0) {
      return Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
    }
    // Hijau: sudah mencapai target
    if (isCompleted) {
      return Colors.green;
    }
    // Merah: belum mencapai target
    return Colors.red;
  }

  Widget _buildTargetCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int current,
    required int target,
    required String unit,
    required bool isCompleted,
  }) {
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: _getIconColor(context, current, isCompleted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                ),
              ),
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$current${unit.isNotEmpty ? '/$target $unit' : '/$target'}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTodaysPlanCard(BuildContext context, AutopilotPlan plan, Map<String, String?> timeWindows, int seasonId, int dayIndex) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.todaysPlan,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PlanBlockCard(
              label: AppLocalizations.of(context)!.planMorning,
              block: plan.morning,
              icon: Icons.wb_sunny,
              timeWindow: timeWindows['morning'],
              seasonId: seasonId,
              dayIndex: dayIndex,
            ),
            const SizedBox(height: 16),
            PlanBlockCard(
              label: AppLocalizations.of(context)!.planDay,
              block: plan.day,
              icon: Icons.light_mode,
              timeWindow: timeWindows['day'],
              seasonId: seasonId,
              dayIndex: dayIndex,
            ),
            const SizedBox(height: 16),
            PlanBlockCard(
              label: AppLocalizations.of(context)!.planNight,
              block: plan.night,
              icon: Icons.nights_stay,
              timeWindow: timeWindows['night'],
              seasonId: seasonId,
              dayIndex: dayIndex,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, AutopilotPlan plan, int seasonId, int dayIndex) {
    // Hide progress card if season is completed (days left == 0)
    if (plan.quranRemainingDays <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.progress,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Always show the 3 progress items
            Column(
              children: [
                _buildProgressItem(
                  context,
                  icon: Icons.menu_book,
                  label: getHabitDisplayName(context, 'quran_pages'),
                  value: AppLocalizations.of(context)!.pagesRemaining(plan.quranRemainingPages),
                  subtitle: AppLocalizations.of(context)!.pagesPerDay(plan.quranDailyTarget),
                ),
                const SizedBox(height: 16),
                _buildProgressItem(
                  context,
                  icon: Icons.calendar_today,
                  label: AppLocalizations.of(context)!.daysLeft,
                  value: AppLocalizations.of(context)!.days(plan.quranRemainingDays),
                  subtitle: null,
                ),
                const SizedBox(height: 16),
                _buildProgressItem(
                  context,
                  icon: Icons.favorite,
                  label: AppLocalizations.of(context)!.dhikrTargetLabel,
                  value: '${plan.dhikrTarget} ${AppLocalizations.of(context)!.daily}',
                  subtitle: null,
                ),
                // Show gentle catch-up as additional info if needed
                if (plan.quranRemainingPages > 0 && plan.quranRemainingDays > 0 && plan.quranDailyTarget > 20) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondaryContainer,
                          Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.gentleCatchup,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppLocalizations.of(context)!.gentleCatchupMessage(
                                  (plan.quranDailyTarget - 20).clamp(0, 5),
                                  plan.quranRemainingDays,
                                ),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Map<String, dynamic>> _getTodayProgressWithTargets(int seasonId, int dayIndex, AutopilotPlan plan) async {
    final database = ref.read(databaseProvider);
    
    // Use the same logic as Today screen for consistency
    // Load plans to get targets (same as Today screen)
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    
    // Load Quran daily data (Quran uses separate table)
    final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
    final quranPages = quranDaily?.pagesRead ?? 0;
    
    // Load entries for the day
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    
    // Get dhikr entry - same logic as Today screen
    final dhikrHabit = await database.habitsDao.getHabitByKey('dhikr');
    final dhikrEntry = dhikrHabit != null
        ? entries.where((e) => e.habitId == dhikrHabit.id).firstOrNull
        : null;
    final dhikrCount = dhikrEntry?.valueInt ?? 0;
    
    // Use targets from plans (same as Today screen), fallback to plan targets
    final quranTarget = quranPlan?.dailyTargetPages ?? plan.quranDailyTarget;
    final dhikrTarget = dhikrPlan?.dailyTarget ?? plan.dhikrTarget;
    
    return {
      'quran': quranPages,
      'dhikr': dhikrCount,
      'quranTarget': quranTarget,
      'dhikrTarget': dhikrTarget,
    };
  }

  Future<AutopilotIntensity> _getAutopilotIntensity() async {
    final database = ref.read(databaseProvider);
    final intensityStr = await database.kvSettingsDao.getValue('autopilot_intensity') ?? 'balanced';
    switch (intensityStr) {
      case 'light':
        return AutopilotIntensity.light;
      case 'strong':
        return AutopilotIntensity.strong;
      default:
        return AutopilotIntensity.balanced;
    }
  }

  Future<Map<String, String?>> _getTimeWindows(BuildContext context, int seasonId, int dayIndex) async {
    final l10n = AppLocalizations.of(context)!;
    final database = ref.read(databaseProvider);
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    if (season == null) {
      return {
        'morning': l10n.afterFajr,
        'day': l10n.midday,
        'night': l10n.afterIsha,
      };
    }

    final latStr = await database.kvSettingsDao.getValue('prayer_latitude');
    final lonStr = await database.kvSettingsDao.getValue('prayer_longitude');
    final tz = await database.kvSettingsDao.getValue('prayer_timezone') ?? 'UTC';
    final method = await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl';
    final highLatRule = await database.kvSettingsDao.getValue('prayer_high_lat_rule') ?? 'middle_of_night';
    final fajrAdj = int.tryParse(await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0') ?? 0;
    final maghribAdj = int.tryParse(await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0') ?? 0;

    if (latStr == null || lonStr == null) {
      return {
        'morning': l10n.afterFajr,
        'day': l10n.midday,
        'night': l10n.afterIsha,
      };
    }

    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) {
      return {
        'morning': l10n.afterFajr,
        'day': l10n.midday,
        'night': l10n.afterIsha,
      };
    }

    try {
      final startDate = DateTime.parse(season.startDate);
      final date = startDate.add(Duration(days: dayIndex - 1));
      // Calculate all prayer times
      final prayerTimes = PrayerTimeService.calculatePrayerTimes(
        date: date,
        latitude: lat,
        longitude: lon,
        timezone: tz,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdj,
        maghribAdjust: maghribAdj,
      );

      final fajr = prayerTimes.fajr;
      final dhuhr = prayerTimes.dhuhr;
      final asr = prayerTimes.asr;
      final isha = prayerTimes.isha;

      return {
        'morning': '${l10n.afterFajr} ${DateFormat('h:mm a').format(fajr)}',
        'day': '${DateFormat('h:mm a').format(dhuhr)} - ${DateFormat('h:mm a').format(asr)}',
        'night': '${l10n.afterIsha} ${DateFormat('h:mm a').format(isha)}',
      };
    } catch (e) {
      return {
        'morning': l10n.afterFajr,
        'day': l10n.midday,
        'night': l10n.afterIsha,
      };
    }
  }

  String _getIntensityLabel(BuildContext context, AutopilotIntensity intensity) {
    final l10n = AppLocalizations.of(context)!;
    switch (intensity) {
      case AutopilotIntensity.light:
        return l10n.intensityLight;
      case AutopilotIntensity.balanced:
        return l10n.intensityBalanced;
      case AutopilotIntensity.strong:
        return l10n.intensityStrong;
    }
  }

  String _getQuranGoalLabel(BuildContext context, QuranGoalType goal) {
    final l10n = AppLocalizations.of(context)!;
    switch (goal) {
      case QuranGoalType.khatam1:
        return l10n.quranGoal1Khatam;
      case QuranGoalType.khatam2:
        return l10n.quranGoal2Khatam;
      case QuranGoalType.custom:
        return l10n.quranGoalCustom;
    }
  }

  Future<void> _savePlan(int seasonId, int totalDays) async {
    final database = ref.read(databaseProvider);

    int pagesPerJuz = 20;
    int juzTargetPerDay = 1;
    int totalJuz = 30;
    int totalPages = 600;
    int dailyTargetPages = 20;

    switch (_quranGoal!) {
      case QuranGoalType.khatam1:
        totalJuz = 30;
        totalPages = 600;
        juzTargetPerDay = 1;
        dailyTargetPages = pagesPerJuz * juzTargetPerDay;
        break;
      case QuranGoalType.khatam2:
        totalJuz = 30;
        totalPages = 1200;
        juzTargetPerDay = 2;
        dailyTargetPages = pagesPerJuz * juzTargetPerDay;
        break;
      case QuranGoalType.custom:
        totalJuz = (_customPages / pagesPerJuz).ceil();
        totalPages = _customPages;
        juzTargetPerDay = (dailyTargetPages / pagesPerJuz).ceil();
        dailyTargetPages = pagesPerJuz * juzTargetPerDay;
        break;
    }

    await database.quranPlanDao.setPlan(
      QuranPlanData(
        seasonId: seasonId,
        pagesPerJuz: pagesPerJuz,
        juzTargetPerDay: juzTargetPerDay,
        dailyTargetPages: dailyTargetPages,
        totalJuz: totalJuz,
        totalPages: totalPages,
        catchupCapPages: _catchupCap,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await database.dhikrPlanDao.setPlan(
      DhikrPlanData(
        seasonId: seasonId,
        dailyTarget: _dhikrTarget,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }
}

enum QuranGoalType {
  khatam1,
  khatam2,
  custom,
}

final dhikrPlanProvider = FutureProvider.family<DhikrPlanData?, int>((ref, seasonId) async {
  final database = ref.watch(databaseProvider);
  return await database.dhikrPlanDao.getPlan(seasonId);
});

