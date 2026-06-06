import 'package:ramadan_tracker/utils/hijri_calendar.dart';

/// Types of recommended (sunnah) fasting the app can detect for a given date.
enum SunnahType {
  seninKamis,
  ayyamulBidh,
  syawal,
  arafah,
  asyura,
  tasua,
  syaban,
  daud,
}

extension SunnahTypeInfo on SunnahType {
  /// Stable key persisted in the database (SunnahFasts.type).
  String get key {
    switch (this) {
      case SunnahType.seninKamis:
        return 'senin_kamis';
      case SunnahType.ayyamulBidh:
        return 'ayyamul_bidh';
      case SunnahType.syawal:
        return 'syawal';
      case SunnahType.arafah:
        return 'arafah';
      case SunnahType.asyura:
        return 'asyura';
      case SunnahType.tasua:
        return 'tasua';
      case SunnahType.syaban:
        return 'syaban';
      case SunnahType.daud:
        return 'daud';
    }
  }

  String labelId() {
    switch (this) {
      case SunnahType.seninKamis:
        return 'Puasa Senin / Kamis';
      case SunnahType.ayyamulBidh:
        return 'Ayyamul Bidh';
      case SunnahType.syawal:
        return 'Puasa Syawal';
      case SunnahType.arafah:
        return 'Puasa Arafah';
      case SunnahType.asyura:
        return 'Puasa Asyura';
      case SunnahType.tasua:
        return "Puasa Tasu'a";
      case SunnahType.syaban:
        return "Puasa Sya'ban";
      case SunnahType.daud:
        return 'Puasa Daud';
    }
  }

  String labelEn() {
    switch (this) {
      case SunnahType.seninKamis:
        return 'Monday / Thursday fast';
      case SunnahType.ayyamulBidh:
        return 'Ayyamul Bidh (white days)';
      case SunnahType.syawal:
        return 'Six days of Shawwal';
      case SunnahType.arafah:
        return 'Day of Arafah fast';
      case SunnahType.asyura:
        return 'Ashura fast';
      case SunnahType.tasua:
        return "Tasu'a fast";
      case SunnahType.syaban:
        return "Sha'ban fast";
      case SunnahType.daud:
        return 'Dawud fast';
    }
  }
}

class SunnahFastingRules {
  SunnahFastingRules._();

  /// Sunnah fasting types that apply on [date] (date-only is used).
  /// Returns an empty list on days where fasting is forbidden.
  static List<SunnahType> typesFor(DateTime date) {
    if (isForbidden(date)) return const [];

    final result = <SunnahType>[];
    final hijri = HijriCalendar.fromGregorian(date);

    if (date.weekday == DateTime.monday || date.weekday == DateTime.thursday) {
      result.add(SunnahType.seninKamis);
    }

    // Ayyamul Bidh: 13, 14, 15 of every Hijri month.
    if (hijri.day == 13 || hijri.day == 14 || hijri.day == 15) {
      result.add(SunnahType.ayyamulBidh);
    }

    // Syawal (month 10), any day except 1 Syawal (Eid, handled by isForbidden).
    if (hijri.month == 10) {
      result.add(SunnahType.syawal);
    }

    // Dzulhijjah (month 12): Arafah is 9 Dzulhijjah.
    if (hijri.month == 12 && hijri.day == 9) {
      result.add(SunnahType.arafah);
    }

    // Muharram (month 1): Tasu'a (9) and Asyura (10).
    if (hijri.month == 1 && hijri.day == 9) {
      result.add(SunnahType.tasua);
    }
    if (hijri.month == 1 && hijri.day == 10) {
      result.add(SunnahType.asyura);
    }

    // Sha'ban (month 8): generally recommended to fast (except last day(s)
    // right before Ramadan; kept simple here).
    if (hijri.month == 8) {
      result.add(SunnahType.syaban);
    }

    return result;
  }

  /// Days on which fasting is forbidden:
  /// - 1 Syawal (Idul Fitri)
  /// - 10 Dzulhijjah (Idul Adha) and 11-13 Dzulhijjah (Tasyriq)
  static bool isForbidden(DateTime date) {
    final hijri = HijriCalendar.fromGregorian(date);
    if (hijri.month == 10 && hijri.day == 1) return true;
    if (hijri.month == 12 && hijri.day >= 10 && hijri.day <= 13) return true;
    return false;
  }

  /// True when [date] falls within the Ramadan month (obligatory fasting,
  /// not tracked by the sunnah feature).
  static bool isRamadan(DateTime date) {
    return HijriCalendar.fromGregorian(date).month == 9;
  }
}
