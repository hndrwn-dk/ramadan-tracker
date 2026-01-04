import 'package:flutter/material.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Get localized habit display name
String getHabitDisplayName(BuildContext context, String habitKey) {
  final l10n = AppLocalizations.of(context);
  if (l10n == null) {
    // Fallback if localization not available
    return _getHabitDisplayNameFallback(habitKey);
  }
  
  switch (habitKey) {
    case 'fasting':
      return l10n.habitFasting;
    case 'quran_pages':
      return l10n.habitQuran;
    case 'dhikr':
      return l10n.habitDhikr;
    case 'taraweeh':
      return l10n.habitTaraweeh;
    case 'sedekah':
      return l10n.habitSedekah;
    case 'itikaf':
      return l10n.habitItikaf;
    case 'prayers':
      return l10n.habitPrayers;
    default:
      return _getHabitDisplayNameFallback(habitKey);
  }
}

/// Fallback habit display name (English) when localization is not available
String _getHabitDisplayNameFallback(String habitKey) {
  switch (habitKey) {
    case 'fasting':
      return 'Fasting';
    case 'quran_pages':
      return 'Quran';
    case 'dhikr':
      return 'Dhikr';
    case 'taraweeh':
      return 'Taraweeh';
    case 'sedekah':
      return 'Sedekah';
    case 'itikaf':
      return 'I\'tikaf';
    case 'prayers':
      return '5 Prayers';
    default:
      return habitKey;
  }
}

/// Get habit icon
IconData getHabitIcon(String habitKey) {
  switch (habitKey) {
    case 'fasting':
      return Icons.wb_sunny;
    case 'quran_pages':
      return Icons.menu_book;
    case 'dhikr':
      return Icons.favorite;
    case 'taraweeh':
      return Icons.nights_stay;
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

