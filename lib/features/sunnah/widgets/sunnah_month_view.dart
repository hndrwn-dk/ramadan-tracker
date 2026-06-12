import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_month_calendar.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_month_legend.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';

/// Month tab content when Ramadan has not started: sunnah fasting calendar.
class SunnahMonthView extends ConsumerStatefulWidget {
  const SunnahMonthView({super.key});

  @override
  ConsumerState<SunnahMonthView> createState() => _SunnahMonthViewState();
}

class _SunnahMonthViewState extends ConsumerState<SunnahMonthView> {
  late DateTime _monthAnchor;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _monthAnchor = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _monthAnchor = DateTime(_monthAnchor.year, _monthAnchor.month + delta, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final monthAsync = ref.watch(sunnahMonthProvider(_monthAnchor));
    final seasonAsync = ref.watch(currentSeasonProvider);
    final monthLabel = DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(_monthAnchor);

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        seasonAsync.when(
          data: (season) {
            if (season == null) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    s.noSeasonSunnahMonthHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            final today = DateTime.now();
            final daysUntil = season.startDate
                .difference(DateTime(today.year, today.month, today.day))
                .inDays;
            if (daysUntil <= 0) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: PremiumCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.schedule,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        s.preRamadanBanner(daysUntil),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            s.sunnahMonthViewHint,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.75),
                ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => _shiftMonth(-1),
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              IconButton(
                onPressed: () => _shiftMonth(1),
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        const SunnahMonthLegend(),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: monthAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (map) => SunnahMonthCalendar(
              monthAnchor: _monthAnchor,
              data: map,
            ),
          ),
        ),
      ],
    );
  }
}
