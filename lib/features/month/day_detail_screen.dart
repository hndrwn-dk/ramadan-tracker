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
import 'package:ramadan_tracker/widgets/score_ring.dart';
import 'package:ramadan_tracker/widgets/habit_toggle.dart';
import 'package:ramadan_tracker/widgets/quran_tracker.dart';
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/counter_widget.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

class DayDetailScreen extends ConsumerStatefulWidget {
  final int seasonId;
  final int dayIndex;

  const DayDetailScreen({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  ConsumerState<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends ConsumerState<DayDetailScreen> {
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final showItikaf = ref.watch(showItikafProvider);
    final last10Start = ref.watch(last10StartProvider);
    final isInLast10 = widget.dayIndex >= last10Start && widget.dayIndex > 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.dayIndex}'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildContent(season.days, isInLast10 || showItikaf);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(int totalDays, bool showItikaf) {
    final habitsAsync = ref.watch(habitsProvider);
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(widget.seasonId));
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(seasonHabitsAsync, entriesAsync),
            const SizedBox(height: 16),
            _buildOneTapCard(
              habitsAsync,
              seasonHabitsAsync,
              entriesAsync,
              showItikaf,
            ),
            const SizedBox(height: 16),
            _buildReflectionCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(
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
                      future: _calculateStreak(),
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

  Widget _buildOneTapCard(
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
                    return _buildHabitsList(habits, seasonHabits, entries, showItikaf);
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

      if (habit.type == 'bool') {
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
                _toggleBoolHabit(habit.id, !value);
              },
            ),
          ),
        );
      } else if (habitKey == 'quran_pages') {
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: QuranTracker(
              seasonId: widget.seasonId,
              dayIndex: widget.dayIndex,
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
                  _setIntHabit(habit.id, value - 1);
                }
              },
              onIncrement: () {
                _setIntHabit(habit.id, value + 1);
              },
              onQuickAdd: (chipValue) {
                _setIntHabit(habit.id, value + chipValue);
              },
            ),
          ),
        );
      } else if (habitKey == 'sedekah') {
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SedekahTracker(
              seasonId: widget.seasonId,
              dayIndex: widget.dayIndex,
              habitId: habit.id,
            ),
          ),
        );
      }
    }

    return Column(children: sortedHabits);
  }

  Widget _buildReflectionCard() {
    return FutureBuilder<List<Note>>(
      future: ref.read(databaseProvider).notesDao.getDayNotes(widget.seasonId, widget.dayIndex),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        final note = notes.isNotEmpty ? notes.first : null;
        _reflectionController.text = note?.body ?? '';

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
                TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'How was today?',
                  ),
                  onChanged: (text) {
                    _saveReflection(text.isEmpty ? null : text, note?.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<int> _calculateStreak() async {
    final database = ref.read(databaseProvider);
    return await CompletionService.calculateStreak(
      seasonId: widget.seasonId,
      currentDayIndex: widget.dayIndex,
      database: database,
    );
  }

  Future<void> _toggleBoolHabit(int habitId, bool value) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setBoolValue(widget.seasonId, widget.dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
  }

  Future<void> _setIntHabit(int habitId, int value) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setIntValue(widget.seasonId, widget.dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
  }

  Future<void> _saveReflection(String? text, int? noteId) async {
    final database = ref.read(databaseProvider);
    if (text == null || text.isEmpty) {
      if (noteId != null) {
        await database.notesDao.deleteNote(noteId);
      }
    } else {
      if (noteId != null) {
        final existingNotes = await database.notesDao.getDayNotes(widget.seasonId, widget.dayIndex);
        if (existingNotes.isNotEmpty) {
          final note = existingNotes.first;
          await database.notesDao.updateNote(
            Note(
              id: note.id,
              seasonId: note.seasonId,
              dayIndex: note.dayIndex,
              title: note.title,
              body: text,
              createdAt: note.createdAt,
            ),
          );
        }
      } else {
        await database.notesDao.createNote(
          seasonId: widget.seasonId,
          dayIndex: widget.dayIndex,
          body: text,
        );
      }
    }
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
  }
}

