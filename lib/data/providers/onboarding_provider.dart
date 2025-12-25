import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';

final shouldShowOnboardingProvider = FutureProvider.autoDispose<bool>((ref) async {
  final database = ref.watch(databaseProvider);
  
  try {
    // Check if any season exists
    final seasons = await database.ramadanSeasonsDao.getAllSeasons();
    debugPrint('Onboarding check: Found ${seasons.length} seasons');
    
    if (seasons.isEmpty) {
      debugPrint('Onboarding check: No seasons found, showing onboarding');
      return true; // No season = show onboarding
    }
    
    // Check if onboarding was completed for the first season
    final firstSeason = seasons.first;
    final flagKey = 'onboarding_done_season_${firstSeason.id}';
    final flag = await database.kvSettingsDao.getValue(flagKey);
    
    debugPrint('Onboarding check: Season ${firstSeason.id} exists, flag=$flag');
    
    // If flag is null or not 'true', show onboarding
    if (flag != 'true') {
      debugPrint('Onboarding check: Flag not set, showing onboarding');
      return true;
    }
    
    // Additional check: verify that goals/habits are actually configured
    // If user skipped onboarding but season exists, we should still show onboarding
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(firstSeason.id);
    final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();
    final quranPlan = await database.quranPlanDao.getPlan(firstSeason.id);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(firstSeason.id);
    
    debugPrint('Onboarding check: Enabled habits=${enabledHabits.length}, quranPlan=${quranPlan != null}, dhikrPlan=${dhikrPlan != null}');
    
    // If no enabled habits or no plans configured, show onboarding
    if (enabledHabits.isEmpty || quranPlan == null || dhikrPlan == null) {
      debugPrint('Onboarding check: Incomplete setup detected, showing onboarding');
      return true;
    }
    
    debugPrint('Onboarding check: Setup complete, not showing onboarding');
    return false;
  } catch (e, stackTrace) {
    // On error, show onboarding to be safe
    debugPrint('Onboarding check error: $e');
    debugPrint('Stack: $stackTrace');
    return true;
  }
});

