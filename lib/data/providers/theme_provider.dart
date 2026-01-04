import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';

ThemeMode _parseThemeMode(String modeString) {
  switch (modeString.toLowerCase()) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

final _themeModeFutureProvider = FutureProvider<ThemeMode>((ref) async {
  final database = ref.read(databaseProvider);
  final modeString = await database.kvSettingsDao.getValue('theme_mode') ?? 'system';
  return _parseThemeMode(modeString);
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, AsyncValue<ThemeMode>>((ref) {
  // Initialize with the future provider value
  final futureValue = ref.watch(_themeModeFutureProvider);
  return ThemeModeNotifier(ref, futureValue);
});

class ThemeModeNotifier extends StateNotifier<AsyncValue<ThemeMode>> {
  final Ref _ref;
  
  ThemeModeNotifier(this._ref, AsyncValue<ThemeMode> initialValue) : super(initialValue);

  Future<void> setThemeMode(String modeString) async {
    final database = _ref.read(databaseProvider);
    await database.kvSettingsDao.setValue('theme_mode', modeString);
    state = AsyncValue.data(_parseThemeMode(modeString));
    // Invalidate the future provider to refresh
    _ref.invalidate(_themeModeFutureProvider);
  }
}

