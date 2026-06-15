import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart'
    show tabIndexProvider, wawasanSunnahTabProvider;
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/settings/create_season_flow.dart';

/// Shared navigation helpers for year-round and season-phase UI.
abstract final class YearRoundNavigation {
  static void openSunnahTab(WidgetRef ref) {
    ref.read(tabIndexProvider.notifier).state = 3;
  }

  static void openPlanTab(WidgetRef ref) {
    ref.read(tabIndexProvider.notifier).state = 2;
  }

  /// Wawasan year-round (pre/post-Ramadan or no active tracking).
  static void openYearRoundInsights(WidgetRef ref) {
    ref.read(wawasanSunnahTabProvider.notifier).state = false;
    ref.read(tabIndexProvider.notifier).state = 4;
  }

  /// Active Ramadan: season insights. Optionally open the sunnah history sub-tab.
  static void openRamadanInsights(WidgetRef ref, {bool sunnahHistory = false}) {
    ref.read(wawasanSunnahTabProvider.notifier).state = sunnahHistory;
    ref.read(tabIndexProvider.notifier).state = 4;
  }

  static void openInsightsForState(WidgetRef ref, SeasonState state,
      {bool sunnahHistory = false}) {
    if (state == SeasonState.active) {
      openRamadanInsights(ref, sunnahHistory: sunnahHistory);
    } else {
      openYearRoundInsights(ref);
    }
  }

  static Future<void> openCreateSeason(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateSeasonFlow()),
    );
  }
}
