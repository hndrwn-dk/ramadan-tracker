import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';

/// Opens Achievements inside the main shell so the bottom nav stays visible.
void openAchievementsScreen(WidgetRef ref) {
  ref.read(achievementsVisibleProvider.notifier).state = true;
}

void closeAchievementsScreen(WidgetRef ref) {
  ref.read(achievementsVisibleProvider.notifier).state = false;
}
