import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/services/autopilot_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

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
        title: const Text('Ramadan Autopilot'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildContent(season.id, season.days);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
          return Center(child: Text('Error: ${quranPlanSnapshot.error}'));
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
                    'Setup Ramadan Autopilot',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configure your goals and available time to generate a daily plan.',
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
                    'Intensity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...AutopilotIntensity.values.map((intensity) {
                    return RadioListTile<AutopilotIntensity>(
                      title: Text(_getIntensityLabel(intensity)),
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
                    'Available Time (minutes)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  _buildTimeSlider('Morning', _morningMinutes, (value) {
                    setState(() {
                      _morningMinutes = value;
                    });
                  }),
                  _buildTimeSlider('Day', _dayMinutes, (value) {
                    setState(() {
                      _dayMinutes = value;
                    });
                  }),
                  _buildTimeSlider('Night', _nightMinutes, (value) {
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
                    'Quran Goal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ...QuranGoalType.values.map((goal) {
                    return RadioListTile<QuranGoalType>(
                      title: Text(_getQuranGoalLabel(goal)),
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
                      decoration: const InputDecoration(
                        labelText: 'Total Pages',
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
                    'Dhikr Target',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Daily Target',
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
              child: const Text('Save Plan'),
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
              Text('$value min'),
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
    final dayIndex = ref.watch(activeDayIndexForUIProvider);
    final seasonState = ref.watch(seasonStateProvider);
    final dhikrPlanAsync = ref.watch(dhikrPlanProvider(seasonId));

    if (seasonState == SeasonState.postRamadan) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 48, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Season Ended',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'The Ramadan season has finished. You can review your progress in the Insights tab.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return dhikrPlanAsync.when(
      data: (dhikrPlan) {
        final effectiveDayIndex = seasonState == SeasonState.preRamadan ? 1 : dayIndex;
        return FutureBuilder<AutopilotPlan>(
          future: AutopilotService.generatePlan(
            seasonId: seasonId,
            currentDayIndex: effectiveDayIndex,
            totalDays: totalDays,
            intensity: AutopilotIntensity.balanced,
            timeBlocks: TimeBlocks(
              morning: _morningMinutes,
              day: _dayMinutes,
              night: _nightMinutes,
            ),
            quranPlan: quranPlan,
            dhikrPlan: dhikrPlan,
            database: ref.read(databaseProvider),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

        final plan = snapshot.data!;

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
                        'Recommended Plan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      _buildTodayTarget(context, plan),
                      const SizedBox(height: 16),
                      Text(
                        'When to do it',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
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
                        'Today\'s Plan',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      _buildTimelineBlock('Morning', plan.morning),
                      const SizedBox(height: 16),
                      _buildTimelineBlock('Day', plan.day),
                      const SizedBox(height: 16),
                      _buildTimelineBlock('Night', plan.night),
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
                        'Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      if (plan.quranRemainingPages > 0 && plan.quranRemainingDays > 0 && plan.quranDailyTarget > 20)
                        Card(
                          color: Theme.of(context).colorScheme.surfaceVariant,
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gentle catch-up',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${(plan.quranDailyTarget - 20).clamp(0, 5)} pages/day for the next ${plan.quranRemainingDays} days',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quran: ${plan.quranRemainingPages} pages remaining'),
                            Text('Days left: ${plan.quranRemainingDays}'),
                            Text('Daily target: ${plan.quranDailyTarget} pages'),
                            Text('Dhikr target: ${plan.dhikrTarget}'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error loading dhikr plan: $error')),
    );
  }

  Widget _buildTodayTarget(BuildContext context, AutopilotPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today Target',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quran',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${plan.quranDailyTarget}/20 pages',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Dhikr',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${plan.dhikrTarget}/100',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineBlock(String label, TimelineBlock block) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (block.tasks.isEmpty)
          Text(
            'No tasks scheduled',
            style: Theme.of(context).textTheme.bodyMedium,
          )
        else
          ...block.tasks.map((task) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${task.name} - ${task.minutes} min'),
                  ),
                  if (task.pages != null) Text('${task.pages} pages'),
                  if (task.count != null) Text('${task.count} count'),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _getIntensityLabel(AutopilotIntensity intensity) {
    switch (intensity) {
      case AutopilotIntensity.light:
        return 'Light';
      case AutopilotIntensity.balanced:
        return 'Balanced';
      case AutopilotIntensity.strong:
        return 'Strong';
    }
  }

  String _getQuranGoalLabel(QuranGoalType goal) {
    switch (goal) {
      case QuranGoalType.khatam1:
        return '1 Khatam';
      case QuranGoalType.khatam2:
        return '2 Khatam';
      case QuranGoalType.custom:
        return 'Custom';
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

