import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/qadha/services/obligations_history_analytics.dart';
import 'package:ramadan_tracker/utils/obligations_utils.dart';

void main() {
  test('ObligationsHistoryAnalytics aggregates zakat, fidyah, and timelines', () {
    final season = SeasonModel(
      id: 1,
      label: 'Ramadan 2026',
      startDate: DateTime(2026, 6, 8),
      days: 30,
      createdAt: DateTime(2026, 1, 1),
    );

    final entries = [
      QadhaLedgerData(
        id: 1,
        kind: 'zakat',
        direction: 'paid',
        days: 2,
        amount: 100000,
        note: ObligationsUtils.encodeCurrencyNote('IDR'),
        dateYmd: '2026-06-08',
        sourceSeasonId: 1,
        createdAt: DateTime(2026, 6, 8).millisecondsSinceEpoch,
      ),
      QadhaLedgerData(
        id: 2,
        kind: 'fidyah',
        direction: 'paid',
        days: 3,
        amount: 45000,
        note: ObligationsUtils.encodeCurrencyNote('IDR'),
        dateYmd: '2026-06-10',
        sourceSeasonId: 1,
        createdAt: DateTime(2026, 6, 10).millisecondsSinceEpoch,
      ),
      QadhaLedgerData(
        id: 3,
        kind: 'zakat',
        direction: 'paid',
        days: 1,
        amount: 50000,
        note: ObligationsUtils.encodeCurrencyNote('SGD'),
        dateYmd: '2026-06-12',
        sourceSeasonId: 1,
        createdAt: DateTime(2026, 6, 12).millisecondsSinceEpoch,
      ),
    ];

    final data = ObligationsHistoryAnalytics.compute(
      entries: entries,
      currency: 'IDR',
      season: season,
    );

    expect(data.zakatTotal, 100000);
    expect(data.fidyahTotal, 45000);
    expect(data.zakatPeople, 2);
    expect(data.fidyahDays, 3);
    expect(data.paymentCount, 2);
    expect(data.monthlyTimeline.length, 1);
    expect(data.monthlyTimeline.first.zakatAmount, 100000);
    expect(data.monthlyTimeline.first.fidyahAmount, 45000);
    expect(data.seasonDailyTimeline[0].zakatAmount, 100000);
    expect(data.seasonDailyTimeline[2].fidyahAmount, 45000);
  });
}
