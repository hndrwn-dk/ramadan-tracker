/// Hijri (Islamic) calendar utility using the tabular "Kuwaiti" arithmetic
/// algorithm. Pure, offline, deterministic. Dates are an approximation of the
/// observed (sighting-based) calendar and may differ by +/-1 day from local
/// announcements, so the app always allows manual override of sunnah days.
class HijriDate {
  /// Hijri year (e.g. 1447).
  final int year;

  /// Hijri month, 1..12 (1 = Muharram, 9 = Ramadan, 10 = Syawal, 12 = Dzulhijjah).
  final int month;

  /// Hijri day of month, 1..30.
  final int day;

  const HijriDate(this.year, this.month, this.day);

  @override
  bool operator ==(Object other) =>
      other is HijriDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$day ${HijriCalendar.monthNameId(month)} $year H';
}

class HijriCalendar {
  HijriCalendar._();

  static const List<String> _monthNamesId = [
    'Muharram',
    'Safar',
    'Rabiul Awwal',
    'Rabiul Akhir',
    'Jumadil Awwal',
    'Jumadil Akhir',
    'Rajab',
    "Sya'ban",
    'Ramadan',
    'Syawal',
    "Dzulqa'dah",
    'Dzulhijjah',
  ];

  static String monthNameId(int month) {
    if (month < 1 || month > 12) return '';
    return _monthNamesId[month - 1];
  }

  /// Convert a Gregorian [date] (date-only is used) to a [HijriDate].
  static HijriDate fromGregorian(DateTime date) {
    final jd = _gregorianToJd(date.year, date.month, date.day);
    return _jdToHijri(jd);
  }

  /// Convert a Hijri date to a Gregorian [DateTime] (at local midnight).
  static DateTime toGregorian(int hYear, int hMonth, int hDay) {
    final jd = _hijriToJd(hYear, hMonth, hDay);
    return _jdToGregorian(jd);
  }

  /// Number of days (29 or 30) in a given Hijri month.
  static int daysInMonth(int hYear, int hMonth) {
    final startJd = _hijriToJd(hYear, hMonth, 1);
    final nextYear = hMonth == 12 ? hYear + 1 : hYear;
    final nextMonth = hMonth == 12 ? 1 : hMonth + 1;
    final nextStartJd = _hijriToJd(nextYear, nextMonth, 1);
    return nextStartJd - startJd;
  }

  static int _gregorianToJd(int year, int month, int day) {
    if ((year > 1582) ||
        (year == 1582 && month > 10) ||
        (year == 1582 && month == 10 && day > 14)) {
      return ((1461 * (year + 4800 + ((month - 14) ~/ 12))) ~/ 4) +
          ((367 * (month - 2 - 12 * ((month - 14) ~/ 12))) ~/ 12) -
          ((3 * ((year + 4900 + ((month - 14) ~/ 12)) ~/ 100)) ~/ 4) +
          day -
          32075;
    }
    return 367 * year -
        ((7 * (year + 5001 + ((month - 9) ~/ 7))) ~/ 4) +
        ((275 * month) ~/ 9) +
        day +
        1729777;
  }

  static HijriDate _jdToHijri(int jd) {
    int l = jd - 1948440 + 10632;
    final n = (l - 1) ~/ 10631;
    l = l - 10631 * n + 354;
    final j = ((10985 - l) ~/ 5316) * ((50 * l) ~/ 17719) +
        (l ~/ 5670) * ((43 * l) ~/ 15238);
    l = l -
        ((30 - j) ~/ 15) * ((17719 * j) ~/ 50) -
        (j ~/ 16) * ((15238 * j) ~/ 43) +
        29;
    final month = (24 * l) ~/ 709;
    final day = l - ((709 * month) ~/ 24);
    final year = 30 * n + j - 30;
    return HijriDate(year, month, day);
  }

  static int _hijriToJd(int year, int month, int day) {
    return ((11 * year + 3) ~/ 30) +
        354 * year +
        30 * month -
        ((month - 1) ~/ 2) +
        day +
        1948440 -
        385;
  }

  static DateTime _jdToGregorian(int jd) {
    int l = jd + 68569;
    final n = (4 * l) ~/ 146097;
    l = l - ((146097 * n + 3) ~/ 4);
    final i = (4000 * (l + 1)) ~/ 1461001;
    l = l - ((1461 * i) ~/ 4) + 31;
    final j = (80 * l) ~/ 2447;
    final day = l - ((2447 * j) ~/ 80);
    l = j ~/ 11;
    final month = j + 2 - 12 * l;
    final year = 100 * (n - 49) + i + l;
    return DateTime(year, month, day);
  }
}
