import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart' show currentDayIndexProvider;
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/features/insights/services/insights_scoring_service.dart';

/// Task Detail analytics screen for a specific habit and date.
class HabitAnalyticsTodayScreen extends ConsumerStatefulWidget {
  final String habitKey;
  final int seasonId;
  final DateTime? selectedDate;

  const HabitAnalyticsTodayScreen({
    super.key,
    required this.habitKey,
    required this.seasonId,
    this.selectedDate,
  });

  @override
  ConsumerState<HabitAnalyticsTodayScreen> createState() => _HabitAnalyticsTodayScreenState();
}

class _HabitAnalyticsTodayScreenState extends ConsumerState<HabitAnalyticsTodayScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getHabitDisplayName(widget.habitKey)),
      ),
      body: seasonAsync.when(
        data: (season) {
          final l10n = AppLocalizations.of(context)!;
          if (season == null) return Center(child: Text(l10n.noSeasonFound));
          return habitsAsync.when(
            data: (habits) {
              final habit = habits.firstWhere((h) => h.key == widget.habitKey);
              final selectedDate = _selectedDate ?? DateTime.now();
              final dayIndex = season.getDayIndex(selectedDate);
              final isToday = _isToday(selectedDate);
              
              return FutureBuilder<Map<String, dynamic>>(
                future: _loadTaskData(season, habit, dayIndex),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data!;
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header / Hero
                        _buildHeader(context, ref, season, habit, selectedDate, dayIndex, isToday, data),
                        const SizedBox(height: 24),
                        // Today/Selected Day Breakdown
                        _buildTodayBreakdownCard(context, data, selectedDate, dayIndex),
                        const SizedBox(height: 24),
                        // Score Breakdown
                        _buildScoreBreakdownCard(context, ref, season, habit, dayIndex, data),
                        const SizedBox(height: 24),
                        // Trend & Pattern
                        _buildTrendPatternCard(context, ref, season, habit, dayIndex),
                        const SizedBox(height: 24),
                        // Missed Days
                        _buildMissedDaysCard(context, ref, season, data),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<Map<String, dynamic>> _loadTaskData(SeasonModel season, HabitModel habit, int dayIndex) async {
    final database = ref.read(databaseProvider);
    final seasonHabits = await ref.read(seasonHabitsProvider(widget.seasonId).future);
    final seasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == habit.id);
    
    final entries = await database.dailyEntriesDao.getDayEntries(widget.seasonId, dayIndex);
    final entry = entries.firstWhere(
      (e) => e.habitId == habit.id,
      orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: dayIndex, habitId: habit.id, updatedAt: 0),
    );

    Map<String, dynamic> data = {
      'habit': habit,
      'seasonHabit': seasonHabit,
      'entry': entry,
      'dayIndex': dayIndex,
    };

    // Load specific data based on habit type
    if (habit.key == 'quran_pages') {
      final quranDaily = await database.quranDailyDao.getDaily(widget.seasonId, dayIndex);
      final quranPlan = await database.quranPlanDao.getPlan(widget.seasonId);
      data['quranDaily'] = quranDaily;
      data['quranPlan'] = quranPlan;
      data['pagesRead'] = quranDaily?.pagesRead ?? 0;
      data['target'] = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
    } else if (habit.key == 'dhikr') {
      final dhikrPlan = await database.dhikrPlanDao.getPlan(widget.seasonId);
      data['count'] = entry.valueInt ?? 0;
      data['target'] = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
    } else if (habit.key == 'sedekah') {
      final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
      final goalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
      final goalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
      data['amount'] = entry.valueInt ?? 0;
      data['currency'] = currency;
      data['target'] = goalEnabled == 'true' && goalAmount != null ? double.tryParse(goalAmount) : null;
    } else if (habit.key == 'prayers') {
      final prayerDetail = await database.prayerDetailsDao.getPrayerDetails(widget.seasonId, dayIndex);
      data['prayerDetail'] = prayerDetail;
    } else if (habit.key == 'taraweeh') {
      final targetRakaatRaw = await database.kvSettingsDao.getValue('taraweeh_rakaat_per_day');
      data['rakaat'] = entry.valueInt ?? 0;
      data['targetRakaat'] = int.tryParse(targetRakaatRaw ?? '') ?? 11;
    }

    // Load missed days data
    final missedDaysData = await _loadMissedDaysData(season, habit, seasonHabit);
    data['missedDays'] = missedDaysData['missedDays'] as List<int>;
    data['hasMissedDays'] = missedDaysData['hasMissedDays'] as bool;

    return data;
  }

  Future<Map<String, dynamic>> _loadMissedDaysData(SeasonModel season, HabitModel habit, SeasonHabitModel seasonHabit) async {
    final database = ref.read(databaseProvider);
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(widget.seasonId);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(widget.seasonId);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(widget.seasonId, 1, season.days);
    final quranPlan = await database.quranPlanDao.getPlan(widget.seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(widget.seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    
    final missedDays = <int>[];
    final last10Start = season.days - 9;
    final currentDayIndex = ref.read(currentDayIndexProvider);
    
    for (int day = 1; day <= currentDayIndex; day++) {
      // Skip Itikaf if not in last 10 nights
      if (habit.key == 'itikaf' && day < last10Start) {
        continue;
      }
      
      bool isMissed = false;
      
      switch (habit.key) {
        case 'fasting':
        case 'taraweeh':
        case 'tahajud':
        case 'itikaf':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueBool: false, updatedAt: 0),
          );
          isMissed = entry.valueBool != true;
          break;
        case 'quran_pages':
          final quran = allQuranDaily.firstWhere(
            (q) => q.dayIndex == day,
            orElse: () => QuranDailyData(seasonId: widget.seasonId, dayIndex: day, pagesRead: 0, updatedAt: 0),
          );
          final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
          isMissed = quran.pagesRead < target;
          break;
        case 'dhikr':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
          isMissed = (entry.valueInt ?? 0) < target;
          break;
        case 'sedekah':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
          if (target != null) {
            isMissed = (entry.valueInt ?? 0) < target.toInt();
          } else {
            isMissed = (entry.valueInt ?? 0) == 0;
          }
          break;
        case 'prayers':
          final prayer = allPrayerDetails.firstWhere(
            (p) => p.dayIndex == day,
            orElse: () => PrayerDetail(seasonId: widget.seasonId, dayIndex: day, fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false, updatedAt: 0),
          );
          final completed = [
            prayer.fajr,
            prayer.dhuhr,
            prayer.asr,
            prayer.maghrib,
            prayer.isha,
          ].where((p) => p).length;
          isMissed = completed < 5;
          break;
      }
      
      if (isMissed) {
        missedDays.add(day);
      }
    }
    
    return {
      'missedDays': missedDays,
      'hasMissedDays': missedDays.isNotEmpty,
    };
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, SeasonModel season, HabitModel habit, DateTime selectedDate, int dayIndex, bool isToday, Map<String, dynamic> data) {
    final status = _getStatus(data);
    final statusColor = _getStatusColor(status);
    
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Task name + icon
          Row(
            children: [
              getHabitIconWidget(
                context,
                habit.key,
                size: 24,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getHabitDisplayName(habit.key),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Status pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Text(
                  status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Date selector (tap to change)
          InkWell(
            onTap: () => _selectDate(context, ref, season),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('MMM d, yyyy').format(selectedDate)} • Day $dayIndex',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_drop_down,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Primary CTA
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to Today screen with selected date
                ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
                ref.read(tabIndexProvider.notifier).state = 0;
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              icon: Icon(isToday ? Icons.today : Icons.calendar_today, size: 18),
              label: Text(isToday ? AppLocalizations.of(context)!.goToToday : AppLocalizations.of(context)!.auditDay(dayIndex)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, WidgetRef ref, SeasonModel season) async {
    final now = DateTime.now();
    final startDate = season.startDate;
    final endDate = startDate.add(Duration(days: season.days - 1));
    final maxDate = endDate.isAfter(now) ? now : endDate;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: startDate,
      lastDate: maxDate,
      helpText: AppLocalizations.of(context)!.selectDayToAnalyze,
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildTodayBreakdownCard(BuildContext context, Map<String, dynamic> data, DateTime selectedDate, int dayIndex) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.todayBreakdown,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          _buildTodayBreakdownContent(context, data, selectedDate, dayIndex),
        ],
      ),
    );
  }

  Widget _buildTodayBreakdownContent(BuildContext context, Map<String, dynamic> data, DateTime selectedDate, int dayIndex) {
    final habit = data['habit'] as HabitModel;
    
    switch (habit.key) {
      case 'taraweeh':
        final entry = data['entry'] as DailyEntry;
        final done = entry.valueBool == true;
        final rakaat = data['rakaat'] as int? ?? 0;
        final targetRakaat = data['targetRakaat'] as int? ?? 11;
        final updatedAt = entry.updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(entry.updatedAt) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.cancel,
                  color: done ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    done ? AppLocalizations.of(context)!.completed : AppLocalizations.of(context)!.notCompleted,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: done ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rakaat',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '$rakaat/$targetRakaat rakaat',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.lastUpdated}: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ],
        );
      case 'fasting':
      case 'tahajud':
      case 'itikaf':
        final entry = data['entry'] as DailyEntry;
        final done = entry.valueBool == true;
        final updatedAt = entry.updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(entry.updatedAt) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.cancel,
                  color: done ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    done ? AppLocalizations.of(context)!.completed : AppLocalizations.of(context)!.notCompleted,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: done ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.lastUpdated}: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ],
        );
      case 'quran_pages':
        final pages = data['pagesRead'] as int;
        final target = data['target'] as int;
        final quranDaily = data['quranDaily'] as QuranDailyData?;
        final updatedAt = quranDaily?.updatedAt != null && quranDaily!.updatedAt > 0 
            ? DateTime.fromMillisecondsSinceEpoch(quranDaily.updatedAt) 
            : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.pagesRead,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '$pages/$target',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: target > 0 ? (pages / target).clamp(0.0, 1.0) : (pages > 0 ? 1.0 : 0.0),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                pages >= target ? Colors.green : (pages > 0 ? Colors.orange : Colors.red),
              ),
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.lastUpdated}: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ],
        );
      case 'dhikr':
        final count = data['count'] as int;
        final target = data['target'] as int;
        final entry = data['entry'] as DailyEntry;
        final updatedAt = entry.updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(entry.updatedAt) : null;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.count,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                Text(
                  '$count/$target',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: target > 0 ? (count / target).clamp(0.0, 1.0) : (count > 0 ? 1.0 : 0.0),
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                count >= target ? Colors.green : (count > 0 ? Colors.orange : Colors.red),
              ),
            ),
            if (updatedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                '${AppLocalizations.of(context)!.lastUpdated}: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ],
        );
      case 'sedekah':
        final amount = data['amount'] as int;
        final target = data['target'] as double?;
        final currency = data['currency'] as String;
        final entry = data['entry'] as DailyEntry;
        final updatedAt = entry.updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(entry.updatedAt) : null;
        if (target != null && target > 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.amountGiven,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    SedekahUtils.formatCurrency(amount.toDouble(), currency),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${AppLocalizations.of(context)!.target}: ${SedekahUtils.formatCurrency(target, currency)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (amount / target).clamp(0.0, 1.0),
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  amount >= target.toInt() ? Colors.green : (amount > 0 ? Colors.orange : Colors.red),
                ),
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    amount > 0 ? Icons.check_circle : Icons.cancel,
                    color: amount > 0 ? Colors.green : Colors.red,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      amount > 0 
                          ? AppLocalizations.of(context)!.given(SedekahUtils.formatCurrency(amount.toDouble(), currency))
                          : AppLocalizations.of(context)!.noDonation,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: amount > 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
              if (updatedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ],
          );
        }
      case 'prayers':
        final prayerDetail = data['prayerDetail'] as PrayerDetail?;
        if (prayerDetail != null) {
          final completed = [
            prayerDetail.fajr,
            prayerDetail.dhuhr,
            prayerDetail.asr,
            prayerDetail.maghrib,
            prayerDetail.isha,
          ].where((p) => p).length;
          final updatedAt = prayerDetail.updatedAt > 0 ? DateTime.fromMillisecondsSinceEpoch(prayerDetail.updatedAt) : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.prayersCompleted,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '$completed/5',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPrayerChips(context, prayerDetail),
              if (updatedAt != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Last updated: ${DateFormat('MMM d, h:mm a').format(updatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                ),
              ],
            ],
          );
        } else {
          return Text(
            'No prayers logged',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
          );
        }
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPrayerChips(BuildContext context, PrayerDetail prayer) {
    final prayers = [
      {'name': 'Fajr', 'done': prayer.fajr},
      {'name': 'Dhuhr', 'done': prayer.dhuhr},
      {'name': 'Asr', 'done': prayer.asr},
      {'name': 'Maghrib', 'done': prayer.maghrib},
      {'name': 'Isha', 'done': prayer.isha},
    ];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: prayers.map((p) {
        final done = p['done'] as bool;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: done 
                ? Colors.green.withOpacity(0.2)
                : Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: done 
                  ? Colors.green.withOpacity(0.5)
                  : Colors.red.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                done ? Icons.check_circle : Icons.cancel,
                color: done ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                p['name'] as String,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: done ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildScoreBreakdownCard(BuildContext context, WidgetRef ref, SeasonModel season, HabitModel habit, int dayIndex, Map<String, dynamic> data) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _calculateScoreBreakdown(context, ref, season, habit, dayIndex, data),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return PremiumCard(
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final scoreData = snapshot.data!;
        final pointsEarned = scoreData['pointsEarned'] as int;
        final reason = scoreData['reason'] as String;
        final toImprove = scoreData['toImprove'] as String?;
        
        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.scoreBreakdown,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.pointsEarned}: ',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    '+$pointsEarned',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: pointsEarned > 0 ? Colors.green : Colors.red,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${AppLocalizations.of(context)!.reason}: $reason',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
              ),
              if (toImprove != null) ...[
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.toImprove(toImprove),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _calculateScoreBreakdown(BuildContext context, WidgetRef ref, SeasonModel season, HabitModel habit, int dayIndex, Map<String, dynamic> data) async {
    final database = ref.read(databaseProvider);
    final allHabits = await ref.read(habitsProvider.future);
    final seasonHabits = await ref.read(seasonHabitsProvider(widget.seasonId).future);
    final entries = await database.dailyEntriesDao.getDayEntries(widget.seasonId, dayIndex);
    final quranDaily = await database.quranDailyDao.getDaily(widget.seasonId, dayIndex);
    final prayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(widget.seasonId, dayIndex, dayIndex);
    final prayerDetail = prayerDetails.isNotEmpty ? prayerDetails.first : null;
    
    // Convert DailyEntry to DailyEntryModel
    final entriesModel = entries.map((e) => DailyEntryModel(
      seasonId: e.seasonId,
      dayIndex: e.dayIndex,
      habitId: e.habitId,
      valueBool: e.valueBool,
      valueInt: e.valueInt,
      note: e.note,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(e.updatedAt),
    )).toList();
    
    // Get habit-specific weight and progress
    final seasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == habit.id);
    int weight = 0;
    double progress = 0.0;
    String reason = '';
    String? toImprove;
    
    switch (habit.key) {
      case 'fasting':
        weight = InsightsScoringService.weightFasting;
        final entry = entriesModel.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(seasonId: widget.seasonId, dayIndex: dayIndex, habitId: habit.id, valueBool: false, updatedAt: DateTime.now()),
        );
        final l10n = AppLocalizations.of(context)!;
        progress = entry.valueBool == true ? 1.0 : 0.0;
        reason = progress >= 1.0 ? l10n.fastingCompleted : l10n.fastingNotCompleted;
        if (progress < 1.0) {
          toImprove = l10n.completeFastingToGain(weight);
        }
        break;
      case 'prayers':
        weight = InsightsScoringService.weightPrayers;
        if (prayerDetail != null) {
          final completedCount = [
            prayerDetail.fajr,
            prayerDetail.dhuhr,
            prayerDetail.asr,
            prayerDetail.maghrib,
            prayerDetail.isha,
          ].where((p) => p).length;
          final l10n = AppLocalizations.of(context)!;
          progress = completedCount / 5.0;
          reason = completedCount == 5 
              ? l10n.all5PrayersCompleted
              : l10n.onlyPrayersCompleted(completedCount);
          if (progress < 1.0) {
            toImprove = l10n.completeRemainingPrayers(5 - completedCount, (weight * (1.0 - progress)).round());
          }
        } else {
          final l10n = AppLocalizations.of(context)!;
          progress = 0.0;
          reason = l10n.noPrayersLogged;
          toImprove = l10n.logAll5Prayers(weight);
        }
        break;
      case 'quran_pages':
        final l10n = AppLocalizations.of(context)!;
        weight = InsightsScoringService.weightQuran;
        final target = data['target'] as int;
        final pages = data['pagesRead'] as int;
        if (target > 0) {
          progress = (pages / target).clamp(0.0, 1.0);
          reason = progress >= 1.0 
              ? l10n.targetMetPages(pages, target)
              : progress > 0
                  ? l10n.partialCompletionPages(pages, target)
                  : l10n.targetNotMetPages(target);
          if (progress < 1.0) {
            final remaining = target - pages;
            toImprove = l10n.readMorePages(remaining, (weight * (1.0 - progress)).round());
          }
        } else {
          progress = pages > 0 ? 1.0 : 0.0;
          reason = pages > 0 ? l10n.pagesRead : l10n.noPagesRead;
          if (progress < 1.0) {
            toImprove = l10n.readPagesToGain(weight);
          }
        }
        break;
      case 'dhikr':
        final l10n = AppLocalizations.of(context)!;
        weight = InsightsScoringService.weightDhikr;
        final target = data['target'] as int;
        final count = data['count'] as int;
        if (target > 0) {
          progress = (count / target).clamp(0.0, 1.0);
          reason = progress >= 1.0 
              ? l10n.targetMetCount(count, target)
              : progress > 0
                  ? l10n.partialCompletionCount(count, target)
                  : l10n.targetNotMetCount(target);
          if (progress < 1.0) {
            final remaining = target - count;
            toImprove = l10n.completeMoreToGain(remaining, (weight * (1.0 - progress)).round());
          }
        } else {
          progress = count > 0 ? 1.0 : 0.0;
          reason = count > 0 ? l10n.dhikrCompleted : l10n.noDhikrLogged;
          if (progress < 1.0) {
            toImprove = l10n.completeDhikrToGain(weight);
          }
        }
        break;
      case 'taraweeh':
        final l10n = AppLocalizations.of(context)!;
        weight = InsightsScoringService.weightTaraweeh;
        final entry = entriesModel.firstWhere(
          (e) => e.habitId == habit.id,
          orElse: () => DailyEntryModel(seasonId: widget.seasonId, dayIndex: dayIndex, habitId: habit.id, valueBool: false, updatedAt: DateTime.now()),
        );
        progress = entry.valueBool == true ? 1.0 : 0.0;
        reason = progress >= 1.0 ? l10n.taraweehCompleted : l10n.taraweehNotCompleted;
        if (progress < 1.0) {
          toImprove = l10n.completeTaraweehToGain(weight);
        }
        break;
      case 'sedekah':
        final l10n = AppLocalizations.of(context)!;
        weight = InsightsScoringService.weightSedekah;
        final target = data['target'] as double?;
        final amount = data['amount'] as int;
        final currency = data['currency'] as String;
        if (target != null && target > 0) {
          progress = (amount / target).clamp(0.0, 1.0);
          reason = progress >= 1.0 
              ? l10n.goalMet
              : progress > 0
                  ? l10n.partialGiving
                  : l10n.noGiving;
          if (progress < 1.0) {
            final remaining = (target - amount).round();
            toImprove = l10n.giveMoreToGain(SedekahUtils.formatCurrency(remaining.toDouble(), currency), (weight * (1.0 - progress)).round());
          }
        } else {
          progress = amount > 0 ? 1.0 : 0.0;
          reason = amount > 0 ? l10n.given(SedekahUtils.formatCurrency(amount.toDouble(), currency)) : l10n.noGiving;
          if (progress < 1.0) {
            toImprove = l10n.giveToGain(weight);
          }
        }
        break;
      case 'itikaf':
        final last10Start = season.days - 9;
        if (dayIndex >= last10Start) {
          weight = InsightsScoringService.weightItikaf;
          final entry = entriesModel.firstWhere(
            (e) => e.habitId == habit.id,
            orElse: () => DailyEntryModel(seasonId: widget.seasonId, dayIndex: dayIndex, habitId: habit.id, valueBool: false, updatedAt: DateTime.now()),
          );
          final l10n = AppLocalizations.of(context)!;
          progress = entry.valueBool == true ? 1.0 : 0.0;
          reason = progress >= 1.0 ? l10n.itikafCompleted : l10n.itikafNotCompleted;
          if (progress < 1.0) {
            toImprove = l10n.completeItikafToGain(weight);
          }
        } else {
          weight = 0;
          progress = 0.0;
          reason = 'Not in last 10 nights';
        }
        break;
    }
    
    final pointsEarned = (weight * progress).round();
    
    return {
      'pointsEarned': pointsEarned,
      'reason': reason,
      'toImprove': toImprove,
    };
  }

  Widget _buildTrendPatternCard(BuildContext context, WidgetRef ref, SeasonModel season, HabitModel habit, int dayIndex) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadTrendPatternData(ref, season, habit, dayIndex),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return PremiumCard(
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final trendData = snapshot.data!;
        final sparklineData = trendData['sparklineData'] as List<double>;
        final bestStreak = trendData['bestStreak'] as int;
        final missCount = trendData['missCount'] as int;
        
        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.trendPattern,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // 7-day sparkline
              if (sparklineData.isNotEmpty) ...[
                SizedBox(
                  height: 80,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (sparklineData.length - 1).toDouble(),
                      minY: 0,
                      maxY: 1.0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: sparklineData.asMap().entries.map((e) {
                            return FlSpot(e.key.toDouble(), e.value);
                          }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Metrics
              Row(
                children: [
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      AppLocalizations.of(context)!.bestStreakLabel,
                      AppLocalizations.of(context)!.daysCount(bestStreak),
                      Icons.local_fire_department,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricChip(
                      context,
                      AppLocalizations.of(context)!.missCount,
                      AppLocalizations.of(context)!.daysCount(missCount),
                      Icons.cancel_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricChip(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadTrendPatternData(WidgetRef ref, SeasonModel season, HabitModel habit, int dayIndex) async {
    final database = ref.read(databaseProvider);
    final allEntries = await database.dailyEntriesDao.getAllSeasonEntries(widget.seasonId);
    final allQuranDaily = await database.quranDailyDao.getAllDaily(widget.seasonId);
    final allPrayerDetails = await database.prayerDetailsDao.getPrayerDetailsRange(widget.seasonId, 1, season.days);
    final quranPlan = await database.quranPlanDao.getPlan(widget.seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(widget.seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final seasonHabits = await ref.read(seasonHabitsProvider(widget.seasonId).future);
    final seasonHabit = seasonHabits.firstWhere((sh) => sh.habitId == habit.id);
    
    // Build 7-day sparkline ending at selected day
    final sparklineData = <double>[];
    final startDay = (dayIndex - 6).clamp(1, dayIndex);
    
    for (int day = startDay; day <= dayIndex; day++) {
      double completion = 0.0;
      
      switch (habit.key) {
        case 'fasting':
        case 'taraweeh':
        case 'tahajud':
        case 'itikaf':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueBool: false, updatedAt: 0),
          );
          completion = entry.valueBool == true ? 1.0 : 0.0;
          break;
        case 'quran_pages':
          final quran = allQuranDaily.firstWhere(
            (q) => q.dayIndex == day,
            orElse: () => QuranDailyData(seasonId: widget.seasonId, dayIndex: day, pagesRead: 0, updatedAt: 0),
          );
          final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
          completion = target > 0 ? (quran.pagesRead / target).clamp(0.0, 1.0) : (quran.pagesRead > 0 ? 1.0 : 0.0);
          break;
        case 'dhikr':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
          completion = target > 0 ? ((entry.valueInt ?? 0) / target).clamp(0.0, 1.0) : ((entry.valueInt ?? 0) > 0 ? 1.0 : 0.0);
          break;
        case 'sedekah':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
          final amount = entry.valueInt ?? 0;
          completion = target != null && target > 0 ? (amount / target).clamp(0.0, 1.0) : (amount > 0 ? 1.0 : 0.0);
          break;
        case 'prayers':
          final prayer = allPrayerDetails.firstWhere(
            (p) => p.dayIndex == day,
            orElse: () => PrayerDetail(seasonId: widget.seasonId, dayIndex: day, fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false, updatedAt: 0),
          );
          final completed = [
            prayer.fajr,
            prayer.dhuhr,
            prayer.asr,
            prayer.maghrib,
            prayer.isha,
          ].where((p) => p).length;
          completion = completed / 5.0;
          break;
      }
      
      sparklineData.add(completion);
    }
    
    // Calculate best streak and miss count
    int bestStreak = 0;
    int currentStreak = 0;
    int missCount = 0;
    final last10Start = season.days - 9;
    
    for (int day = 1; day <= dayIndex; day++) {
      if (habit.key == 'itikaf' && day < last10Start) continue;
      
      bool isDone = false;
      switch (habit.key) {
        case 'fasting':
        case 'taraweeh':
        case 'tahajud':
        case 'itikaf':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueBool: false, updatedAt: 0),
          );
          isDone = entry.valueBool == true;
          break;
        case 'quran_pages':
          final quran = allQuranDaily.firstWhere(
            (q) => q.dayIndex == day,
            orElse: () => QuranDailyData(seasonId: widget.seasonId, dayIndex: day, pagesRead: 0, updatedAt: 0),
          );
          final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
          isDone = quran.pagesRead >= target;
          break;
        case 'dhikr':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
          isDone = (entry.valueInt ?? 0) >= target;
          break;
        case 'sedekah':
          final entry = allEntries.firstWhere(
            (e) => e.dayIndex == day && e.habitId == habit.id,
            orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: day, habitId: habit.id, valueInt: 0, updatedAt: 0),
          );
          final target = sedekahGoalEnabled == 'true' && sedekahGoalAmount != null ? double.tryParse(sedekahGoalAmount) : null;
          if (target != null) {
            isDone = (entry.valueInt ?? 0) >= target.toInt();
          } else {
            isDone = (entry.valueInt ?? 0) > 0;
          }
          break;
        case 'prayers':
          final prayer = allPrayerDetails.firstWhere(
            (p) => p.dayIndex == day,
            orElse: () => PrayerDetail(seasonId: widget.seasonId, dayIndex: day, fajr: false, dhuhr: false, asr: false, maghrib: false, isha: false, updatedAt: 0),
          );
          final completed = [
            prayer.fajr,
            prayer.dhuhr,
            prayer.asr,
            prayer.maghrib,
            prayer.isha,
          ].where((p) => p).length;
          isDone = completed == 5;
          break;
      }
      
      if (isDone) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
        missCount++;
      }
    }
    
    return {
      'sparklineData': sparklineData,
      'bestStreak': bestStreak,
      'missCount': missCount,
    };
  }

  Widget _buildMissedDaysCard(BuildContext context, WidgetRef ref, SeasonModel season, Map<String, dynamic> data) {
    final missedDays = data['missedDays'] as List<int>? ?? [];
    final hasMissedDays = data['hasMissedDays'] as bool? ?? false;
    
    if (!hasMissedDays || missedDays.isEmpty) {
      return PremiumCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No missed days. Great consistency!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.green,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.missedDays,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${missedDays.length} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: missedDays.map((day) {
              return InkWell(
                onTap: () {
                  // Update selected date and reload
                  final seasonAsync = ref.read(currentSeasonProvider);
                  seasonAsync.whenData((season) {
                    if (season != null) {
                      final date = season.getDateForDay(day);
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Day $day',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _getStatus(Map<String, dynamic> data) {
    final habit = data['habit'] as HabitModel;
    
    switch (habit.key) {
      case 'fasting':
      case 'taraweeh':
      case 'tahajud':
      case 'itikaf':
        final entry = data['entry'] as DailyEntry;
        return entry.valueBool == true ? 'Done' : 'Miss';
      case 'quran_pages':
        final pages = data['pagesRead'] as int;
        final target = data['target'] as int;
        if (pages >= target) return 'Done';
        if (pages > 0) return 'Partial';
        return 'Miss';
      case 'dhikr':
        final count = data['count'] as int;
        final target = data['target'] as int;
        if (count >= target) return 'Done';
        if (count > 0) return 'Partial';
        return 'Miss';
      case 'sedekah':
        final amount = data['amount'] as int;
        final target = data['target'] as double?;
        if (target != null) {
          if (amount >= target.toInt()) return 'Done';
          if (amount > 0) return 'Partial';
          return 'Miss';
        }
        return amount > 0 ? 'Done' : 'Miss';
      case 'prayers':
        final prayerDetail = data['prayerDetail'] as PrayerDetail?;
        if (prayerDetail != null) {
          final completed = [
            prayerDetail.fajr,
            prayerDetail.dhuhr,
            prayerDetail.asr,
            prayerDetail.maghrib,
            prayerDetail.isha,
          ].where((p) => p).length;
          if (completed == 5) return 'Done';
          if (completed > 0) return 'Partial';
          return 'Miss';
        }
        return 'Miss';
      default:
        return 'Unknown';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Done':
        return Colors.green;
      case 'Partial':
        return Colors.orange;
      case 'Miss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getHabitIcon(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return Icons.no_meals;
      case 'quran_pages':
        return Icons.menu_book;
      case 'dhikr':
        return Icons.favorite;
      case 'taraweeh':
        return Icons.nights_stay;
      case 'tahajud':
        return Icons.self_improvement;
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

  String _getHabitDisplayName(String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return 'Fasting';
      case 'quran_pages':
        return 'Quran';
      case 'dhikr':
        return 'Dhikr';
      case 'taraweeh':
        return 'Taraweeh';
      case 'tahajud':
        return 'Tahajud';
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
}
