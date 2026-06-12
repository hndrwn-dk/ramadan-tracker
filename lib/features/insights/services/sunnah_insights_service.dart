import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

class SunnahInsightsData {
  final int seninKamisStreak;
  final int totalThisYear;
  final int totalAllTime;
  final int qadhaFastsThisYear;
  final Map<String, int> typeCountsThisYear;
  final List<int> monthlyCountsThisYear;
  final List<int> weeklyCountsLast8Weeks;
  final List<SunnahDayHeatmapCell> last35Days;

  const SunnahInsightsData({
    required this.seninKamisStreak,
    required this.totalThisYear,
    required this.totalAllTime,
    required this.qadhaFastsThisYear,
    required this.typeCountsThisYear,
    required this.monthlyCountsThisYear,
    required this.weeklyCountsLast8Weeks,
    required this.last35Days,
  });

  bool get hasAnyData => totalAllTime > 0;

  /// Soft year goal: ~2 sunnah fasts per elapsed month (for hero ring).
  int get yearProgressPercent {
    final now = DateTime.now();
    final monthsElapsed = now.month;
    final goal = monthsElapsed * 2;
    if (goal <= 0) return 0;
    return ((totalThisYear / goal) * 100).round().clamp(0, 100);
  }
}

/// One cell in the recent sunnah fasting heatmap.
class SunnahDayHeatmapCell {
  final DateTime date;
  final int status; // 0 untracked, 1 fasted, 2+ excused

  const SunnahDayHeatmapCell({required this.date, required this.status});
}

/// Computes sunnah fasting analytics for the Wawasan card and detail screen.
class SunnahInsightsService {
  static Future<SunnahInsightsData> load(AppDatabase db) async {
    final rows = await db.sunnahFastsDao.getAll();
    final now = DateTime.now();
    final year = now.year;
    final yearPrefix = '$year-';

    final fastedDates = <String>{};
    final typeCountsThisYear = <String, int>{};
    var qadhaFastsThisYear = 0;
    final monthlyCounts = List<int>.filled(12, 0);

    for (final r in rows) {
      if (r.status != FastingStatus.fasted) continue;
      fastedDates.add(r.dateYmd);
      if (!r.dateYmd.startsWith(yearPrefix)) continue;

      if (r.isQadha) qadhaFastsThisYear++;

      final typeKey = _resolveTypeKey(r);
      if (typeKey != null) {
        typeCountsThisYear[typeKey] = (typeCountsThisYear[typeKey] ?? 0) + 1;
      }

      final parts = r.dateYmd.split('-');
      if (parts.length == 3) {
        final month = int.tryParse(parts[1]);
        if (month != null && month >= 1 && month <= 12) {
          monthlyCounts[month - 1]++;
        }
      }
    }

    final totalThisYear =
        fastedDates.where((d) => d.startsWith(yearPrefix)).length;

    final statusByDate = <String, int>{};
    for (final r in rows) {
      statusByDate[r.dateYmd] = r.status;
    }

    final weeklyCounts = List<int>.filled(8, 0);
    final today = DateTime(now.year, now.month, now.day);
    for (var w = 0; w < 8; w++) {
      final weekEnd = today.subtract(Duration(days: (7 - w) * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      for (var d = 0; d < 7; d++) {
        final date = weekStart.add(Duration(days: d));
        final key = SunnahFastsDao.dateKey(date);
        if (statusByDate[key] == FastingStatus.fasted) {
          weeklyCounts[w]++;
        }
      }
    }

    final last35Days = <SunnahDayHeatmapCell>[];
    for (var i = 34; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final key = SunnahFastsDao.dateKey(date);
      last35Days.add(
        SunnahDayHeatmapCell(
          date: date,
          status: statusByDate[key] ?? 0,
        ),
      );
    }

    int streak = 0;
    var cursor = DateTime(now.year, now.month, now.day);
    var safety = 0;
    while (safety < 220) {
      safety++;
      cursor = cursor.subtract(const Duration(days: 1));
      if (cursor.weekday != DateTime.monday &&
          cursor.weekday != DateTime.thursday) {
        continue;
      }
      if (SunnahFastingRules.isForbidden(cursor) ||
          SunnahFastingRules.isRamadan(cursor)) {
        continue;
      }
      final key = SunnahFastsDao.dateKey(cursor);
      if (fastedDates.contains(key)) {
        streak++;
      } else {
        break;
      }
    }

    return SunnahInsightsData(
      seninKamisStreak: streak,
      totalThisYear: totalThisYear,
      totalAllTime: fastedDates.length,
      qadhaFastsThisYear: qadhaFastsThisYear,
      typeCountsThisYear: typeCountsThisYear,
      monthlyCountsThisYear: monthlyCounts,
      weeklyCountsLast8Weeks: weeklyCounts,
      last35Days: last35Days,
    );
  }

  static String? _resolveTypeKey(SunnahFast row) {
    if (row.type != null && row.type!.isNotEmpty && row.type != 'custom') {
      return row.type;
    }
    final parts = row.dateYmd.split('-');
    if (parts.length != 3) return null;
    final date = DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
    final types = SunnahFastingRules.typesFor(date);
    return types.isNotEmpty ? types.first.key : 'custom';
  }
}

int? sunnahTypeTarget(String typeKey) {
  switch (typeKey) {
    case 'syawal':
      return 6;
    case 'asyura':
    case 'arafah':
    case 'tasua':
      return 1;
    default:
      return null;
  }
}

String sunnahTypeLabel(SunnahType type, bool id) =>
    id ? type.labelId() : type.labelEn();
