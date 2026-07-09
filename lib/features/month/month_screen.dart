import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_month_view.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/features/month/widgets/month_legend_compact.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/features/month/widgets/day_summary_sheet.dart';
import 'package:ramadan_tracker/data/providers/achievement_days_provider.dart';
import 'package:ramadan_tracker/features/month/widgets/month_journey_card.dart';
import 'package:ramadan_tracker/features/month/widgets/season_trophy_sheet.dart';
import 'package:ramadan_tracker/features/engagement/widgets/coach_mark_tip.dart';
import 'package:ramadan_tracker/domain/services/coach_mark_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/settings_icon_button.dart';

class MonthScreen extends ConsumerWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final seasonState = ref.watch(seasonStateProvider);
    final sunnahStrings = SunnahStrings.of(context);
    final useSunnahMode = seasonState.isYearRoundMode;

    return _MonthTrophyScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            useSunnahMode ? sunnahStrings.sunnahMonthViewTitle : l10n.monthViewTitle,
          ),
          actions: const [SettingsIconButton()],
        ),
        body: seasonAsync.when(
          data: (season) {
            if (useSunnahMode) {
              return const SunnahMonthView();
            }
            if (season == null) {
              return const SunnahMonthView();
            }
            return buildMonthGrid(context, ref, season.id, season.days);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(l10n.errorMessage(error.toString()))),
        ),
      ),
    );
  }
}

class _MonthTrophyScope extends ConsumerStatefulWidget {
  final Widget child;
  const _MonthTrophyScope({required this.child});

  @override
  ConsumerState<_MonthTrophyScope> createState() => _MonthTrophyScopeState();
}

class _MonthTrophyScopeState extends ConsumerState<_MonthTrophyScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SeasonTrophySheet.showIfNeeded(context, ref);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget buildMonthGrid(BuildContext context, WidgetRef ref, int seasonId, int days) {
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
        const horizontalPad = 20.0;
        const gridGap = 10.0;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 0),
              child: CoachMarkTip(
                coachKey: CoachMarkService.monthCalendar,
                message: AppLocalizations.of(context)!.coachMarkMonthCalendar,
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 0),
              child: MonthJourneyCard(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 0),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: AppSurface(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        crossAxisSpacing: gridGap,
                        mainAxisSpacing: gridGap,
                        childAspectRatio: 1,
                      ),
                      itemCount: days,
                      itemBuilder: (context, index) {
                        final dayIndex = index + 1;
                        final isToday = dayIndex == currentDayIndex;
                        final isLast10 =
                            dayIndex >= last10Start && dayIndex <= season.days;
                        final isInSeason =
                            dayIndex >= 1 && dayIndex <= season.days;

                        final entriesAsync = ref.watch(
                          dailyEntriesProvider(
                            (seasonId: seasonId, dayIndex: dayIndex),
                          ),
                        );
                        final seasonHabitsAsync =
                            ref.watch(seasonHabitsProvider(seasonId));
                        final habitsAsync = ref.watch(habitsProvider);
                        final database = ref.watch(databaseProvider);

                        final achievementDays =
                            ref.watch(achievementDayIndicesProvider).valueOrNull ??
                                const <int>{};

                        return buildMonthDayCell(
                          context,
                          ref,
                          seasonId,
                          dayIndex,
                          isToday,
                          isLast10,
                          isInSeason,
                          achievementDays.contains(dayIndex),
                          entriesAsync,
                          seasonHabitsAsync,
                          habitsAsync,
                          database,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(horizontalPad, 12, horizontalPad, 20),
              child: MonthLegendCompact(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: Text(l10n.errorLoadingSeason)),
    );
  }

Widget buildMonthDayCell(
    BuildContext context,
    WidgetRef ref,
    int seasonId,
    int dayIndex,
    bool isToday,
    bool isLast10,
    bool isInSeason,
    bool hasAchievement,
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
                    showMonthDaySummary(context, ref, seasonId, dayIndex);
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
                width: double.infinity,
                height: double.infinity,
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
                  color: isToday ? null : AppSurface.cellFillColor(context),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : AppSurface.borderColor(context),
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
                      : null,
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
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
                                    fontSize: 11,
                                    height: 1.1,
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
                                            Widget scoreWidget = const SizedBox.shrink();
                                            if (hasEntries || score > 0) {
                                              final opacity = (score / 100).clamp(0.0, 1.0);
                                              scoreWidget = Container(
                                                width: 14,
                                                height: 14,
                                                margin: const EdgeInsets.only(top: 1),
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Theme.of(context).colorScheme.primary,
                                                    width: 1.5,
                                                  ),
                                                  color: score >= 100
                                                      ? Theme.of(context).colorScheme.primary
                                                      : Theme.of(context).colorScheme.primary.withOpacity(opacity * 0.3),
                                                ),
                                                child: score >= 100
                                                    ? Center(
                                                        child: Icon(
                                                          Icons.check,
                                                          size: 9,
                                                          color: Theme.of(context).colorScheme.onPrimary,
                                                        ),
                                                      )
                                                    : null,
                                              );
                                            }
                                            return scoreWidget;
                                          },
                                        );
                                      },
                                      loading: () => const SizedBox(
                                        width: 10,
                                        height: 10,
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
                                width: 10,
                                height: 10,
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
        if (hasAchievement && isInSeason)
          Positioned(
            top: -2,
            left: -2,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.surface,
                  width: 1,
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

void showMonthDaySummary(BuildContext context, WidgetRef ref, int seasonId, int dayIndex) {
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


