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
    return seasons.first;
  }
}

