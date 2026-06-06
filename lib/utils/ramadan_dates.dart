/// Lookup table for approximate Ramadan start dates (Gregorian).
/// Based on Umm al-Qura / common astronomical calculation.
/// Used for scheduling "next Ramadan" reminder notifications.
class RamadanDates {
  RamadanDates._();

  static const int daysBeforeRamadan = 7;
  static const int reminderHour = 9;
  static const int reminderMinute = 0;

  /// Approximate first day of Ramadan by (display) year.
  /// E.g. 2027 -> 8 Feb 2027; 2031 -> 26 Dec 2030.
  static final Map<int, DateTime> _startByYear = {
    2025: DateTime(2025, 3, 1),
    2026: DateTime(2026, 2, 18),
    2027: DateTime(2027, 2, 8),
    2028: DateTime(2028, 1, 28),
    2029: DateTime(2029, 1, 16),
    2030: DateTime(2030, 1, 6),
    2031: DateTime(2030, 12, 26),
    2032: DateTime(2031, 12, 16),
    2033: DateTime(2032, 12, 5),
    2034: DateTime(2033, 11, 24),
    2035: DateTime(2034, 11, 14),
  };

  /// Returns the approximate Ramadan start date for the given year, or null if unknown.
  static DateTime? getRamadanStartForYear(int year) {
    return _startByYear[year];
  }

  /// Returns the date/time when the "next Ramadan" reminder should fire:
  /// [daysBeforeRamadan] days before Ramadan start at 09:00 (date only; time applied by caller).
  static DateTime? getReminderFireDateForYear(int year) {
    final start = getRamadanStartForYear(year);
    if (start == null) return null;
    return DateTime(start.year, start.month, start.day)
        .subtract(const Duration(days: daysBeforeRamadan));
  }

  /// Minimum year to consider (e.g. 2025).
  static int get minYear => _startByYear.keys.reduce((a, b) => a < b ? a : b);

  /// Maximum year in lookup table.
  static int get maxYear => _startByYear.keys.reduce((a, b) => a > b ? a : b);

  /// The next Ramadan start date on/after [from] (date-only), or null if the
  /// lookup table does not cover it.
  static DateTime? nextStartFrom(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    DateTime? best;
    for (final start in _startByYear.values) {
      final d = DateTime(start.year, start.month, start.day);
      if (!d.isBefore(today)) {
        if (best == null || d.isBefore(best)) best = d;
      }
    }
    return best;
  }

  /// Whole days until the next Ramadan start, or null if unknown.
  static int? daysUntilNext(DateTime from) {
    final next = nextStartFrom(from);
    if (next == null) return null;
    final today = DateTime(from.year, from.month, from.day);
    return next.difference(today).inDays;
  }
}
