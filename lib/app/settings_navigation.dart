import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/features/settings/settings_screen.dart';

/// Opens Settings as a pushed route (not a bottom tab).
void openSettingsScreen(
  BuildContext context,
  WidgetRef ref, {
  String? section,
}) {
  if (section != null) {
    ref.read(openSettingsSectionProvider.notifier).state = section;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
  );
}
