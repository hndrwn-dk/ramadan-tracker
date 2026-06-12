import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/utils/obligations_utils.dart';

class MonthlyPaymentBucket {
  final int year;
  final int month;
  final int zakatAmount;
  final int fidyahAmount;

  const MonthlyPaymentBucket({
    required this.year,
    required this.month,
    required this.zakatAmount,
    required this.fidyahAmount,
  });

  int get total => zakatAmount + fidyahAmount;
}

class DailyPaymentBucket {
  final int dayIndex;
  final int zakatAmount;
  final int fidyahAmount;

  const DailyPaymentBucket({
    required this.dayIndex,
    required this.zakatAmount,
    required this.fidyahAmount,
  });

  int get total => zakatAmount + fidyahAmount;
}

class ObligationsHistoryAnalytics {
  final int zakatTotal;
  final int fidyahTotal;
  final int zakatPeople;
  final int fidyahDays;
  final int paymentCount;
  final List<MonthlyPaymentBucket> monthlyTimeline;
  final List<DailyPaymentBucket> seasonDailyTimeline;
  final int? seasonDays;

  const ObligationsHistoryAnalytics({
    required this.zakatTotal,
    required this.fidyahTotal,
    required this.zakatPeople,
    required this.fidyahDays,
    required this.paymentCount,
    required this.monthlyTimeline,
    required this.seasonDailyTimeline,
    this.seasonDays,
  });

  bool get hasData => paymentCount > 0 && (zakatTotal > 0 || fidyahTotal > 0);

  static ObligationsHistoryAnalytics compute({
    required List<QadhaLedgerData> entries,
    required String currency,
    SeasonModel? season,
  }) {
    final displayCurrency = currency.toUpperCase();
    int zakatTotal = 0;
    int fidyahTotal = 0;
    int zakatPeople = 0;
    int fidyahDays = 0;
    int paymentCount = 0;

    final monthlyMap = <String, ({int zakat, int fidyah})>{};
    final seasonDaysCount = season?.days ?? 0;
    final seasonDailyZakat = seasonDaysCount > 0
        ? List<int>.filled(seasonDaysCount, 0)
        : <int>[];
    final seasonDailyFidyah = seasonDaysCount > 0
        ? List<int>.filled(seasonDaysCount, 0)
        : <int>[];

    for (final e in entries) {
      if (e.direction != 'paid') continue;
      if (e.kind != 'zakat' && e.kind != 'fidyah') continue;
      if (e.amount <= 0) continue;

      final entryCurrency = ObligationsUtils.parseCurrencyFromNote(
        e.note,
        fallback: displayCurrency,
      );
      if (entryCurrency != displayCurrency) continue;

      paymentCount++;
      final created = DateTime.fromMillisecondsSinceEpoch(e.createdAt);
      final monthKey =
          '${created.year}-${created.month.toString().padLeft(2, '0')}';
      final existing = monthlyMap[monthKey] ?? (zakat: 0, fidyah: 0);

      if (e.kind == 'zakat') {
        zakatTotal += e.amount;
        zakatPeople += e.days;
        monthlyMap[monthKey] = (
          zakat: existing.zakat + e.amount,
          fidyah: existing.fidyah,
        );
      } else {
        fidyahTotal += e.amount;
        fidyahDays += e.days;
        monthlyMap[monthKey] = (
          zakat: existing.zakat,
          fidyah: existing.fidyah + e.amount,
        );
      }

      if (season != null && seasonDaysCount > 0) {
        final inSeason = ObligationsUtils.isInSeason(
          createdAtMs: e.createdAt,
          dateYmd: e.dateYmd,
          sourceSeasonId: e.sourceSeasonId,
          seasonId: season.id,
          seasonStart: season.startDate,
          seasonDays: season.days,
        );
        if (inSeason) {
          final dayIndex = ObligationsUtils.dayIndexInSeason(
            dateYmd: e.dateYmd,
            createdAtMs: e.createdAt,
            seasonStart: season.startDate,
            seasonDays: season.days,
          );
          if (dayIndex != null) {
            final idx = dayIndex - 1;
            if (e.kind == 'zakat') {
              seasonDailyZakat[idx] += e.amount;
            } else {
              seasonDailyFidyah[idx] += e.amount;
            }
          }
        }
      }
    }

    final monthlyTimeline = monthlyMap.entries.map((e) {
      final parts = e.key.split('-');
      return MonthlyPaymentBucket(
        year: int.parse(parts[0]),
        month: int.parse(parts[1]),
        zakatAmount: e.value.zakat,
        fidyahAmount: e.value.fidyah,
      );
    }).toList()
      ..sort((a, b) {
        if (a.year != b.year) return a.year.compareTo(b.year);
        return a.month.compareTo(b.month);
      });

    final seasonDailyTimeline = <DailyPaymentBucket>[];
    if (seasonDaysCount > 0) {
      for (var i = 0; i < seasonDaysCount; i++) {
        seasonDailyTimeline.add(
          DailyPaymentBucket(
            dayIndex: i + 1,
            zakatAmount: seasonDailyZakat[i],
            fidyahAmount: seasonDailyFidyah[i],
          ),
        );
      }
    }

    return ObligationsHistoryAnalytics(
      zakatTotal: zakatTotal,
      fidyahTotal: fidyahTotal,
      zakatPeople: zakatPeople,
      fidyahDays: fidyahDays,
      paymentCount: paymentCount,
      monthlyTimeline: monthlyTimeline,
      seasonDailyTimeline: seasonDailyTimeline,
      seasonDays: seasonDaysCount > 0 ? seasonDaysCount : null,
    );
  }
}
