import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/qadha_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/insights/models/insights_range.dart';
import 'package:ramadan_tracker/features/insights/services/season_insights_service.dart';
import 'package:ramadan_tracker/features/qadha/qadha_screen.dart';
import 'package:ramadan_tracker/features/qadha/widgets/obligations_history_charts.dart';
import 'package:ramadan_tracker/features/qadha/widgets/obligations_history_section.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/utils/obligations_utils.dart';

class ObligationsReviewScreen extends ConsumerStatefulWidget {
  final InsightsRange range;
  final int seasonId;

  const ObligationsReviewScreen({
    super.key,
    required this.range,
    required this.seasonId,
  });

  @override
  ConsumerState<ObligationsReviewScreen> createState() =>
      _ObligationsReviewScreenState();
}

class _ObligationsReviewScreenState
    extends ConsumerState<ObligationsReviewScreen> {
  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(s.obligationsReviewTitle)),
      body: FutureBuilder<_ObligationsReviewData?>(
        future: _loadData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data;
          if (data == null) {
            return Center(child: Text(s.obligationsChartEmpty));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ObligationsHistoryCharts(
                entries: data.filteredEntries,
                currency: data.currency,
                season: data.season,
                rangeAnalytics: data.analytics,
              ),
              const SizedBox(height: 24),
              ObligationsHistorySection(
                entries: data.filteredEntries,
                zakatByCurrency: const {},
                fidyahByCurrency: const {},
                onDelete: (e) async {
                  final db = ref.read(databaseProvider);
                  await db.qadhaLedgerDao.deleteEntry(e.id);
                  ref.read(qadhaRefreshProvider.notifier).state++;
                  if (mounted) setState(() {});
                },
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const QadhaScreen()),
                  );
                },
                icon: const Icon(Icons.add, size: 18),
                label: Text(s.obligationsAddPayment),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<_ObligationsReviewData?> _loadData() async {
    final database = ref.read(databaseProvider);
    final seasonRow =
        await database.ramadanSeasonsDao.getSeasonById(widget.seasonId);
    if (seasonRow == null) return null;

    final season = SeasonModel.fromDb(seasonRow);
    final currency =
        await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    final currentDay = ref.read(currentDayIndexProvider);

    late int startDay;
    late int endDay;
    switch (widget.range) {
      case InsightsRange.today:
        startDay = currentDay;
        endDay = currentDay;
        break;
      case InsightsRange.sevenDays:
        startDay = (currentDay - 6).clamp(1, season.days);
        endDay = currentDay.clamp(1, season.days);
        break;
      case InsightsRange.season:
        startDay = 1;
        endDay = currentDay.clamp(1, season.days);
        break;
    }

    final analytics = await SeasonInsightsService.getObligationsRangeAnalytics(
      season: season,
      database: database,
      startDayIndex: startDay,
      endDayIndex: endDay,
      displayCurrency: currency,
    );

    final allEntries = await database.qadhaLedgerDao.getAll();
    final filtered = allEntries.where((e) {
      if (e.direction != 'paid') return false;
      if (e.kind != 'zakat' && e.kind != 'fidyah') return false;
      if (!ObligationsUtils.isInSeason(
        createdAtMs: e.createdAt,
        dateYmd: e.dateYmd,
        sourceSeasonId: e.sourceSeasonId,
        seasonId: season.id,
        seasonStart: season.startDate,
        seasonDays: season.days,
      )) {
        return false;
      }
      final entryCurrency = ObligationsUtils.parseCurrencyFromNote(
        e.note,
        fallback: currency,
      );
      if (entryCurrency != currency) return false;
      final dayIndex = ObligationsUtils.dayIndexInSeason(
        dateYmd: e.dateYmd,
        createdAtMs: e.createdAt,
        seasonStart: season.startDate,
        seasonDays: season.days,
      );
      return dayIndex != null && dayIndex >= startDay && dayIndex <= endDay;
    }).toList();

    return _ObligationsReviewData(
      season: season,
      currency: currency,
      analytics: analytics,
      filteredEntries: filtered,
    );
  }
}

class _ObligationsReviewData {
  final SeasonModel season;
  final String currency;
  final ObligationsSeasonAnalytics analytics;
  final List<QadhaLedgerData> filteredEntries;

  const _ObligationsReviewData({
    required this.season,
    required this.currency,
    required this.analytics,
    required this.filteredEntries,
  });
}
