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
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/counter_widget.dart';
import 'package:ramadan_tracker/features/settings/settings_screen.dart';
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
                Text('Ramadan Offline'),
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
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildContent(season.id, dayIndex, season.days);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
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
              _buildHeroCard(seasonId, dayIndex, seasonHabitsAsync, entriesAsync),
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
                      final score = CompletionService.calculateCompletionScore(
                        enabledHabits: enabledHabits.cast(),
                        entries: entries.cast(),
                      );
                      return ScoreRing(score: score);
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
                    seasonHabitsAsync.when(
                      data: (seasonHabits) => entriesAsync.when(
                        data: (entries) {
                          final enabledHabits = (seasonHabits as List).where((sh) => sh.isEnabled).toList();
                          final completed = (entries as List).where((e) => e.isCompleted).length;
                          return Text(
                            'Done: $completed/${enabledHabits.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          );
                        },
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
    
    final habitOrder = ['fasting', 'quran_pages', 'dhikr', 'taraweeh', 'sedekah', 'itikaf'];
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
        if (habitKey == 'fasting') icon = Icons.wb_sunny;
        if (habitKey == 'taraweeh') icon = Icons.nights_stay;
        if (habitKey == 'itikaf') icon = Icons.mosque;

        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitToggle(
              label: habit.name,
              value: value,
              icon: icon,
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
                  decoration: const InputDecoration(
                    hintText: 'How was today?',
                  ),
                  onChanged: (text) {
                    _setNote(seasonId, dayIndex, reflectionHabitId, text.isEmpty ? null : text);
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

