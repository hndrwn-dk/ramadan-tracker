import 'dart:async';

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
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/data/providers/completion_score_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/domain/services/streak_shield_service.dart';
import 'package:ramadan_tracker/app/app.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';
import 'package:ramadan_tracker/widgets/habit_toggle.dart';
import 'package:ramadan_tracker/widgets/quran_tracker.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/counter_widget.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/widgets/prayer_details_widget.dart';
import 'package:ramadan_tracker/features/goals/edit_goals_flow.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:flutter/services.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/today/widgets/ramadan_fasting_status_sheet.dart';
import 'package:ramadan_tracker/features/year_round/year_round_navigation.dart';
import 'package:ramadan_tracker/features/year_round/widgets/pre_ramadan_banner.dart';
import 'package:ramadan_tracker/features/year_round/widgets/year_round_actions.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_quest_provider.dart';
import 'package:ramadan_tracker/features/today/widgets/today_fasting_times_card.dart';
import 'package:ramadan_tracker/features/today/widgets/today_habit_trends_card.dart';
import 'package:ramadan_tracker/features/today/widgets/today_home_engagement.dart';
import 'package:ramadan_tracker/features/today/widgets/today_qadha_entry_tile.dart';
import 'package:ramadan_tracker/app/settings_navigation.dart';
import 'package:ramadan_tracker/widgets/settings_icon_button.dart';
import 'package:ramadan_tracker/widgets/donation_icon_button.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/features/today/today_checklist_navigation.dart';
import 'package:ramadan_tracker/features/today/widgets/today_checklist_body.dart';
import 'package:ramadan_tracker/features/today/widgets/today_checklist_sticky_bar.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/widgets/app_back_button.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key, this.checklistOnly = false});

  /// Full-screen daily habit logging (pushed from Today home).
  final bool checklistOnly;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final dayIndex = ref.watch(activeDayIndexForUIProvider);
    final seasonState = ref.watch(seasonStateProvider);

    if (widget.checklistOnly) {
      return seasonAsync.when(
        data: (season) {
          if (season == null) {
            return Scaffold(
              appBar: AppBar(
                leading: const AppBackButton(),
                title: Text(l10n.todayChecklistTitle),
              ),
              body: const YearRoundNoSeasonBody(),
            );
          }
          final last10Start = season.days - 9;
          final showItikaf = dayIndex >= last10Start && dayIndex > 0;
          return _buildChecklistOnlyScaffold(
            season.id,
            dayIndex,
            showItikaf,
          );
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            leading: const AppBackButton(),
            title: Text(l10n.todayChecklistTitle),
          ),
          body: Center(child: Text(l10n.errorMessage(error.toString()))),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nights_stay, size: 24),
                const SizedBox(width: 8),
                Text(
                  seasonAsync.maybeWhen(
                    data: (season) {
                      if (season == null) return l10n.appTitle;
                      if (seasonState == SeasonState.active ||
                          seasonState == SeasonState.preRamadan) {
                        return 'Ramadan';
                      }
                      return l10n.appTitle;
                    },
                    orElse: () => l10n.appTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            seasonAsync.when(
              data: (season) {
                if (season == null) return const SizedBox.shrink();
                final now = DateTime.now();
                final displayDate = season.getDateForDay(dayIndex);
                final dateStr = DateFormat('MMM d, yyyy').format(displayDate);
                String subtitle;
                if (seasonState == SeasonState.preRamadan) {
                  subtitle = l10n.preRamadanWithDate(dateStr);
                } else if (seasonState == SeasonState.postRamadan) {
                  subtitle = l10n.seasonEndedWithDate(dateStr);
                } else {
                  subtitle = '${l10n.dayOfSeason(dayIndex, season.days)} • $dateStr';
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
          const DonationIconButton(),
          const SettingsIconButton(),
        ],
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const YearRoundNoSeasonBody();
          }
          return _buildContent(season.id, dayIndex, season.days, seasonState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorMessage(error.toString()))),
      ),
    );
  }

  Widget _buildChecklistOnlyScaffold(
    int seasonId,
    int dayIndex,
    bool showItikaf,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final season = ref.watch(currentSeasonProvider).value;

    final isSeasonToday = season != null &&
        dayIndex == season.getDayIndex(DateTime.now());
    final title = isSeasonToday
        ? l10n.todayChecklistTitle
        : l10n.dayChecklistTitle(dayIndex);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(title),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)),
          );
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: TodayChecklistBody(
            seasonId: seasonId,
            dayIndex: dayIndex,
            showItikaf: showItikaf,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(int seasonId, int dayIndex, int totalDays, SeasonState state) {
    final scrollBody = RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state == SeasonState.preRamadan) ...[
              const PreRamadanBanner(),
              const SizedBox(height: 16),
            ],
            if (state == SeasonState.postRamadan) ...[
              _buildSeasonEndedCard(seasonId),
              const SizedBox(height: 12),
              const TodayQadhaEntryTile(),
              const SizedBox(height: 24),
              const YearRoundActions(compact: true),
            ],
            if (state == SeasonState.active) ...[
              _buildTimesCard(seasonId, dayIndex, slim: true),
              const SizedBox(height: 12),
              if (_isInLast10Days(dayIndex, totalDays)) ...[
                _buildLast10DaysHeroCard(dayIndex, totalDays),
                const SizedBox(height: 16),
              ],
              _buildHeroCard(seasonId, dayIndex, totalDays),
              const SizedBox(height: 12),
              TodayHabitTrendsCard(seasonId: seasonId, dayIndex: dayIndex),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );

    if (state == SeasonState.active) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: scrollBody),
          TodayChecklistStickyBar(seasonId: seasonId, dayIndex: dayIndex),
        ],
      );
    }

    return scrollBody;
  }

  bool _isInLast10Days(int dayIndex, int totalDays) {
    final last10Start = totalDays - 9;
    return dayIndex >= last10Start && dayIndex > 0;
  }

  Widget _buildLast10DaysHeroCard(int dayIndex, int totalDays) {
    final daysRemaining = totalDays - dayIndex + 1;
    final last10Start = totalDays - 9;
    final positionInLast10 = dayIndex - last10Start + 1;
    
    // Different motivational messages based on position in last 10 days
    String title;
    String message;
    IconData icon;
    
    final l10n = AppLocalizations.of(context)!;
    if (daysRemaining == 1) {
      title = l10n.lastDay;
      message = l10n.lastDayMessage;
      icon = Icons.celebration;
    } else if (daysRemaining <= 3) {
      title = l10n.almostThere;
      message = l10n.almostThereMessage(daysRemaining);
      icon = Icons.flag;
    } else if (positionInLast10 <= 3) {
      title = l10n.last10Days;
      message = l10n.last10DaysMessage;
      icon = Icons.stars;
    } else {
      title = l10n.finalStretch;
      message = l10n.finalStretchMessage;
      icon = Icons.local_fire_department;
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.daysRemaining(daysRemaining),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonEndedCard(int seasonId) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.seasonEnded,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.seasonEndedMessage,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.8),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final narrow = constraints.maxWidth < 340;
                final newSeasonBtn = OutlinedButton.icon(
                  onPressed: () => YearRoundNavigation.openCreateSeason(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n.newSeason),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.5),
                    ),
                  ),
                );
                final insightsBtn = ElevatedButton.icon(
                  onPressed: () => YearRoundNavigation.openYearRoundInsights(ref),
                  icon: const Icon(Icons.insights, size: 18),
                  label: Text(l10n.viewInsights),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.onPrimaryContainer,
                    foregroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      newSeasonBtn,
                      const SizedBox(height: 8),
                      insightsBtn,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: newSeasonBtn),
                    const SizedBox(width: 12),
                    Expanded(child: insightsBtn),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesCard(int seasonId, int dayIndex, {bool slim = false}) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getPrayerTimesWithTimezone(seasonId),
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
                          AppLocalizations.of(context)!.enableLocationForSahurIftar,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to settings
                          },
                          child: Text(AppLocalizations.of(context)!.enableLocation),
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
        final fajrUtc = times['fajr'] as DateTime?;
        final maghribUtc = times['maghrib'] as DateTime?;
        final timezoneStr = times['timezone'] as String? ?? 'UTC';
        final database = ref.read(databaseProvider);
        
        return FutureBuilder<Map<String, dynamic>>(
          future: _getReminderSettings(database),
          builder: (context, settingsSnapshot) {
            final sahurOffset = settingsSnapshot.data?['sahur_offset'] ?? 30;
            final iftarOffset = settingsSnapshot.data?['iftar_offset'] ?? 0;
            
            if (fajrUtc == null || maghribUtc == null) {
              if (slim) {
                return TodayFastingTimesPlaceholder(
                  onEnableLocation: () => openSettingsScreen(context, ref),
                );
              }
              // Show card with message if location not set
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
                              AppLocalizations.of(context)!.enableLocationForSahurIftar,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            TextButton(
                              onPressed: () {
                                openSettingsScreen(context, ref);
                              },
                              child: Text(AppLocalizations.of(context)!.enableLocation),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Convert UTC to target timezone for display (stored times are always UTC)
            DateTime fajr = fajrUtc;
            DateTime maghrib = maghribUtc;
            try {
              if (timezoneStr != 'UTC' && timezoneStr.isNotEmpty) {
                final targetLocation = tz.getLocation(timezoneStr);
                final fajrUtcMoment = fajrUtc.isUtc ? fajrUtc : DateTime.utc(fajrUtc.year, fajrUtc.month, fajrUtc.day, fajrUtc.hour, fajrUtc.minute, fajrUtc.second);
                final maghribUtcMoment = maghribUtc.isUtc ? maghribUtc : DateTime.utc(maghribUtc.year, maghribUtc.month, maghribUtc.day, maghribUtc.hour, maghribUtc.minute, maghribUtc.second);
                final fajrTz = tz.TZDateTime.from(fajrUtcMoment, targetLocation);
                final maghribTz = tz.TZDateTime.from(maghribUtcMoment, targetLocation);
                fajr = DateTime(fajrTz.year, fajrTz.month, fajrTz.day, fajrTz.hour, fajrTz.minute, fajrTz.second);
                maghrib = DateTime(maghribTz.year, maghribTz.month, maghribTz.day, maghribTz.hour, maghribTz.minute, maghribTz.second);
              }
            } catch (_) {
              // Use UTC times if conversion fails
            }
            
            final sahurTime = fajr.subtract(Duration(minutes: sahurOffset));
            final iftarTime = maghrib.add(Duration(minutes: iftarOffset));

            if (slim) {
              return TodayFastingTimesCard(
                sahurTime: sahurTime,
                iftarTime: iftarTime,
                fajr: fajr,
                maghrib: maghrib,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.times,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Tooltip(
                              message: AppLocalizations.of(context)!.refreshTimesTooltip,
                              child: IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                onPressed: () {
                                  _refreshPrayerTimes(seasonId);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.timesForDate(
                            DateFormat('d MMM yyyy').format(fajr),
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.prayerTimesVaryDaily,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                                  AppLocalizations.of(context)!.sahur,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  DateFormat('HH:mm').format(sahurTime),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${DateFormat('HH:mm').format(fajr)} ${AppLocalizations.of(context)!.fajr}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.iftar,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  DateFormat('HH:mm').format(iftarTime),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                Text(
                                  '${DateFormat('HH:mm').format(maghrib)} ${AppLocalizations.of(context)!.maghrib}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                        _TimesCountdownLine(
                          iftarTime: iftarTime,
                          sahurTime: sahurTime,
                          showIftar: true,
                          showSahur: false,
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPrayerOffsetTipBanner(seasonId, fajr, maghrib),
              ],
            );
          },
        );
      },
    );
  }

  /// Returns true if Fajr or Maghrib look off by ~1 hour (e.g. UTC shown as local, or wrong TZ).
  /// For Indonesia/Singapore: Fajr typically 03:00-06:00, Maghrib 17:00-20:00.
  bool _isPrayerTimePlausiblyOffByOneHour(DateTime fajrLocal, DateTime maghribLocal) {
    final fajrHour = fajrLocal.hour;
    final maghribHour = maghribLocal.hour;
    final fajrInRange = fajrHour >= 3 && fajrHour <= 6;
    final maghribInRange = maghribHour >= 17 && maghribHour <= 20;
    return !fajrInRange || !maghribInRange;
  }

  Future<bool> _isPrayerOffsetTipDismissed(int seasonId) async {
    final database = ref.read(databaseProvider);
    final key = 'prayer_offset_tip_dismissed_season_$seasonId';
    final value = await database.kvSettingsDao.getValue(key);
    return value == 'true';
  }

  Future<void> _dismissPrayerOffsetTip(int seasonId) async {
    final database = ref.read(databaseProvider);
    await database.kvSettingsDao.setValue('prayer_offset_tip_dismissed_season_$seasonId', 'true');
    if (mounted) setState(() {});
  }

  Widget _buildPrayerOffsetTipBanner(int seasonId, DateTime fajrLocal, DateTime maghribLocal) {
    if (!_isPrayerTimePlausiblyOffByOneHour(fajrLocal, maghribLocal)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return FutureBuilder<bool>(
      future: _isPrayerOffsetTipDismissed(seasonId),
      builder: (context, snapshot) {
        if (snapshot.data == true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.prayerOffsetTipTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => _dismissPrayerOffsetTip(seasonId),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.prayerOffsetTipBody,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        openSettingsScreen(context, ref, section: 'times');
                      },
                      child: Text(l10n.prayerOffsetTipCta),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, DateTime>> _getPrayerTimes(int seasonId) async {
    final result = await _getPrayerTimesWithTimezone(seasonId);
    if (result.isEmpty) return {};
    return {
      'fajr': result['fajr'] as DateTime,
      'maghrib': result['maghrib'] as DateTime,
    };
  }

  Future<Map<String, dynamic>> _getPrayerTimesWithTimezone(int seasonId) async {
    final database = ref.read(databaseProvider);
    final latStr = await database.kvSettingsDao.getValue('prayer_latitude');
    final lonStr = await database.kvSettingsDao.getValue('prayer_longitude');
    final timezoneStr = await database.kvSettingsDao.getValue('prayer_timezone') ?? 'UTC';
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
      final times = await PrayerTimeService.getCachedOrCalculate(
        database: database,
        seasonId: seasonId,
        date: DateTime.now(),
        latitude: lat,
        longitude: lon,
        timezone: timezoneStr,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdj,
        maghribAdjust: maghribAdj,
      );
      return {
        'fajr': times['fajr'],
        'maghrib': times['maghrib'],
        'timezone': timezoneStr,
      };
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getReminderSettings(AppDatabase database) async {
    final sahurOffset = (int.tryParse(await database.kvSettingsDao.getValue('sahur_offset') ?? '30') ?? 30).clamp(1, 45);
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

  Widget _buildHeroCard(int seasonId, int dayIndex, int totalDays) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final season = ref.watch(currentSeasonProvider).value;
    final isSeasonToday =
        season != null && dayIndex == season.getDayIndex(DateTime.now());
    final checklistLabel = isSeasonToday
        ? l10n.openTodayChecklist
        : l10n.dayChecklistTitle(dayIndex);

    return AppSurface(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TodayHomeGreeting(dayIndex: dayIndex, totalDays: totalDays),
            const SizedBox(height: 16),
            Row(
              children: [
                ref.watch(completionScoreProvider((seasonId: seasonId, dayIndex: dayIndex))).when(
                  data: (score) => ScoreRing(score: score, label: l10n.scoreLabel),
                  loading: () => ScoreRing(score: 0, label: l10n.scoreLabel),
                  error: (_, __) => ScoreRing(score: 0, label: l10n.scoreLabel),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<int>(
                        future: _calculateStreak(seasonId, dayIndex),
                        builder: (context, snapshot) {
                          final streak = snapshot.data ?? 0;
                          return Text(
                            l10n.streakDays(streak),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          );
                        },
                      ),
                      const SizedBox(height: 6),
                      ref.watch(
                        checklistProgressProvider((seasonId: seasonId, dayIndex: dayIndex)),
                      ).when(
                        data: (progress) => Text(
                          l10n.doneCount(progress.completed, progress.total),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.75),
                              ),
                        ),
                        loading: () => Text(l10n.doneCount(0, 0)),
                        error: (_, __) => Text(l10n.doneCount(0, 0)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            TodayJourneyMiniStrip(seasonId: seasonId, dayIndex: dayIndex),
            const SizedBox(height: 16),
            Text(
              l10n.todayHomeLogPrompt,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _openTodayChecklistScreen,
              icon: const Icon(Icons.checklist_rounded),
              label: Text(checklistLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditGoalsFlow(seasonId: seasonId),
                    ),
                  );
                },
                child: Text(l10n.editGoals),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTodayChecklistScreen() {
    final dayIndex = ref.read(activeDayIndexForUIProvider);
    openDayChecklist(context, ref, dayIndex: dayIndex, switchToTodayTab: false);
  }

  Widget _buildOneTapTodayCard(
    int seasonId,
    int dayIndex,
    AsyncValue<List<dynamic>> habitsAsync,
    AsyncValue<List<dynamic>> seasonHabitsAsync,
    AsyncValue<List<dynamic>> entriesAsync,
    bool showItikaf, {
    bool bareList = false,
  }) {
    final habitList = habitsAsync.when(
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
          error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingEntries),
        ),
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingHabits),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingHabits),
    );

    if (bareList) {
      return habitList;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.oneTapToday,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            habitList,
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
    final habitOrder = ['fasting', 'quran_pages', 'dhikr', 'taraweeh', 'sedekah', 'prayers', 'tahajud', 'itikaf'];
    final sortedHabits = <Widget>[];

    // Debug logging
    debugPrint('=== _buildHabitsList: seasonId=$seasonId, dayIndex=$dayIndex ===');
    debugPrint('  Total habits: ${habits.length}');
    debugPrint('  Total seasonHabits: ${seasonHabits.length}');
    debugPrint('  Total entries: ${entries.length}');
    debugPrint('  showItikaf: $showItikaf');
    for (final sh in seasonHabits) {
      final habit = (habits as List).where((h) => h.id == sh.habitId).firstOrNull;
      debugPrint('  SeasonHabit: habitId=${sh.habitId}, habitKey=${habit?.key}, isEnabled=${sh.isEnabled}');
    }

    final fastingHabit = (habits as List).where((h) => h.key == 'fasting').firstOrNull;
    final fastingEntry = fastingHabit != null
        ? (entries as List).where((e) => e.habitId == fastingHabit.id).firstOrNull
        : null;
    final fastingStatus = fastingEntry != null
        ? FastingStatus.fromEntry(fastingEntry.valueInt, fastingEntry.valueBool)
        : FastingStatus.notDone;
    final isDayHaidOrNifas = FastingStatus.isHaidOrNifas(fastingStatus);

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
            : habitKey == 'itikaf'
                ? ItikafIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                : habitKey == 'taraweeh'
                    ? TaraweehIcon(size: 20, color: Theme.of(context).textTheme.bodyMedium?.color)
                    : null;

        debugPrint('  Adding bool habit to UI: $habitKey (value=$value)');
        
        // Prayers always use detailed mode (track each prayer individually)
        if (habitKey == 'prayers') {
          if (isDayHaidOrNifas) {
            sortedHabits.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHaidNifasExcusedCard(context, getHabitDisplayName(context, habitKey)),
              ),
            );
          } else {
            sortedHabits.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _wrapHabitInCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: PrayerDetailsWidget(
                      seasonId: seasonId,
                      dayIndex: dayIndex,
                    ),
                  ),
                ),
              ),
            );
          }
        } else if (habitKey == 'taraweeh') {
          if (isDayHaidOrNifas) {
            sortedHabits.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildHaidNifasExcusedCard(context, getHabitDisplayName(context, habitKey)),
              ),
            );
          } else {
            final rakaat = entry?.valueInt;
            final isDone = entry?.valueBool ?? false;
            sortedHabits.add(
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _wrapHabitInCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildTaraweehRakaatContent(
                      seasonId: seasonId,
                      dayIndex: dayIndex,
                      habitId: habit.id,
                      isDone: isDone,
                      selectedRakaat: rakaat,
                    ),
                  ),
                ),
              ),
            );
          }
        } else if (habitKey == 'fasting') {
          final fastingStatus = FastingStatus.fromEntry(entry?.valueInt, entry?.valueBool);
          final isCompleted = FastingStatus.isCompletedForDay(entry?.valueInt, entry?.valueBool);
          sortedHabits.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildFastingRow(
                seasonId: seasonId,
                dayIndex: dayIndex,
                habitId: habit.id,
                status: fastingStatus,
                isCompleted: isCompleted,
                note: entry?.note,
              ),
            ),
          );
        } else if (habitKey == 'tahajud' && isDayHaidOrNifas) {
          sortedHabits.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHaidNifasExcusedCard(context, getHabitDisplayName(context, habitKey)),
            ),
          );
        } else {
          // Other boolean habits (HabitToggle has its own border)
          sortedHabits.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HabitToggle(
                label: getHabitDisplayName(context, habitKey),
                value: value,
                icon: icon,
                iconWidget: iconWidget,
                onTap: () {
                  _toggleBoolHabit(seasonId, dayIndex, habit.id, !value);
                },
              ),
            ),
          );
        }
      } else if (habitKey == 'quran_pages') {
        debugPrint('  Adding quran_pages to UI');
        if (isDayHaidOrNifas) {
          sortedHabits.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHaidNifasExcusedCard(context, getHabitDisplayName(context, habitKey)),
            ),
          );
        } else {
          sortedHabits.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _wrapHabitInCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: QuranTracker(
                    seasonId: seasonId,
                    dayIndex: dayIndex,
                    habitId: habit.id,
                  ),
                ),
              ),
            ),
          );
        }
      } else if (habitKey == 'dhikr') {
        final value = entry?.valueInt ?? 0;
        debugPrint('  Adding dhikr to UI (value=$value)');
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _wrapHabitInCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FutureBuilder<int>(
                  future: ref.read(databaseProvider).dhikrPlanDao.getPlan(seasonId).then((plan) => plan?.dailyTarget ?? 100),
                  builder: (context, snapshot) {
                    final target = snapshot.data ?? 100;
                    return CounterWidget(
                      label: getHabitDisplayName(context, habitKey),
                      value: value,
                      target: target,
                      targetLabel: AppLocalizations.of(context)!.ofDhikr(target),
                      icon: Icons.favorite,
                      iconWidget: DhikrIcon(size: 20, color: Theme.of(context).colorScheme.primary),
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
                    );
                  },
                ),
              ),
            ),
          ),
        );
      } else if (habitKey == 'sedekah') {
        debugPrint('  Adding sedekah to UI');
        sortedHabits.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _wrapHabitInCard(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SedekahTracker(
                  seasonId: seasonId,
                  dayIndex: dayIndex,
                  habitId: habit.id,
                ),
              ),
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

  Future<int> _calculateStreak(int seasonId, int dayIndex) async {
    final database = ref.read(databaseProvider);
    return await CompletionService.calculateStreak(
      seasonId: seasonId,
      currentDayIndex: dayIndex,
      database: database,
    );
  }

  Future<void> _onEngagementUpdate(int seasonId, int dayIndex) async {
    final database = ref.read(databaseProvider);
    await StreakShieldService.tryConsumeForExcusedDay(
      database: database,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );
    await evaluateAchievements(ref, seasonId: seasonId, dayIndex: dayIndex);
    await refreshDailyQuests(ref, seasonId: seasonId, dayIndex: dayIndex);
  }

  Future<void> _toggleBoolHabit(int seasonId, int dayIndex, int habitId, bool value) async {
    HapticFeedback.lightImpact();
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setBoolValue(seasonId, dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    await _onEngagementUpdate(seasonId, dayIndex);
  }

  Future<void> _setTaraweehRakaat(int seasonId, int dayIndex, int habitId, int? rakaat) async {
    HapticFeedback.lightImpact();
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setBoolAndIntValue(
      seasonId,
      dayIndex,
      habitId,
      rakaat != null,
      rakaat,
    );
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    await _onEngagementUpdate(seasonId, dayIndex);
  }

  Widget _buildHaidNifasExcusedCard(BuildContext context, String habitLabel) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(isDark ? 0.6 : 0.8),
          width: 1,
        ),
        color: Colors.amber.withOpacity(isDark ? 0.12 : 0.08),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.amber.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  habitLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.excused,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fastingStatusLabel(int status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case FastingStatus.fasted:
        return l10n.fastingStatusFasted;
      case FastingStatus.excusedSick:
        return l10n.fastingStatusExcusedSick;
      case FastingStatus.excusedNifas:
        return l10n.fastingStatusExcusedNifas;
      case FastingStatus.excusedHaid:
        return l10n.fastingStatusExcusedHaid;
      case FastingStatus.excusedOther:
        return l10n.fastingStatusExcusedOther;
      default:
        return l10n.fastingStatusNotDone;
    }
  }

  Widget _buildFastingRow({
    required int seasonId,
    required int dayIndex,
    required int habitId,
    required int status,
    required bool isCompleted,
    String? note,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = status == FastingStatus.excusedOther && note != null && note.isNotEmpty
        ? '${_fastingStatusLabel(status)}: $note'
        : _fastingStatusLabel(status);
    return InkWell(
      onTap: () => _showFastingOptionsSheet(seasonId, dayIndex, habitId, currentStatus: status, currentNote: note),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: AppSurface.nestedDecoration(
          context,
          color: AppSurface.fillColor(context),
          borderRadius: 12,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(
                    Icons.no_meals,
                    size: 20,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.habitFasting,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: isCompleted
                    ? null
                    : Border.all(
                        color: AppSurface.borderColor(context),
                        width: 2,
                      ),
              ),
              child: Icon(
                isCompleted ? Icons.check : Icons.circle,
                size: 18,
                color: isCompleted
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showFastingOptionsSheet(int seasonId, int dayIndex, int habitId, {int? currentStatus, String? currentNote}) async {
    HapticFeedback.lightImpact();
    final season = await ref.read(currentSeasonProvider.future);
    if (!mounted) return;
    final date = season?.getDateForDay(dayIndex);

    final result = await showRamadanFastingStatusSheet(
      context,
      dayIndex: dayIndex,
      date: date,
      currentStatus: currentStatus,
      currentNote: currentNote,
    );

    if (result == null || !mounted) return;

    await _setFastingStatus(
      seasonId,
      dayIndex,
      habitId,
      result.status,
      note: result.note,
    );

    if (!mounted) return;
    final s = SunnahStrings.of(context);
    final message = ramadanFastingSavedMessage(s, result.status);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }

  Future<void> _setFastingStatus(int seasonId, int dayIndex, int habitId, int status, {String? note}) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setFastingStatus(seasonId, dayIndex, habitId, status, note: note);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    await _onEngagementUpdate(seasonId, dayIndex);
  }

  Widget _wrapHabitInCard({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? Colors.white.withOpacity(0.12) : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: child,
    );
  }

  Widget _buildTaraweehRakaatContent({
    required int seasonId,
    required int dayIndex,
    required int habitId,
    required bool isDone,
    required int? selectedRakaat,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            TaraweehIcon(
              size: 20,
              color: isDone
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
            const SizedBox(width: 12),
            Text(
              getHabitDisplayName(context, 'taraweeh'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _TaraweehRakaatChip(
                label: l10n.taraweehRakaat11,
                isSelected: selectedRakaat == 11,
                onTap: () {
                  _setTaraweehRakaat(seasonId, dayIndex, habitId, selectedRakaat == 11 ? null : 11);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TaraweehRakaatChip(
                label: l10n.taraweehRakaat23,
                isSelected: selectedRakaat == 23,
                onTap: () {
                  _setTaraweehRakaat(seasonId, dayIndex, habitId, selectedRakaat == 23 ? null : 23);
                },
              ),
            ),
          ],
        ),
        FutureBuilder<({int totalRakaat, int targetRakaat})?>(
          future: _getTaraweehSeasonProgress(seasonId, habitId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) return const SizedBox.shrink();
            final d = snapshot.data!;
            if (d.targetRakaat <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                l10n.taraweehRakaatProgress(d.totalRakaat, d.targetRakaat),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<({int totalRakaat, int targetRakaat})?> _getTaraweehSeasonProgress(int seasonId, int habitId) async {
    final database = ref.read(databaseProvider);
    final season = await ref.read(currentSeasonProvider.future);
    if (season == null) return null;
    final entries = await database.dailyEntriesDao.getAllSeasonEntries(seasonId);
    final totalRakaat = entries.where((e) => e.habitId == habitId).fold<int>(0, (s, e) => s + (e.valueInt ?? 0));
    final raw = await database.kvSettingsDao.getValue('taraweeh_rakaat_per_day');
    final perDay = int.tryParse(raw ?? '') ?? 11;
    final targetRakaat = perDay * season.days;
    return (totalRakaat: totalRakaat, targetRakaat: targetRakaat);
  }

  Future<void> _setIntHabit(int seasonId, int dayIndex, int habitId, int value) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setIntValue(seasonId, dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    await _onEngagementUpdate(seasonId, dayIndex);
  }

  Future<void> _setNote(int seasonId, int dayIndex, int habitId, String? note) async {
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setNote(seasonId, dayIndex, habitId, note);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
  }
}

class _TaraweehRakaatChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TaraweehRakaatChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimesCountdownLine extends StatefulWidget {
  const _TimesCountdownLine({
    required this.iftarTime,
    required this.sahurTime,
    required this.showIftar,
    required this.showSahur,
  });
  final DateTime iftarTime;
  final DateTime sahurTime;
  final bool showIftar;
  final bool showSahur;

  @override
  State<_TimesCountdownLine> createState() => _TimesCountdownLineState();
}

class _TimesCountdownLineState extends State<_TimesCountdownLine> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  static String _formatCountdown(Duration d) {
    if (d.inHours >= 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      final s = d.inSeconds % 60;
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _formatTime(DateTime t) {
    return DateFormat('HH:mm').format(t);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final l10n = AppLocalizations.of(context)!;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w500,
    );
    final List<Widget> lines = [];

    if (widget.showIftar) {
      if (now.isBefore(widget.iftarTime)) {
        final d = widget.iftarTime.difference(now);
        lines.add(Text(l10n.iftarIn(_formatCountdown(d)), style: style));
      } else {
        lines.add(Text(l10n.iftarPassed(_formatTime(widget.iftarTime)), style: style));
      }
    }

    if (widget.showSahur) {
      if (now.isBefore(widget.sahurTime)) {
        final d = widget.sahurTime.difference(now);
        lines.add(Text(l10n.sahurIn(_formatCountdown(d)), style: style));
      } else {
        lines.add(Text(l10n.sahurPassed(_formatTime(widget.sahurTime)), style: style));
      }
    }

    if (lines.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) children.add(const SizedBox(height: 4));
      children.add(lines[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

