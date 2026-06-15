import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Picks which Ramadan season drives sahur/iftar/goal notification scheduling.
class NotificationSeasonResolver {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Active season first, otherwise nearest upcoming (pre-Ramadan).
  /// Returns null when every season has already ended (post-Ramadan only).
  static RamadanSeason? pickForScheduling(
    List<RamadanSeason> seasons,
    DateTime referenceDate,
  ) {
    if (seasons.isEmpty) return null;

    final today = dateOnly(referenceDate);

    for (final season in seasons) {
      final model = SeasonModel.fromDb(season);
      if (model.getState(today) == SeasonState.active) {
        return season;
      }
    }

    RamadanSeason? nearestUpcoming;
    DateTime? nearestStart;
    for (final season in seasons) {
      final start = dateOnly(DateTime.parse(season.startDate));
      if (start.isAfter(today)) {
        if (nearestStart == null || start.isBefore(nearestStart)) {
          nearestUpcoming = season;
          nearestStart = start;
        }
      }
    }

    return nearestUpcoming;
  }

  /// Whether [scheduleStart]..[scheduleEnd] has at least one day to schedule.
  static bool hasSchedulableDateRange(DateTime scheduleStart, DateTime scheduleEnd) {
    return !dateOnly(scheduleStart).isAfter(dateOnly(scheduleEnd));
  }
}
