import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/last10_provider.dart';
import 'package:ramadan_tracker/features/month/day_detail_screen.dart';

class MonthScreen extends ConsumerWidget {
  const MonthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Month View'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) {
            return const Center(child: Text('No season found'));
          }
          return _buildMonthGrid(context, ref, season.id, season.days);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Widget _buildMonthGrid(BuildContext context, WidgetRef ref, int seasonId, int days) {
    final currentDayIndex = ref.watch(currentDayIndexProvider);
    final last10Start = ref.watch(last10StartProvider);

    return Column(
      children: [
        _buildLegend(context),
        Expanded(
          child: GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: days,
      itemBuilder: (context, index) {
        final dayIndex = index + 1;
        final isToday = dayIndex == currentDayIndex;
        final isLast10 = dayIndex >= last10Start;
        final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DayDetailScreen(seasonId: seasonId, dayIndex: dayIndex),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white.withOpacity(0.1),
                width: isToday ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$dayIndex',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                    ),
                    const SizedBox(height: 2),
                    entriesAsync.when(
                      data: (entries) {
                        final hasEntries = entries.isNotEmpty;
                        final completed = entries.where((e) => e.isCompleted).length;
                        final totalEnabled = entries.length;
                        
                        if (hasEntries && totalEnabled > 0) {
                          final score = (completed / totalEnabled * 100).round();
                          if (score >= 60) {
                            return Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          } else {
                            return Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                      loading: () => const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.5),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
                if (isLast10)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildLegendItem(context, Icons.radio_button_checked, 'Ring = completion'),
          _buildLegendItem(context, Icons.circle, 'Dot = tracked'),
          _buildLegendItem(context, Icons.star, '✨ = last 10'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}


