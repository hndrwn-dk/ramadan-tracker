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
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/counter_widget.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/utils/extensions.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';

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
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: seasonAsync.when(
          data: (season) {
            if (season == null) {
              return const Center(child: Text('No season found'));
            }
            return _buildContent(season.days, isInLast10 || showItikaf);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('Error: $error')),
        ),
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
            _buildHeroCard(habitsAsync, seasonHabitsAsync, entriesAsync),
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
                          seasonId: widget.seasonId,
                          dayIndex: widget.dayIndex,
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
                    habitsAsync.when(
                      data: (allHabits) => seasonHabitsAsync.when(
                        data: (seasonHabits) => entriesAsync.when(
                          data: (entries) {
                            return FutureBuilder<Map<String, int>>(
                              future: _calculateCompletedCount(
                                seasonId: widget.seasonId,
                                dayIndex: widget.dayIndex,
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
    final habitOrder = ['fasting', 'quran_pages', 'dhikr', 'taraweeh', 'sedekah', 'prayers', 'tahajud', 'itikaf'];
    final sortedHabits = <Widget>[];

    // Debug logging
    debugPrint('=== DayDetailScreen._buildHabitsList: seasonId=${widget.seasonId}, dayIndex=${widget.dayIndex} ===');
    debugPrint('  Total habits: ${habits.length}');
    debugPrint('  Total seasonHabits: ${seasonHabits.length}');
    debugPrint('  Total entries: ${entries.length}');
    debugPrint('  showItikaf: $showItikaf');

    for (final habitKey in habitOrder) {
      final habit = (habits as List).where((h) => h.key == habitKey).firstOrNull;
      if (habit == null) {
        debugPrint('  Habit not found: $habitKey');
        continue;
      }

      // Find SeasonHabit from all seasonHabits, not just enabled ones
      final sh = (seasonHabits as List).where((s) => s.habitId == habit.id).firstOrNull;
      if (sh == null) {
        debugPrint('  SeasonHabit not found for: $habitKey (habitId=${habit.id})');
        continue;
      }
      
      if (!sh.isEnabled) {
        debugPrint('  Habit disabled: $habitKey');
        continue;
      }

      if (habitKey == 'itikaf' && !showItikaf) {
        debugPrint('  Itikaf skipped (not in last 10 days)');
        continue;
      }

      final entry = (entries as List).where((e) => e.habitId == habit.id).firstOrNull;
      debugPrint('  Entry for $habitKey: ${entry != null ? "found (valueBool=${entry.valueBool}, valueInt=${entry.valueInt})" : "not found"}');

      // Cast habit to HabitModel to access type enum properly
      final habitModel = habit as HabitModel;
      debugPrint('  Processing habit: $habitKey (type=${habitModel.type}, isEnabled=${sh.isEnabled})');

      if (habitModel.type == HabitType.bool) {
        final value = entry?.valueBool ?? false;
        IconData? icon;
        if (habitKey == 'fasting') icon = Icons.no_meals;
        if (habitKey == 'taraweeh') icon = Icons.nights_stay;
        if (habitKey == 'itikaf') icon = Icons.mosque;
        if (habitKey == 'prayers') icon = Icons.mosque;
        if (habitKey == 'tahajud') icon = Icons.self_improvement;
        final iconWidget = habitKey == 'tahajud'
            ? TahajudIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
            : habitKey == 'prayers'
                ? PrayersIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                : habitKey == 'itikaf'
                    ? ItikafIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                    : habitKey == 'taraweeh'
                        ? TaraweehIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                        : null;

        debugPrint('  Adding bool habit to UI: $habitKey (value=$value)');
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: HabitToggle(
              label: habit.name,
              value: value,
              icon: icon,
              iconWidget: iconWidget,
              onTap: () {
                _toggleBoolHabit(habit.id, !value);
              },
            ),
          ),
        );
      } else if (habitKey == 'quran_pages') {
        debugPrint('  Adding quran_pages to UI');
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
        debugPrint('  Adding dhikr to UI (value=$value)');
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: CounterWidget(
              label: habit.name,
              value: value,
              icon: Icons.favorite,
              iconWidget: DhikrIcon(size: 20, color: Theme.of(context).colorScheme.primary),
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
        debugPrint('  Adding sedekah to UI');
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
      } else {
        // Log if habit type is not handled
        debugPrint('  Habit type not handled: $habitKey (type=${habitModel.type})');
      }
    }

    debugPrint('  Total habits added to UI: ${sortedHabits.length}');
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
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'How was today?',
                  ),
                  onChanged: (text) {
                    _saveReflection(text.isEmpty ? null : text, note?.id);
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            ),
          ),
        );
      },
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

