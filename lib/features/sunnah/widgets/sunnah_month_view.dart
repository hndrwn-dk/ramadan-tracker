import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_month_calendar.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_month_legend.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/hijri_calendar.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Month tab: full sunnah fasting calendar with month navigation.
class SunnahMonthView extends ConsumerStatefulWidget {
  const SunnahMonthView({super.key});

  static const double _hPad = 16;

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

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _monthAnchor = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final monthAsync = ref.watch(sunnahMonthProvider(_monthAnchor));
    final seasonAsync = ref.watch(currentSeasonProvider);
    final seasonState = ref.watch(seasonStateProvider);
    final locale = Localizations.localeOf(context).toString();
    final monthLabel = DateFormat.yMMMM(locale).format(_monthAnchor);
    final hijriMid = HijriCalendar.fromGregorian(
      DateTime(_monthAnchor.year, _monthAnchor.month, 15),
    );
    final hijriLabel = locale.startsWith('id')
        ? '${HijriCalendar.monthNameId(hijriMid.month)} ${hijriMid.year} H'
        : '${HijriCalendar.monthNameId(hijriMid.month)} ${hijriMid.year} AH';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        SunnahMonthView._hPad,
        SunnahMonthView._hPad,
        SunnahMonthView._hPad,
        24,
      ),
      children: [
        seasonAsync.when(
          data: (season) {
            if (season == null) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    s.noSeasonSunnahMonthHint,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }
            if (seasonState == SeasonState.postRamadan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PremiumCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s.monthPostRamadanHint,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
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
              padding: const EdgeInsets.only(bottom: 12),
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
        PremiumCard(
          padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          monthLabel,
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        Text(
                          hijriLabel,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _jumpToToday,
                  icon: const Icon(Icons.today, size: 18),
                  label: Text(s.legendToday),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        monthAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('Error: $e'),
          data: (map) {
            final summary = _monthSummary(_monthAnchor, map);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PremiumCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      _summaryChip(
                        context,
                        label: s.monthSummaryFasted,
                        value: '${summary.fasted}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      _summaryChip(
                        context,
                        label: s.monthSummaryExcused,
                        value: '${summary.excused}',
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 12),
                      _summaryChip(
                        context,
                        label: s.monthSummarySunnahDays,
                        value: '${summary.sunnahDays}',
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: const SunnahMonthLegend(),
                ),
                const SizedBox(height: 12),
                PremiumCard(
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
                  child: SunnahMonthCalendar(
                    monthAnchor: _monthAnchor,
                    data: map,
                    style: SunnahCalendarStyle.full,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _summaryChip(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  _MonthSummary _monthSummary(
    DateTime monthAnchor,
    Map<String, SunnahFast> data,
  ) {
    final daysInMonth =
        DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    var fasted = 0;
    var excused = 0;
    var sunnahDays = 0;

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(monthAnchor.year, monthAnchor.month, d);
      if (SunnahFastingRules.typesFor(date).isNotEmpty) {
        sunnahDays++;
      }
      final key = SunnahMonthCalendar.dateKey(date);
      final entry = data[key];
      if (entry == null) continue;
      if (entry.status == FastingStatus.fasted) {
        fasted++;
      } else if (FastingStatus.isExcused(entry.status)) {
        excused++;
      }
    }

    return _MonthSummary(
      fasted: fasted,
      excused: excused,
      sunnahDays: sunnahDays,
    );
  }
}

class _MonthSummary {
  final int fasted;
  final int excused;
  final int sunnahDays;

  const _MonthSummary({
    required this.fasted,
    required this.excused,
    required this.sunnahDays,
  });
}
