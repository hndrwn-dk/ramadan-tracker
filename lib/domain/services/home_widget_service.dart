import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/repositories/season_repository.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/hijri_calendar.dart';
import 'package:ramadan_tracker/utils/islamic_events.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';
import 'package:timezone/timezone.dart' as tz;

/// Pushes season-aware content to the Android home screen widget.
/// During active Ramadan: Sahur/Iftar countdown + Tarawih hint.
/// Outside Ramadan: Hijri date, sunnah fast status, and next Islamic event.
class HomeWidgetService {
  HomeWidgetService._();

  static const String _androidName = 'SunnahWidgetProvider';
  static const String _qualifiedAndroidName =
      'com.tursinalabs.ramadan.tracker.SunnahWidgetProvider';

  static const String actionLogSunnah = 'ramadantracker://log_sunnah';
  static const String actionOpenToday = 'ramadantracker://open_today';

  /// Builds the sunnah line shown on the widget (non-Ramadan season mode).
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

  /// Compact countdown for the widget (updates hourly / on app resume).
  static String formatCountdownCompact(Duration d, {required bool isId}) {
    if (d.isNegative) return isId ? '0m' : '0m';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h >= 1) {
      return isId ? '${h}j ${m}m' : '${h}h ${m}m';
    }
    if (m >= 1) return isId ? '${m}m' : '${m}m';
    return isId ? '<1m' : '<1m';
  }

  /// Primary Ramadan widget line: next Sahur or Iftar countdown.
  static String formatRamadanCountdownLine({
    required bool isId,
    required DateTime now,
    required DateTime sahurTime,
    required DateTime iftarTime,
  }) {
    final countdown = formatCountdownCompact;
    if (now.isBefore(sahurTime)) {
      final t = countdown(sahurTime.difference(now), isId: isId);
      return isId ? 'Sahur dalam $t' : 'Sahur in $t';
    }
    if (now.isBefore(iftarTime)) {
      final t = countdown(iftarTime.difference(now), isId: isId);
      return isId ? 'Iftar dalam $t' : 'Iftar in $t';
    }
    final tomorrowSahur = sahurTime.add(const Duration(days: 1));
    final t = countdown(tomorrowSahur.difference(now), isId: isId);
    return isId ? 'Sahur besok dalam $t' : 'Sahur tomorrow in $t';
  }

  /// Secondary Ramadan widget line: Tarawih status or day index.
  static String formatRamadanSecondaryLine({
    required bool isId,
    required int dayIndex,
    required int totalDays,
    required bool taraweehEnabled,
    required bool taraweehDone,
    required bool afterIftar,
    required bool ramadanFastLogged,
  }) {
    if (taraweehEnabled) {
      if (taraweehDone) {
        return isId ? 'Tarawih selesai' : 'Taraweeh done';
      }
      if (afterIftar) {
        return isId ? 'Tarawih belum dicatat' : 'Taraweeh not logged';
      }
    }
    final dayLine = isId
        ? 'Hari ke $dayIndex/$totalDays'
        : 'Day $dayIndex/$totalDays';
    if (!ramadanFastLogged) {
      final fastHint = isId ? 'Puasa belum dicatat' : 'Fast not logged';
      return '$dayLine · $fastHint';
    }
    return dayLine;
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

      final season = await SeasonRepository(database).getCurrentSeason();
      final isRamadanSeason =
          season != null && season.getState(today) == SeasonState.active;

      String primaryLine;
      String secondaryLine;
      String actionLabel;
      String actionUri;

      if (isRamadanSeason) {
        final activeSeason = season!;
        final dayIndex = activeSeason.getDayIndex(today);
        final ramadanPayload = await _buildRamadanPayload(
          database: database,
          season: activeSeason,
          dayIndex: dayIndex,
          today: today,
          isId: isId,
        );
        primaryLine = ramadanPayload.primary;
        secondaryLine = ramadanPayload.secondary;
        actionLabel = isId ? 'Buka Today' : 'Open Today';
        actionUri = actionOpenToday;
      } else {
        final existing = await database.sunnahFastsDao.getByDate(today);
        final fasted = existing?.status == FastingStatus.fasted;
        primaryLine = formatSunnahTodayLine(
          isId: isId,
          fasted: fasted,
          today: today,
        );

        final events = IslamicEvents.upcoming(today, limit: 1);
        secondaryLine = '';
        if (events.isNotEmpty) {
          final e = events.first;
          final name = isId ? e.event.nameId : e.event.nameEn;
          if (e.daysUntil == 0) {
            secondaryLine = name;
          } else {
            secondaryLine = isId
                ? '$name - ${e.daysUntil} hari lagi'
                : '$name - in ${e.daysUntil} days';
          }
        }
        actionLabel = isId ? 'Catat puasa' : 'Log fast';
        actionUri = actionLogSunnah;
      }

      await HomeWidget.saveWidgetData<String>('widget_mode', isRamadanSeason ? 'ramadan' : 'sunnah');
      await HomeWidget.saveWidgetData<String>('hijri_date', hijriText);
      await HomeWidget.saveWidgetData<String>('sunnah_today', primaryLine);
      await HomeWidget.saveWidgetData<String>('next_event', secondaryLine);
      await HomeWidget.saveWidgetData<String>('widget_log_label', actionLabel);
      await HomeWidget.saveWidgetData<String>('widget_action_uri', actionUri);
      await HomeWidget.updateWidget(
        androidName: _androidName,
        qualifiedAndroidName: _qualifiedAndroidName,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] update failed: $e');
    }
  }

  static Future<({String primary, String secondary})> _buildRamadanPayload({
    required AppDatabase database,
    required SeasonModel season,
    required int dayIndex,
    required DateTime today,
    required bool isId,
  }) async {
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(season.id);
    final fastingHabit = await database.habitsDao.getHabitByKey('fasting');
    final taraweehHabit = await database.habitsDao.getHabitByKey('taraweeh');

    var ramadanFastLogged = false;
    var taraweehEnabled = false;
    var taraweehDone = false;

    if (fastingHabit != null) {
      final fastingEntry = await database.dailyEntriesDao.getEntry(
        season.id,
        dayIndex,
        fastingHabit.id,
      );
      ramadanFastLogged = fastingEntry?.valueInt == 1;
    }

    if (taraweehHabit != null) {
      final sh = seasonHabits.where((h) => h.habitId == taraweehHabit.id).firstOrNull;
      taraweehEnabled = sh?.isEnabled ?? false;
      if (taraweehEnabled) {
        final taraweehEntry = await database.dailyEntriesDao.getEntry(
          season.id,
          dayIndex,
          taraweehHabit.id,
        );
        taraweehDone = taraweehEntry?.valueBool ?? false;
      }
    }

    final prayerTimes = await _loadPrayerTimes(database, season.id, today);
    var afterIftar = false;
    String primary;

    if (prayerTimes != null) {
      final sahurOffset =
          (int.tryParse(await database.kvSettingsDao.getValue('sahur_offset') ?? '30') ?? 30)
              .clamp(1, 45);
      final iftarOffset =
          int.tryParse(await database.kvSettingsDao.getValue('iftar_offset') ?? '0') ?? 0;
      final sahurTime =
          prayerTimes.fajr.subtract(Duration(minutes: sahurOffset));
      final iftarTime =
          prayerTimes.maghrib.add(Duration(minutes: iftarOffset));
      afterIftar = today.isAfter(iftarTime) || today.isAtSameMomentAs(iftarTime);

      if (ramadanFastLogged) {
        primary = isId ? 'Puasa Ramadan tercatat' : 'Ramadan fast logged';
      } else {
        primary = formatRamadanCountdownLine(
          isId: isId,
          now: today,
          sahurTime: sahurTime,
          iftarTime: iftarTime,
        );
      }
    } else {
      primary = isId
          ? 'Hari ke $dayIndex/${season.days}'
          : 'Day $dayIndex/${season.days}';
      if (!ramadanFastLogged) {
        final hint = isId ? ' · atur lokasi sholat' : ' · set prayer location';
        primary = '$primary$hint';
      }
    }

    final secondary = formatRamadanSecondaryLine(
      isId: isId,
      dayIndex: dayIndex,
      totalDays: season.days,
      taraweehEnabled: taraweehEnabled,
      taraweehDone: taraweehDone,
      afterIftar: afterIftar,
      ramadanFastLogged: ramadanFastLogged,
    );

    return (primary: primary, secondary: secondary);
  }

  static Future<({DateTime fajr, DateTime maghrib})?> _loadPrayerTimes(
    AppDatabase database,
    int seasonId,
    DateTime today,
  ) async {
    final latStr = await database.kvSettingsDao.getValue('prayer_latitude');
    final lonStr = await database.kvSettingsDao.getValue('prayer_longitude');
    if (latStr == null || lonStr == null) return null;

    final lat = double.tryParse(latStr);
    final lon = double.tryParse(lonStr);
    if (lat == null || lon == null) return null;

    final timezoneStr =
        await database.kvSettingsDao.getValue('prayer_timezone') ?? 'UTC';
    final method =
        await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl';
    final highLatRule = await database.kvSettingsDao.getValue('prayer_high_lat_rule') ??
        'middle_of_night';
    final fajrAdj =
        int.tryParse(await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0') ?? 0;
    final maghribAdj =
        int.tryParse(await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0') ?? 0;

    try {
      final times = await PrayerTimeService.getCachedOrCalculate(
        database: database,
        seasonId: seasonId,
        date: today,
        latitude: lat,
        longitude: lon,
        timezone: timezoneStr,
        method: method,
        highLatRule: highLatRule,
        fajrAdjust: fajrAdj,
        maghribAdjust: maghribAdj,
      );

      final fajrUtc = times['fajr']!;
      final maghribUtc = times['maghrib']!;
      var fajr = fajrUtc;
      var maghrib = maghribUtc;

      if (timezoneStr != 'UTC' && timezoneStr.isNotEmpty) {
        final targetLocation = tz.getLocation(timezoneStr);
        final fajrUtcMoment = fajrUtc.isUtc
            ? fajrUtc
            : DateTime.utc(
                fajrUtc.year,
                fajrUtc.month,
                fajrUtc.day,
                fajrUtc.hour,
                fajrUtc.minute,
                fajrUtc.second,
              );
        final maghribUtcMoment = maghribUtc.isUtc
            ? maghribUtc
            : DateTime.utc(
                maghribUtc.year,
                maghribUtc.month,
                maghribUtc.day,
                maghribUtc.hour,
                maghribUtc.minute,
                maghribUtc.second,
              );
        final fajrTz = tz.TZDateTime.from(fajrUtcMoment, targetLocation);
        final maghribTz = tz.TZDateTime.from(maghribUtcMoment, targetLocation);
        fajr = DateTime(
          fajrTz.year,
          fajrTz.month,
          fajrTz.day,
          fajrTz.hour,
          fajrTz.minute,
          fajrTz.second,
        );
        maghrib = DateTime(
          maghribTz.year,
          maghribTz.month,
          maghribTz.day,
          maghribTz.hour,
          maghribTz.minute,
          maghribTz.second,
        );
      }

      return (fajr: fajr, maghrib: maghrib);
    } catch (e) {
      if (kDebugMode) debugPrint('[HomeWidget] prayer times failed: $e');
      return null;
    }
  }
}
