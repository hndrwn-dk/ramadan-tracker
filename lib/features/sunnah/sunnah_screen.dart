import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/data/providers/sunnah_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/qadha/qadha_screen.dart';
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_recent_days_strip.dart';
import 'package:ramadan_tracker/features/year_round/year_round_navigation.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_ramadan_focus_card.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/sunnah_share_card.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/hijri_calendar.dart';
import 'package:ramadan_tracker/utils/islamic_events.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/settings_icon_button.dart';

class SunnahScreen extends ConsumerWidget {
  const SunnahScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final s = SunnahStrings.of(context);
    final seasonState = ref.watch(seasonStateProvider);
    final isRamadanActive = seasonState == SeasonState.active;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sunnah),
        actions: [
          if (!isRamadanActive)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                final stats = ref.read(sunnahStatsProvider).asData?.value;
                if (stats != null) showSunnahShareDialog(context, stats, s);
              },
            ),
          const SettingsIconButton(),
        ],
      ),
      body: isRamadanActive
          ? _RamadanModeBody(s: s)
          : _YearRoundBody(s: s),
    );
  }
}

class _RamadanModeBody extends ConsumerWidget {
  final SunnahStrings s;
  const _RamadanModeBody({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HijriHeader(s: s, date: today),
        const SizedBox(height: 16),
        const SunnahRamadanFocusCard(),
        const SizedBox(height: 16),
        _QadhaEntryTile(s: s, yearRound: false),
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
    );
  }
}

class _YearRoundBody extends ConsumerWidget {
  final SunnahStrings s;
  const _YearRoundBody({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = DateTime.now();
    final monthAnchor = DateTime(today.year, today.month, 1);
    final monthAsync = ref.watch(sunnahMonthProvider(monthAnchor));
    final statsAsync = ref.watch(sunnahStatsProvider);
    final monthFasted = monthAsync.asData?.value.values
            .where((e) => e.status == FastingStatus.fasted)
            .length ??
        0;

    return ListView(
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
              _WawasanBanner(s: s),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _QadhaEntryTile(s: s, yearRound: true),
        const SizedBox(height: 16),
        PremiumCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.monthLog,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (monthFasted > 0)
                    Text(
                      '$monthFasted',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const SunnahRecentDaysStrip(),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => YearRoundNavigation.openMonthTab(ref),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(s.openFullMonthCalendar),
                ),
              ),
            ],
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
    );
  }
}

class _WawasanBanner extends ConsumerWidget {
  final SunnahStrings s;
  const _WawasanBanner({required this.s});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.insights_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              s.wawasanSunnahBanner,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          TextButton(
            onPressed: () => YearRoundNavigation.openYearRoundInsights(ref),
            child: Text(s.openWawasan),
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
          Expanded(
            child: Column(
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
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
                      ),
                ),
              ],
            ),
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
                            fasted ? Colors.green : scheme.surfaceContainerHighest,
                        child: Icon(
                          fasted ? Icons.check : Icons.wb_sunny_outlined,
                          color: fasted
                              ? Colors.white
                              : scheme.onSurfaceVariant,
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
                        fasted ? Colors.green : scheme.surfaceContainerHighest,
                    child: Icon(
                      fasted ? Icons.check : Icons.wb_sunny_outlined,
                      color:
                          fasted ? Colors.white : scheme.onSurfaceVariant,
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

class _QadhaEntryTile extends StatelessWidget {
  final SunnahStrings s;
  final bool yearRound;
  const _QadhaEntryTile({required this.s, this.yearRound = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.volunteer_activism),
        title: Text(s.obligationsTitle),
        subtitle: Text(
          yearRound ? s.obligationsSubtitleYearRound : s.obligationsSubtitle,
        ),
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
                        : scheme.onTertiaryContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text('$count / 6',
              style: TextStyle(color: scheme.onTertiaryContainer)),
        ],
      ),
    );
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
