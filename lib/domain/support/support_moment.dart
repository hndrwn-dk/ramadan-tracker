import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/support/support_checklist_days.dart';
import 'package:ramadan_tracker/domain/support/support_prompt_policy.dart';

class SupportMoment {
  const SupportMoment({
    required this.milestone,
    required this.inLastTenNights,
  });

  final SupportMilestone? milestone;
  final bool inLastTenNights;
}

Future<SupportMoment> loadSupportMoment(
  AppDatabase database,
  DateTime today,
) async {
  final seasons = (await database.ramadanSeasonsDao.getAllSeasons())
      .map(SeasonModel.fromDb)
      .toList();
  final inLastTen = isInLastTenNights(seasons, today);

  var filled = 0;
  for (final season in seasons) {
    final raw = season.getRawDayIndex(today);
    if (raw >= 10 && raw <= season.days && raw < season.days - 9) {
      filled = await countFilledChecklistDays(
        database: database,
        seasonId: season.id,
        throughDay: 10,
      );
      break;
    }
  }

  final sunnahRows = await database.sunnahFastsDao.getAll();
  return SupportMoment(
    milestone: selectSupportMilestone(
      seasons: seasons,
      today: today,
      filledDaysInFirstTen: filled,
      recordedSunnahFastDays: countRecordedSunnahFasts(sunnahRows),
    ),
    inLastTenNights: inLastTen,
  );
}
