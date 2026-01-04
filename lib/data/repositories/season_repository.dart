import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

class SeasonRepository {
  final AppDatabase database;

  SeasonRepository(this.database);

  Future<List<SeasonModel>> getAllSeasons() async {
    final seasons = await database.ramadanSeasonsDao.getAllSeasons();
    return seasons.map((s) => SeasonModel.fromDb(s)).toList();
  }

  Future<SeasonModel?> getSeasonById(int id) async {
    final season = await database.ramadanSeasonsDao.getSeasonById(id);
    return season != null ? SeasonModel.fromDb(season) : null;
  }

  Future<int> createSeason({
    required String label,
    required DateTime startDate,
    required int days,
  }) async {
    return await database.ramadanSeasonsDao.createSeason(
      label: label,
      startDate: startDate,
      days: days,
    );
  }

  Future<SeasonModel?> getCurrentSeason() async {
    final seasons = await getAllSeasons();
    if (seasons.isEmpty) return null;
    
    final now = DateTime.now();
    final normalizedNow = DateTime(now.year, now.month, now.day);
    
    // First, try to find a season that includes today's date
    // Season range: startDate (day 1) to startDate + (days - 1) (day N)
    for (final season in seasons) {
      final normalizedStartDate = DateTime(
        season.startDate.year,
        season.startDate.month,
        season.startDate.day,
      );
      final endDate = normalizedStartDate.add(Duration(days: season.days - 1));
      
      // Check if today is within season range (inclusive)
      // Using comparison operators for clarity
      if (normalizedNow.compareTo(normalizedStartDate) >= 0 &&
          normalizedNow.compareTo(endDate) <= 0) {
        // Today is within this season's range
        return season;
      }
    }
    
    // If no season includes today, find the nearest upcoming season
    // (startDate > today, closest to today)
    SeasonModel? nearestUpcoming;
    DateTime? nearestStartDate;
    
    for (final season in seasons) {
      final normalizedStartDate = DateTime(
        season.startDate.year,
        season.startDate.month,
        season.startDate.day,
      );
      
      if (normalizedStartDate.isAfter(normalizedNow)) {
        if (nearestUpcoming == null || normalizedStartDate.isBefore(nearestStartDate!)) {
          nearestUpcoming = season;
          nearestStartDate = normalizedStartDate;
        }
      }
    }
    
    // Return nearest upcoming season (will be Pre-Ramadan) or first season if none found
    return nearestUpcoming ?? seasons.first;
  }
}

