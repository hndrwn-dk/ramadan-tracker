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
                  padding: const EdgeInsets.fromLTRB(12, 16, 12, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SunnahUsageHeader(
                        fasted: summary.fasted,
                        excused: summary.excused,
                        sunnahDays: summary.sunnahDays,
                      ),
                      const SizedBox(height: 12),
                      SunnahMonthCalendar(
                        monthAnchor: _monthAnchor,
                        data: map,
                        style: SunnahCalendarStyle.premium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const PremiumCard(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: SunnahMonthLegend(
                    defaultExpanded: false,
                    showTypeCodes: true,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // Usage header extracted below to keep the build method readable.

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

class _SunnahUsageHeader extends StatelessWidget {
  final int fasted;
  final int excused;
  final int sunnahDays;

  const _SunnahUsageHeader({
    required this.fasted,
    required this.excused,
    required this.sunnahDays,
  });

  @override
  Widget build(BuildContext context) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;

    final total = sunnahDays;
    final logged = fasted + excused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.monthSummarySunnahDays,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
              ),
            ),
            Text(
              '$logged / $total',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: scheme.surfaceContainerHighest,
            border: Border.all(
              color: scheme.outline.withValues(alpha: 0.22),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: total > 0
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (fasted > 0)
                      Expanded(
                        flex: fasted,
                        child: ColoredBox(color: scheme.primary),
                      ),
                    if (excused > 0)
                      Expanded(
                        flex: excused,
                        child: ColoredBox(
                          color: scheme.tertiary.withValues(alpha: 0.75),
                        ),
                      ),
                    if (logged < total)
                      Expanded(
                        flex: total - logged,
                        child: const SizedBox.expand(),
                      ),
                  ],
                )
              : null,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '${s.monthSummaryFasted}: $fasted',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.primary,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              child: Text(
                '${s.monthSummaryExcused}: $excused',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ],
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
