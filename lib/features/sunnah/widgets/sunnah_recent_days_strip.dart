import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_month_calendar.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Compact rolling window for the Sunnah tab — not a full month calendar.
class SunnahRecentDaysStrip extends ConsumerWidget {
  final int dayCount;

  const SunnahRecentDaysStrip({super.key, this.dayCount = 14});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final start = todayDate.subtract(Duration(days: dayCount - 1));
    final startAnchor = DateTime(start.year, start.month, 1);
    final endAnchor = DateTime(todayDate.year, todayDate.month, 1);

    final startAsync = ref.watch(sunnahMonthProvider(startAnchor));
    if (startAnchor == endAnchor) {
      return startAsync.when(
        loading: () => const SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (map) => _buildStrip(context, ref, map, start, todayDate),
      );
    }

    final endAsync = ref.watch(sunnahMonthProvider(endAnchor));
    return startAsync.when(
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (startMap) => endAsync.when(
        loading: () => const SizedBox(
          height: 72,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (e, _) => Text('Error: $e'),
        data: (endMap) {
          final merged = <String, SunnahFast>{...startMap, ...endMap};
          return _buildStrip(context, ref, merged, start, todayDate);
        },
      ),
    );
  }

  Widget _buildStrip(
    BuildContext context,
    WidgetRef ref,
    Map<String, SunnahFast> data,
    DateTime start,
    DateTime todayDate,
  ) {
    final s = SunnahStrings.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dates = List.generate(
      dayCount,
      (i) => start.add(Duration(days: i)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.recentDaysStripTitle(dayCount),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              s.legendFasted,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: dates.map((date) {
              final key = SunnahMonthCalendar.dateKey(date);
              final entry = data[key];
              final fasted = entry?.status == FastingStatus.fasted;
              final excused =
                  entry != null && FastingStatus.isExcused(entry.status);
              final isToday = date == todayDate;

              Color bg;
              Color fg = scheme.onSurface.withValues(alpha: 0.8);
              if (fasted) {
                bg = scheme.primary;
                fg = scheme.onPrimary;
              } else if (excused) {
                bg = scheme.tertiary.withValues(alpha: 0.35);
              } else if (isToday) {
                bg = scheme.primaryContainer.withValues(alpha: 0.5);
              } else {
                bg = scheme.surfaceContainerHighest;
              }

              final weekday = DateFormat.E(locale).format(date);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => showSunnahStatusSheet(context, ref, date),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(14),
                      border: isToday
                          ? Border.all(color: scheme.primary, width: 2)
                          : Border.all(
                              color: AppSurface.borderColor(context),
                            ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekday,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                color: fg.withValues(alpha: 0.85),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: fg,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
