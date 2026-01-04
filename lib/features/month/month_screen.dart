import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/features/month/widgets/month_legend_compact.dart';
import 'package:ramadan_tracker/features/month/widgets/day_summary_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class MonthScreen extends ConsumerWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(l10n.monthViewTitle),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return Center(child: Text(l10n.noSeasonFound));
          }
          return _buildMonthGrid(context, ref, season.id, season.days);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorMessage(error.toString()))),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, WidgetRef ref, int seasonId, int days) {
    final currentDayIndex = ref.watch(currentDayIndexProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    final l10n = AppLocalizations.of(context)!;
    return seasonAsync.when(
      data: (season) {
        if (season == null) {
          return Center(child: Text(l10n.noSeasonFound));
        }
        
        // Calculate last 10 days based on season days, not calendar
        final last10Start = season.days - 9;
        
        return Column(
          children: [
            const MonthLegendCompact(),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: days,
                itemBuilder: (context, index) {
                  final dayIndex = index + 1;
                  final isToday = dayIndex == currentDayIndex;
                  final isLast10 = dayIndex >= last10Start && dayIndex <= season.days;
                  final isInSeason = dayIndex >= 1 && dayIndex <= season.days;
                  
                  final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
                  final seasonHabitsAsync = ref.watch(seasonHabitsProvider(seasonId));
                  final habitsAsync = ref.watch(habitsProvider);
                  final database = ref.watch(databaseProvider);

                  return _buildDayCell(
                    context,
                    ref,
                    seasonId,
                    dayIndex,
                    isToday,
                    isLast10,
                    isInSeason,
                    entriesAsync,
                    seasonHabitsAsync,
                    habitsAsync,
                    database,
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.errorLoadingSeason)),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    WidgetRef ref,
    int seasonId,
    int dayIndex,
    bool isToday,
    bool isLast10,
    bool isInSeason,
    AsyncValue<List<DailyEntryModel>> entriesAsync,
    AsyncValue<List<SeasonHabitModel>> seasonHabitsAsync,
    AsyncValue<List<HabitModel>> habitsAsync,
    AppDatabase database,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isInSeason
                ? () {
                    _showDaySummary(context, ref, seasonId, dayIndex);
                  }
                : () {
                    final l10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.outsideSeason),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
            borderRadius: BorderRadius.circular(16),
            child: Opacity(
              opacity: isInSeason ? 1.0 : 0.4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: isToday
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primaryContainer,
                            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
                          ],
                        )
                      : null,
                  color: isToday ? null : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    width: isToday ? 2.5 : 1,
                  ),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Transform.scale(
                        scale: 0.9,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$dayIndex',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                    color: isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                    fontSize: 12,
                                  ),
                            ),
                            entriesAsync.when(
                              data: (entries) {
                                return seasonHabitsAsync.when(
                                  data: (seasonHabits) {
                                    return habitsAsync.when(
                                      data: (allHabits) {
                                        final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();
                                        
                                        if (enabledHabits.isEmpty) {
                                          return const SizedBox.shrink();
                                        }
                                        
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
                                            final hasEntries = entries.isNotEmpty;
                                            
                                            // Ring with opacity fill based on completion
                                            if (hasEntries || score > 0) {
                                              final opacity = (score / 100).clamp(0.0, 1.0);
                                              return Container(
                                                width: 16,
                                                height: 16,
                                                margin: const EdgeInsets.only(top: 2),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    width: 2,
                                                  ),
                                                  color: score >= 100
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.3),
                                                ),
                                                child: score >= 100
                                                    ? Center(
                                                        child: Icon(
                                                          Icons.check,
                                                          size: 10,
                                                          color: Theme.of(context).colorScheme.onPrimary,
                                                        ),
                                                      )
                                                    : null,
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        );
                                      },
                                      loading: () => const SizedBox(
                                        width: 12,
                                        height: 12,
                                        child: CircularProgressIndicator(strokeWidth: 1.5),
                                      ),
                                      error: (_, __) => const SizedBox.shrink(),
                                    );
                                  },
                                  loading: () => const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 1.5),
                                  ),
                                  error: (_, __) => const SizedBox.shrink(),
                                );
                              },
                              loading: () => const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 1.5),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isLast10 && isInSeason)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Icon(
                Icons.star,
                size: 10,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
          ),
      ],
    );
  }

  void _showDaySummary(BuildContext context, WidgetRef ref, int seasonId, int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => DaySummarySheet(
          seasonId: seasonId,
          dayIndex: dayIndex,
        ),
      ),
    );
  }

}


