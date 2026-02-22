import 'package:flutter/material.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';

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
    case 'tahajud':
      return l10n.habitTahajud;
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
    case 'tahajud':
      return 'Tahajud';
    default:
      return habitKey;
  }
}

/// Get habit icon as IconData (for quran_pages use [getHabitIconWidget] to get custom SVG icon).
IconData getHabitIcon(String habitKey) {
  switch (habitKey) {
    case 'fasting':
      return Icons.no_meals;
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
    case 'tahajud':
      return Icons.self_improvement;
    default:
      return Icons.check_circle;
  }
}

/// Get habit icon as Widget. Use this when displaying the icon (quran_pages uses custom SVG).
Widget getHabitIconWidget(
  BuildContext context,
  String habitKey, {
  double size = 24,
  Color? color,
}) {
  if (habitKey == 'quran_pages') {
    return QuranIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  if (habitKey == 'tahajud') {
    return TahajudIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  if (habitKey == 'prayers') {
    return PrayersIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  if (habitKey == 'itikaf') {
    return ItikafIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  if (habitKey == 'taraweeh') {
    return TaraweehIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  if (habitKey == 'dhikr') {
    return DhikrIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  if (habitKey == 'sedekah') {
    return SedekahIcon(size: size, color: color ?? IconTheme.of(context).color);
  }
  return Icon(
    getHabitIcon(habitKey),
    size: size,
    color: color ?? IconTheme.of(context).color,
  );
}

