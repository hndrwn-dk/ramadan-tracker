import 'package:flutter/material.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/habit_trend_item.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/services/weekly_insights_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

/// 7-day habit trends for Today home (current week vs previous week).
class TodayHabitTrendsService {
  TodayHabitTrendsService._();

  static const _habitOrder = [
    'fasting',
    'quran_pages',
    'prayers',
    'dhikr',
    'taraweeh',
    'sedekah',
    'tahajud',
    'itikaf',
  ];

  static Future<List<HabitTrendItem>> trends({
    required AppDatabase database,
    required SeasonModel season,
    required int dayIndex,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    required AppLocalizations l10n,
  }) async {
    final enabled = seasonHabits.where((sh) => sh.isEnabled).toList();
    if (enabled.isEmpty || dayIndex < 1) return [];

    final end = dayIndex.clamp(1, season.days);
    final start = (end - 6).clamp(1, end);
    final prevEnd = start - 1;
    final hasPrevious = prevEnd >= 1;
    final prevStart = hasPrevious ? (prevEnd - 6).clamp(1, prevEnd) : 1;

    final items = <HabitTrendItem>[];

    for (final habitKey in _habitOrder) {
      final seasonHabit = enabled
          .where((sh) {
            final h = allHabits.where((habit) => habit.id == sh.habitId).firstOrNull;
            return h?.key == habitKey;
          })
          .firstOrNull;
      if (seasonHabit == null) continue;

      if (habitKey == 'itikaf') {
        final last10Start = season.days - 9;
        if (end < last10Start) continue;
      }

      final current = await WeeklyInsightsService.getWeeklyTaskSummary(
        habitKey: habitKey,
        season: season,
        startDayIndex: start,
        endDayIndex: end,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );

      WeeklyTaskStatus? previous;
      if (hasPrevious) {
        previous = await WeeklyInsightsService.getWeeklyTaskSummary(
          habitKey: habitKey,
          season: season,
          startDayIndex: prevStart,
          endDayIndex: prevEnd,
          database: database,
          allHabits: allHabits,
          seasonHabits: seasonHabits,
        );
      }

      items.add(
        HabitTrendItem(
          habitKey: habitKey,
          label: _habitLabel(l10n, habitKey),
          valueText: _formatValue(l10n, habitKey, current, end - start + 1),
          direction: _direction(habitKey, current, previous, hasPrevious: hasPrevious),
          accentColor: _accentColor(habitKey),
        ),
      );
    }

    return items;
  }

  static String _habitLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'fasting':
        return l10n.habitFasting;
      case 'quran_pages':
        return l10n.habitQuran;
      case 'prayers':
        return l10n.habitPrayers;
      case 'dhikr':
        return l10n.habitDhikr;
      case 'taraweeh':
        return l10n.habitTaraweeh;
      case 'sedekah':
        return l10n.habitSedekah;
      case 'tahajud':
        return l10n.habitTahajud;
      case 'itikaf':
        return l10n.habitItikaf;
      default:
        return key;
    }
  }

  static Color _accentColor(String key) {
    switch (key) {
      case 'fasting':
        return const Color(0xFF2DD4BF);
      case 'quran_pages':
        return const Color(0xFF60A5FA);
      case 'prayers':
        return const Color(0xFFA78BFA);
      case 'dhikr':
        return const Color(0xFFFBBF24);
      case 'taraweeh':
        return const Color(0xFF818CF8);
      case 'sedekah':
        return const Color(0xFFF472B6);
      case 'tahajud':
        return const Color(0xFF34D399);
      case 'itikaf':
        return const Color(0xFFFB923C);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static double _metric(String habitKey, WeeklyTaskStatus status) {
    switch (habitKey) {
      case 'quran_pages':
      case 'dhikr':
      case 'sedekah':
        return status.avgActual ?? 0;
      case 'prayers':
        return status.avgCompleted ?? 0;
      default:
        final days = status.statuses.length;
        if (days == 0) return 0;
        return status.doneCount / days;
    }
  }

  static HabitTrendDirection _direction(
    String habitKey,
    WeeklyTaskStatus current,
    WeeklyTaskStatus? previous, {
    required bool hasPrevious,
  }) {
    if (!hasPrevious || previous == null) return HabitTrendDirection.neutral;

    final cur = _metric(habitKey, current);
    final prev = _metric(habitKey, previous);
    final delta = cur - prev;

    if (habitKey == 'quran_pages' || habitKey == 'dhikr' || habitKey == 'sedekah') {
      if (delta.abs() < 0.5) return HabitTrendDirection.neutral;
    } else if (habitKey == 'prayers') {
      if (delta.abs() < 0.15) return HabitTrendDirection.neutral;
    } else {
      if (delta.abs() < 0.08) return HabitTrendDirection.neutral;
    }

    return delta > 0 ? HabitTrendDirection.up : HabitTrendDirection.down;
  }

  static String _formatValue(
    AppLocalizations l10n,
    String habitKey,
    WeeklyTaskStatus status,
    int daysInWindow,
  ) {
    switch (habitKey) {
      case 'quran_pages':
        final avg = status.avgActual ?? 0;
        return l10n.todayTrendQuranPerDay(avg.round());
      case 'dhikr':
        final avg = status.avgActual ?? 0;
        return l10n.todayTrendCountPerDay(avg.round());
      case 'prayers':
        final avg = status.avgCompleted ?? 0;
        return l10n.todayTrendPrayersPerDay(avg.toStringAsFixed(1));
      case 'sedekah':
        final avg = status.avgActual ?? 0;
        return l10n.todayTrendSedekahPerDay(_compactAmount(avg.round()));
      default:
        return l10n.todayTrendDaysDone(status.doneCount, daysInWindow);
    }
  }

  static String _compactAmount(int amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return '$amount';
  }
}
