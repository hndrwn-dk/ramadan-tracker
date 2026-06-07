import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/features/qadha/qadha_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_share_card.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/hijri_calendar.dart';
import 'package:ramadan_tracker/utils/islamic_events.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

class SunnahScreen extends ConsumerWidget {
  const SunnahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = SunnahStrings.of(context);
    final today = DateTime.now();
    final monthAnchor = DateTime(today.year, today.month, 1);
    final monthAsync = ref.watch(sunnahMonthProvider(monthAnchor));
    final statsAsync = ref.watch(sunnahStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.sunnahTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              final stats = statsAsync.asData?.value;
              if (stats != null) showSunnahShareDialog(context, stats, s);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HijriHeader(s: s, date: today),
          const SizedBox(height: 16),
          _TodayCard(s: s, date: today),
          const SizedBox(height: 16),
          if (SunnahFastingRules.typesFor(today).contains(SunnahType.syawal) ||
              HijriCalendar.fromGregorian(today).month == 10)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _SyawalCard(s: s),
            ),
          statsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatsRow(s: s, stats: stats),
                const SizedBox(height: 16),
                _YearBreakdownSection(s: s, stats: stats),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _QadhaEntryTile(s: s),
          const SizedBox(height: 16),
          Text(s.monthLog, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          monthAsync.when(
            loading: () =>
                const Center(child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator())),
            error: (e, _) => Text('Error: $e'),
            data: (map) => _MonthCalendar(
              s: s,
              monthAnchor: monthAnchor,
              data: map,
            ),
          ),
          const SizedBox(height: 24),
          _UpcomingEvents(s: s, date: today),
          const SizedBox(height: 24),
          Text(
            s.approxNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}

class _HijriHeader extends StatelessWidget {
  final SunnahStrings s;
  final DateTime date;
  const _HijriHeader({required this.s, required this.date});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hijri = HijriCalendar.fromGregorian(date);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.nightlight_round, color: scheme.onPrimaryContainer),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${hijri.day} ${HijriCalendar.monthNameId(hijri.month)} ${hijri.year} H',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                s.hubSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onPrimaryContainer.withOpacity(0.85),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  final SunnahStrings s;
  final DateTime date;
  const _TodayCard({required this.s, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final types = SunnahFastingRules.typesFor(date);
    final dayAsync = ref.watch(sunnahDayProvider(date));
    final fasted = dayAsync.asData?.value?.status == FastingStatus.fasted;
    final isId = s.id;
    final typeLabel = types.isEmpty
        ? s.noSunnahToday
        : types.map((t) => isId ? t.labelId() : t.labelEn()).join(' / ');

    final narrow = MediaQuery.sizeOf(context).width < 380;
    final statusColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.today, style: Theme.of(context).textTheme.labelMedium),
        Text(
          typeLabel,
          style: Theme.of(context).textTheme.titleMedium,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    final actionButton = FilledButton(
      onPressed: () => showSunnahStatusSheet(context, ref, date),
      child: Text(fasted ? s.fasted : s.markFast),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            fasted ? Colors.green : scheme.surfaceVariant,
                        child: Icon(
                          fasted ? Icons.check : Icons.wb_sunny_outlined,
                          color:
                              fasted ? Colors.white : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: statusColumn),
                    ],
                  ),
                  const SizedBox(height: 12),
                  actionButton,
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        fasted ? Colors.green : scheme.surfaceVariant,
                    child: Icon(
                      fasted ? Icons.check : Icons.wb_sunny_outlined,
                      color: fasted ? Colors.white : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: statusColumn),
                  const SizedBox(width: 8),
                  actionButton,
                ],
              ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final SunnahStrings s;
  final SunnahStats stats;
  const _StatsRow({required this.s, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _box(context, '${stats.seninKamisStreak}', s.streak),
        const SizedBox(width: 12),
        _box(context, '${stats.totalThisYear}', s.thisYear),
        const SizedBox(width: 12),
        _box(context, '${stats.totalAllTime}', s.allTime),
      ],
    );
  }

  Widget _box(BuildContext context, String value, String label) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      )),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearBreakdownSection extends StatelessWidget {
  final SunnahStrings s;
  final SunnahStats stats;
  const _YearBreakdownSection({required this.s, required this.stats});

  int? _targetFor(SunnahType type) {
    switch (type) {
      case SunnahType.syawal:
        return 6;
      case SunnahType.asyura:
      case SunnahType.arafah:
      case SunnahType.tasua:
        return 1;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final year = DateTime.now().year;
    final hasAny = stats.typeCountsThisYear.values.any((c) => c > 0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.yearBreakdownTitleFor(year),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              s.yearBreakdownHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.65),
                  ),
            ),
            const SizedBox(height: 12),
            if (!hasAny)
              Text(
                s.t(
                  'Belum ada catatan tahun ini. Tandai puasa sunnah untuk mulai melacak.',
                  'No logs yet this year. Mark a sunnah fast to start tracking.',
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.7),
                    ),
              )
            else
              ...sunnahBreakdownTypes.map((type) {
                final count = stats.typeCountsThisYear[type.key] ?? 0;
                final target = _targetFor(type);
                final label = s.id ? type.labelId() : type.labelEn();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: count == 0
                                        ? scheme.onSurface.withOpacity(0.45)
                                        : null,
                                  ),
                            ),
                          ),
                          Text(
                            s.timesCount(count),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: count == 0
                                      ? scheme.onSurface.withOpacity(0.35)
                                      : scheme.primary,
                                ),
                          ),
                        ],
                      ),
                      if (target != null) ...[
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (count / target).clamp(0.0, 1.0),
                            minHeight: 6,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count / $target',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: scheme.onSurface.withOpacity(0.55),
                              ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _QadhaEntryTile extends StatelessWidget {
  final SunnahStrings s;
  const _QadhaEntryTile({required this.s});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.volunteer_activism),
        title: Text(s.obligationsTitle),
        subtitle: Text(s.obligationsSubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const QadhaScreen()),
        ),
      ),
    );
  }
}

class _SyawalCard extends ConsumerWidget {
  final SunnahStrings s;
  const _SyawalCard({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthAnchor = DateTime(now.year, now.month, 1);
    final monthAsync = ref.watch(sunnahMonthProvider(monthAnchor));
    final count = monthAsync.asData?.value.values
            .where((f) =>
                f.type == SunnahType.syawal.key &&
                f.status == FastingStatus.fasted)
            .length ??
        0;
    final progress = (count / 6).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.tertiaryContainer, scheme.secondaryContainer],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.syawalTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onTertiaryContainer,
                  )),
          Text(s.syawalSubtitle,
              style: TextStyle(color: scheme.onTertiaryContainer)),
          const SizedBox(height: 16),
          Row(
            children: List.generate(6, (i) {
              final done = i < count;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 10,
                  decoration: BoxDecoration(
                    color: done
                        ? scheme.primary
                        : scheme.onTertiaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('$count / 6  (${(progress * 100).round()}%)',
              style: TextStyle(color: scheme.onTertiaryContainer)),
        ],
      ),
    );
  }
}

class _MonthCalendar extends ConsumerWidget {
  final SunnahStrings s;
  final DateTime monthAnchor;
  final Map<String, SunnahFast> data;
  const _MonthCalendar({
    required this.s,
    required this.monthAnchor,
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final daysInMonth =
        DateTime(monthAnchor.year, monthAnchor.month + 1, 0).day;
    final firstWeekday = monthAnchor.weekday % 7; // 0 = Sunday lead
    final cells = <Widget>[];

    for (var i = 0; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }

    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(monthAnchor.year, monthAnchor.month, d);
      final key = _dateKey(date);
      final entry = data[key];
      final isSunnah = SunnahFastingRules.typesFor(date).isNotEmpty;
      final fasted = entry?.status == FastingStatus.fasted;
      final excused = entry != null &&
          FastingStatus.isExcused(entry.status);

      Color bg;
      Color fg = scheme.onSurface;
      if (fasted) {
        bg = scheme.primary;
        fg = scheme.onPrimary;
      } else if (excused) {
        bg = scheme.tertiary.withOpacity(0.3);
      } else if (isSunnah) {
        bg = scheme.primary.withOpacity(0.12);
      } else {
        bg = Colors.transparent;
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
              border: isSunnah && !fasted
                  ? Border.all(color: scheme.primary.withOpacity(0.4))
                  : null,
            ),
            alignment: Alignment.center,
            child: Text('$d', style: TextStyle(color: fg, fontSize: 13)),
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

  String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class _UpcomingEvents extends StatelessWidget {
  final SunnahStrings s;
  final DateTime date;
  const _UpcomingEvents({required this.s, required this.date});

  @override
  Widget build(BuildContext context) {
    final events = IslamicEvents.upcoming(date, limit: 6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.upcomingEvents,
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...events.map((e) {
          final label = s.id ? e.event.nameId : e.event.nameEn;
          final when = e.daysUntil == 0
              ? s.today
              : e.daysUntil == 1
                  ? s.tomorrow
                  : '${e.daysUntil} ${s.inDays}';
          return ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(label),
            trailing: Text(when,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    )),
          );
        }),
      ],
    );
  }
}
