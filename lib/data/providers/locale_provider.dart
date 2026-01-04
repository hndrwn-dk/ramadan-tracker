import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';

Locale _parseLocale(String? localeString) {
  if (localeString == null || localeString.isEmpty) {
    return const Locale('en', ''); // Default to English
  }
  switch (localeString.toLowerCase()) {
    case 'id':
      return const Locale('id', '');
    case 'en':
    default:
      return const Locale('en', '');
  }
}

final _localeFutureProvider = FutureProvider<Locale>((ref) async {
  final database = ref.read(databaseProvider);
  final localeString = await database.kvSettingsDao.getValue('app_language');
  return _parseLocale(localeString);
});

final localeProvider = StateNotifierProvider<LocaleNotifier, AsyncValue<Locale>>((ref) {
  final futureValue = ref.watch(_localeFutureProvider);
  return LocaleNotifier(ref, futureValue);
});

class LocaleNotifier extends StateNotifier<AsyncValue<Locale>> {
  final Ref _ref;
  
  LocaleNotifier(this._ref, AsyncValue<Locale> initialValue) : super(initialValue);

  Future<void> setLocale(String localeString) async {
    final database = _ref.read(databaseProvider);
    await database.kvSettingsDao.setValue('app_language', localeString);
    state = AsyncValue.data(_parseLocale(localeString));
    // Invalidate the future provider to refresh
    _ref.invalidate(_localeFutureProvider);
  }
}

