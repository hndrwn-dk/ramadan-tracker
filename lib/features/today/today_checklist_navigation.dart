import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/features/today/today_screen.dart';

/// Opens the full-screen habit checklist for [dayIndex].
void openDayChecklist(
  BuildContext context,
  WidgetRef ref, {
  required int dayIndex,
  bool switchToTodayTab = true,
}) {
  ref.read(selectedDayIndexProvider.notifier).state = dayIndex;
  if (switchToTodayTab) {
    ref.read(tabIndexProvider.notifier).state = 0;
  }

  final navigator = Navigator.of(context, rootNavigator: true);
  WidgetsBinding.instance.addPostFrameCallback((_) {
    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => const TodayScreen(checklistOnly: true),
      ),
    );
  });
}
