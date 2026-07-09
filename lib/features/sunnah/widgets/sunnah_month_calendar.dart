import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

enum SunnahCalendarStyle {
  /// Compact grid for the Sunnah tab preview.
  compact,

  /// Full month explorer for the Month tab.
  full,

  /// Premium month explorer (cleaner cells, no tiny type text).
  premium,
}

/// Gregorian month grid for year-round sunnah fasting log.
class SunnahMonthCalendar extends ConsumerWidget {
  final DateTime monthAnchor;
  final Map<String, SunnahFast> data;
  final SunnahCalendarStyle style;

  const SunnahMonthCalendar({
    super.key,
    required this.monthAnchor,
    required this.data,
    this.style = SunnahCalendarStyle.compact,
  });

  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final daysInMonth =
        DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final firstWeekday = monthAnchor.weekday % 7;
    final isFull = style == SunnahCalendarStyle.full;
    final isPremium = style == SunnahCalendarStyle.premium;
    final showWeekdayHeader = isFull || isPremium;
    final cells = <Widget>[];

    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      cells.add(_buildDayCell(
        context,
        ref,
        scheme: scheme,
        date: DateTime(monthAnchor.year, monthAnchor.month, d),
        todayDate: todayDate,
        isFull: isFull,
        isPremium: isPremium,
      ));
    }

    final grid = GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: showWeekdayHeader
          ? (isPremium ? 1.0 : 0.82)
          : 1.0,
      children: cells,
    );

    if (!showWeekdayHeader) return grid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WeekdayHeaderRow(),
        const SizedBox(height: 4),
        grid,
      ],
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    WidgetRef ref, {
    required ColorScheme scheme,
    required DateTime date,
    required DateTime todayDate,
    required bool isFull,
    required bool isPremium,
  }) {
    final isToday = date == todayDate;
    final key = dateKey(date);
    final entry = data[key];
    final sunnahTypes = SunnahFastingRules.typesFor(date);
    final isSunnah = sunnahTypes.isNotEmpty;
    final fasted = entry?.status == FastingStatus.fasted;
    final excused = entry != null && FastingStatus.isExcused(entry.status);
    final isFuture = date.isAfter(todayDate);
    final showDot =
        isPremium && isSunnah && !fasted && !excused; // premium hides type text
    final SunnahType? dotType = showDot ? sunnahTypes.first : null;

    Color bg;
    Color fg = scheme.onSurface;
    if (fasted) {
      bg = scheme.primary;
      fg = scheme.onPrimary;
    } else if (excused) {
      bg = scheme.tertiary.withValues(alpha: 0.3);
    } else if (isToday) {
      bg = scheme.primaryContainer.withValues(alpha: 0.45);
    } else if (isSunnah && !isFuture) {
      bg = scheme.primary.withValues(alpha: 0.12);
    } else if (isSunnah && isFuture) {
      bg = scheme.surfaceContainerHighest.withValues(alpha: 0.6);
    } else {
      bg = Colors.transparent;
    }

    final double cellRadius = isPremium ? 8 : ((isFull) ? 12 : 10);
    final double cellMargin = isPremium ? 2 : ((isFull) ? 3 : 2);

    final Border? cellBorder;
    if (isToday) {
      cellBorder = Border.all(
        color: scheme.primary,
        width: isPremium ? 1.5 : 2.5,
      );
    } else if (isSunnah && !fasted) {
      cellBorder = Border.all(
        color: scheme.primary.withValues(alpha: isFuture ? 0.2 : 0.4),
        width: isPremium ? 1.0 : ((isFull) ? 1.5 : 1),
      );
    } else {
      cellBorder = null;
    }

    final typeHint =
        isFull && isSunnah ? _typeAbbrev(context, sunnahTypes.first) : null;

    final double dotOpacity = isFuture ? 0.45 : 1.0;
    final Color dotColor = _dotColorForType(scheme, dotType);

    return InkWell(
      onTap: () => showSunnahStatusSheet(context, ref, date),
      borderRadius: BorderRadius.circular(cellRadius),
      child: Container(
        margin: EdgeInsets.all(cellMargin),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(cellRadius),
          border: cellBorder,
          // Premium removes shadow for cleaner, tappable calendar cells.
          boxShadow: (isToday && !isPremium)
              ? [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.18),
                    blurRadius: isFull ? 6 : 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                color: fg,
                fontSize: isPremium ? 14 : ((isFull) ? 15 : 13),
                fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (typeHint != null) ...[
              const SizedBox(height: 2),
              Text(
                typeHint,
                style: TextStyle(
                  color: fasted
                      ? fg.withValues(alpha: 0.85)
                      : scheme.primary.withValues(alpha: 0.75),
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ] else if (showDot) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: dotOpacity),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _dotColorForType(ColorScheme scheme, SunnahType? type) {
    if (type == null) return scheme.onSurface.withValues(alpha: 0.35);
    switch (type) {
      case SunnahType.seninKamis:
        return scheme.primary;
      case SunnahType.ayyamulBidh:
        return scheme.onSurface.withValues(alpha: 0.55);
      default:
        return scheme.primary.withValues(alpha: 0.7);
    }
  }

  String _typeAbbrev(BuildContext context, SunnahType type) {
    final id = Localizations.localeOf(context).languageCode == 'id';
    switch (type) {
      case SunnahType.seninKamis:
        return id ? 'S/K' : 'M/T';
      case SunnahType.ayyamulBidh:
        return 'AB';
      case SunnahType.syawal:
        return 'SY';
      case SunnahType.arafah:
        return 'AR';
      case SunnahType.asyura:
        return 'AS';
      case SunnahType.tasua:
        return 'TS';
      case SunnahType.syaban:
        return 'SB';
      case SunnahType.daud:
        return 'DD';
    }
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final sunday = DateTime(2024, 1, 7);
    final labels = List.generate(
      7,
      (i) => DateFormat.E(locale).format(sunday.add(Duration(days: i))),
    );

    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.55),
                    ),
              ),
            ),
          )
          .toList(),
    );
  }
}
