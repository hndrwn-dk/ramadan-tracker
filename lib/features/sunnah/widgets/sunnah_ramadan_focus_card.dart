import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Shown on the Sunnah tab while Ramadan is active — links to Hari Ini & Wawasan.
class SunnahRamadanFocusCard extends ConsumerWidget {
  const SunnahRamadanFocusCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final scheme = Theme.of(context).colorScheme;

    return seasonAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Error: $e'),
      )),
      data: (season) {
        if (season == null) return const SizedBox.shrink();

        final dayIndex = ref.watch(activeDayIndexForUIProvider);
        final daysLeft = (season.days - dayIndex).clamp(0, season.days);

        return Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mosque, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.ramadanFocusTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.dayOfSeason(dayIndex, season.days),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
                if (daysLeft > 0)
                  Text(
                    s.ramadanDaysLeft(daysLeft),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                        ),
                  ),
                const SizedBox(height: 12),
                Text(
                  s.ramadanFocusBody,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 340;
                    final todayBtn = FilledButton.icon(
                      onPressed: () {
                        ref.read(tabIndexProvider.notifier).state = 0;
                      },
                      icon: const Icon(Icons.today, size: 18),
                      label: Text(s.openTodayTab),
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.onPrimaryContainer,
                        foregroundColor: scheme.primaryContainer,
                      ),
                    );
                    final insightsBtn = OutlinedButton.icon(
                      onPressed: () {
                        ref.read(wawasanSunnahTabProvider.notifier).state = false;
                        ref.read(tabIndexProvider.notifier).state = 4;
                      },
                      icon: const Icon(Icons.insights, size: 18),
                      label: Text(l10n.viewInsights),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onPrimaryContainer,
                        side: BorderSide(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                    final sunnahHistoryBtn = OutlinedButton.icon(
                      onPressed: () {
                        ref.read(wawasanSunnahTabProvider.notifier).state = true;
                        ref.read(tabIndexProvider.notifier).state = 4;
                      },
                      icon: const Icon(Icons.nightlight_round, size: 18),
                      label: Text(s.viewSunnahHistoryDuringRamadan),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: scheme.onPrimaryContainer,
                        side: BorderSide(
                          color: scheme.onPrimaryContainer.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          todayBtn,
                          const SizedBox(height: 8),
                          insightsBtn,
                          const SizedBox(height: 8),
                          sunnahHistoryBtn,
                        ],
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(child: todayBtn),
                            const SizedBox(width: 12),
                            Expanded(child: insightsBtn),
                          ],
                        ),
                        const SizedBox(height: 8),
                        sunnahHistoryBtn,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
