import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/services/completion_service.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildInsights(context, ref, season.id, season.days);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildInsights(BuildContext context, WidgetRef ref, int seasonId, int days) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadInsightsData(ref.read(databaseProvider), seasonId, days),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(context, ref);
        }

        final data = snapshot.data!;
        final quranData = data['quran'] as List<FlSpot>;
        final dhikrData = data['dhikr'] as List<FlSpot>;
        final scoreData = data['score'] as List<FlSpot>;
        final hasData = data['hasData'] as bool;
        final trackedDays = data['trackedDays'] as int;

        if (!hasData) {
          return _buildEmptyState(context, ref);
        }

        if (trackedDays < 3) {
          return _buildEarlyInsights(context, ref, data);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quran Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: quranData.isEmpty
                            ? const Center(child: Text('No data'))
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: quranData,
                                      isCurved: true,
                                      color: Theme.of(context).colorScheme.primary,
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dhikr Progress',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: dhikrData.isEmpty
                            ? const Center(child: Text('No data'))
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: dhikrData,
                                      isCurved: true,
                                      color: Theme.of(context).colorScheme.secondary,
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completion Score Trend',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: scoreData.isEmpty
                            ? const Center(child: Text('No data'))
                            : LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: true),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: true),
                                    ),
                                    rightTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                    topTitles: const AxisTitles(
                                      sideTitles: SideTitles(showTitles: false),
                                    ),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  minY: 0,
                                  maxY: 100,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: scoreData,
                                      isCurved: true,
                                      color: Theme.of(context).colorScheme.tertiary,
                                      barWidth: 3,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: Theme.of(context).colorScheme.tertiary.withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadInsightsData(
    AppDatabase database,
    int seasonId,
    int days,
  ) async {
    final quranDaily = await database.quranDailyDao.getAllDaily(seasonId);
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);

    final quranData = <FlSpot>[];
    final dhikrData = <FlSpot>[];
    final scoreData = <FlSpot>[];

    int quranCumulative = 0;
    int dhikrCumulative = 0;

    for (int day = 1; day <= days; day++) {
      final quranEntry = quranDaily.where((e) => e.dayIndex == day).firstOrNull ??
          QuranDailyData(
            seasonId: seasonId,
            dayIndex: day,
            pagesRead: 0,
            updatedAt: 0,
          );

      quranCumulative += quranEntry.pagesRead;
      quranData.add(FlSpot(day.toDouble(), quranCumulative.toDouble()));

      final entries = await database.dailyEntriesDao.getDayEntries(seasonId, day);
      final dhikrHabit = await database.habitsDao.getHabitByKey('dhikr');
      if (dhikrHabit != null) {
        final dhikrEntry = entries.where((e) => e.habitId == dhikrHabit.id).firstOrNull;
        dhikrCumulative += dhikrEntry?.valueInt ?? 0;
      }
      dhikrData.add(FlSpot(day.toDouble(), dhikrCumulative.toDouble()));

      final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
      final enabledHabits = seasonHabits.where((sh) => sh.isEnabled).toList();
      final allHabits = await database.habitsDao.getAllHabits();
      if (enabledHabits.isNotEmpty) {
        final score = await CompletionService.calculateCompletionScore(
          seasonId: seasonId,
          dayIndex: day,
          enabledHabits: enabledHabits,
          entries: entries,
          database: database,
          allHabits: allHabits,
        );
        scoreData.add(FlSpot(day.toDouble(), score));
      } else {
        scoreData.add(FlSpot(day.toDouble(), 0.0));
      }
    }

    final hasData = quranCumulative > 0 || dhikrCumulative > 0 || scoreData.any((s) => s.y > 0);
    final trackedDays = scoreData.where((s) => s.y > 0).length;

    return {
      'quran': quranData,
      'dhikr': dhikrData,
      'score': scoreData,
      'hasData': hasData,
      'trackedDays': trackedDays,
      'quranTotal': quranCumulative,
      'dhikrTotal': dhikrCumulative,
    };
  }

  Widget _buildEarlyInsights(BuildContext context, WidgetRef ref, Map<String, dynamic> data) {
    final quranTotal = data['quranTotal'] as int;
    final dhikrTotal = data['dhikrTotal'] as int;
    final trackedDays = data['trackedDays'] as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Early Insights',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            '$trackedDays',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            'Days tracked',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$quranTotal',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            'Quran pages',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            '$dhikrTotal',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            'Dhikr count',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep going!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track 3+ days to see detailed charts and trends.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Data Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking today to see insights.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Switch to Today tab (index 0)
                ref.read(tabIndexProvider.notifier).state = 0;
              },
              icon: const Icon(Icons.today),
              label: const Text('Go to Today'),
            ),
          ],
        ),
      ),
    );
  }
}

