import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Monthly sunnah challenge progress (Senin-Kamis + optional Shawwal in Syawal).
class SunnahMonthlyChallengeService {
  SunnahMonthlyChallengeService._();

  static Future<SunnahMonthlyChallengeProgress> progress(
    AppDatabase database,
    DateTime today,
  ) async {
    final rows = await database.sunnahFastsDao.getAll();
    final month = DateTime(today.year, today.month);

    var seninKamis = 0;
    for (final row in rows) {
      if (row.status != FastingStatus.fasted) continue;
      final d = DateTime.parse(row.dateYmd);
      if (d.year != month.year || d.month != month.month) continue;
      final types = SunnahFastingRules.typesFor(d);
      if (types.contains(SunnahType.seninKamis)) seninKamis++;
    }

    var shawwal = 0;
    if (today.month == 10) {
      shawwal = rows
          .where((r) =>
              r.type == 'syawal' && r.status == FastingStatus.fasted)
          .length;
    }

    return SunnahMonthlyChallengeProgress(
      seninKamisDone: seninKamis,
      seninKamisTarget: 4,
      shawwalDone: shawwal,
      shawwalTarget: 6,
      showShawwal: today.month == 10,
    );
  }
}

class SunnahMonthlyChallengeProgress {
  final int seninKamisDone;
  final int seninKamisTarget;
  final int shawwalDone;
  final int shawwalTarget;
  final bool showShawwal;

  const SunnahMonthlyChallengeProgress({
    required this.seninKamisDone,
    required this.seninKamisTarget,
    required this.shawwalDone,
    required this.shawwalTarget,
    required this.showShawwal,
  });

  double get seninKamisFraction =>
      seninKamisTarget > 0 ? (seninKamisDone / seninKamisTarget).clamp(0.0, 1.0) : 0;

  bool get seninKamisComplete => seninKamisDone >= seninKamisTarget;
}
