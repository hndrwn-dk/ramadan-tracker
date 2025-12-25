import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/last10_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';
import 'package:ramadan_tracker/widgets/habit_toggle.dart';
import 'package:ramadan_tracker/widgets/quran_tracker.dart';
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/counter_widget.dart';
import 'package:ramadan_tracker/features/settings/settings_screen.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:flutter/services.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _focusMode = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _oneTapCardKey = GlobalKey();
  final TextEditingController _reflectionController = TextEditingController();

  @override
  void dispose() {
    _reflectionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final dayIndex = ref.watch(activeDayIndexForUIProvider);
    final seasonState = ref.watch(seasonStateProvider);

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
                String subtitle;
                if (seasonState == SeasonState.preRamadan) {
                  subtitle = 'Pre-Ramadan • $dateStr';
                } else if (seasonState == SeasonState.postRamadan) {
                  subtitle = 'Season Ended • $dateStr';
                } else {
                  subtitle = 'Day $dayIndex of ${season.days} • $dateStr';
                }
                return Text(
                  subtitle,
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
          return _buildContent(season.id, dayIndex, season.days, seasonState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildContent(int seasonId, int dayIndex, int totalDays, SeasonState state) {
    final habitsAsync = ref.watch(habitsProvider);
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(seasonId));
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    final showItikaf = ref.watch(showItikafProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state == SeasonState.preRamadan)
              _buildStateBanner(
                'Pre-Ramadan',
                'Season not started yet. Browse and plan ahead.',
                Icons.calendar_today,
              ),
            if (state == SeasonState.postRamadan)
              _buildStateBanner(
                'Season Ended',
                'Season finished. You can review your progress.',
                Icons.check_circle,
              ),
            if (state != SeasonState.active) const SizedBox(height: 16),
            if (!_focusMode) ...[
              _buildHeroCard(seasonId, dayIndex, seasonHabitsAsync, entriesAsync),
              const SizedBox(height: 16),
              _buildTimesCard(seasonId, dayIndex),
              const SizedBox(height: 16),
            ],
            entriesAsync.when(
              data: (entries) {
                if (entries.isEmpty && state == SeasonState.active) {
                  return Column(
                    children: [
                      _buildStartHereCard(seasonId, dayIndex),
                      const SizedBox(height: 16),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
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

  Widget _buildStateBanner(String title, String message, IconData icon) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesCard(int seasonId, int dayIndex) {
    return FutureBuilder<Map<String, DateTime>>(
      future: _getPrayerTimes(seasonId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.access_time),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Enable location for Sahur/Iftar',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to settings
                          },
                          child: const Text('Enable Location'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final times = snapshot.data!;
        final fajr = times['fajr'];
        final maghrib = times['maghrib'];
        final database = ref.read(databaseProvider);
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _getReminderSettings(database),
          builder: (context, settingsSnapshot) {
            final sahurOffset = settingsSnapshot.data?['sahur_offset'] ?? 30;
            final iftarOffset = settingsSnapshot.data?['iftar_offset'] ?? 0;
            
            if (fajr == null || maghrib == null) {
              return const SizedBox.shrink();
            }

            final sahurTime = fajr.subtract(Duration(minutes: sahurOffset));
            final iftarTime = maghrib.add(Duration(minutes: iftarOffset));

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Times',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: () {
                            _refreshPrayerTimes(seasonId);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sahur',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat('HH:mm').format(sahurTime),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${DateFormat('HH:mm').format(fajr)} Fajr',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Iftar',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Text(
                              DateFormat('HH:mm').format(iftarTime),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              '${DateFormat('HH:mm').format(maghrib)} Maghrib',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
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
    );
  }

  Widget _buildStartHereCard(int seasonId, int dayIndex) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today in 10 seconds',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap what you did. Add pages & dhikr. Done.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Scroll to One Tap card
                      if (_oneTapCardKey.currentContext != null) {
                        Scrollable.ensureVisible(
                          _oneTapCardKey.currentContext!,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: const Text('Open One Tap'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to Settings for goals
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Text('Edit Goals'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, DateTime>> _getPrayerTimes(int seasonId) async {
    final database = ref.read(databaseProvider);
    final latStr = await database.kvSettingsDao.getValue('prayer_latitude');
    final lonStr = await database.kvSettingsDao.getValue('prayer_longitude');
    final tz = await database.kvSettingsDao.getValue('prayer_timezone') ?? 'UTC';
    final method = await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl';
    final highLatRule = await database.kvSettingsDao.getValue('prayer_high_lat_rule') ?? 'middle_of_night';
    final fajrAdj = int.tryParse(await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0') ?? 0;
    final maghribAdj = int.tryParse(await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0') ?? 0;

    if (latStr == null || lonStr == null) {
      return {};
    }

    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);

    if (lat == null || lon == null) {
      return {};
    }

    try {
      return await PrayerTimeService.getCachedOrCalculate(
        database: database,
        seasonId: seasonId,
        date: DateTime.now(),
        latitude: lat,
        longitude: lon,
        timezone: tz,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdj,
        maghribAdjust: maghribAdj,
      );
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getReminderSettings(AppDatabase database) async {
    final sahurOffset = int.tryParse(await database.kvSettingsDao.getValue('sahur_offset') ?? '30') ?? 30;
    final iftarOffset = int.tryParse(await database.kvSettingsDao.getValue('iftar_offset') ?? '0') ?? 0;
    return {
      'sahur_offset': sahurOffset,
      'iftar_offset': iftarOffset,
    };
  }

  Future<void> _refreshPrayerTimes(int seasonId) async {
    final database = ref.read(databaseProvider);
    final latStr = await database.kvSettingsDao.getValue('prayer_latitude');
    final lonStr = await database.kvSettingsDao.getValue('prayer_longitude');
    final tz = await database.kvSettingsDao.getValue('prayer_timezone') ?? 'UTC';
    final method = await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl';
    final highLatRule = await database.kvSettingsDao.getValue('prayer_high_lat_rule') ?? 'middle_of_night';
    final fajrAdj = int.tryParse(await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0') ?? 0;
    final maghribAdj = int.tryParse(await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0') ?? 0;

    if (latStr != null && lonStr != null) {
      final lat = double.tryParse(latStr);
      final lon = double.tryParse(lonStr);
      if (lat != null && lon != null) {
        await database.prayerTimesCacheDao.clearCacheForSeason(seasonId);
        await PrayerTimeService.ensureTodayAndTomorrowCached(
          database: database,
          seasonId: seasonId,
          latitude: lat,
          longitude: lon,
          timezone: tz,
          method: method,
          highLatRule: highLatRule,
          fajrAdjust: fajrAdj,
          maghribAdjust: maghribAdj,
        );
        setState(() {});
      }
    }
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
      key: _oneTapCardKey,
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
              onQuickAdd: (chipValue) {
                _setIntHabit(seasonId, dayIndex, habit.id, value + chipValue);
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
    return FutureBuilder<List<Note>>(
      future: ref.read(databaseProvider).notesDao.getDayNotes(seasonId, dayIndex),
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
                    _saveReflection(seasonId, dayIndex, text.isEmpty ? null : text, note?.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveReflection(int seasonId, int dayIndex, String? text, int? noteId) async {
    final database = ref.read(databaseProvider);
    if (text == null || text.isEmpty) {
      if (noteId != null) {
        await database.notesDao.deleteNote(noteId);
      }
    } else {
        if (noteId != null) {
          final existingNotes = await database.notesDao.getDayNotes(seasonId, dayIndex);
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
          seasonId: seasonId,
          dayIndex: dayIndex,
          body: text,
        );
      }
    }
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
    HapticFeedback.lightImpact();
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

