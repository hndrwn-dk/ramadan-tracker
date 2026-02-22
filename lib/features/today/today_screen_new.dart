import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/last10_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/services/quran_service.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';
import 'package:ramadan_tracker/widgets/habit_toggle.dart';
import 'package:ramadan_tracker/widgets/quran_tracker.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/counter_widget.dart';
import 'package:ramadan_tracker/features/settings/settings_screen.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _focusMode = false;
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final dayIndex = ref.watch(currentDayIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.nights_stay, size: 24),
                SizedBox(width: 8),
                Text('Ramadan Tracker'),
              ],
            ),
            const SizedBox(height: 4),
            seasonAsync.when(
              data: (season) {
                if (season == null) return const SizedBox.shrink();
                final now = DateTime.now();
                final dateStr = DateFormat('MMM d, yyyy').format(now);
                return Text(
                  'Day $dayIndex of ${season.days} • $dateStr',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _focusMode = !_focusMode;
              });
            },
            tooltip: 'Focus Mode',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: seasonAsync.when(
          data: (season) {
            if (season == null) {
              return const Center(child: Text('No season found'));
            }
            return _buildContent(season.id, dayIndex, season.days);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
      ),
    );
  }

  Widget _buildContent(int seasonId, int dayIndex, int totalDays) {
    final habitsAsync = ref.watch(habitsProvider);
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(seasonId));
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    final showItikaf = ref.watch(showItikafProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_focusMode) ...[
              _buildHeroCard(seasonId, dayIndex, habitsAsync, seasonHabitsAsync, entriesAsync),
              const SizedBox(height: 16),
            ],
            _buildOneTapTodayCard(
              seasonId,
              dayIndex,
              habitsAsync,
              seasonHabitsAsync,
              entriesAsync,
              showItikaf,
            ),
            const SizedBox(height: 16),
            _buildReflectionCard(seasonId, dayIndex),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
    int seasonId,
    int dayIndex,
    AsyncValue<List<dynamic>> habitsAsync,
    AsyncValue<List<dynamic>> seasonHabitsAsync,
    AsyncValue<List<dynamic>> entriesAsync,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                seasonHabitsAsync.when(
                  data: (seasonHabits) => entriesAsync.when(
                    data: (entries) {
                      final enabledHabits = (seasonHabits as List).where((sh) => sh.isEnabled).toList();
                      return FutureBuilder<double>(
                        future: CompletionService.calculateCompletionScore(
                          seasonId: seasonId,
                          dayIndex: dayIndex,
                          enabledHabits: enabledHabits.cast(),
                          entries: entries.cast(),
                          database: ref.read(databaseProvider),
                          allHabits: habitsAsync.value,
                        ),
                        builder: (context, snapshot) {
                          final score = snapshot.data ?? 0.0;
                          return ScoreRing(score: score);
                        },
                      );
                    },
                    loading: () => const ScoreRing(score: 0),
                    error: (_, __) => const ScoreRing(score: 0),
                  ),
                  loading: () => const ScoreRing(score: 0),
                  error: (_, __) => const ScoreRing(score: 0),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<int>(
                      future: _calculateStreak(seasonId, dayIndex),
                      builder: (context, snapshot) {
                        final streak = snapshot.data ?? 0;
                        return Text(
                          'Streak: $streak days',
                          style: Theme.of(context).textTheme.titleLarge,
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    habitsAsync.when(
                      data: (allHabits) => seasonHabitsAsync.when(
                        data: (seasonHabits) => entriesAsync.when(
                          data: (entries) {
                            return FutureBuilder<Map<String, int>>(
                              future: _calculateCompletedCount(
                                seasonId: seasonId,
                                dayIndex: dayIndex,
                                enabledHabits: (seasonHabits as List).where((sh) => sh.isEnabled).toList(),
                                entries: entries.cast(),
                                allHabits: allHabits,
                              ),
                              builder: (context, snapshot) {
                                final result = snapshot.data ?? {'completed': 0, 'total': 0};
                                return Text(
                                  'Done: ${result['completed']}/${result['total']}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                );
                              },
                            );
                          },
                          loading: () => const Text('Done: 0/0'),
                          error: (_, __) => const Text('Done: 0/0'),
                        ),
                        loading: () => const Text('Done: 0/0'),
                        error: (_, __) => const Text('Done: 0/0'),
                      ),
                      loading: () => const Text('Done: 0/0'),
                      error: (_, __) => const Text('Done: 0/0'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOneTapTodayCard(
    int seasonId,
    int dayIndex,
    AsyncValue<List<dynamic>> habitsAsync,
    AsyncValue<List<dynamic>> seasonHabitsAsync,
    AsyncValue<List<dynamic>> entriesAsync,
    bool showItikaf,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One Tap Today',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            habitsAsync.when(
              data: (habits) => seasonHabitsAsync.when(
                data: (seasonHabits) => entriesAsync.when(
                  data: (entries) {
                    return _buildHabitsList(
                      seasonId,
                      dayIndex,
                      habits,
                      seasonHabits,
                      entries,
                      showItikaf,
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (_, __) => const Text('Error loading entries'),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('Error loading habits'),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error loading habits'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHabitsList(
    int seasonId,
    int dayIndex,
    List<dynamic> habits,
    List<dynamic> seasonHabits,
    List<dynamic> entries,
    bool showItikaf,
  ) {
    final enabledHabits = (seasonHabits as List).where((sh) => sh.isEnabled).toList();
    
    final habitOrder = ['fasting', 'quran_pages', 'dhikr', 'taraweeh', 'sedekah', 'prayers', 'tahajud', 'itikaf'];
    final sortedHabits = <Widget>[];

    for (final habitKey in habitOrder) {
      final habit = (habits as List).where((h) => h.key == habitKey).firstOrNull;
      if (habit == null) continue;

      final sh = enabledHabits.where((s) => s.habitId == habit.id).firstOrNull;
      if (sh == null || !sh.isEnabled) continue;

      if (habitKey == 'itikaf' && !showItikaf) continue;

      final entry = (entries as List).where((e) => e.habitId == habit.id).firstOrNull;

      if (habit.type.toString() == 'HabitType.bool') {
        final value = entry?.valueBool ?? false;
        IconData? icon;
        if (habitKey == 'fasting') icon = Icons.no_meals;
        if (habitKey == 'taraweeh') icon = Icons.nights_stay;
        if (habitKey == 'itikaf') icon = Icons.mosque;
        if (habitKey == 'tahajud') icon = Icons.self_improvement;
        if (habitKey == 'prayers') icon = Icons.mosque;
        final iconWidget = habitKey == 'tahajud'
            ? TahajudIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
            : habitKey == 'prayers'
                ? PrayersIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                : habitKey == 'itikaf'
                    ? ItikafIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                    : habitKey == 'taraweeh'
                        ? TaraweehIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                        : null;

        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitToggle(
              label: habit.name,
              value: value,
              icon: icon,
              iconWidget: iconWidget,
              onTap: () {
                _toggleBoolHabit(seasonId, dayIndex, habit.id, !value);
              },
            ),
          ),
        );
      } else if (habitKey == 'quran_pages') {
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: QuranTracker(
              seasonId: seasonId,
              dayIndex: dayIndex,
              habitId: habit.id,
            ),
          ),
        );
      } else if (habitKey == 'dhikr') {
        final value = entry?.valueInt ?? 0;
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CounterWidget(
              label: habit.name,
              value: value,
              quickAddChips: const [33, 100, 300],
              onDecrement: () {
                if (value > 0) {
                  _setIntHabit(seasonId, dayIndex, habit.id, value - 1);
                }
              },
              onIncrement: () {
                _setIntHabit(seasonId, dayIndex, habit.id, value + 1);
              },
            ),
          ),
        );
      } else if (habitKey == 'sedekah') {
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SedekahTracker(
              seasonId: seasonId,
              dayIndex: dayIndex,
              habitId: habit.id,
            ),
          ),
        );
      }
    }

    return Column(children: sortedHabits);
  }

  Widget _buildReflectionCard(int seasonId, int dayIndex) {
    final reflectionHabitId = 6;
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reflection',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            entriesAsync.when(
              data: (entries) {
                final reflectionEntry = entries.where((e) => e.habitId == reflectionHabitId).firstOrNull;
                _reflectionController.text = reflectionEntry?.note ?? '';

                return TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'How was today?',
                  ),
                  onChanged: (text) {
                    _setNote(seasonId, dayIndex, reflectionHabitId, text.isEmpty ? null : text);
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error'),
            ),
          ],
        ),
      ),
    );
  }

  Future<int> _calculateStreak(int seasonId, int dayIndex) async {
    final database = ref.read(databaseProvider);
    return await CompletionService.calculateStreak(
      seasonId: seasonId,
      currentDayIndex: dayIndex,
      database: database,
    );
  }

  Future<Map<String, int>> _calculateCompletedCount({
    required int seasonId,
    required int dayIndex,
    required List enabledHabits,
    required List entries,
    List? allHabits,
  }) async {
    if (enabledHabits.isEmpty) return {'completed': 0, 'total': 0};

    final database = ref.read(databaseProvider);
    
    // Load plans for count-based habits
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    
    // Load Quran daily data (Quran uses separate table)
    final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
    
    // Check if we're in the last 10 days (for Itikaf)
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    final last10Start = season != null ? season.days - 9 : 0;
    final isInLast10Days = dayIndex >= last10Start && dayIndex > 0;

    int completedCount = 0;
    int totalRelevantHabits = 0;

    for (final habit in enabledHabits) {
      // Get habit key to identify count habits and Itikaf
      String? habitKey;
      if (allHabits != null) {
        try {
          final fullHabit = allHabits.firstWhere((h) => h.id == habit.habitId);
          habitKey = fullHabit.key;
        } catch (e) {
          habitKey = null;
        }
      }
      
      // Skip Itikaf if not in last 10 days
      if (habitKey == 'itikaf' && !isInLast10Days) {
        continue; // Don't count Itikaf in total if not in last 10 days
      }
      
      // Count this habit in total relevant habits
      totalRelevantHabits++;
      
      final entry = entries.where((e) => 
        e.habitId == habit.habitId && 
        e.seasonId == seasonId && 
        e.dayIndex == dayIndex
      ).firstOrNull ??
          DailyEntryModel(
            seasonId: seasonId,
            dayIndex: dayIndex,
            habitId: habit.habitId,
            updatedAt: DateTime.now(),
          );

      bool isCompleted = false;
      
      // Count habits (quran_pages, dhikr, sedekah) should be checked based on target
      if (habitKey == 'quran_pages') {
        // Quran uses QuranDaily table, not DailyEntries
        final target = quranPlan?.dailyTargetPages ?? 20;
        if (target > 0) {
          final currentValue = quranDaily?.pagesRead ?? 0;
          isCompleted = currentValue >= target;
        } else {
          final currentValue = quranDaily?.pagesRead ?? 0;
          isCompleted = currentValue > 0;
        }
      } else if (habitKey == 'dhikr') {
        // Dhikr target from DhikrPlan
        final target = dhikrPlan?.dailyTarget ?? 100;
        if (target > 0) {
          isCompleted = (entry.valueInt ?? 0) >= target;
        } else {
          isCompleted = (entry.valueInt ?? 0) > 0;
        }
      } else if (habitKey == 'sedekah') {
        // Sedekah target from KvSettings
        if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
          final target = double.tryParse(sedekahGoalAmount) ?? 0;
          if (target > 0) {
            // Convert valueInt to double for accurate comparison
            final currentValue = (entry.valueInt ?? 0).toDouble();
            isCompleted = currentValue >= target;
          } else {
            isCompleted = (entry.valueInt ?? 0) > 0;
          }
        } else {
          // If sedekah goal disabled, consider completed if value > 0
          isCompleted = (entry.valueInt ?? 0) > 0;
        }
      } else {
        // Boolean habits (fasting, taraweeh, itikaf, prayers)
        isCompleted = entry.isCompleted;
      }

      if (isCompleted) {
        completedCount++;
      }
    }

    return {'completed': completedCount, 'total': totalRelevantHabits};
  }

  Future<void> _toggleBoolHabit(int seasonId, int dayIndex, int habitId, bool value) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setBoolValue(seasonId, dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
  }

  Future<void> _setIntHabit(int seasonId, int dayIndex, int habitId, int value) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setIntValue(seasonId, dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
  }

  Future<void> _setNote(int seasonId, int dayIndex, int habitId, String? note) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setNote(seasonId, dayIndex, habitId, note);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
  }
}

