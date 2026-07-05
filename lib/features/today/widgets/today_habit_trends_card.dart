import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/models/habit_trend_item.dart';
import 'package:ramadan_tracker/domain/services/today_habit_trends_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Fitness-style 7-day habit trend grid for Today home.
class TodayHabitTrendsCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const TodayHabitTrendsCard({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(seasonId));
    final habitsAsync = ref.watch(habitsProvider);
    final seasonAsync = ref.watch(currentSeasonProvider);

    return seasonAsync.when(
      data: (season) {
        if (season == null) return const SizedBox.shrink();
        return habitsAsync.when(
          data: (habits) => seasonHabitsAsync.when(
            data: (seasonHabits) => FutureBuilder<List<HabitTrendItem>>(
              future: TodayHabitTrendsService.trends(
                database: ref.read(databaseProvider),
                season: season,
                dayIndex: dayIndex,
                allHabits: habits,
                seasonHabits: seasonHabits,
                l10n: l10n,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final trends = snapshot.data!;
                return AppSurface(
                  padding: const EdgeInsets.all(16),
                  onTap: () => ref.read(tabIndexProvider.notifier).state = 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.todayTrendsTitle,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                Text(
                                  l10n.todayTrendsSubtitle,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.55),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _TrendGrid(trends: trends),
                    ],
                  ),
                );
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Two-column grid with row height driven by content (no fixed aspect ratio).
class _TrendGrid extends StatelessWidget {
  final List<HabitTrendItem> trends;

  const _TrendGrid({required this.trends});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < trends.length; i += 2) {
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _TrendCell(item: trends[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < trends.length
                    ? _TrendCell(item: trends[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

class _TrendCell extends StatelessWidget {
  final HabitTrendItem item;

  const _TrendCell({required this.item});

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.direction) {
      HabitTrendDirection.up => Icons.keyboard_arrow_up_rounded,
      HabitTrendDirection.down => Icons.keyboard_arrow_down_rounded,
      HabitTrendDirection.neutral => Icons.remove_rounded,
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: item.accentColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 22, color: item.accentColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                item.valueText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: item.accentColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
