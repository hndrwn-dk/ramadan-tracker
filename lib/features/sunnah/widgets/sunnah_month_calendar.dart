import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// Gregorian month grid for year-round sunnah fasting log.
class SunnahMonthCalendar extends ConsumerWidget {
  final DateTime monthAnchor;
  final Map<String, SunnahFast> data;

  const SunnahMonthCalendar({
    super.key,
    required this.monthAnchor,
    required this.data,
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
    final todayDate =
        DateTime(today.year, today.month, today.day);
    final daysInMonth =
        DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final firstWeekday = monthAnchor.weekday % 7;
    final cells = <Widget>[];

    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(monthAnchor.year, monthAnchor.month, d);
      final isToday = date == todayDate;
      final key = dateKey(date);
      final entry = data[key];
      final isSunnah = SunnahFastingRules.typesFor(date).isNotEmpty;
      final fasted = entry?.status == FastingStatus.fasted;
      final excused =
          entry != null && FastingStatus.isExcused(entry.status);

      Color bg;
      Color fg = scheme.onSurface;
      if (fasted) {
        bg = scheme.primary;
        fg = scheme.onPrimary;
      } else if (excused) {
        bg = scheme.tertiary.withValues(alpha: 0.3);
      } else if (isToday) {
        bg = scheme.primaryContainer.withValues(alpha: 0.45);
      } else if (isSunnah) {
        bg = scheme.primary.withValues(alpha: 0.12);
      } else {
        bg = Colors.transparent;
      }

      final Border? cellBorder;
      if (isToday) {
        cellBorder = Border.all(color: scheme.primary, width: 2.5);
      } else if (isSunnah && !fasted) {
        cellBorder = Border.all(color: scheme.primary.withValues(alpha: 0.4));
      } else {
        cellBorder = null;
      }

      cells.add(
        InkWell(
          onTap: () => showSunnahStatusSheet(context, ref, date),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
              border: cellBorder,
              boxShadow: isToday
                  ? [
                      BoxShadow(
                        color: scheme.primary.withValues(alpha: 0.18),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              '$d',
              style: TextStyle(
                color: fg,
                fontSize: 13,
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cells,
    );
  }
}
