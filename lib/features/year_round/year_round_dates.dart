import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/utils/ramadan_dates.dart';

abstract final class YearRoundDates {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days until the user's upcoming season or the next calendar Ramadan.
  static int? daysUntilRamadan({SeasonModel? season, DateTime? reference}) {
    final today = dateOnly(reference ?? DateTime.now());
    if (season != null) {
      final start = dateOnly(season.startDate);
      final days = start.difference(today).inDays;
      if (days > 0) return days;
      if (season.getState(today) == SeasonState.preRamadan) {
        return days;
      }
    }
    return RamadanDates.daysUntilNext(today);
  }
}
