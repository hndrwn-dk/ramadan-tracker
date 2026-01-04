import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/models/day_point.dart';
import 'package:ramadan_tracker/features/insights/models/habit_stats.dart';
import 'package:ramadan_tracker/features/insights/providers/insights_provider.dart';
import 'package:ramadan_tracker/features/insights/screens/task_detail_insights_screen.dart';
import 'package:ramadan_tracker/features/insights/screens/sedekah_review_screen.dart';
import 'package:ramadan_tracker/features/insights/screens/season_report_screen.dart';
import 'package:ramadan_tracker/features/insights/screens/habit_analytics_today_screen.dart';
import 'package:ramadan_tracker/features/insights/screens/sedekah_analytics_today_screen.dart';
import 'package:ramadan_tracker/features/insights/widgets/task_analytics_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/mini_heatmap_strip.dart';
import 'package:ramadan_tracker/features/insights/widgets/weekly_summary_hero_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/weekly_rhythm_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/weekly_highlights_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/weekly_task_row.dart';
import 'package:ramadan_tracker/features/insights/widgets/sedekah_weekly_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/weekly_review_bottom_sheet.dart';
import 'package:ramadan_tracker/features/insights/services/weekly_insights_service.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_summary_hero_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_trend_chart.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_day_heatmap.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_highlights_grid.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_task_analytics_row.dart';
import 'package:ramadan_tracker/features/insights/widgets/sedekah_season_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/mood_reflection_season_card.dart';
import 'package:ramadan_tracker/features/insights/widgets/season_audit_bottom_sheet.dart';
import 'package:ramadan_tracker/features/insights/widgets/day_summary_bottom_sheet.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/widgets/score_ring.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';

/// Refactored Insights Screen with proper range-based scoring and comparison.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> with AutomaticKeepAliveClientMixin {
  InsightsRange _selectedRange = InsightsRange.today;
  DateTime? _selectedDate; // For Today tab date selection (null = today)
  int _refreshKey = 0; // Key to force FutureBuilder refresh
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive to allow refresh
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final currentTabIndex = ref.read(tabIndexProvider);
        // Only refresh if we're on Insights tab
        if (currentTabIndex == 3) {
          setState(() {
            _refreshKey++;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Listen to tab changes to refresh when returning to Insights tab
    ref.listen<int>(tabIndexProvider, (previous, next) {
      // When tab changes to Insights (index 3) from another tab, refresh
      if (previous != 3 && next == 3 && mounted) {
        setState(() {
          _refreshKey++;
        });
      }
    });
    
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
        title: _selectedRange == InsightsRange.sevenDays
            ? ref.watch(currentSeasonProvider).when(
                data: (season) {
                  if (season == null) return Text(l10n.insights);
                  final currentDayIndex = ref.read(currentDayIndexProvider);
                  final range = WeeklyInsightsService.getLast7DaysRange(
                    season: season,
                    currentDayIndex: currentDayIndex,
                  );
                  final startFormatted = DateFormat('MMM d').format(range.startDate);
                  final endFormatted = DateFormat('MMM d').format(range.endDate);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.insights),
                      Text(
                        '${l10n.last7Days} • $startFormatted–$endFormatted',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                      ),
                    ],
                  );
                },
                loading: () => Text(l10n.insights),
                error: (_, __) => Text(l10n.insights),
              )
            : _selectedRange == InsightsRange.season
                ? ref.watch(currentSeasonProvider).when(
                    data: (season) {
                      if (season == null) return Text(l10n.insights);
                      final endDate = season.startDate.add(Duration(days: season.days - 1));
                      final startFormatted = DateFormat('MMM d').format(season.startDate);
                      final endFormatted = DateFormat('MMM d').format(endDate);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.insights),
                          Text(
                            '${l10n.ramadanSeason} • ${l10n.day1ToDay(season.days)} • $startFormatted–$endFormatted',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      );
                    },
                    loading: () => Text(l10n.insights),
                    error: (_, __) => Text(l10n.insights),
                  )
                : Text(l10n.insights),
      ),
      body: ref.watch(currentSeasonProvider).when(
        data: (season) {
          if (season == null) {
            return Center(child: Text(l10n.noSeasonFound));
          }
          return _buildInsights(context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text(l10n.errorMessage(error.toString()))),
      ),
    );
  }

  Widget _buildInsights(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // For Today tab with date selection, use the date-aware provider
    final insightsAsync = _selectedRange == InsightsRange.today && _selectedDate != null
        ? ref.watch(insightsDataProviderWithDate((range: _selectedRange, date: _selectedDate)))
        : ref.watch(insightsDataProvider(_selectedRange));

    return insightsAsync.when(
      data: (data) {
        if (data.daysCount == 0) {
          return _buildEmptyState(context, ref);
        }
        // Show different UI for 7 Days tab
        if (_selectedRange == InsightsRange.sevenDays) {
          return _build7DaysView(context, ref, data);
        }
        
        // Show different UI for Season tab
        if (_selectedRange == InsightsRange.season) {
          return _buildSeasonView(context, ref, data);
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeframeSelector(),
              const SizedBox(height: 24),
              // Date selector for Today tab only
              if (_selectedRange == InsightsRange.today) ...[
                _buildDateSelector(context, ref),
                const SizedBox(height: 16),
              ],
              _buildSummaryCard(context, ref, data),
              const SizedBox(height: 24),
              _buildHighlightsSection(context, ref, data),
              const SizedBox(height: 24),
              // Sedekah Today Financial summary (Today tab only)
              if (_selectedRange == InsightsRange.today) ...[
                _buildSedekahTodaySummary(context, ref, data),
                const SizedBox(height: 24),
              ],
              // Sedekah Financial Review (for 7 Days and Season)
              if (_selectedRange == InsightsRange.sevenDays || _selectedRange == InsightsRange.season) ...[
                _buildSedekahReviewSection(context, ref, data),
                const SizedBox(height: 24),
              ],
              _buildTaskInsightsSection(context, ref, data),
              const SizedBox(height: 24),
              if (data.trendSeries.length > 1) ...[
                _buildTrendsCard(context, data),
                const SizedBox(height: 24),
              ],
              if (_selectedRange == InsightsRange.season) ...[
                _buildCompareSeasonsSection(context, ref),
                const SizedBox(height: 24),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text(l10n.errorMessage(error.toString()))),
    );
  }

  Widget _buildTimeframeSelector() {
    final l10n = AppLocalizations.of(context)!;
    return SegmentedButton<InsightsRange>(
      segments: [
        ButtonSegment(value: InsightsRange.today, label: Text(l10n.today)),
        ButtonSegment(value: InsightsRange.sevenDays, label: Text(l10n.sevenDays)),
        ButtonSegment(value: InsightsRange.season, label: Text(l10n.insightsSeasonTab)),
      ],
      selected: {_selectedRange},
      onSelectionChanged: (Set<InsightsRange> newSelection) {
        setState(() {
          _selectedRange = newSelection.first;
          // Reset date selection when switching away from Today tab
          if (newSelection.first != InsightsRange.today) {
            _selectedDate = null;
          }
        });
      },
    );
  }

  Widget _buildDateSelector(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        
        final selectedDate = _selectedDate ?? DateTime.now();
        final isToday = _selectedDate == null || 
            (selectedDate.year == DateTime.now().year &&
             selectedDate.month == DateTime.now().month &&
             selectedDate.day == DateTime.now().day);
        
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isToday ? l10n.today : DateFormat('MMM d, yyyy').format(selectedDate),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_calendar, size: 20),
              onPressed: () => _showDatePicker(context, ref, season),
              tooltip: l10n.changeDate,
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref, SeasonModel season) async {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final startDate = season.startDate;
    final endDate = startDate.add(Duration(days: season.days - 1));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: startDate,
      lastDate: endDate.isAfter(now) ? now : endDate,
      helpText: l10n.selectDayToAnalyze,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      // Invalidate insights data to refresh with new date
      ref.invalidate(insightsDataProvider(_selectedRange));
    }
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, InsightsData data) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();

        // Use selected date's day index if available, otherwise use current day
        final dayIndex = _selectedDate != null && _selectedRange == InsightsRange.today
            ? season.getDayIndex(_selectedDate!)
            : ref.read(currentDayIndexProvider);

        String title;
        String? subtitle;
        List<Widget> chips = [];

        switch (_selectedRange) {
          case InsightsRange.today:
            title = l10n.todayScore;
            final completionPercent = data.avgScore / 100.0;
            chips = [
              _buildChip(context, Icons.local_fire_department, l10n.streakDays(data.currentStreak)),
              _buildChip(
                context,
                Icons.check_circle,
                completionPercent >= 1.0 ? l10n.percentComplete(100) : l10n.percentComplete(data.avgScore),
              ),
              _buildChip(context, Icons.calendar_today, l10n.dayOfTotal(dayIndex, season.days)),
            ];
            break;
          case InsightsRange.sevenDays:
            title = l10n.sevenDayAverageScore;
            subtitle = l10n.totalScore(data.totalScore, data.daysCount * 100);
            final perfectDays = (data.completionRate * data.daysCount).round();
            chips = [
              _buildChip(context, Icons.check_circle, l10n.perfectDays(perfectDays, data.daysCount)),
              _buildChip(context, Icons.local_fire_department, l10n.currentStreak(data.currentStreak)),
              _buildChip(context, Icons.emoji_events, l10n.bestStreak(data.bestStreak)),
            ];
            break;
          case InsightsRange.season:
            title = l10n.seasonAverageScore;
            subtitle = l10n.totalScore(data.totalScore, data.daysCount * 100);
            final perfectDays = (data.completionRate * data.daysCount).round();
            chips = [
              _buildChip(context, Icons.calendar_today, l10n.daysCompleted(dayIndex, season.days)),
              _buildChip(context, Icons.check_circle, l10n.perfectDaysOnly(perfectDays)),
              _buildChip(context, Icons.local_fire_department, l10n.longestStreak(data.bestStreak)),
            ];
            break;
        }

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Text(
                          '${data.avgScore}',
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ScoreRing(score: data.avgScore.toDouble()),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: chips,
              ),
              // Score drivers for Today tab
              if (_selectedRange == InsightsRange.today) ...[
                const SizedBox(height: 16),
                _buildScoreDrivers(context, ref, data),
              ],
              const SizedBox(height: 16),
              if (_selectedRange == InsightsRange.today)
                _buildTodaySummaryCtas(context, ref, data)
              else
                _buildSummaryCtas(context, ref, data),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildChip(BuildContext context, IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      padding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }

  /// Build contextual CTAs for Today tab based on score
  Widget _buildTodaySummaryCtas(BuildContext context, WidgetRef ref, InsightsData data) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        
        final selectedDate = _selectedDate ?? DateTime.now();
        final isToday = _selectedDate == null || 
            (selectedDate.year == DateTime.now().year &&
             selectedDate.month == DateTime.now().month &&
             selectedDate.day == DateTime.now().day);
        
        // If showing a non-today date, show "View Day" CTA
        if (!isToday) {
          return OutlinedButton.icon(
            onPressed: () {
              final dayIndex = season.getDayIndex(selectedDate);
              ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
              ref.read(tabIndexProvider.notifier).state = 0;
            },
            icon: const Icon(Icons.today, size: 18),
            label: Text(l10n.viewDay(DateFormat('MMM d').format(selectedDate))),
          );
        }
        
        // If showing today, show contextual CTA based on score
        if (data.avgScore < 100) {
          // Score < 100: Show "Review what's missing" button
          return ElevatedButton.icon(
            onPressed: () => _showWhatMissingBottomSheet(context, ref, data),
            icon: const Icon(Icons.search, size: 18),
            label: Text(l10n.reviewWhatsMissing),
          );
        } else {
          // Score = 100: Show "View Ramadan consistency" button
          return OutlinedButton.icon(
            onPressed: () {
              // Scroll to Task Insights section (handled by parent scroll controller)
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.scrollDownToSeeHeatmaps)),
              );
            },
            icon: const Icon(Icons.calendar_view_month, size: 18),
            label: Text(l10n.viewRamadanConsistency),
          );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showWhatMissingBottomSheet(BuildContext context, WidgetRef ref, InsightsData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WhatMissingSheet(data: data, ref: ref),
    );
  }

  Widget _buildSummaryCtas(BuildContext context, WidgetRef ref, InsightsData data) {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        
        switch (_selectedRange) {
          case InsightsRange.today:
            // This should not be called for Today tab (use _buildTodaySummaryCtas instead)
            return const SizedBox.shrink();
          case InsightsRange.sevenDays:
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showWeeklyReview(context, ref, data);
                    },
                    icon: const Icon(Icons.calendar_view_week, size: 18),
                    label: Text(l10n.weeklyReview),
                  ),
                ),
              ],
            );
          case InsightsRange.season:
            return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SeasonReportScreen(seasonId: season.id),
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment, size: 18),
                    label: Text(l10n.seasonReport),
                  ),
                ),
              ],
            );
        }
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showWeeklyReview(BuildContext context, WidgetRef ref, InsightsData data) {
    // Show weekly review bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WeeklyReviewSheet(data: data),
    );
  }

  void _showSeasonComparison(BuildContext context, WidgetRef ref) {
    // Show season comparison bottom sheet or navigate to screen
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SeasonComparisonSheet(),
    );
  }

  Widget _buildHighlightsSection(BuildContext context, WidgetRef ref, InsightsData data) {
    var highlights = <Widget>[];

    switch (_selectedRange) {
      case InsightsRange.today:
        // Today-specific highlights - handled separately in _buildHighlightsSection
        // Return empty for now, will be replaced with async widget
        // No highlights added here, handled in _buildTodayHighlightsWidget
        break;
      case InsightsRange.sevenDays:
        // 7 Days highlights: most consistent, needs focus, best day (max 3)
        _addMostConsistentHabit(highlights, data);
        _addNeedsFocusHabit(highlights, data);
        if (data.trendSeries.isNotEmpty) {
          final l10n = AppLocalizations.of(context)!;
          final sorted = List<DayPoint>.from(data.trendSeries)..sort((a, b) => b.score.compareTo(a.score));
          final bestDay = sorted.first;
          highlights.add(_buildHighlightCard(
            context,
            icon: Icons.emoji_events,
            title: l10n.bestDayScore,
            subtitle: '${DateFormat('MMM d').format(bestDay.date)}: ${bestDay.score}',
          ));
        }
        // Limit to max 3
        if (highlights.length > 3) {
          highlights = highlights.take(3).toList();
        }
        break;
      case InsightsRange.season:
        // Season highlights: Tarawih progress, Itikaf last 10 nights, Sedekah total (max 3)
        final l10n = AppLocalizations.of(context)!;
        final taraweehStats = data.perHabitStats['taraweeh'];
        if (taraweehStats != null && taraweehStats.totalDays != null) {
          final done = taraweehStats.doneDays ?? 0;
          final total = taraweehStats.totalDays!;
          highlights.add(_buildHighlightCard(
            context,
            icon: Icons.nights_stay,
            title: l10n.tarawihProgress,
            subtitle: l10n.doneNights(done, total),
          ));
        }
        final itikafStats = data.perHabitStats['itikaf'];
        if (itikafStats != null && itikafStats.nightsDone != null) {
          highlights.add(_buildHighlightCard(
            context,
            icon: Icons.mosque,
            title: l10n.itikafLast10Nights,
            subtitle: l10n.nights(itikafStats.nightsDone!),
          ));
        }
        final sedekahStats = data.perHabitStats['sedekah'];
        if (sedekahStats != null && sedekahStats.totalAmount != null && sedekahStats.totalAmount! > 0) {
          // Will show currency in async builder
          highlights.add(_buildHighlightCard(
            context,
            icon: Icons.volunteer_activism,
            title: l10n.sedekahTotalGiven,
            subtitle: l10n.tapToViewDetails,
          ));
        }
        // Limit to max 3
        if (highlights.length > 3) {
          highlights = highlights.take(3).toList();
        }
        break;
    }

    // For Today tab, use async widget
    if (_selectedRange == InsightsRange.today) {
      return _buildTodayHighlightsWidget(context, ref, data);
    }

    // For 7 Days and Season, build highlights synchronously

    if (highlights.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.highlights,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: highlights.length,
            itemBuilder: (context, index) => Container(
              width: 280,
              margin: const EdgeInsets.only(right: 12),
              child: highlights[index],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightCard(BuildContext context, {required IconData icon, required String title, required String subtitle}) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInsightsSection(BuildContext context, WidgetRef ref, InsightsData data) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _selectedRange == InsightsRange.today ? l10n.habitAnalytics : l10n.taskInsights,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_selectedRange == InsightsRange.today)
          // For Today tab, use analytics cards with heatmaps
          ...data.perHabitStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildTaskAnalyticsCardForToday(context, ref, entry.key, entry.value),
            );
          })
        else
          // For 7 Days and Season, use simple cards
          ...data.perHabitStats.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildHabitCard(context, ref, entry.key, entry.value),
            );
          }),
      ],
    );
  }

  Widget _buildHabitCard(BuildContext context, WidgetRef ref, String habitKey, HabitStats stats) {
    final name = _getHabitDisplayName(habitKey);
    final statText = _getHabitSubtitle(habitKey, stats, ref);

    // For Today tab, show status badge and reason label
    Widget? statusBadge;
    String? reasonLabel;
    if (_selectedRange == InsightsRange.today) {
      final statusResult = _getTodayHabitStatus(context, habitKey, stats, ref);
      statusBadge = statusResult['badge'] as Widget?;
      reasonLabel = statusResult['reason'] as String?;
    }

    return PremiumCard(
      onTap: () {
        if (_selectedRange == InsightsRange.today) {
          final seasonAsync = ref.read(currentSeasonProvider);
          seasonAsync.whenData((season) {
            if (season != null) {
              _navigateToHabitAnalyticsToday(context, ref, habitKey, season.id);
            }
          });
        } else {
          _navigateToTaskAnalytics(context, ref, habitKey);
        }
      },
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(_getHabitIcon(habitKey), size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (statusBadge != null) ...[
                      const SizedBox(width: 8),
                      statusBadge,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statText,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (reasonLabel != null && _selectedRange == InsightsRange.today) ...[
                  const SizedBox(height: 4),
                  Text(
                    reasonLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildCtaChip(context, AppLocalizations.of(context)!.analytics, () {
            if (_selectedRange == InsightsRange.today) {
              final seasonAsync = ref.read(currentSeasonProvider);
              seasonAsync.whenData((season) {
                if (season != null) {
                  _navigateToHabitAnalyticsToday(context, ref, habitKey, season.id);
                }
              });
            } else {
              _navigateToTaskAnalytics(context, ref, habitKey);
            }
          }),
        ],
      ),
    );
  }

  /// Build analytics card with heatmap for Today tab
  Widget _buildTaskAnalyticsCardForToday(BuildContext context, WidgetRef ref, String habitKey, HabitStats stats) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    // Watch tabIndexProvider and currentDayIndexProvider to trigger refresh when returning to Insights tab or day changes
    final tabIndex = ref.watch(tabIndexProvider);
    final currentDayIndexFromProvider = ref.watch(currentDayIndexProvider);
    
    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        
        final selectedDate = _selectedDate ?? DateTime.now();
        final currentDayIndex = season.getDayIndex(selectedDate);
        
        return FutureBuilder<Map<String, dynamic>>(
          // Use key that changes when tab changes, day changes, or refresh key changes to force refresh
          key: ValueKey('task_analytics_${habitKey}_${season.id}_${currentDayIndex}_${tabIndex}_${currentDayIndexFromProvider}_$_refreshKey'),
          future: _loadTaskAnalyticsData(ref, habitKey, season, currentDayIndex),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return PremiumCard(
                padding: const EdgeInsets.all(16),
                child: const Center(child: CircularProgressIndicator()),
              );
            }
            
            final data = snapshot.data!;
            final status = data['status'] as String;
            final keyMetricText = data['keyMetricText'] as String;
            final heatmapDays = data['heatmapDays'] as List<DayStatus>;
            final hasMissedDays = data['hasMissedDays'] as bool;
            final latestMissedDay = data['latestMissedDay'] as int?;
            
            return TaskAnalyticsCard(
              habitKey: habitKey,
              habitName: _getHabitDisplayName(habitKey),
              icon: _getHabitIcon(habitKey),
              status: status,
              keyMetricText: keyMetricText,
              heatmapDays: heatmapDays,
              currentDayIndex: currentDayIndex,
              season: season,
              onAnalyticsTap: () {
                _navigateToHabitAnalyticsToday(context, ref, habitKey, season.id);
              },
              onAuditMissedTap: hasMissedDays && latestMissedDay != null
                  ? () {
                      // Navigate to Today screen with the latest missed day
                      // Update state first, then navigate
                      ref.read(selectedDayIndexProvider.notifier).state = latestMissedDay;
                      ref.read(tabIndexProvider.notifier).state = 0;
                      // Close Insights screen if it's a pushed screen
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    }
                  : null,
              onHeatmapDayTap: (dayIndex) {
                // Navigate to Task Detail with selected date
                final selectedDate = season.getDateForDay(dayIndex);
                // Show loading indicator while navigating
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );
                // Navigate asynchronously to prevent blocking
                Future.microtask(() async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HabitAnalyticsTodayScreen(
                        habitKey: habitKey,
                        seasonId: season.id,
                        selectedDate: selectedDate,
                      ),
                    ),
                  );
                  // Dismiss loading overlay if still mounted
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                });
              },
            );
          },
        );
      },
      loading: () => PremiumCard(
        padding: const EdgeInsets.all(16),
        child: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  /// Load all Ramadan data for a task to build analytics card
  Future<Map<String, dynamic>> _loadTaskAnalyticsData(
    WidgetRef ref,
    String habitKey,
    SeasonModel season,
    int currentDayIndex,
  ) async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
    final habit = habits.firstWhere((h) => h.key == habitKey);
    final seasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == habit.id);
    
    if (!seasonHabit.isEnabled) {
      return {
        'status': AppLocalizations.of(context)!.disabled,
        'keyMetricText': AppLocalizations.of(context)!.notEnabled,
        'heatmapDays': <DayStatus>[],
        'hasMissedDays': false,
        'latestMissedDay': null,
      };
    }
    
    // Load all Ramadan data
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(season.id, 1, season.days);
    final quranPlan = await database.quranPlanDao.getPlan(season.id);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    
    // Build heatmap days and calculate metrics
    final l10n = AppLocalizations.of(context)!;
    final heatmapDays = <DayStatus>[];
    String status = l10n.miss;
    String keyMetricText = '';
    bool hasMissedDays = false;
    int? latestMissedDay;
    
    // Today's data
    final todayEntries = allEntries.where((e) => e.dayIndex == currentDayIndex && e.habitId == habit.id).toList();
    final todayEntry = todayEntries.isNotEmpty ? todayEntries.first : null;
    final todayQuran = allQuranDaily.firstWhere(
      (q) => q.dayIndex == currentDayIndex,
      orElse: () => QuranDailyData(seasonId: season.id, dayIndex: currentDayIndex, pagesRead: 0, updatedAt: 0),
    );
    final todayPrayer = allPrayerDetails.firstWhere(
      (p) => p.dayIndex == currentDayIndex,
      orElse: () => PrayerDetail(seasonId: season.id, dayIndex: currentDayIndex, fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false, updatedAt: 0),
    );
    
    // Calculate today's status and metrics
    double todayCompletion = 0.0;
    switch (habitKey) {
      case 'fasting':
      case 'taraweeh':
      case 'itikaf':
        final done = todayEntry?.valueBool == true;
        todayCompletion = done ? 1.0 : 0.0;
        status = done ? l10n.done : l10n.miss;
        final doneDays = allEntries.where((e) => e.habitId == habit.id && e.valueBool == true).length;
        keyMetricText = l10n.thisRamadan(doneDays, season.days);
        if (habitKey == 'itikaf') {
          final last10Start = season.days - 9;
          final itikafDays = allEntries.where((e) => e.habitId == habit.id && e.dayIndex >= last10Start && e.valueBool == true).length;
          keyMetricText = l10n.doneItikaf(itikafDays);
        }
        break;
      case 'quran_pages':
        final pages = todayQuran.pagesRead;
        final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
        todayCompletion = target > 0 ? (pages / target).clamp(0.0, 1.0) : (pages > 0 ? 1.0 : 0.0);
        status = todayCompletion >= 1.0 ? l10n.done : (todayCompletion > 0 ? l10n.partial : l10n.miss);
        final totalPages = allQuranDaily.fold<int>(0, (sum, q) => sum + q.pagesRead);
        final avgPages = season.days > 0 ? (totalPages / season.days).round() : 0;
        keyMetricText = l10n.todayPagesAvg(pages, target, avgPages);
        break;
      case 'dhikr':
        final count = todayEntry?.valueInt ?? 0;
        final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
        todayCompletion = target > 0 ? (count / target).clamp(0.0, 1.0) : (count > 0 ? 1.0 : 0.0);
        status = todayCompletion >= 1.0 ? l10n.done : (todayCompletion > 0 ? l10n.partial : l10n.miss);
        final totalCount = allEntries.where((e) => e.habitId == habit.id).fold<int>(0, (sum, e) => sum + (e.valueInt ?? 0));
        final avgCount = season.days > 0 ? (totalCount / season.days).round() : 0;
        keyMetricText = l10n.todayCountAvg(count, target, avgCount);
        break;
      case 'sedekah':
        final amount = todayEntry?.valueInt ?? 0;
        final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
        todayCompletion = target != null && target > 0 ? (amount / target).clamp(0.0, 1.0) : (amount > 0 ? 1.0 : 0.0);
        status = todayCompletion >= 1.0 ? l10n.done : (todayCompletion > 0 ? l10n.partial : l10n.miss);
        final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
        final totalAmount = allEntries.where((e) => e.habitId == habit.id).fold<int>(0, (sum, e) => sum + (e.valueInt ?? 0));
        final amountFormatted = SedekahUtils.formatCurrency(amount.toDouble(), currency);
        final targetFormatted = target != null ? SedekahUtils.formatCurrency(target, currency) : 'N/A';
        final totalFormatted = SedekahUtils.formatCurrency(totalAmount.toDouble(), currency);
        keyMetricText = l10n.todayAmountTotal(amountFormatted, targetFormatted, totalFormatted);
        break;
      case 'prayers':
        final completed = [
          todayPrayer.fajr,
          todayPrayer.dhuhr,
          todayPrayer.asr,
          todayPrayer.maghrib,
          todayPrayer.isha,
        ].where((p) => p).length;
        todayCompletion = completed / 5.0;
        status = completed == 5 ? l10n.done : (completed > 0 ? l10n.partial : l10n.miss);
        final perfectDays = allPrayerDetails.where((p) {
          final count = [p.fajr, p.dhuhr, p.asr, p.maghrib, p.isha].where((prayer) => prayer).length;
          return count == 5;
        }).length;
        keyMetricText = l10n.todayPrayersPerfect(completed, perfectDays, season.days);
        break;
    }
    
    // Build heatmap for all Ramadan days
    final last10Start = season.days - 9;
    for (int day = 1; day <= season.days; day++) {
      // Skip Itikaf if not in last 10 nights
      if (habitKey == 'itikaf' && day < last10Start) {
        continue;
      }
      
      double completion = 0.0;
      bool isMissed = false;
      
      switch (habitKey) {
        case 'fasting':
        case 'taraweeh':
        case 'itikaf':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: season.id, dayIndex: day, habitId: habit.id, valueBool: false, updatedAt: 0),
          );
          completion = entry.valueBool == true ? 1.0 : 0.0;
          isMissed = entry.valueBool != true;
          break;
        case 'quran_pages':
          final quran = allQuranDaily.firstWhere(
            (q) => q.dayIndex == day,
            orElse: () => QuranDailyData(seasonId: season.id, dayIndex: day, pagesRead: 0, updatedAt: 0),
          );
          final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
          completion = target > 0 ? (quran.pagesRead / target).clamp(0.0, 1.0) : (quran.pagesRead > 0 ? 1.0 : 0.0);
          isMissed = completion < 1.0;
          break;
        case 'dhikr':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: season.id, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
          final count = entry.valueInt ?? 0;
          completion = target > 0 ? (count / target).clamp(0.0, 1.0) : (count > 0 ? 1.0 : 0.0);
          isMissed = completion < 1.0;
          break;
        case 'sedekah':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: season.id, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
          final amount = entry.valueInt ?? 0;
          completion = target != null && target > 0 ? (amount / target).clamp(0.0, 1.0) : (amount > 0 ? 1.0 : 0.0);
          isMissed = target != null ? amount < target.toInt() : amount == 0;
          break;
        case 'prayers':
          final prayer = allPrayerDetails.firstWhere(
            (p) => p.dayIndex == day,
            orElse: () => PrayerDetail(seasonId: season.id, dayIndex: day, fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false, updatedAt: 0),
          );
          final completed = [
            prayer.fajr,
            prayer.dhuhr,
            prayer.asr,
            prayer.maghrib,
            prayer.isha,
          ].where((p) => p).length;
          completion = completed / 5.0;
          isMissed = completed < 5;
          break;
      }
      
      heatmapDays.add(DayStatus(
        dayIndex: day,
        completion: completion,
        isToday: day == currentDayIndex,
      ));
      
      if (isMissed && (latestMissedDay == null || day > latestMissedDay)) {
        latestMissedDay = day;
        hasMissedDays = true;
      }
    }
    
    return {
      'status': status,
      'keyMetricText': keyMetricText,
      'heatmapDays': heatmapDays,
      'hasMissedDays': hasMissedDays,
      'latestMissedDay': latestMissedDay,
    };
  }

  Widget _buildSedekahTodaySummary(BuildContext context, WidgetRef ref, InsightsData data) {
    final sedekahStats = data.perHabitStats['sedekah'];
    if (sedekahStats == null) return const SizedBox.shrink();

    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        // Use selected date's day index if available, otherwise use current day
        final dayIndex = _selectedDate != null
            ? season.getDayIndex(_selectedDate!)
            : ref.read(currentDayIndexProvider);
        return FutureBuilder<Map<String, dynamic>>(
          future: _getTodaySedekahSummaryData(ref, season.id, dayIndex),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final summaryData = snapshot.data!;
            final amount = summaryData['amount'] as int;
            final currency = summaryData['currency'] as String;
            final target = summaryData['target'] as double?;
            final transactionCount = summaryData['transactionCount'] as int? ?? 0;

            String statusText;
            Color statusColor;
            if (target != null && target > 0) {
              if (amount >= target.toInt()) {
                statusText = amount > target.toInt() ? 'Over' : 'Met';
                statusColor = Colors.green;
              } else {
                statusText = 'Below';
                statusColor = Colors.orange;
              }
            } else {
              statusText = amount > 0 ? 'Given' : 'None';
              statusColor = amount > 0 ? Colors.green : Colors.grey;
            }

            return PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sedekah Today',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          statusText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                        ),
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
                            'Today given',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            SedekahUtils.formatCurrency(amount.toDouble(), currency),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      if (target != null && target > 0) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Target',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              SedekahUtils.formatCurrency(target, currency),
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  if (transactionCount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$transactionCount transaction${transactionCount > 1 ? 's' : ''} today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToSedekahAnalyticsToday(context, ref, season.id),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Details'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<Map<String, dynamic>> _getTodaySedekahSummaryData(WidgetRef ref, int seasonId, int dayIndex) async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah', orElse: () => throw StateError('Sedekah habit not found'));
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final sedekahEntry = entries.firstWhere(
      (e) => e.habitId == sedekahHabit.id,
      orElse: () => DailyEntry(seasonId: seasonId, dayIndex: dayIndex, habitId: sedekahHabit.id, valueInt: 0, updatedAt: 0),
    );
    final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    final goalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final goalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final target = goalEnabled == 'true' && goalAmount != null ? double.tryParse(goalAmount) : null;
    
    // Count transactions (for now, we'll use 1 if amount > 0, as we don't track individual transactions)
    final transactionCount = sedekahEntry.valueInt != null && sedekahEntry.valueInt! > 0 ? 1 : 0;

    return {
      'amount': sedekahEntry.valueInt ?? 0,
      'currency': currency,
      'target': target,
      'transactionCount': transactionCount,
    };
  }

  Map<String, dynamic> _getTodayHabitStatus(BuildContext context, String habitKey, HabitStats stats, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Widget? badge;
    String? reason;

    switch (habitKey) {
      case 'fasting':
      case 'taraweeh':
      case 'itikaf':
        final done = stats.doneDays != null && stats.doneDays! > 0;
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: done 
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            done ? l10n.done : l10n.miss,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: done ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
          ),
        );
        reason = done ? 'On track' : 'Missed';
        break;
      case 'quran_pages':
        final pages = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        if (target == 0) {
          badge = null;
          reason = pages > 0 ? 'Partial' : 'Miss';
        } else {
          final percent = pages / target;
          if (percent >= 1.0) {
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            );
            reason = 'Over target';
          } else if (percent > 0) {
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Partial',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            );
            reason = 'Missed';
          } else {
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Miss',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            );
            reason = 'Missed';
          }
        }
        break;
      case 'dhikr':
        final count = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        if (target == 0) {
          badge = null;
          reason = count > 0 ? 'Partial' : 'Miss';
        } else {
          final percent = count / target;
          if (percent >= 1.0) {
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Done',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            );
            reason = 'On track';
          } else if (percent > 0) {
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Partial',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            );
            reason = 'Missed';
          } else {
            badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Miss',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
              ),
            );
            reason = 'Missed';
          }
        }
        break;
      case 'prayers':
        final all5 = stats.all5Days ?? 0;
        if (all5 >= 5) {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Done',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
            ),
          );
          reason = 'Perfect';
        } else if (all5 > 0) {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Partial',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
            ),
          );
          reason = 'Partial';
        } else {
          badge = Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Miss',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
            ),
          );
          reason = 'Missed';
        }
        break;
      case 'sedekah':
        // Sedekah status will be shown in the dedicated summary card
        badge = null;
        reason = null;
        break;
      default:
        badge = null;
        reason = null;
    }

    return {
      'badge': badge,
      'reason': reason,
    };
  }

  String _getHabitSubtitle(String habitKey, HabitStats stats, WidgetRef ref) {
    switch (_selectedRange) {
      case InsightsRange.today:
        return _getTodaySubtitle(habitKey, stats, ref);
      case InsightsRange.sevenDays:
        return _getSevenDaysSubtitle(habitKey, stats, ref);
      case InsightsRange.season:
        return _getSeasonSubtitle(habitKey, stats, ref);
    }
  }

  String _getTodaySubtitle(String habitKey, HabitStats stats, WidgetRef ref) {
    switch (habitKey) {
      case 'fasting':
        return stats.doneDays != null && stats.doneDays! > 0 ? 'Done' : 'Not done';
      case 'quran_pages':
        final pages = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        return 'Today $pages/$target pages';
      case 'dhikr':
        final count = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        return 'Today $count/$target';
      case 'taraweeh':
        return stats.doneDays != null && stats.doneDays! > 0 ? 'Done' : 'Not done';
      case 'sedekah':
        // Will be computed from today's data
        return 'Tap to view';
      case 'prayers':
        final all5 = stats.all5Days ?? 0;
        return 'Perfect: $all5/5';
      case 'itikaf':
        return stats.nightsDone != null && stats.nightsDone! > 0 ? 'Done' : 'Not done';
      default:
        return '';
    }
  }

  String _getSevenDaysSubtitle(String habitKey, HabitStats stats, WidgetRef ref) {
    switch (habitKey) {
      case 'fasting':
        return 'Done ${stats.doneDays ?? 0}/${stats.totalDays ?? 0} days';
      case 'quran_pages':
        final avg = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        final hitTarget = stats.daysMetTarget ?? 0;
        return 'Avg $avg/$target pages • hit target $hitTarget/7';
      case 'dhikr':
        final avg = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        final completed = stats.daysMetTarget ?? 0;
        return 'Avg $avg/$target • completed $completed/7';
      case 'taraweeh':
        return 'Done ${stats.doneDays ?? 0}/${stats.totalDays ?? 0} days';
      case 'sedekah':
        // Will show total and hit target
        return 'Tap to view';
      case 'prayers':
        final perfect = stats.all5Days ?? 0;
        return 'Perfect days $perfect/7';
      case 'itikaf':
        return 'Nights done ${stats.nightsDone ?? 0}';
      default:
        return '';
    }
  }

  String _getSeasonSubtitle(String habitKey, HabitStats stats, WidgetRef ref) {
    switch (habitKey) {
      case 'fasting':
        return 'Done ${stats.doneDays ?? 0}/${stats.totalDays ?? 0} days';
      case 'quran_pages':
        final avg = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        final hitTarget = stats.daysMetTarget ?? 0;
        return 'Avg $avg/$target pages • hit target $hitTarget days';
      case 'dhikr':
        final avg = stats.avgValue?.round() ?? 0;
        final target = stats.targetValue ?? 0;
        final completed = stats.daysMetTarget ?? 0;
        return 'Avg $avg/$target • completed $completed days';
      case 'taraweeh':
        return 'Done ${stats.doneDays ?? 0}/${stats.totalDays ?? 0} days';
      case 'sedekah':
        // Will show total and avg
        return 'Tap to view';
      case 'prayers':
        final perfect = stats.all5Days ?? 0;
        return 'Perfect days $perfect';
      case 'itikaf':
        return 'Nights done ${stats.nightsDone ?? 0}/10';
      default:
        return '';
    }
  }

  Widget _buildCtaChip(BuildContext context, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToTaskAnalytics(BuildContext context, WidgetRef ref, String habitKey) {
    // Navigate to TaskDetailInsightsScreen instead of Today
    final seasonAsync = ref.read(currentSeasonProvider);
    seasonAsync.whenData((season) {
      if (season != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TaskDetailInsightsScreen(
              habitKey: habitKey,
              range: _selectedRange,
              seasonId: season.id,
            ),
          ),
        );
      }
    });
  }

  void _navigateToHabitAnalyticsToday(BuildContext context, WidgetRef ref, String habitKey, int seasonId) {
    // Navigate to HabitAnalyticsTodayScreen (new screen for Today-only analytics)
    // Use unawaited to prevent blocking
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HabitAnalyticsTodayScreen(
          habitKey: habitKey,
          seasonId: seasonId,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  void _navigateToSedekahAnalyticsToday(BuildContext context, WidgetRef ref, int seasonId) {
    // Navigate to SedekahAnalyticsTodayScreen (new screen for Today-only financial review)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SedekahAnalyticsTodayScreen(
          seasonId: seasonId,
          selectedDate: _selectedDate,
        ),
      ),
    );
  }

  void _showTodayReviewBottomSheet(BuildContext context, WidgetRef ref, InsightsData data) {
    // Show in-place bottom sheet summary for today
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TodayReviewSheet(data: data),
    );
  }

  Widget _buildTrendsCard(BuildContext context, InsightsData data) {
    if (data.trendSeries.length <= 1) return const SizedBox.shrink();

    final spots = data.trendSeries.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.score.toDouble());
    }).toList();

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Completion Trend',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (data.trendSeries.length - 1).toDouble(),
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < data.trendSeries.length) {
                          final dayPoint = data.trendSeries[value.toInt()];
                          return Text(
                            DateFormat('MMM d').format(dayPoint.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Theme.of(context).colorScheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Theme.of(context).colorScheme.primary,
                          strokeWidth: 2,
                          strokeColor: Theme.of(context).colorScheme.surface,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompareSeasonsSection(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(seasonComparisonProvider);

    return comparisonAsync.when(
      data: (comparison) {
        if (comparison == null) {
          return PremiumCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No previous season yet',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final current = comparison['current'] as InsightsData;
        final previous = comparison['previous'] as InsightsData;

        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compare Seasons',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildComparisonRow(
                context,
                'Avg score',
                '${current.avgScore}',
                '${previous.avgScore}',
                current.avgScore - previous.avgScore,
              ),
              _buildComparisonRow(
                context,
                'Perfect days',
                '${(current.completionRate * current.daysCount).round()}/${current.daysCount}',
                '${(previous.completionRate * previous.daysCount).round()}/${previous.daysCount}',
                (current.completionRate * current.daysCount).round() - (previous.completionRate * previous.daysCount).round(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String label, String currentValue, String previousValue, int delta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Row(
            children: [
              Text(
                currentValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 8),
              Text(
                delta >= 0 ? '+$delta' : '$delta',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: delta >= 0 ? Colors.green : Colors.red,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking today to see insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(tabIndexProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.today),
              label: const Text('Go to Today'),
            ),
          ],
        ),
      ),
    );
  }

  String _getHabitDisplayName(String habitKey) {
    return getHabitDisplayName(context, habitKey);
  }

  IconData _getHabitIcon(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return Icons.wb_sunny;
      case 'quran_pages':
        return Icons.menu_book;
      case 'dhikr':
        return Icons.favorite;
      case 'taraweeh':
        return Icons.nights_stay;
      case 'sedekah':
        return Icons.volunteer_activism;
      case 'prayers':
        return Icons.mosque;
      case 'itikaf':
        return Icons.mosque;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildTodayHighlightsWidget(BuildContext context, WidgetRef ref, InsightsData data) {
    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        // Use selected date's day index if available, otherwise use current day
        final dayIndex = _selectedDate != null
            ? season.getDayIndex(_selectedDate!)
            : ref.read(currentDayIndexProvider);
        return FutureBuilder<Map<String, dynamic>>(
          future: _buildTodayHighlightsData(ref, season.id, dayIndex, data),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final highlightsData = snapshot.data!;
            var highlights = <Widget>[];

            // Reflection mood
            final mood = highlightsData['mood'] as String?;
            if (mood != null) {
              highlights.add(_buildHighlightCard(
                context,
                icon: _getMoodIcon(mood),
                title: 'Mood: $mood',
                subtitle: 'Reflection recorded',
              ));
            }

            // Quran stats
            final quranStats = highlightsData['quranStats'] as HabitStats?;
            if (quranStats != null && quranStats.targetValue != null && quranStats.targetValue! > 0) {
              final avgPages = quranStats.avgValue ?? 0;
              final target = quranStats.targetValue!;
              if (avgPages >= target * 0.9) {
                highlights.add(_buildHighlightCard(
                  context,
                  icon: Icons.menu_book,
                  title: 'Quran on track',
                  subtitle: '${avgPages.round()}/$target pages',
                ));
              } else {
                highlights.add(_buildHighlightCard(
                  context,
                  icon: Icons.warning_amber_rounded,
                  title: 'Quran needs catch-up',
                  subtitle: '${avgPages.round()}/$target pages',
                ));
              }
            }

            // Prayers
            final prayersStats = highlightsData['prayersStats'] as HabitStats?;
            if (prayersStats != null && prayersStats.all5Days != null && prayersStats.all5Days! > 0) {
              highlights.add(_buildHighlightCard(
                context,
                icon: Icons.mosque,
                title: 'All 5 prayers done',
                subtitle: 'Complete',
              ));
            }

            // Sedekah (with target comparison if enabled)
            final sedekahData = highlightsData['sedekahData'] as Map<String, dynamic>?;
            if (sedekahData != null) {
              final amount = sedekahData['amount'] as int;
              final currency = sedekahData['currency'] as String;
              final target = sedekahData['target'] as double?;
              if (amount > 0) {
                String subtitle = SedekahUtils.formatCurrency(amount.toDouble(), currency);
                if (target != null && target > 0) {
                  final diff = amount - target.toInt();
                  final sign = diff >= 0 ? '+' : '';
                  subtitle += ' ($sign${SedekahUtils.formatCurrency(diff.toDouble(), currency)} vs target)';
                }
                highlights.add(_buildHighlightCard(
                  context,
                  icon: Icons.volunteer_activism,
                  title: 'Sedekah today',
                  subtitle: subtitle,
                ));
              }
            }

            // Limit to max 2 for Today
            if (highlights.length > 2) {
              highlights = highlights.take(2).toList();
            }

            if (highlights.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highlights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: highlights.length,
                    itemBuilder: (context, index) => Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      child: highlights[index],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<Map<String, dynamic>> _buildTodayHighlightsData(WidgetRef ref, int seasonId, int dayIndex, InsightsData data) async {
    final database = ref.read(databaseProvider);

    // Reflection mood summary
    final notes = await database.notesDao.getDayNotes(seasonId, dayIndex);
    final note = notes.isNotEmpty ? notes.first : null;

    // Quran stats
    final quranStats = data.perHabitStats['quran_pages'];

    // Prayers stats
    final prayersStats = data.perHabitStats['prayers'];

    // Sedekah data
    Map<String, dynamic>? sedekahData;
    final sedekahStats = data.perHabitStats['sedekah'];
    if (sedekahStats != null) {
      sedekahData = await _getTodaySedekahData(ref, seasonId, dayIndex);
    }

    return {
      'mood': note?.mood,
      'quranStats': quranStats,
      'prayersStats': prayersStats,
      'sedekahData': sedekahData,
    };
  }


  Widget _buildScoreDrivers(BuildContext context, WidgetRef ref, InsightsData data) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getScoreDriversData(ref, data),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final drivers = snapshot.data!['drivers'] as List<Widget>;
        if (drivers.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Score drivers',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: drivers,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _getScoreDriversData(WidgetRef ref, InsightsData data) async {
    final drivers = <Widget>[];
    final seasonAsync = ref.read(currentSeasonProvider);
    
    return seasonAsync.when(
      data: (season) async {
        if (season == null) return {'drivers': drivers};
        // Use selected date's day index if available, otherwise use current day
        final dayIndex = _selectedDate != null
            ? season.getDayIndex(_selectedDate!)
            : ref.read(currentDayIndexProvider);
        final database = ref.read(databaseProvider);
        final habits = await ref.read(habitsProvider.future);
        final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
        final entries = await database.dailyEntriesDao.getDayEntries(season.id, dayIndex);
        final quranDaily = await database.quranDailyDao.getDaily(season.id, dayIndex);
        final prayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(season.id, dayIndex, dayIndex);
        final prayerDetail = prayerDetails.isNotEmpty ? prayerDetails.first : null;
        final quranPlan = await database.quranPlanDao.getPlan(season.id);
        final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
        final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
        final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
        final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';

        // Fasting
        final fastingHabit = habits.firstWhere((h) => h.key == 'fasting', orElse: () => throw StateError('Fasting habit not found'));
        final fastingSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == fastingHabit.id);
        if (fastingSeasonHabit.isEnabled) {
          final fastingEntry = entries.firstWhere((e) => e.habitId == fastingHabit.id, orElse: () => DailyEntry(seasonId: season.id, dayIndex: dayIndex, habitId: fastingHabit.id, valueBool: false, updatedAt: 0));
          final isDone = fastingEntry.valueBool == true;
          drivers.add(_buildScoreDriverChip(
            context, 
            'Fasting', 
            isDone ? 'Done' : 'Miss',
            status: isDone ? 'passed' : 'missed',
          ));
        }

        // Quran
        final quranHabit = habits.firstWhere((h) => h.key == 'quran_pages', orElse: () => throw StateError('Quran habit not found'));
        final quranSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == quranHabit.id);
        if (quranSeasonHabit.isEnabled) {
          final quranTarget = quranPlan?.dailyTargetPages ?? quranSeasonHabit.targetValue ?? quranHabit.defaultTarget ?? 20;
          final quranPages = quranDaily?.pagesRead ?? 0;
          String status;
          if (quranPages >= quranTarget) {
            status = 'passed';
          } else if (quranPages > 0) {
            status = 'partial';
          } else {
            status = 'missed';
          }
          drivers.add(_buildScoreDriverChip(
            context, 
            'Quran', 
            '$quranPages/$quranTarget',
            status: status,
          ));
        }

        // Dhikr
        final dhikrHabit = habits.firstWhere((h) => h.key == 'dhikr', orElse: () => throw StateError('Dhikr habit not found'));
        final dhikrSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == dhikrHabit.id);
        if (dhikrSeasonHabit.isEnabled) {
          final dhikrEntry = entries.firstWhere((e) => e.habitId == dhikrHabit.id, orElse: () => DailyEntry(seasonId: season.id, dayIndex: dayIndex, habitId: dhikrHabit.id, valueInt: 0, updatedAt: 0));
          final dhikrTarget = dhikrPlan?.dailyTarget ?? dhikrSeasonHabit.targetValue ?? dhikrHabit.defaultTarget ?? 100;
          final dhikrCount = dhikrEntry.valueInt ?? 0;
          String status;
          if (dhikrCount >= dhikrTarget) {
            status = 'passed';
          } else if (dhikrCount > 0) {
            status = 'partial';
          } else {
            status = 'missed';
          }
          drivers.add(_buildScoreDriverChip(
            context, 
            'Dhikr', 
            '$dhikrCount/$dhikrTarget',
            status: status,
          ));
        }

        // Sedekah
        final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah', orElse: () => throw StateError('Sedekah habit not found'));
        final sedekahSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == sedekahHabit.id);
        if (sedekahSeasonHabit.isEnabled) {
          final sedekahEntry = entries.firstWhere((e) => e.habitId == sedekahHabit.id, orElse: () => DailyEntry(seasonId: season.id, dayIndex: dayIndex, habitId: sedekahHabit.id, valueInt: 0, updatedAt: 0));
          final sedekahAmount = sedekahEntry.valueInt ?? 0;
          final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
          String status;
          String displayValue;
          if (target != null && target > 0) {
            if (sedekahAmount >= target.toInt()) {
              status = 'passed';
            } else if (sedekahAmount > 0) {
              status = 'partial';
            } else {
              status = 'missed';
            }
            displayValue = SedekahUtils.formatCurrency(sedekahAmount.toDouble(), currency);
          } else {
            status = sedekahAmount > 0 ? 'passed' : 'missed';
            displayValue = SedekahUtils.formatCurrency(sedekahAmount.toDouble(), currency);
          }
          drivers.add(_buildScoreDriverChip(
            context, 
            'Sedekah', 
            displayValue,
            status: status,
          ));
        }

        // 5 Prayers
        final prayersHabit = habits.firstWhere((h) => h.key == 'prayers', orElse: () => throw StateError('Prayers habit not found'));
        final prayersSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == prayersHabit.id);
        if (prayersSeasonHabit.isEnabled && prayerDetail != null) {
          final prayersDone = [
            prayerDetail.fajr,
            prayerDetail.dhuhr,
            prayerDetail.asr,
            prayerDetail.maghrib,
            prayerDetail.isha,
          ].where((p) => p).length;
          String status;
          if (prayersDone >= 5) {
            status = 'passed';
          } else if (prayersDone > 0) {
            status = 'partial';
          } else {
            status = 'missed';
          }
          drivers.add(_buildScoreDriverChip(
            context, 
            '5 Prayers', 
            '$prayersDone/5',
            status: status,
          ));
        }

        // Taraweeh
        final taraweehHabit = habits.firstWhere((h) => h.key == 'taraweeh', orElse: () => throw StateError('Taraweeh habit not found'));
        final taraweehSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == taraweehHabit.id);
        if (taraweehSeasonHabit.isEnabled) {
          final taraweehEntry = entries.firstWhere((e) => e.habitId == taraweehHabit.id, orElse: () => DailyEntry(seasonId: season.id, dayIndex: dayIndex, habitId: taraweehHabit.id, valueBool: false, updatedAt: 0));
          final isDone = taraweehEntry.valueBool == true;
          drivers.add(_buildScoreDriverChip(
            context, 
            'Taraweeh', 
            isDone ? 'Done' : 'Miss',
            status: isDone ? 'passed' : 'missed',
          ));
        }

        // Itikaf (only if in last 10 nights)
        final last10Start = season.days - 9;
        if (dayIndex >= last10Start) {
          final itikafHabit = habits.firstWhere((h) => h.key == 'itikaf', orElse: () => throw StateError('Itikaf habit not found'));
          final itikafSeasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == itikafHabit.id);
          if (itikafSeasonHabit.isEnabled) {
            final itikafEntry = entries.firstWhere((e) => e.habitId == itikafHabit.id, orElse: () => DailyEntry(seasonId: season.id, dayIndex: dayIndex, habitId: itikafHabit.id, valueBool: false, updatedAt: 0));
            final isDone = itikafEntry.valueBool == true;
            drivers.add(_buildScoreDriverChip(
              context, 
              'Itikaf', 
              isDone ? 'Done' : 'Miss',
              status: isDone ? 'passed' : 'missed',
            ));
          }
        }

        return {'drivers': drivers};
      },
      loading: () async => {'drivers': drivers},
      error: (_, __) async => {'drivers': drivers},
    );
  }

  Widget _buildScoreDriverChip(BuildContext context, String label, String value, {required String status}) {
    Color backgroundColor;
    Color textColor;
    
    switch (status) {
      case 'passed':
        backgroundColor = Colors.green.withOpacity(0.2);
        textColor = Colors.green;
        break;
      case 'partial':
        backgroundColor = Colors.orange.withOpacity(0.2);
        textColor = Colors.orange;
        break;
      case 'missed':
        backgroundColor = Colors.red.withOpacity(0.2);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest;
        textColor = Theme.of(context).colorScheme.onSurface;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: textColor,
                ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  color: textColor,
                ),
          ),
        ],
      ),
    );
  }

  IconData _getMoodIcon(String mood) {
    switch (mood.toLowerCase()) {
      case 'excellent':
        return Icons.sentiment_very_satisfied;
      case 'good':
        return Icons.sentiment_satisfied;
      case 'okay':
        return Icons.sentiment_neutral;
      case 'difficult':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.mood;
    }
  }


  Future<Map<String, dynamic>> _getTodaySedekahData(WidgetRef ref, int seasonId, int dayIndex) async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah', orElse: () => throw StateError('Sedekah habit not found'));
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final sedekahEntry = entries.firstWhere((e) => e.habitId == sedekahHabit.id, orElse: () => DailyEntry(seasonId: seasonId, dayIndex: dayIndex, habitId: sedekahHabit.id, valueInt: 0, updatedAt: 0));
      final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
      final goalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
      final goalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
      final target = goalEnabled == 'true' && goalAmount != null ? double.tryParse(goalAmount) : null;
    return {
      'amount': sedekahEntry.valueInt ?? 0,
      'currency': currency,
      'target': target,
    };
  }

  void _addMostConsistentHabit(List<Widget> highlights, InsightsData data) {
    if (data.perHabitStats.isEmpty) return;
    String? mostConsistent;
    double highestRate = 0;
    for (final entry in data.perHabitStats.entries) {
      final stats = entry.value;
      double rate = 0;
      if (stats.doneDays != null && stats.totalDays != null && stats.totalDays! > 0) {
        rate = stats.doneDays! / stats.totalDays!;
      } else if (stats.daysMetTarget != null && stats.totalDays != null && stats.totalDays! > 0) {
        rate = stats.daysMetTarget! / stats.totalDays!;
      }
      if (rate > highestRate) {
        highestRate = rate;
        mostConsistent = entry.key;
      }
    }
    if (mostConsistent != null && highestRate > 0.7) {
      highlights.add(_buildHighlightCard(
        context,
        icon: Icons.check_circle_outline,
        title: 'Most consistent habit',
        subtitle: _getHabitDisplayName(mostConsistent),
      ));
    }
  }

  void _addNeedsFocusHabit(List<Widget> highlights, InsightsData data) {
    if (data.perHabitStats.isEmpty) return;
    String? needsFocus;
    double lowestRate = 1.0;
    for (final entry in data.perHabitStats.entries) {
      final stats = entry.value;
      double rate = 1.0;
      if (stats.doneDays != null && stats.totalDays != null && stats.totalDays! > 0) {
        rate = stats.doneDays! / stats.totalDays!;
      } else if (stats.daysMetTarget != null && stats.totalDays != null && stats.totalDays! > 0) {
        rate = stats.daysMetTarget! / stats.totalDays!;
      }
      if (rate < lowestRate && rate < 0.7) {
        lowestRate = rate;
        needsFocus = entry.key;
      }
    }
    if (needsFocus != null && lowestRate < 0.7) {
      highlights.add(_buildHighlightCard(
        context,
        icon: Icons.warning_amber_rounded,
        title: 'Needs focus habit',
        subtitle: _getHabitDisplayName(needsFocus),
      ));
    }
  }

  Widget _buildSedekahReviewSection(BuildContext context, WidgetRef ref, InsightsData data) {
    final sedekahStats = data.perHabitStats['sedekah'];
    if (sedekahStats == null) return const SizedBox.shrink();

    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        return FutureBuilder<Map<String, dynamic>>(
          future: _getSedekahReviewData(ref, data),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final reviewData = snapshot.data!;
            final currency = reviewData['currency'] as String;
            final totalAmount = reviewData['totalAmount'] as int;
            final avgAmount = reviewData['avgAmount'] as double;
            final highestDay = reviewData['highestDay'] as int?;
            final givingDays = reviewData['givingDays'] as int;
            final totalDays = reviewData['totalDays'] as int;
            final target = reviewData['target'] as double?;

            return PremiumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Sedekah Financial Review',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SedekahReviewScreen(
                                range: _selectedRange,
                                seasonId: season.id,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open review'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSedekahReviewRow(
                    context,
                    'Total period amount',
                    SedekahUtils.formatCurrency(totalAmount.toDouble(), currency),
                  ),
                  _buildSedekahReviewRow(
                    context,
                    'Average per day',
                    SedekahUtils.formatCurrency(avgAmount, currency),
                  ),
                  if (highestDay != null)
                    _buildSedekahReviewRow(
                      context,
                      'Highest day',
                      'Day $highestDay: ${SedekahUtils.formatCurrency(reviewData['highestAmount'] as double, currency)}',
                    ),
                  _buildSedekahReviewRow(
                    context,
                    'Giving days',
                    '$givingDays/$totalDays days',
                  ),
                  if (target != null && target > 0) ...[
                    const SizedBox(height: 8),
                    _buildSedekahReviewRow(
                      context,
                      'Daily goal',
                      SedekahUtils.formatCurrency(target, currency),
                    ),
                    _buildSedekahReviewRow(
                      context,
                      'Goal progress',
                      '${((avgAmount / target) * 100).round()}% of goal',
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildSedekahReviewRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getSedekahReviewData(WidgetRef ref, InsightsData data) async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah', orElse: () => throw StateError('Sedekah habit not found'));
    final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null
        ? double.tryParse(sedekahGoalAmount)
        : null;

    final sedekahStats = data.perHabitStats['sedekah'];
    final totalAmount = sedekahStats?.totalAmount ?? 0;
    final avgAmount = sedekahStats?.avgAmount ?? 0.0;
    final givingDays = sedekahStats?.daysMetGoal ?? 0; // Using daysMetGoal as proxy for giving days
    final totalDays = data.daysCount;

    // Find highest day
    int? highestDay;
    double highestAmount = 0;
    final seasonAsync = ref.read(currentSeasonProvider);
    return seasonAsync.when(
      data: (season) async {
        if (season == null) {
          return {
            'currency': currency,
            'totalAmount': totalAmount,
            'avgAmount': avgAmount,
            'highestDay': null,
            'highestAmount': 0.0,
            'givingDays': givingDays,
            'totalDays': totalDays,
            'target': target,
          };
        }

        // Find day with highest sedekah amount
        for (int day = data.startDate.day; day <= data.endDate.day; day++) {
          final dayIndex = day - data.startDate.day + 1;
          if (dayIndex < 1 || dayIndex > season.days) continue;
          final entries = await database.dailyEntriesDao.getDayEntries(season.id, dayIndex);
          final entry = entries.firstWhere(
            (e) => e.habitId == sedekahHabit.id,
            orElse: () => DailyEntry(seasonId: season.id, dayIndex: dayIndex, habitId: sedekahHabit.id, valueInt: 0, updatedAt: 0),
          );
          final amount = (entry.valueInt ?? 0).toDouble();
          if (amount > highestAmount) {
            highestAmount = amount;
            highestDay = dayIndex;
          }
        }

        return {
          'currency': currency,
          'totalAmount': totalAmount,
          'avgAmount': avgAmount,
          'highestDay': highestDay,
          'highestAmount': highestAmount,
          'givingDays': givingDays,
          'totalDays': totalDays,
          'target': target,
        };
      },
      loading: () async => {
        'currency': currency,
        'totalAmount': totalAmount,
        'avgAmount': avgAmount,
        'highestDay': null,
        'highestAmount': 0.0,
        'givingDays': givingDays,
        'totalDays': totalDays,
        'target': target,
      },
      error: (_, __) async => {
        'currency': currency,
        'totalAmount': totalAmount,
        'avgAmount': avgAmount,
        'highestDay': null,
        'highestAmount': 0.0,
        'givingDays': givingDays,
        'totalDays': totalDays,
        'target': target,
      },
    );
  }

  Widget _build7DaysView(BuildContext context, WidgetRef ref, InsightsData data) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        
        final currentDayIndex = ref.read(currentDayIndexProvider);
        final range = WeeklyInsightsService.getLast7DaysRange(
          season: season,
          currentDayIndex: currentDayIndex,
        );
        
        // Watch providers that might change when data is updated
        final tabIndex = ref.watch(tabIndexProvider);
        final currentDayIndexFromProvider = ref.watch(currentDayIndexProvider);
        
        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey('7days_view_${season.id}_${tabIndex}_${currentDayIndexFromProvider}_$_refreshKey'),
          future: _load7DaysData(ref, season, range),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            final weeklyData = snapshot.data!;
            final weeklyScore = weeklyData['weeklyScore'] as int;
            final totalEarned = weeklyData['totalEarned'] as int;
            final maxPossible = weeklyData['maxPossible'] as int;
            final bestStreak = weeklyData['bestStreak'] as int;
            final perfectDays = weeklyData['perfectDays'] as int;
            final missedTasksCount = weeklyData['missedTasksCount'] as int;
            final dayStatuses = weeklyData['dayStatuses'] as List<WeeklyDayStatus>;
            final highlights = weeklyData['highlights'] as WeeklyHighlights;
            final taskStatuses = weeklyData['taskStatuses'] as Map<String, WeeklyTaskStatus>;
            final sedekahData = weeklyData['sedekahData'] as SedekahWeeklyData?;
            final currency = weeklyData['currency'] as String;
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeframeSelector(),
                  const SizedBox(height: 24),
                  // Weekly Summary Hero Card
                  WeeklySummaryHeroCard(
                    weeklyScore: weeklyScore,
                    totalEarned: totalEarned,
                    maxPossible: maxPossible,
                    bestStreak: bestStreak,
                    perfectDays: perfectDays,
                    totalDays: 7,
                    missedTasksCount: missedTasksCount,
                    onReviewMissedDays: () {
                      WeeklyReviewBottomSheet.show(
                        context,
                        dayStatuses: dayStatuses,
                        season: season,
                        onAuditDay: (dayIndex) {
                          ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                          ref.read(tabIndexProvider.notifier).state = 0;
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Weekly Rhythm Card
                  WeeklyRhythmCard(
                    dayStatuses: dayStatuses,
                    season: season,
                    onDayTap: (date) {
                      final dayIndex = season.getDayIndex(date);
                      ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                      ref.read(tabIndexProvider.notifier).state = 0;
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  // Weekly Highlights
                  WeeklyHighlightsCard(
                    mostConsistentTask: highlights.mostConsistentTask,
                    needsAttentionTask: highlights.needsAttentionTask,
                    biggestImprovementTask: highlights.biggestImprovementTask,
                    onTaskTap: (habitKey) {
                      final today = DateTime.now();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HabitAnalyticsTodayScreen(
                            habitKey: habitKey,
                            seasonId: season.id,
                            selectedDate: today,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Sedekah Weekly Card
                  if (sedekahData != null) ...[
                    SedekahWeeklyCard(
                      data: sedekahData,
                      currency: currency,
                      onViewDetails: () {
                        final today = DateTime.now();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HabitAnalyticsTodayScreen(
                              habitKey: 'sedekah',
                              seasonId: season.id,
                              selectedDate: today,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Task Insights List
                  Text(
                    'Task Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...taskStatuses.entries.map((entry) {
                    final habitKey = entry.key;
                    final taskStatus = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: WeeklyTaskRow(
                        habitKey: habitKey,
                        habitName: _getHabitDisplayNameHelper(habitKey),
                        icon: _getHabitIconHelper(habitKey),
                        taskStatus: taskStatus,
                        season: season,
                        startDayIndex: range.startDayIndex,
                        onCellTap: (key, date) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HabitAnalyticsTodayScreen(
                                habitKey: key,
                                seasonId: season.id,
                                selectedDate: date,
                              ),
                            ),
                          );
                        },
                        onAnalyticsTap: () {
                          final today = DateTime.now();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HabitAnalyticsTodayScreen(
                                habitKey: habitKey,
                                seasonId: season.id,
                                selectedDate: today,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading season')),
    );
  }

  Future<Map<String, dynamic>> _load7DaysData(
    WidgetRef ref,
    SeasonModel season,
    ({int startDayIndex, int endDayIndex, DateTime startDate, DateTime endDate}) range,
  ) async {
    final database = ref.read(databaseProvider);
    final allHabits = await ref.read(habitsProvider.future);
    final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
    
    // Get weekly score
    final weeklyScoreData = await WeeklyInsightsService.getWeeklyScore(
      season: season,
      startDayIndex: range.startDayIndex,
      endDayIndex: range.endDayIndex,
      database: database,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
    );
    
    // Get day statuses
    final dayStatuses = await WeeklyInsightsService.getWeeklyDayStatuses(
      season: season,
      startDayIndex: range.startDayIndex,
      endDayIndex: range.endDayIndex,
      database: database,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
    );
    
    // Get highlights
    final highlights = await WeeklyInsightsService.getWeeklyHighlights(
      season: season,
      startDayIndex: range.startDayIndex,
      endDayIndex: range.endDayIndex,
      database: database,
      allHabits: allHabits,
      seasonHabits: seasonHabits,
    );
    
    // Get task statuses for each habit
    final taskStatuses = <String, WeeklyTaskStatus>{};
    for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
      final habit = allHabits.firstWhere((h) => h.id == seasonHabit.habitId);
      final habitKey = habit.key;
      
      if (habitKey == 'itikaf') {
        final last10Start = season.days - 9;
        if (range.endDayIndex < last10Start) continue;
      }
      
      taskStatuses[habitKey] = await WeeklyInsightsService.getWeeklyTaskSummary(
        habitKey: habitKey,
        season: season,
        startDayIndex: range.startDayIndex,
        endDayIndex: range.endDayIndex,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
    }
    
    // Get Sedekah data
    SedekahWeeklyData? sedekahData;
    final sedekahHabit = allHabits.firstWhere(
      (h) => h.key == 'sedekah',
      orElse: () => throw StateError('Sedekah habit not found'),
    );
    final sedekahSeasonHabit = seasonHabits.firstWhere(
      (sh) => sh.habitId == sedekahHabit.id,
      orElse: () => throw StateError('Sedekah season habit not found'),
    );
    if (sedekahSeasonHabit.isEnabled) {
      sedekahData = await WeeklyInsightsService.getSedekahWeeklyData(
        season: season,
        startDayIndex: range.startDayIndex,
        endDayIndex: range.endDayIndex,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
    }
    
    final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    
    return {
      'weeklyScore': weeklyScoreData.weeklyScore,
      'totalEarned': weeklyScoreData.totalEarned,
      'maxPossible': weeklyScoreData.maxPossible,
      'bestStreak': weeklyScoreData.bestStreak,
      'perfectDays': weeklyScoreData.perfectDays,
      'missedTasksCount': weeklyScoreData.missedTasksCount,
      'dayStatuses': dayStatuses,
      'highlights': highlights,
      'taskStatuses': taskStatuses,
      'sedekahData': sedekahData,
      'currency': currency,
    };
  }

  Widget _buildSeasonView(BuildContext context, WidgetRef ref, InsightsData data) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        
        // Watch providers that might change when data is updated
        final tabIndex = ref.watch(tabIndexProvider);
        final currentDayIndexFromProvider = ref.watch(currentDayIndexProvider);
        
        return FutureBuilder<Map<String, dynamic>>(
          key: ValueKey('season_view_${season.id}_${tabIndex}_${currentDayIndexFromProvider}_$_refreshKey'),
          future: _loadSeasonData(ref, season),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }
            
            final seasonData = snapshot.data!;
            final aggregateRaw = seasonData['aggregate'];
            
            if (aggregateRaw == null) {
              return const Center(child: Text('Failed to load season data'));
            }
            
            final aggregate = aggregateRaw as ({
              int seasonScoreAvg,
              int totalEarned,
              int totalMax,
              int perfectDaysCount,
              int missedDaysCount,
              int bestStreak,
            });
            
            final trendSeries = (seasonData['trendSeries'] as List<({DateTime date, int score})>?) ?? [];
            final dayStatuses = (seasonData['dayStatuses'] as List<SeasonDayStatus>?) ?? [];
            final highlights = seasonData['highlights'] as SeasonHighlights? ?? SeasonHighlights();
            final taskAnalytics = (seasonData['taskAnalytics'] as Map<String, TaskSeasonAnalytics>?) ?? <String, TaskSeasonAnalytics>{};
            final sedekahAnalytics = seasonData['sedekahAnalytics'] as SedekahSeasonAnalytics?;
            final reflectionAnalytics = seasonData['reflectionAnalytics'] as ReflectionSeasonAnalytics? ?? ReflectionSeasonAnalytics(
              moodCounts: {},
              avgScoreByMood: {},
            );
            final currency = (seasonData['currency'] as String?) ?? 'IDR';
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeframeSelector(),
                  const SizedBox(height: 24),
                  // Season Summary Hero
                  SeasonSummaryHeroCard(
                    seasonScore: aggregate.seasonScoreAvg,
                    totalEarned: aggregate.totalEarned,
                    maxPossible: aggregate.totalMax,
                    perfectDays: aggregate.perfectDaysCount,
                    totalDays: season.days,
                    bestStreak: aggregate.bestStreak,
                    missedDays: aggregate.missedDaysCount,
                    onSeasonAudit: () {
                      SeasonAuditBottomSheet.show(
                        context,
                        dayStatuses: dayStatuses,
                        season: season,
                        onAuditDay: (dayIndex) {
                          ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                          ref.read(tabIndexProvider.notifier).state = 0;
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Completion Trend
                  SeasonTrendChart(
                    trendSeries: trendSeries,
                    onPointTap: (date) {
                      // Show loading indicator while loading data
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );
                      // Load data asynchronously to prevent blocking
                      Future.microtask(() async {
                        try {
                          final dayIndex = season.getDayIndex(date);
                          final summary = await SeasonInsightsService.getDaySummary(
                            seasonId: season.id,
                            dayIndex: dayIndex,
                            season: season,
                            allHabits: await ref.read(habitsProvider.future),
                            seasonHabits: await ref.read(seasonHabitsProvider(season.id).future),
                            database: ref.read(databaseProvider),
                          );
                          final dayStatus = dayStatuses.firstWhere((d) => d.dayIndex == dayIndex);
                          // Dismiss loading overlay before showing bottom sheet
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            DaySummaryBottomSheet.show(
                              context,
                              dayIndex: dayIndex,
                              date: date,
                              score: summary['score'] as int,
                              drivers: summary['drivers'] as Map<String, dynamic>,
                              mood: dayStatus.mood,
                              reflection: dayStatus.reflection,
                              season: season,
                              onOpenDay: () {
                                ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                                ref.read(tabIndexProvider.notifier).state = 0;
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          }
                        } catch (e) {
                          // Dismiss loading overlay on error
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Season Heatmap
                  SeasonDayHeatmap(
                    dayStatuses: dayStatuses,
                    onDayTap: (dayIndex) {
                      // Show loading indicator while loading data
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(child: CircularProgressIndicator()),
                      );
                      // Load data asynchronously to prevent blocking
                      Future.microtask(() async {
                        try {
                          final date = season.startDate.add(Duration(days: dayIndex - 1));
                          final summary = await SeasonInsightsService.getDaySummary(
                            seasonId: season.id,
                            dayIndex: dayIndex,
                            season: season,
                            allHabits: await ref.read(habitsProvider.future),
                            seasonHabits: await ref.read(seasonHabitsProvider(season.id).future),
                            database: ref.read(databaseProvider),
                          );
                          final dayStatus = dayStatuses.firstWhere((d) => d.dayIndex == dayIndex);
                          // Dismiss loading overlay before showing bottom sheet
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            DaySummaryBottomSheet.show(
                              context,
                              dayIndex: dayIndex,
                              date: date,
                              score: summary['score'] as int,
                              drivers: summary['drivers'] as Map<String, dynamic>,
                              mood: dayStatus.mood,
                              reflection: dayStatus.reflection,
                              season: season,
                              onOpenDay: () {
                                ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                                ref.read(tabIndexProvider.notifier).state = 0;
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            );
                          }
                        } catch (e) {
                          // Dismiss loading overlay on error
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  // Highlights
                  SeasonHighlightsGrid(
                    highlights: highlights,
                    onTaskTap: (habitKey) {
                      final today = DateTime.now();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HabitAnalyticsTodayScreen(
                            habitKey: habitKey,
                            seasonId: season.id,
                            selectedDate: today,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Sedekah Season Card
                  if (sedekahAnalytics != null) ...[
                    SedekahSeasonCard(
                      data: sedekahAnalytics,
                      currency: currency,
                      season: season,
                      onViewDetails: () {
                        final today = DateTime.now();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HabitAnalyticsTodayScreen(
                              habitKey: 'sedekah',
                              seasonId: season.id,
                              selectedDate: today,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Mood & Reflection
                  MoodReflectionSeasonCard(
                    analytics: reflectionAnalytics,
                    onReviewReflections: () {
                      // TODO: Implement reflection review screen
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reflection review coming soon')),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Task Insights
                  Text(
                    'Task Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ...taskAnalytics.entries.map((entry) {
                    final habitKey = entry.key;
                    final analytics = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SeasonTaskAnalyticsRow(
                        habitKey: habitKey,
                        habitName: _getHabitDisplayNameHelper(habitKey),
                        icon: _getHabitIconHelper(habitKey),
                        analytics: analytics,
                        season: season,
                        onAnalyticsTap: () {
                          final today = DateTime.now();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => HabitAnalyticsTodayScreen(
                                habitKey: habitKey,
                                seasonId: season.id,
                                selectedDate: today,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading season')),
    );
  }

  Future<Map<String, dynamic>> _loadSeasonData(
    WidgetRef ref,
    SeasonModel season,
  ) async {
    try {
      final database = ref.read(databaseProvider);
      final allHabits = await ref.read(habitsProvider.future);
      final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
      
      // Get aggregate
      final aggregate = await SeasonInsightsService.computeSeasonAggregate(
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      // Get trend series
      final trendSeries = await SeasonInsightsService.getSeasonTrendSeries(
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      // Get day statuses
      final dayStatuses = await SeasonInsightsService.getAllSeasonDayStatuses(
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      // Get highlights
      final highlights = await SeasonInsightsService.getSeasonHighlights(
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      // Get task analytics
      final taskAnalytics = <String, TaskSeasonAnalytics>{};
      for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
        final habit = allHabits.firstWhere((h) => h.id == seasonHabit.habitId);
        final habitKey = habit.key;
        
        if (habitKey == 'itikaf') {
          final last10Start = season.days - 9;
          // Only include if season has reached last 10 days
          if (season.days < last10Start) continue;
        }
        
        taskAnalytics[habitKey] = await SeasonInsightsService.getTaskSeasonAnalytics(
          habitKey: habitKey,
          season: season,
          database: database,
          allHabits: allHabits,
          seasonHabits: seasonHabits,
        );
      }
      
      // Get Sedekah analytics
      SedekahSeasonAnalytics? sedekahAnalytics;
      try {
        final sedekahHabit = allHabits.firstWhere(
          (h) => h.key == 'sedekah',
        );
        final sedekahSeasonHabit = seasonHabits.firstWhere(
          (sh) => sh.habitId == sedekahHabit.id,
        );
        if (sedekahSeasonHabit.isEnabled) {
          sedekahAnalytics = await SeasonInsightsService.getSedekahSeasonAnalytics(
            season: season,
            database: database,
            allHabits: allHabits,
            seasonHabits: seasonHabits,
          );
        }
      } catch (e) {
        // Sedekah habit might not exist, skip it
      }
      
      // Get reflection analytics
      final reflectionAnalytics = await SeasonInsightsService.getReflectionSeasonAnalytics(
        season: season,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
      
      final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
      
      return {
        'aggregate': aggregate,
        'trendSeries': trendSeries,
        'dayStatuses': dayStatuses,
        'highlights': highlights,
        'taskAnalytics': taskAnalytics,
        'sedekahAnalytics': sedekahAnalytics,
        'reflectionAnalytics': reflectionAnalytics,
        'currency': currency,
      };
    } catch (e) {
      // Return empty/default data on error
      return {
        'aggregate': (
          seasonScoreAvg: 0,
          totalEarned: 0,
          totalMax: season.days * 100,
          perfectDaysCount: 0,
          missedDaysCount: 0,
          bestStreak: 0,
        ),
        'trendSeries': <({DateTime date, int score})>[],
        'dayStatuses': <SeasonDayStatus>[],
        'highlights': SeasonHighlights(),
        'taskAnalytics': <String, TaskSeasonAnalytics>{},
        'sedekahAnalytics': null,
        'reflectionAnalytics': ReflectionSeasonAnalytics(
          moodCounts: {},
          avgScoreByMood: {},
        ),
        'currency': 'IDR',
      };
    }
  }
}

// Helper functions for habit display
String _getHabitDisplayNameHelper(String habitKey) {
  switch (habitKey) {
    case 'fasting':
      return 'Fasting';
    case 'quran_pages':
      return 'Quran';
    case 'dhikr':
      return 'Dhikr';
    case 'taraweeh':
      return 'Taraweeh';
    case 'sedekah':
      return 'Sedekah';
    case 'prayers':
      return '5 Prayers';
    case 'itikaf':
      return 'I\'tikaf';
    default:
      return habitKey;
  }
}

IconData _getHabitIconHelper(String habitKey) {
  switch (habitKey) {
    case 'fasting':
      return Icons.wb_sunny;
    case 'quran_pages':
      return Icons.menu_book;
    case 'dhikr':
      return Icons.favorite;
    case 'taraweeh':
      return Icons.nights_stay;
    case 'sedekah':
      return Icons.volunteer_activism;
    case 'prayers':
      return Icons.mosque;
    case 'itikaf':
      return Icons.mosque;
    default:
      return Icons.check_circle;
  }
}

// Weekly Review Bottom Sheet
class _WeeklyReviewSheet extends ConsumerWidget {
  final InsightsData data;

  const _WeeklyReviewSheet({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Weekly Review',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Weekly score trend
                      if (data.trendSeries.length > 1) ...[
                        Text(
                          'Score Trend',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: (data.trendSeries.length - 1).toDouble(),
                              minY: 0,
                              maxY: 100,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: data.trendSeries.asMap().entries.map((e) {
                                    return FlSpot(e.key.toDouble(), e.value.score.toDouble());
                                  }).toList(),
                                  isCurved: true,
                                  color: Theme.of(context).colorScheme.primary,
                                  barWidth: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Best and hardest day
                      if (data.trendSeries.isNotEmpty) ...[
                        Row(
                          children: [
                            Expanded(
                              child: PremiumCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.emoji_events, size: 32, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Best Day',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d').format(data.trendSeries.first.date),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Score: ${data.trendSeries.first.score}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: PremiumCard(
                                child: Column(
                                  children: [
                                    Icon(Icons.trending_down, size: 32, color: Theme.of(context).colorScheme.error),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Hardest Day',
                                      style: Theme.of(context).textTheme.titleSmall,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('MMM d').format(data.trendSeries.last.date),
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    Text(
                                      'Score: ${data.trendSeries.last.score}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                      ],
                      // Task links
                      Text(
                        'Task Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...data.perHabitStats.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(_getHabitIconHelper(entry.key), color: Theme.of(context).colorScheme.primary),
                            title: Text(_getHabitDisplayNameHelper(entry.key)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              ref.read(tabIndexProvider.notifier).state = 0;
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

}

// Season Comparison Bottom Sheet
class _SeasonComparisonSheet extends ConsumerWidget {
  const _SeasonComparisonSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comparisonAsync = ref.watch(seasonComparisonProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Compare Seasons',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: comparisonAsync.when(
                  data: (comparison) {
                    if (comparison == null) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No previous season yet',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final current = comparison['current'] as InsightsData;
                    final previous = comparison['previous'] as InsightsData;
                    final currentSeason = comparison['currentSeason'];
                    final previousSeason = comparison['previousSeason'];

                    return SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Season selector info
                          PremiumCard(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current: ${currentSeason.label}',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      'Previous: ${previousSeason.label}',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Comparison metrics
                          _buildComparisonMetric(
                            context,
                            'Avg score',
                            current.avgScore,
                            previous.avgScore,
                          ),
                          _buildComparisonMetric(
                            context,
                            'Perfect days',
                            (current.completionRate * current.daysCount).round(),
                            (previous.completionRate * previous.daysCount).round(),
                          ),
                          // Add more metrics for Quran, Dhikr, Sedekah
                          if (current.perHabitStats.containsKey('quran_pages') && previous.perHabitStats.containsKey('quran_pages'))
                            _buildComparisonMetric(
                              context,
                              'Quran pages',
                              current.perHabitStats['quran_pages']?.totalValue ?? 0,
                              previous.perHabitStats['quran_pages']?.totalValue ?? 0,
                            ),
                          if (current.perHabitStats.containsKey('dhikr') && previous.perHabitStats.containsKey('dhikr'))
                            _buildComparisonMetric(
                              context,
                              'Dhikr total',
                              current.perHabitStats['dhikr']?.totalValue ?? 0,
                              previous.perHabitStats['dhikr']?.totalValue ?? 0,
                            ),
                          if (current.perHabitStats.containsKey('sedekah') && previous.perHabitStats.containsKey('sedekah'))
                            FutureBuilder<String?>(
                              future: ref.read(databaseProvider).kvSettingsDao.getValue('sedekah_currency'),
                              builder: (context, currencySnapshot) {
                                final currency = currencySnapshot.data ?? 'IDR';
                                return _buildComparisonMetricWithCurrency(
                                  context,
                                  'Sedekah total',
                                  current.perHabitStats['sedekah']?.totalAmount ?? 0,
                                  previous.perHabitStats['sedekah']?.totalAmount ?? 0,
                                  currency,
                                );
                              },
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonMetric(BuildContext context, String label, int current, int previous) {
    final delta = current - previous;
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            Row(
              children: [
                Text(
                  '$current',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  delta >= 0 ? '+$delta' : '$delta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: delta >= 0 ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMetricWithCurrency(BuildContext context, String label, int current, int previous, String currency) {
    final delta = current - previous;
    return PremiumCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyLarge),
            Row(
              children: [
                Text(
                  SedekahUtils.formatCurrency(current.toDouble(), currency),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  delta >= 0 ? '+${SedekahUtils.formatCurrency(delta.toDouble(), currency)}' : SedekahUtils.formatCurrency(delta.toDouble(), currency),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: delta >= 0 ? Colors.green : Colors.red,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// What's Missing Bottom Sheet
class _WhatMissingSheet extends ConsumerWidget {
  final InsightsData data;
  final WidgetRef ref;

  const _WhatMissingSheet({required this.data, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'What\'s Missing',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: seasonAsync.when(
                  data: (season) {
                    if (season == null) {
                      return const Center(child: Text('No season found'));
                    }
                    return FutureBuilder<Map<String, dynamic>>(
                      future: _loadMissingTasksData(ref, season, data),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        final missingData = snapshot.data!;
                        final missingTasks = missingData['missingTasks'] as List<Map<String, dynamic>>;
                        final latestMissedDay = missingData['latestMissedDay'] as int?;
                        
                        return SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score: ${data.avgScore}%',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Complete remaining tasks to reach 100%',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                              ),
                              const SizedBox(height: 24),
                              if (missingTasks.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 64,
                                          color: Colors.green,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'All tasks completed!',
                                          style: Theme.of(context).textTheme.titleLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else ...[
                                Text(
                                  'Missing Tasks',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                ...missingTasks.map((task) {
                                  return PremiumCard(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _getHabitIconHelper(task['key'] as String),
                                          size: 24,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                task['name'] as String,
                                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                task['reason'] as String,
                                                style: Theme.of(context).textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 24),
                                if (latestMissedDay != null)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        ref.read(selectedDayIndexProvider.notifier).state = latestMissedDay;
                                        ref.read(tabIndexProvider.notifier).state = 0;
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.calendar_today, size: 18),
                                      label: Text('Audit last missed day (Day $latestMissedDay)'),
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading data')),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadMissingTasksData(WidgetRef ref, SeasonModel season, InsightsData data) async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
    final currentDayIndex = ref.read(currentDayIndexProvider);
    
    final missingTasks = <Map<String, dynamic>>[];
    int? latestMissedDay;
    
    // Get today's entries
    final entries = await database.dailyEntriesDao.getDayEntries(season.id, currentDayIndex);
    final quranDaily = await database.quranDailyDao.getDaily(season.id, currentDayIndex);
    final prayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(season.id, currentDayIndex, currentDayIndex);
    final prayerDetail = prayerDetails.isNotEmpty ? prayerDetails.first : null;
    final quranPlan = await database.quranPlanDao.getPlan(season.id);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(season.id);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    
    // Check each enabled habit
    for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
      final habit = habits.firstWhere((h) => h.id == seasonHabit.habitId);
      final habitKey = habit.key;
      
      // Skip Itikaf if not in last 10 nights
      final last10Start = season.days - 9;
      if (habitKey == 'itikaf' && currentDayIndex < last10Start) {
        continue;
      }
      
      final entry = entries.firstWhere(
        (e) => e.habitId == habit.id,
        orElse: () => DailyEntry(seasonId: season.id, dayIndex: currentDayIndex, habitId: habit.id, updatedAt: 0),
      );
      
      bool isMissing = false;
      String reason = '';
      
      switch (habitKey) {
        case 'fasting':
        case 'taraweeh':
        case 'itikaf':
          isMissing = entry.valueBool != true;
          reason = 'Not completed';
          break;
        case 'quran_pages':
          final pages = quranDaily?.pagesRead ?? 0;
          final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
          isMissing = pages < target;
          reason = 'Only $pages/$target pages';
          break;
        case 'dhikr':
          final count = entry.valueInt ?? 0;
          final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
          isMissing = count < target;
          reason = 'Only $count/$target';
          break;
        case 'sedekah':
          final amount = entry.valueInt ?? 0;
          final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
          if (target != null) {
            isMissing = amount < target.toInt();
            reason = 'Only ${SedekahUtils.formatCurrency(amount.toDouble(), await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR')}/${SedekahUtils.formatCurrency(target, await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR')}';
          } else {
            isMissing = amount == 0;
            reason = 'No donation today';
          }
          break;
        case 'prayers':
          if (prayerDetail != null) {
            final completed = [
              prayerDetail.fajr,
              prayerDetail.dhuhr,
              prayerDetail.asr,
              prayerDetail.maghrib,
              prayerDetail.isha,
            ].where((p) => p).length;
            isMissing = completed < 5;
            reason = 'Only $completed/5 prayers';
          } else {
            isMissing = true;
            reason = 'No prayers logged';
          }
          break;
      }
      
      if (isMissing) {
        missingTasks.add({
          'key': habitKey,
          'name': _getHabitDisplayNameHelper(habitKey),
          'reason': reason,
        });
        
        // Find latest missed day for this habit
        final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(season.id);
        final allQuranDaily = await database.quranDailyDao.getAllDaily(season.id);
        final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(season.id, 1, currentDayIndex);
        
        for (int day = currentDayIndex; day >= 1; day--) {
          bool dayMissed = false;
          
          switch (habitKey) {
            case 'fasting':
            case 'taraweeh':
            case 'itikaf':
              final dayEntry = allEntries.firstWhere(
                (e) => e.dayIndex == day && e.habitId == habit.id,
                orElse: () => DailyEntry(seasonId: season.id, dayIndex: day, habitId: habit.id, updatedAt: 0),
              );
              dayMissed = dayEntry.valueBool != true;
              break;
            case 'quran_pages':
              final dayQuran = allQuranDaily.firstWhere(
                (q) => q.dayIndex == day,
                orElse: () => QuranDailyData(seasonId: season.id, dayIndex: day, pagesRead: 0, updatedAt: 0),
              );
              final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
              dayMissed = dayQuran.pagesRead < target;
              break;
            case 'dhikr':
              final dayEntry = allEntries.firstWhere(
                (e) => e.dayIndex == day && e.habitId == habit.id,
                orElse: () => DailyEntry(seasonId: season.id, dayIndex: day, habitId: habit.id, updatedAt: 0),
              );
              final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
              dayMissed = (dayEntry.valueInt ?? 0) < target;
              break;
            case 'sedekah':
              final dayEntry = allEntries.firstWhere(
                (e) => e.dayIndex == day && e.habitId == habit.id,
                orElse: () => DailyEntry(seasonId: season.id, dayIndex: day, habitId: habit.id, updatedAt: 0),
              );
              final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
              if (target != null) {
                dayMissed = (dayEntry.valueInt ?? 0) < target.toInt();
              } else {
                dayMissed = (dayEntry.valueInt ?? 0) == 0;
              }
              break;
            case 'prayers':
              final dayPrayer = allPrayerDetails.firstWhere(
                (p) => p.dayIndex == day,
                orElse: () => PrayerDetail(seasonId: season.id, dayIndex: day, fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false, updatedAt: 0),
              );
              final completed = [
                dayPrayer.fajr,
                dayPrayer.dhuhr,
                dayPrayer.asr,
                dayPrayer.maghrib,
                dayPrayer.isha,
              ].where((p) => p).length;
              dayMissed = completed < 5;
              break;
          }
          
          if (dayMissed) {
            if (latestMissedDay == null || day > latestMissedDay) {
              latestMissedDay = day;
            }
            break; // Found a missed day for this habit
          }
        }
      }
    }
    
    return {
      'missingTasks': missingTasks,
      'latestMissedDay': latestMissedDay,
    };
  }

  String _getHabitDisplayNameHelper(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return 'Fasting';
      case 'quran_pages':
        return 'Quran';
      case 'dhikr':
        return 'Dhikr';
      case 'taraweeh':
        return 'Taraweeh';
      case 'sedekah':
        return 'Sedekah';
      case 'prayers':
        return '5 Prayers';
      case 'itikaf':
        return 'I\'tikaf';
      default:
        return habitKey;
    }
  }

  IconData _getHabitIconHelper(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return Icons.wb_sunny;
      case 'quran_pages':
        return Icons.menu_book;
      case 'dhikr':
        return Icons.favorite;
      case 'taraweeh':
        return Icons.nights_stay;
      case 'sedekah':
        return Icons.volunteer_activism;
      case 'prayers':
        return Icons.mosque;
      case 'itikaf':
        return Icons.mosque;
      default:
        return Icons.check_circle;
    }
  }
}

// Today Review Bottom Sheet
class _TodayReviewSheet extends ConsumerWidget {
  final InsightsData data;

  const _TodayReviewSheet({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Today Review',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score: ${data.avgScore}%',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Completion breakdown and score drivers for today will be shown here.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      // TODO: Add detailed breakdown
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
