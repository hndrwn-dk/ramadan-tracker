import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/services/insights_service.dart';

/// Provider for insights data based on range type.
final insightsDataProvider = FutureProvider.family<InsightsData, InsightsRange>((ref, rangeType) async {
  final database = ref.read(databaseProvider);
  final seasonAsync = ref.watch(currentSeasonProvider);
  final currentDayIndex = ref.read(currentDayIndexProvider);
  final allHabits = await ref.read(habitsProvider.future);
  
  return seasonAsync.when(
    data: (season) async {
      if (season == null) {
        throw Exception('No season found');
      }
      final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
      return InsightsService.generateInsightsData(
        rangeType: rangeType,
        season: season,
        currentDayIndex: currentDayIndex,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
    },
    loading: () => throw Exception('Loading season'),
    error: (error, stack) => throw error,
  );
});

/// Provider for insights data with optional date override (for Today tab date selection).
final insightsDataProviderWithDate = FutureProvider.family<InsightsData, ({InsightsRange range, DateTime? date})>((ref, params) async {
  final database = ref.read(databaseProvider);
  final seasonAsync = ref.watch(currentSeasonProvider);
  final allHabits = await ref.read(habitsProvider.future);
  
  return seasonAsync.when(
    data: (season) async {
      if (season == null) {
        throw Exception('No season found');
      }
      
      // Calculate day index from date if provided, otherwise use current day
      final dayIndex = params.date != null 
          ? season.getDayIndex(params.date!)
          : ref.read(currentDayIndexProvider);
      
      final seasonHabits = await ref.read(seasonHabitsProvider(season.id).future);
      return InsightsService.generateInsightsData(
        rangeType: params.range,
        season: season,
        currentDayIndex: dayIndex,
        database: database,
        allHabits: allHabits,
        seasonHabits: seasonHabits,
      );
    },
    loading: () => throw Exception('Loading season'),
    error: (error, stack) => throw error,
  );
});

/// Provider for comparing seasons (current vs previous).
final seasonComparisonProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final database = ref.read(databaseProvider);
  final allSeasons = await ref.read(allSeasonsProvider.future);
  
  if (allSeasons.length < 2) {
    return null; // Not enough seasons to compare
  }
  
  final currentSeason = allSeasons.first;
  final previousSeason = allSeasons[1];
  
  final currentDayIndex = ref.read(currentDayIndexProvider);
  final allHabits = await ref.read(habitsProvider.future);
  
  // Get current season data
  final currentSeasonHabits = await ref.read(seasonHabitsProvider(currentSeason.id).future);
  final currentData = await InsightsService.generateInsightsData(
    rangeType: InsightsRange.season,
    season: currentSeason,
    currentDayIndex: currentDayIndex,
    database: database,
    allHabits: allHabits,
    seasonHabits: currentSeasonHabits,
  );
  
  // Get previous season data
  final previousSeasonHabits = await ref.read(seasonHabitsProvider(previousSeason.id).future);
  final previousDayIndex = previousSeason.days; // Use last day of previous season
  final previousData = await InsightsService.generateInsightsData(
    rangeType: InsightsRange.season,
    season: previousSeason,
    currentDayIndex: previousDayIndex,
    database: database,
    allHabits: allHabits,
    seasonHabits: previousSeasonHabits,
  );
  
  return {
    'current': currentData,
    'previous': previousData,
    'currentSeason': currentSeason,
    'previousSeason': previousSeason,
  };
});

