import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Bump to force sunnah providers to refetch after a write.
final sunnahRefreshProvider = StateProvider<int>((ref) => 0);

/// All sunnah fast rows in a given Gregorian [month], keyed by 'YYYY-MM-DD'.
final sunnahMonthProvider =
    FutureProvider.family<Map<String, SunnahFast>, DateTime>((ref, month) async {
  ref.watch(sunnahRefreshProvider);
  final db = ref.watch(databaseProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  final rows = await db.sunnahFastsDao.getRange(start, end);
  return {for (final r in rows) r.dateYmd: r};
});

/// The sunnah fast row for a specific [date] (null if untracked).
final sunnahDayProvider =
    FutureProvider.family<SunnahFast?, DateTime>((ref, date) async {
  ref.watch(sunnahRefreshProvider);
  final db = ref.watch(databaseProvider);
  return db.sunnahFastsDao.getByDate(date);
});

class SunnahStats {
  /// Most recent consecutive Monday/Thursday opportunities that were fasted.
  final int seninKamisStreak;

  /// Total days fasted (sunnah) in the current Gregorian year.
  final int totalThisYear;

  /// Total days fasted (sunnah) all time.
  final int totalAllTime;

  /// Fasted days grouped by [SunnahType.key] for the current Gregorian year.
  final Map<String, int> typeCountsThisYear;

  const SunnahStats({
    required this.seninKamisStreak,
    required this.totalThisYear,
    required this.totalAllTime,
    required this.typeCountsThisYear,
  });
}

/// Display order for the yearly sunnah breakdown section.
const sunnahBreakdownTypes = [
  SunnahType.seninKamis,
  SunnahType.ayyamulBidh,
  SunnahType.syaban,
  SunnahType.asyura,
  SunnahType.tasua,
  SunnahType.arafah,
  SunnahType.syawal,
];

String? _resolveSunnahTypeKey(SunnahFast row) {
  if (row.status != FastingStatus.fasted) return null;
  if (row.type != null &&
      row.type!.isNotEmpty &&
      row.type != 'custom') {
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

final sunnahStatsProvider = FutureProvider<SunnahStats>((ref) async {
  ref.watch(sunnahRefreshProvider);
  final db = ref.watch(databaseProvider);
  final rows = await db.sunnahFastsDao.getAll();
  final now = DateTime.now();
  final year = now.year;

  final fastedDates = <String>{};
  final typeCountsThisYear = <String, int>{};
  for (final r in rows) {
    if (r.status == FastingStatus.fasted) {
      fastedDates.add(r.dateYmd);
      final typeKey = _resolveSunnahTypeKey(r);
      if (typeKey != null && r.dateYmd.startsWith('$year-')) {
        typeCountsThisYear[typeKey] = (typeCountsThisYear[typeKey] ?? 0) + 1;
      }
    }
  }

  final totalThisYear = fastedDates
      .where((d) => d.startsWith('$year-'))
      .length;

  int streak = 0;
  var cursor = DateTime(now.year, now.month, now.day);
  // Walk back up to ~2 years of Mon/Thu opportunities.
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

  return SunnahStats(
    seninKamisStreak: streak,
    totalThisYear: totalThisYear,
    totalAllTime: fastedDates.length,
    typeCountsThisYear: typeCountsThisYear,
  );
});
