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
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final dayIndex = ref.watch(activeDayIndexForUIProvider);
    final seasonState = ref.watch(seasonStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.nights_stay, size: 24),
                const SizedBox(width: 8),
                Text(l10n.appTitle),
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
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {
              setState(() {
                _focusMode = !_focusMode;
              });
            },
            tooltip: l10n.focusMode,
          ),
        ],
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return _buildNoSeasonView();
          }
          return _buildContent(season.id, dayIndex, season.days, seasonState);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorMessage(error.toString()))),
      ),
    );
  }

  Widget _buildContent(int seasonId, int dayIndex, int totalDays, SeasonState state) {
    final habitsAsync = ref.watch(habitsProvider);
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(seasonId));
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
    // Calculate showItikaf based on the displayed dayIndex, not current day
    final last10Start = totalDays - 9;
    final showItikaf = dayIndex >= last10Start && dayIndex > 0;

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
                AppLocalizations.of(context)!.preRamadan,
                AppLocalizations.of(context)!.preRamadanSubtitle,
                Icons.calendar_today,
              ),
            if (state == SeasonState.postRamadan)
              _buildSeasonEndedCard(seasonId),
            if (state != SeasonState.active) const SizedBox(height: 16),
            // Only show tracking content if season is active
            if (state == SeasonState.active) ...[
              if (!_focusMode) ...[
                // Show Last 10 Days Hero Card if in last 10 days
                if (_isInLast10Days(dayIndex, totalDays)) ...[
                  _buildLast10DaysHeroCard(dayIndex, totalDays),
                  const SizedBox(height: 16),
                ],
                _buildHeroCard(seasonId, dayIndex, habitsAsync, seasonHabitsAsync, entriesAsync),
                const SizedBox(height: 16),
                _buildTimesCard(seasonId, dayIndex),
                const SizedBox(height: 16),
              ],
              entriesAsync.when(
                data: (entries) {
                  if (entries.isEmpty) {
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
          ],
        ),
      ),
    );
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

  Widget _buildNoSeasonView() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.noSeasonFound,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.createNewSeasonMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Settings tab
                ref.read(tabIndexProvider.notifier).state = 4;
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.createNewSeason),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                // Restart onboarding
                ref.invalidate(shouldShowOnboardingProvider);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const MainScreen(),
                  ),
                  (route) => false,
                );
              },
              child: Text(l10n.startSetup),
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to Settings tab
                      ref.read(tabIndexProvider.notifier).state = 4;
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.newSeason),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to Insights tab
                      ref.read(tabIndexProvider.notifier).state = 3;
                    },
                    icon: const Icon(Icons.insights, size: 18),
                    label: Text(l10n.viewInsights),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimesCard(int seasonId, int dayIndex) {
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
            final showIftarCountdown = settingsSnapshot.data?['show_iftar_countdown'] ?? true;
            final showSahurCountdown = settingsSnapshot.data?['show_sahur_countdown'] ?? false;
            
            if (fajrUtc == null || maghribUtc == null) {
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
                                // Navigate to settings
                                ref.read(tabIndexProvider.notifier).state = 4;
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
                          showIftar: showIftarCountdown,
                          showSahur: showSahurCountdown,
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
                        ref.read(openSettingsSectionProvider.notifier).state = 'times';
                        ref.read(tabIndexProvider.notifier).state = 4;
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

  Widget _buildStartHereCard(int seasonId, int dayIndex) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.todayIn10Seconds,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.todayIn10SecondsMessage,
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
                    child: Text(l10n.openOneTap),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to Edit Goals flow
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditGoalsFlow(seasonId: seasonId),
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
                    child: Text(l10n.editGoals),
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
                // Use completion score provider which auto-refreshes when entries or quran daily changes
                ref.watch(completionScoreProvider((seasonId: seasonId, dayIndex: dayIndex))).when(
                  data: (score) => ScoreRing(score: score),
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
                      AppLocalizations.of(context)!.streakDays(streak),
                      style: Theme.of(context).textTheme.titleLarge,
                    );
                      },
                    ),
                    const SizedBox(height: 8),
                    seasonHabitsAsync.when(
                      data: (seasonHabits) => entriesAsync.when(
                        data: (entries) {
                          return habitsAsync.when(
                            data: (allHabits) {
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
                                    AppLocalizations.of(context)!.doneCount(result['completed']!, result['total']!),
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  );
                                },
                              );
                            },
                            loading: () => Text(AppLocalizations.of(context)!.doneCount(0, 0)),
                            error: (_, __) => Text(AppLocalizations.of(context)!.doneCount(0, 0)),
                          );
                        },
                        loading: () => Text(AppLocalizations.of(context)!.doneCount(0, 0)),
                        error: (_, __) => Text(AppLocalizations.of(context)!.doneCount(0, 0)),
                      ),
                      loading: () => Text(AppLocalizations.of(context)!.doneCount(0, 0)),
                      error: (_, __) => Text(AppLocalizations.of(context)!.doneCount(0, 0)),
                    ),
                  ],
                ),
              ],
            ),
            // Reflection snippet if available
            FutureBuilder<List<Note>>(
              future: ref.read(databaseProvider).notesDao.getDayNotes(seasonId, dayIndex),
              builder: (context, noteSnapshot) {
                final notes = noteSnapshot.data ?? [];
                final note = notes.isNotEmpty ? notes.first : null;
                if (note != null && note.body.isNotEmpty) {
                  final preview = note.body.length > 60 ? '${note.body.substring(0, 60)}...' : note.body;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.edit_note,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              preview,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
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
              AppLocalizations.of(context)!.oneTapToday,
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
                  error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingEntries),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingHabits),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => Text(AppLocalizations.of(context)!.errorLoadingHabits),
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
        } else if (habitKey == 'taraweeh') {
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

  Widget _buildReflectionCard(int seasonId, int dayIndex) {
    return FutureBuilder<List<Note>>(
      future: ref.read(databaseProvider).notesDao.getDayNotes(seasonId, dayIndex),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];
        final note = notes.isNotEmpty ? notes.first : null;
        _reflectionController.text = note?.body ?? '';
        final currentMood = note?.mood;

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
                      AppLocalizations.of(context)!.reflection,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (currentMood != null)
                      _buildMoodChip(currentMood),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.howWasToday,
                  ),
                  onChanged: (text) {
                    _saveReflection(seasonId, dayIndex, text.isEmpty ? null : text, currentMood, note?.id);
                  },
                  onSubmitted: (_) {
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 12),
                // Mood selector
                Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  children: [
                    _buildMoodButton('excellent', currentMood == 'excellent', () {
                      _saveReflection(seasonId, dayIndex, _reflectionController.text.isEmpty ? null : _reflectionController.text, 'excellent', note?.id);
                    }),
                    _buildMoodButton('good', currentMood == 'good', () {
                      _saveReflection(seasonId, dayIndex, _reflectionController.text.isEmpty ? null : _reflectionController.text, 'good', note?.id);
                    }),
                    _buildMoodButton('ok', currentMood == 'ok', () {
                      _saveReflection(seasonId, dayIndex, _reflectionController.text.isEmpty ? null : _reflectionController.text, 'ok', note?.id);
                    }),
                    _buildMoodButton('difficult', currentMood == 'difficult', () {
                      _saveReflection(seasonId, dayIndex, _reflectionController.text.isEmpty ? null : _reflectionController.text, 'difficult', note?.id);
                    }),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodChip(String mood) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color) = _getMoodIconAndColor(mood);
    String moodLabel;
    switch (mood) {
      case 'excellent':
        moodLabel = l10n.moodExcellent;
        break;
      case 'good':
        moodLabel = l10n.moodGood;
        break;
      case 'ok':
        moodLabel = l10n.moodOk;
        break;
      case 'difficult':
        moodLabel = l10n.moodDifficult;
        break;
      default:
        moodLabel = mood[0].toUpperCase() + mood.substring(1);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            moodLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String mood, bool isSelected, VoidCallback onTap) {
    final l10n = AppLocalizations.of(context)!;
    final (icon, color) = _getMoodIconAndColor(mood);
    String moodLabel;
    switch (mood) {
      case 'excellent':
        moodLabel = l10n.moodExcellent;
        break;
      case 'good':
        moodLabel = l10n.moodGood;
        break;
      case 'ok':
        moodLabel = l10n.moodOk;
        break;
      case 'difficult':
        moodLabel = l10n.moodDifficult;
        break;
      default:
        moodLabel = mood[0].toUpperCase() + mood.substring(1);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outline.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                moodLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _getMoodIconAndColor(String mood) {
    switch (mood) {
      case 'excellent':
        return (Icons.sentiment_very_satisfied, Colors.green);
      case 'good':
        return (Icons.sentiment_satisfied, Colors.blue);
      case 'ok':
        return (Icons.sentiment_neutral, Colors.orange);
      case 'difficult':
        return (Icons.sentiment_very_dissatisfied, Colors.red);
      default:
        return (Icons.sentiment_neutral, Colors.grey);
    }
  }

  Future<void> _saveReflection(int seasonId, int dayIndex, String? text, String? mood, int? noteId) async {
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
                mood: mood,
                createdAt: note.createdAt,
              ),
            );
          }
        } else {
        await database.notesDao.createNote(
          seasonId: seasonId,
          dayIndex: dayIndex,
          body: text,
          mood: mood,
        );
      }
    }
    // Invalidate to refresh UI
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
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
    
    // Debug: log entries received
    debugPrint('_calculateCompletedCount: Received ${entries.length} entries for seasonId=$seasonId, dayIndex=$dayIndex');
    for (final e in entries) {
      debugPrint('  Entry: habitId=${e.habitId}, valueInt=${e.valueInt}, valueBool=${e.valueBool}, isCompleted=${e.isCompleted}');
    }
    
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
      
      // Find entry - ensure we're matching correctly
      final entry = entries.where((e) => 
        e.habitId == habit.habitId && 
        e.seasonId == seasonId && 
        e.dayIndex == dayIndex
      ).firstOrNull;
      
      // If no entry found, create a default one
      final finalEntry = entry ?? DailyEntryModel(
        seasonId: seasonId,
        dayIndex: dayIndex,
        habitId: habit.habitId,
        updatedAt: DateTime.now(),
      );
      
      debugPrint('Checking habit: $habitKey (habitId=${habit.habitId}), entry found: ${entry != null}, valueInt: ${finalEntry.valueInt}, valueBool: ${finalEntry.valueBool}');

      bool isCompleted = false;
      
      // Count habits (quran_pages, dhikr, sedekah) should be checked based on target
      if (habitKey == 'quran_pages') {
        // Quran uses QuranDaily table, not DailyEntries
        final target = quranPlan?.dailyTargetPages ?? 20;
        if (target > 0) {
          final currentValue = quranDaily?.pagesRead ?? 0;
          isCompleted = currentValue >= target;
          debugPrint('Quran: currentValue=$currentValue, target=$target, isCompleted=$isCompleted');
        } else {
          final currentValue = quranDaily?.pagesRead ?? 0;
          isCompleted = currentValue > 0;
        }
      } else if (habitKey == 'dhikr') {
        // Dhikr target from DhikrPlan
        final target = dhikrPlan?.dailyTarget ?? 100;
        if (target > 0) {
          final currentValue = finalEntry.valueInt ?? 0;
          isCompleted = currentValue >= target;
        } else {
          isCompleted = (finalEntry.valueInt ?? 0) > 0;
        }
      } else if (habitKey == 'sedekah') {
        // Sedekah target from KvSettings
        if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
          final target = double.tryParse(sedekahGoalAmount) ?? 0;
          if (target > 0) {
            // Convert valueInt to double for accurate comparison
            final currentValue = (finalEntry.valueInt ?? 0).toDouble();
            isCompleted = currentValue >= target;
          } else {
            isCompleted = (finalEntry.valueInt ?? 0) > 0;
          }
        } else {
          // If sedekah goal disabled, consider completed if value > 0
          isCompleted = (finalEntry.valueInt ?? 0) > 0;
        }
      } else {
        // Boolean habits (fasting, taraweeh, itikaf, prayers)
        isCompleted = finalEntry.isCompleted;
      }

      if (isCompleted) {
        completedCount++;
        debugPrint('Habit completed: $habitKey');
      } else {
        // Debug: log which habit is not completed
        debugPrint('Habit not completed: $habitKey (valueInt: ${finalEntry.valueInt}, valueBool: ${finalEntry.valueBool}, isCompleted: ${finalEntry.isCompleted})');
      }
    }

    return {'completed': completedCount, 'total': totalRelevantHabits};
  }

  Future<void> _toggleBoolHabit(int seasonId, int dayIndex, int habitId, bool value) async {
    HapticFeedback.lightImpact();
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setBoolValue(seasonId, dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
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

