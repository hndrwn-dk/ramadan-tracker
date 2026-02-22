import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';

class DaySummarySheet extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const DaySummarySheet({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(seasonId));
    final habitsAsync = ref.watch(habitsProvider);
    final database = ref.watch(databaseProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: seasonAsync.when(
                    data: (season) {
                      if (season == null) {
                        return Text(
                          l10n.dayLabel(dayIndex),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        );
                      }
                      final startDate = season.startDate;
                      final dayDate = startDate.add(Duration(days: dayIndex - 1));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.dayOfSeason(dayIndex, season.days),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMMM d, yyyy').format(dayDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Completion Score
                  Center(
                    child: entriesAsync.when(
                      data: (entries) {
                        return seasonHabitsAsync.when(
                          data: (seasonHabits) {
                            return habitsAsync.when(
                              data: (allHabits) {
                                final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();
                                return FutureBuilder<double>(
                                  future: CompletionService.calculateCompletionScore(
                                    seasonId: seasonId,
                                    dayIndex: dayIndex,
                                    enabledHabits: enabledHabits,
                                    entries: entries,
                                    database: database,
                                    allHabits: allHabits,
                                  ),
                                  builder: (context, snapshot) {
                                    final score = snapshot.data ?? 0.0;
                                    return Column(
                                      children: [
                                        ScoreRing(score: score),
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.percentComplete(int.parse(score.toStringAsFixed(0))),
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              loading: () => const CircularProgressIndicator(),
                              error: (_, __) => const SizedBox.shrink(),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Habits List
                  Text(
                    l10n.trackedHabits,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildHabitsList(context, ref, entriesAsync, seasonHabitsAsync, habitsAsync),
                ],
              ),
            ),
          ),
          // Actions (add bottom safe area so buttons are not cut off by nav bar on some devices)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.of(context).padding.bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.close),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                      ref.read(tabIndexProvider.notifier).state = 0;
                    },
                    child: Text(l10n.viewDayButton),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsList(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<DailyEntryModel>> entriesAsync,
    AsyncValue<List<SeasonHabitModel>> seasonHabitsAsync,
    AsyncValue<List<HabitModel>> habitsAsync,
  ) {
    return entriesAsync.when(
      data: (entries) {
        return seasonHabitsAsync.when(
          data: (seasonHabits) {
            return habitsAsync.when(
              data: (allHabits) {
                final habitOrder = ['fasting', 'quran_pages', 'dhikr', 'taraweeh', 'sedekah', 'prayers', 'tahajud', 'itikaf'];

                // Check if in last 10 days
                final seasonAsync = ref.watch(currentSeasonProvider);
                final showItikaf = seasonAsync.when(
                  data: (season) {
                    if (season == null) return false;
                    final last10Start = season.days - 9;
                    return dayIndex >= last10Start && dayIndex > 0;
                  },
                  loading: () => false,
                  error: (_, __) => false,
                );

                final habitWidgets = <Widget>[];

                for (final habitKey in habitOrder) {
                  final habit = allHabits.where((h) => h.key == habitKey).firstOrNull;
                  if (habit == null) continue;

                  final sh = seasonHabits.where((s) => s.habitId == habit.id).firstOrNull;
                  if (sh == null || !sh.isEnabled) continue;

                  if (habitKey == 'itikaf' && !showItikaf) continue;

                  final entry = entries.where((e) => e.habitId == habit.id).firstOrNull;

                  // Prayers always use detailed mode (track each prayer individually)
                  if (habitKey == 'prayers') {
                    habitWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPrayersDetailedItem(context, ref, habit, entry),
                      ),
                    );
                  } else {
                    habitWidgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildHabitItem(context, ref, habit, entry, sh, seasonId, dayIndex),
                      ),
                    );
                  }
                }

                return Column(children: habitWidgets);
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingHabits),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingSeasonHabits),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingEntries),
    );
  }

  Widget _buildHabitItem(
    BuildContext context,
    WidgetRef ref,
    HabitModel habit,
    DailyEntryModel? entry,
    SeasonHabitModel seasonHabit,
    int seasonId,
    int dayIndex,
  ) {
    final habitKey = habit.key;
    final database = ref.read(databaseProvider);

    return FutureBuilder<Map<String, dynamic>>(
      future: _getHabitStatus(context, habitKey, entry, seasonHabit, database, seasonId, dayIndex),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final status = snapshot.data!;
        final label = status['label'] as String;
        final value = status['value'] as String;
        final isCompleted = status['isCompleted'] as bool;
        final icon = status['icon'] as IconData?;
        final habitKey = status['habitKey'] as String?;
        final iconColor = isCompleted
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              if (icon != null || habitKey != null) ...[
                habitKey != null
                    ? getHabitIconWidget(context, habitKey, size: 20, color: iconColor)
                    : Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 20,
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getHabitStatus(
    BuildContext context,
    String habitKey,
    DailyEntryModel? entry,
    SeasonHabitModel seasonHabit,
    AppDatabase database,
    int seasonId,
    int dayIndex,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    
    switch (habitKey) {
      case 'fasting':
      case 'taraweeh':
      case 'tahajud':
      case 'itikaf':
        final isCompleted = entry?.valueBool ?? false;
        String label;
        if (habitKey == 'fasting') {
          label = l10n.habitFasting;
        } else if (habitKey == 'taraweeh') {
          label = l10n.habitTaraweeh;
        } else if (habitKey == 'tahajud') {
          label = l10n.habitTahajud;
        } else {
          label = l10n.habitItikaf;
        }
        return {
          'label': label,
          'value': isCompleted ? l10n.done : l10n.notDone,
          'isCompleted': isCompleted,
          'icon': getHabitIcon(habitKey),
          'habitKey': habitKey,
        };

      case 'quran_pages':
        final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
        final pagesRead = quranDaily?.pagesRead ?? 0;
        final target = seasonHabit.targetValue ?? 20;
        return {
          'label': l10n.habitQuran,
          'value': l10n.quranPagesFormat(pagesRead, target),
          'isCompleted': pagesRead >= target,
          'icon': Icons.menu_book,
          'habitKey': habitKey,
        };

      case 'dhikr':
        final count = entry?.valueInt ?? 0;
        final target = seasonHabit.targetValue ?? 100;
        return {
          'label': l10n.habitDhikr,
          'value': l10n.dhikrCountFormat(count, target),
          'isCompleted': count >= target,
          'icon': Icons.favorite,
          'habitKey': habitKey,
        };

      case 'sedekah':
        final amount = (entry?.valueInt ?? 0).toDouble();
        final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
        final goalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled') == 'true';
        final goalAmountStr = await database.kvSettingsDao.getValue('sedekah_goal_amount');
        final goalAmount = goalAmountStr != null ? double.tryParse(goalAmountStr) ?? 0.0 : 0.0;
        final normalizedCurrency = _normalizeCurrency(currency);
        final formattedAmount = SedekahUtils.formatCurrency(amount, normalizedCurrency);
        
        String valueText;
        bool isCompleted = false;
        if (goalEnabled && goalAmount > 0) {
          valueText = '$formattedAmount / ${SedekahUtils.formatCurrency(goalAmount, normalizedCurrency)}';
          isCompleted = amount >= goalAmount;
        } else {
          valueText = formattedAmount;
          isCompleted = amount > 0;
        }
        
        return {
          'label': l10n.habitSedekah,
          'value': valueText,
          'isCompleted': isCompleted,
          'icon': Icons.volunteer_activism,
          'habitKey': habitKey,
        };

      case 'prayers':
        // Always use detailed mode (track each prayer individually)
        final prayerDetails = await database.prayerDetailsDao.getPrayerDetails(seasonId, dayIndex);
        if (prayerDetails != null) {
          final completed = [
            prayerDetails.fajr,
            prayerDetails.dhuhr,
            prayerDetails.asr,
            prayerDetails.maghrib,
            prayerDetails.isha,
          ].where((p) => p).length;
          return {
            'label': l10n.habitPrayers,
            'value': '$completed / 5 ${l10n.completed}',
            'isCompleted': completed == 5,
            'icon': Icons.mosque,
            'showDetails': true,
            'habitKey': habitKey,
          };
        }
        // Fallback if no prayer details found
        return {
          'label': l10n.habitPrayers,
          'value': '0 / 5 ${l10n.completed}',
          'isCompleted': false,
          'icon': Icons.mosque,
          'habitKey': habitKey,
        };

      default:
        return {
          'label': habitKey,
          'value': 'Unknown',
          'isCompleted': false,
          'icon': null,
          'habitKey': habitKey,
        };
    }
  }

  Widget _buildPrayersDetailedItem(
    BuildContext context,
    WidgetRef ref,
    HabitModel habit,
    DailyEntryModel? entry,
  ) {
    return FutureBuilder<PrayerDetail?>(
      future: ref.read(databaseProvider).prayerDetailsDao.getPrayerDetails(seasonId, dayIndex),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        
        final details = snapshot.data;
        final fajr = details?.fajr ?? false;
        final dhuhr = details?.dhuhr ?? false;
        final asr = details?.asr ?? false;
        final maghrib = details?.maghrib ?? false;
        final isha = details?.isha ?? false;
        final completedCount = [fajr, dhuhr, asr, maghrib, isha].where((p) => p).length;
        final allCompleted = completedCount == 5;
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PrayersIcon(
                    size: 20,
                    color: allCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      getHabitDisplayName(context, 'prayers'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  Icon(
                    allCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: allCompleted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$completedCount / 5 ${AppLocalizations.of(context)!.completed}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildPrayerStatusChip(context, AppLocalizations.of(context)!.prayerFajr, fajr),
                  _buildPrayerStatusChip(context, AppLocalizations.of(context)!.prayerDhuhr, dhuhr),
                  _buildPrayerStatusChip(context, AppLocalizations.of(context)!.prayerAsr, asr),
                  _buildPrayerStatusChip(context, AppLocalizations.of(context)!.maghrib, maghrib),
                  _buildPrayerStatusChip(context, AppLocalizations.of(context)!.prayerIsha, isha),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrayerStatusChip(BuildContext context, String label, bool completed) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: completed
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color: completed
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: completed ? 2 : 1,
            ),
          ),
          child: completed
              ? Icon(
                  Icons.check,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                )
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 9,
              ),
        ),
      ],
    );
  }

  String _normalizeCurrency(String currency) {
    final symbolToCode = {
      'Rp': 'IDR',
      'RP': 'IDR',
      'S\$': 'SGD',
      '\$': 'USD',
      'RM': 'MYR',
    };
    return symbolToCode[currency] ?? currency.toUpperCase();
  }
}


