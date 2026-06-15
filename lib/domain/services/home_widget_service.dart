import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/hijri_calendar.dart';
import 'package:ramadan_tracker/utils/islamic_events.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Pushes Hijri date + today's sunnah fast + next Islamic event to the Android
/// home screen widget. Safe no-op on non-Android platforms.
class HomeWidgetService {
  HomeWidgetService._();

  static const String _androidName = 'SunnahWidgetProvider';
  static const String _qualifiedAndroidName =
      'com.tursinalabs.ramadan.tracker.SunnahWidgetProvider';

  /// Builds the sunnah line shown on the widget (season-independent).
  static String formatSunnahTodayLine({
    required bool isId,
    required bool fasted,
    required DateTime today,
  }) {
    if (fasted) {
      return isId ? 'Puasa sunnah tercatat' : 'Sunnah fast logged';
    }
    if (SunnahFastingRules.isRamadan(today)) {
      return isId ? 'Bulan Ramadan' : 'Ramadan';
    }
    final types = SunnahFastingRules.typesFor(today);
    if (types.isEmpty) {
      return isId ? 'Tidak ada puasa sunnah hari ini' : 'No sunnah fast today';
    }
    final label = isId ? types.first.labelId() : types.first.labelEn();
    return isId ? 'Hari ini: $label' : 'Today: $label';
  }

  static Future<void> update(AppDatabase database) async {
    if (!Platform.isAndroid) return;
    try {
      final locale = await database.kvSettingsDao.getValue('app_language') ?? 'en';
      final isId = locale == 'id';
      final today = DateTime.now();

      final hijri = HijriCalendar.fromGregorian(today);
      final hijriText =
          '${hijri.day} ${HijriCalendar.monthNameId(hijri.month)} ${hijri.year} H';

      final existing = await database.sunnahFastsDao.getByDate(today);
      final fasted = existing?.status == FastingStatus.fasted;
      final sunnahText = formatSunnahTodayLine(
        isId: isId,
        fasted: fasted,
        today: today,
      );

      final events = IslamicEvents.upcoming(today, limit: 1);
      String eventText = '';
      if (events.isNotEmpty) {
        final e = events.first;
        final name = isId ? e.event.nameId : e.event.nameEn;
        if (e.daysUntil == 0) {
          eventText = name;
        } else {
          eventText = isId
              ? '$name - ${e.daysUntil} hari lagi'
              : '$name - in ${e.daysUntil} days';
        }
      }

      await HomeWidget.saveWidgetData<String>('hijri_date', hijriText);
      await HomeWidget.saveWidgetData<String>('sunnah_today', sunnahText);
      await HomeWidget.saveWidgetData<String>('next_event', eventText);
      await HomeWidget.updateWidget(
        androidName: _androidName,
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] update failed: $e');
    }
  }
}
