import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_quest_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/services/streak_shield_service.dart';
import 'package:ramadan_tracker/features/plan/plan_screen.dart' show dhikrPlanProvider;
import 'package:ramadan_tracker/features/sunnah/sunnah_strings.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_header.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_quick_add_panel.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist_habit_card.dart';
import 'package:ramadan_tracker/features/today/widgets/ramadan_fasting_status_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/prayer_details_widget.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_tracker.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';

/// Collapsed-default accordion checklist (option A) for [TodayScreen.checklistOnly].
class TodayChecklistBody extends ConsumerStatefulWidget {
  final int seasonId;
  final int dayIndex;
  final bool showItikaf;

  const TodayChecklistBody({
    super.key,
    required this.seasonId,
    required this.dayIndex,
    required this.showItikaf,
  });

  @override
  ConsumerState<TodayChecklistBody> createState() => _TodayChecklistBodyState();
}

class _TodayChecklistBodyState extends ConsumerState<TodayChecklistBody> {
  String? _expandedKey;

  static const _habitOrder = [
    'fasting',
    'quran_pages',
    'dhikr',
    'taraweeh',
    'sedekah',
    'prayers',
    'tahajud',
    'itikaf',
  ];

  static const _expandableKeys = {'quran_pages', 'prayers', 'dhikr', 'sedekah'};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final habitsAsync = ref.watch(habitsProvider);
    final seasonHabitsAsync = ref.watch(seasonHabitsProvider(widget.seasonId));
    final entriesAsync = ref.watch(
      dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)),
    );
    final progressAsync = ref.watch(
      checklistProgressProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)),
    );

    return habitsAsync.when(
      data: (habits) => seasonHabitsAsync.when(
        data: (seasonHabits) => entriesAsync.when(
          data: (entries) {
            final cards = _buildHabitCards(
              context,
              l10n,
              habits,
              seasonHabits,
              entries,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                progressAsync.when(
                  data: (progress) => ChecklistProgressHeader(
                    completed: progress.completed,
                    total: progress.total,
                  ),
                  loading: () => const SizedBox(height: 72),
                  error: (_, __) => const SizedBox(height: 8),
                ),
                ...cards,
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Text(l10n.errorLoadingEntries),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Text(l10n.errorLoadingHabits),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Text(l10n.errorLoadingHabits),
    );
  }

  List<Widget> _buildHabitCards(
    BuildContext context,
    AppLocalizations l10n,
    List habits,
    List seasonHabits,
    List entries,
  ) {
    final fastingHabit = habits.cast<dynamic>().where((h) => h.key == 'fasting').firstOrNull;
    final fastingEntry = fastingHabit != null
        ? entries.cast<dynamic>().where((e) => e.habitId == fastingHabit.id).firstOrNull
        : null;
    final fastingStatus = fastingEntry != null
        ? FastingStatus.fromEntry(fastingEntry.valueInt, fastingEntry.valueBool)
        : FastingStatus.notDone;
    final isDayHaidOrNifas = FastingStatus.isHaidOrNifas(fastingStatus);

    final widgets = <Widget>[];
    for (final habitKey in _habitOrder) {
      final habit = habits.cast<dynamic>().where((h) => h.key == habitKey).firstOrNull;
      if (habit == null) continue;
      final sh = seasonHabits.cast<dynamic>().where((s) => s.habitId == habit.id).firstOrNull;
      if (sh == null || !sh.isEnabled) continue;
      if (habitKey == 'itikaf' && !widget.showItikaf) continue;

      final entry = entries.cast<dynamic>().where((e) => e.habitId == habit.id).firstOrNull;
      final habitModel = habit as HabitModel;

      if (isDayHaidOrNifas &&
          habitKey != 'fasting' &&
          (habitKey == 'quran_pages' ||
              habitKey == 'prayers' ||
              habitKey == 'taraweeh' ||
              habitKey == 'tahajud')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _excusedCard(context, l10n, getHabitDisplayName(context, habitKey)),
          ),
        );
        continue;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _habitCard(
            context,
            l10n,
            habitKey: habitKey,
            habit: habitModel,
            entry: entry,
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _habitCard(
    BuildContext context,
    AppLocalizations l10n, {
    required String habitKey,
    required HabitModel habit,
    required dynamic entry,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final expanded = _expandedKey == habitKey;
    final label = getHabitDisplayName(context, habitKey);
    final accent = scheme.primary;

    switch (habitKey) {
      case 'fasting':
        final status = FastingStatus.fromEntry(entry?.valueInt, entry?.valueBool);
        final resolved = FastingStatus.isCompletedForDay(entry?.valueInt, entry?.valueBool);
        final subtitle = _fastingSubtitle(l10n, status, entry?.note as String?);
        return ChecklistHabitCard(
          leadingIcon: ChecklistHabitIcon(
            accent: accent,
            child: Icon(Icons.no_meals_rounded, color: accent, size: 20),
          ),
          trailingAction: ChecklistToggleAction(done: resolved),
          title: label,
          subtitle: subtitle,
          showOptionsHint: true,
          onTap: () => _toggleFastingQuick(habit.id, status),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            _openFastingSheet(habit.id, status, entry?.note as String?);
          },
          onActionTap: () => _toggleFastingQuick(habit.id, status),
        );

      case 'quran_pages':
        return _QuranChecklistCard(
          seasonId: widget.seasonId,
          dayIndex: widget.dayIndex,
          habitId: habit.id,
          label: label,
          accent: accent,
          expanded: expanded,
          onTap: () => _toggleExpand(habitKey),
        );

      case 'prayers':
        return _PrayersChecklistCard(
          seasonId: widget.seasonId,
          dayIndex: widget.dayIndex,
          label: label,
          accent: accent,
          expanded: expanded,
          onTap: () => _toggleExpand(habitKey),
        );

      case 'dhikr':
        final value = entry?.valueInt ?? 0;
        final dhikrPlanAsync = ref.watch(dhikrPlanProvider(widget.seasonId));
        final target = dhikrPlanAsync.valueOrNull?.dailyTarget ?? 100;
        final progress = target > 0 ? value / target : 0.0;
        return ChecklistHabitCard(
          leadingIcon: ChecklistHabitIcon(
            accent: accent,
            child: DhikrIcon(size: 20, color: accent),
          ),
          title: label,
          subtitle: l10n.checklistCountOf(value, target),
          progress: progress,
          expanded: expanded,
          showExpandHint: true,
          expandedChild: ChecklistQuickAddPanel(
            currentValue: value,
            chips: const [33, 100, 300],
            onAdd: (chip) => _setIntHabit(habit.id, value + chip),
            onSetValue: (v) => _setIntHabit(habit.id, v),
            onManualEdit: (current) => _promptIntValue(
              context,
              title: l10n.checklistEnterDhikr,
              initial: current,
            ),
          ),
          onTap: () => _toggleExpand(habitKey),
        );

      case 'taraweeh':
        final isDone = entry?.valueBool ?? false;
        return FutureBuilder<String?>(
          future: ref.read(databaseProvider).kvSettingsDao.getValue('taraweeh_rakaat_per_day'),
          builder: (context, snapshot) {
            final perDay = int.tryParse(snapshot.data ?? '') ?? 11;
            final rakaatLabel =
                perDay == 23 ? l10n.taraweehRakaat23 : l10n.taraweehRakaat11;
            return ChecklistHabitCard(
              leadingIcon: ChecklistHabitIcon(
                accent: accent,
                child: TaraweehIcon(size: 20, color: accent),
              ),
              trailingAction: ChecklistToggleAction(done: isDone),
              title: label,
              subtitle: rakaatLabel,
              onTap: () => _toggleBoolHabit(habit.id, !isDone),
              onActionTap: () => _toggleBoolHabit(habit.id, !isDone),
            );
          },
        );

      case 'sedekah':
        return _SedekahChecklistCard(
          seasonId: widget.seasonId,
          dayIndex: widget.dayIndex,
          habitId: habit.id,
          label: label,
          accent: accent,
          expanded: expanded,
          onTap: () => _toggleExpand(habitKey),
        );

      case 'tahajud':
      case 'itikaf':
        final value = entry?.valueBool ?? false;
        return ChecklistHabitCard(
          leadingIcon: ChecklistHabitIcon(
            accent: accent,
            child: habitKey == 'tahajud'
                ? TahajudIcon(size: 20, color: accent)
                : ItikafIcon(size: 20, color: accent),
          ),
          trailingAction: ChecklistToggleAction(done: value),
          title: label,
          subtitle: value ? l10n.completed : l10n.checklistNotDoneYet,
          onTap: () => _toggleBoolHabit(habit.id, !value),
          onActionTap: () => _toggleBoolHabit(habit.id, !value),
        );

      default:
        if (habit.type == HabitType.bool) {
          final value = entry?.valueBool ?? false;
          return ChecklistHabitCard(
            leadingIcon: ChecklistHabitIcon(
              accent: accent,
              child: Icon(Icons.check_circle_outline, color: accent, size: 22),
            ),
            trailingAction: ChecklistToggleAction(done: value),
            title: label,
            subtitle: value ? l10n.completed : l10n.notDone,
            onTap: () => _toggleBoolHabit(habit.id, !value),
            onActionTap: () => _toggleBoolHabit(habit.id, !value),
          );
        }
        return const SizedBox.shrink();
    }
  }

  void _toggleExpand(String habitKey) {
    if (!_expandableKeys.contains(habitKey)) return;
    setState(() {
      _expandedKey = _expandedKey == habitKey ? null : habitKey;
    });
  }

  Future<int?> _promptIntValue(
    BuildContext context, {
    required String title,
    required int initial,
  }) async {
    final controller = TextEditingController(text: initial > 0 ? '$initial' : '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel),
          ),
          TextButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              Navigator.pop(ctx, parsed ?? 0);
            },
            child: Text(AppLocalizations.of(ctx)!.save),
          ),
        ],
      ),
    );
    return result;
  }

  Future<void> _toggleFastingQuick(int habitId, int currentStatus) async {
    HapticFeedback.lightImpact();
    final nextStatus = currentStatus == FastingStatus.fasted
        ? FastingStatus.notDone
        : FastingStatus.fasted;
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setFastingStatus(
      widget.seasonId,
      widget.dayIndex,
      habitId,
      nextStatus,
    );
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
    await _onEngagementUpdate();
  }

  String _fastingSubtitle(AppLocalizations l10n, int status, String? note) {
    switch (status) {
      case FastingStatus.fasted:
        return l10n.fastingStatusFasted;
      case FastingStatus.excusedSick:
        return l10n.fastingStatusExcusedSick;
      case FastingStatus.excusedNifas:
        return l10n.fastingStatusExcusedNifas;
      case FastingStatus.excusedHaid:
        return l10n.fastingStatusExcusedHaid;
      case FastingStatus.excusedOther:
        if (note != null && note.isNotEmpty) {
          return '${l10n.fastingStatusExcusedOther}: $note';
        }
        return l10n.fastingStatusExcusedOther;
      default:
        return l10n.fastingStatusNotDone;
    }
  }

  Widget _excusedCard(BuildContext context, AppLocalizations l10n, String habitLabel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
        color: Colors.amber.withValues(alpha: 0.08),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.amber.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(habitLabel, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(l10n.excused, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onEngagementUpdate() async {
    final database = ref.read(databaseProvider);
    await StreakShieldService.tryConsumeForExcusedDay(
      database: database,
      seasonId: widget.seasonId,
      dayIndex: widget.dayIndex,
    );
    await evaluateAchievements(ref, seasonId: widget.seasonId, dayIndex: widget.dayIndex);
    await refreshDailyQuests(ref, seasonId: widget.seasonId, dayIndex: widget.dayIndex);
  }

  Future<void> _toggleBoolHabit(int habitId, bool value) async {
    HapticFeedback.lightImpact();
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setBoolValue(widget.seasonId, widget.dayIndex, habitId, value);
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
    await _onEngagementUpdate();
  }

  Future<void> _setIntHabit(int habitId, int value) async {
    HapticFeedback.lightImpact();
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setIntValue(
      widget.seasonId,
      widget.dayIndex,
      habitId,
      value.clamp(0, 999999),
    );
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
    await _onEngagementUpdate();
  }

  Future<void> _openFastingSheet(int habitId, int currentStatus, String? currentNote) async {
    HapticFeedback.lightImpact();
    final season = await ref.read(currentSeasonProvider.future);
    if (!mounted) return;
    final result = await showRamadanFastingStatusSheet(
      context,
      dayIndex: widget.dayIndex,
      date: season?.getDateForDay(widget.dayIndex),
      currentStatus: currentStatus,
      currentNote: currentNote,
    );
    if (result == null || !mounted) return;
    final database = ref.read(databaseProvider);
    await database.dailyEntriesDao.setFastingStatus(
      widget.seasonId,
      widget.dayIndex,
      habitId,
      result.status,
      note: result.note,
    );
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
    await _onEngagementUpdate();
    if (!mounted) return;
    final s = SunnahStrings.of(context);
    final message = ramadanFastingSavedMessage(s, result.status);
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 3)),
      );
    }
  }
}

class _QuranChecklistCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;
  final int habitId;
  final String label;
  final Color accent;
  final bool expanded;
  final VoidCallback onTap;

  const _QuranChecklistCard({
    required this.seasonId,
    required this.dayIndex,
    required this.habitId,
    required this.label,
    required this.accent,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final quranPlanAsync = ref.watch(quranPlanProvider(seasonId));
    final quranDailyAsync = ref.watch(quranDailyProvider((seasonId: seasonId, dayIndex: dayIndex)));

    return quranPlanAsync.when(
      data: (plan) => quranDailyAsync.when(
        data: (daily) {
          final pagesRead = daily?.pagesRead ?? 0;
          final target = plan?.dailyTargetPages ?? 20;
          final progress = target > 0 ? pagesRead / target : 0.0;
          return ChecklistHabitCard(
            leadingIcon: ChecklistHabitIcon(
              accent: accent,
              child: QuranIcon(size: 20, color: accent),
            ),
            title: label,
            subtitle: l10n.checklistPagesOf(pagesRead, target),
            progress: progress,
            expanded: expanded,
            showExpandHint: true,
            expandedChild: ChecklistQuickAddPanel(
              currentValue: pagesRead,
              chips: const [5, 10, 20],
              onAdd: (chip) => _updatePages(ref, pagesRead + chip),
              onSetValue: (v) => _updatePages(ref, v),
              onManualEdit: (current) => _promptQuranPages(context, current),
            ),
            onTap: onTap,
          );
        },
        skipLoadingOnReload: true,
        loading: () => _loadingPlaceholder(label, accent),
        error: (_, __) => const SizedBox.shrink(),
      ),
      skipLoadingOnReload: true,
      loading: () => _loadingPlaceholder(label, accent),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _updatePages(WidgetRef ref, int newPages) {
    final database = ref.read(databaseProvider);
    database.quranDailyDao.setPages(seasonId, dayIndex, newPages.clamp(0, 9999));
    ref.invalidate(quranDailyProvider((seasonId: seasonId, dayIndex: dayIndex)));
  }

  Future<int?> _promptQuranPages(BuildContext context, int initial) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: initial > 0 ? '$initial' : '');
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.checklistEnterPages),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text.trim()) ?? 0),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    return result;
  }
}

class _PrayersChecklistCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;
  final String label;
  final Color accent;
  final bool expanded;
  final VoidCallback onTap;

  const _PrayersChecklistCard({
    required this.seasonId,
    required this.dayIndex,
    required this.label,
    required this.accent,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(prayerDetailsProvider((seasonId: seasonId, dayIndex: dayIndex)));

    return detailsAsync.when(
      data: (details) {
        final l10n = AppLocalizations.of(context)!;
        final completed = [
          details?.fajr,
          details?.dhuhr,
          details?.asr,
          details?.maghrib,
          details?.isha,
        ].where((p) => p == true).length;
        const target = 5;
        return ChecklistHabitCard(
          leadingIcon: ChecklistHabitIcon(
            accent: accent,
            child: Icon(Icons.mosque_outlined, color: accent, size: 20),
          ),
          title: label,
          subtitle: l10n.checklistPrayersOf(completed, target),
          progress: completed / target,
          expanded: expanded,
          showExpandHint: true,
          expandedChild: PrayerDetailsWidget(
            seasonId: seasonId,
            dayIndex: dayIndex,
            controlsOnly: true,
          ),
          onTap: onTap,
        );
      },
      skipLoadingOnReload: true,
      loading: () => _loadingPlaceholder(label, accent),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SedekahChecklistCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;
  final int habitId;
  final String label;
  final Color accent;
  final bool expanded;
  final VoidCallback onTap;

  const _SedekahChecklistCard({
    required this.seasonId,
    required this.dayIndex,
    required this.habitId,
    required this.label,
    required this.accent,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));

    return entriesAsync.when(
      data: (entries) {
        final entry = entries.where((e) => e.habitId == habitId).firstOrNull;
        final amount = entry?.valueInt ?? 0;
        return FutureBuilder<String>(
          future: ref.read(databaseProvider).kvSettingsDao.getValue('sedekah_currency').then((c) => c ?? 'IDR'),
          builder: (context, currencySnapshot) {
            final currency = currencySnapshot.data ?? 'IDR';
            final formatted = SedekahUtils.formatCurrency(amount.toDouble(), currency);
            return ChecklistHabitCard(
              leadingIcon: ChecklistHabitIcon(
                accent: accent,
                child: SedekahIcon(size: 20, color: accent),
              ),
              trailingAction: ChecklistEditAction(onTap: onTap),
              title: label,
              subtitle: formatted,
              expanded: expanded,
              expandedChild: SedekahTracker(
                seasonId: seasonId,
                dayIndex: dayIndex,
                habitId: habitId,
                controlsOnly: true,
              ),
              onTap: onTap,
              onActionTap: onTap,
            );
          },
        );
      },
      skipLoadingOnReload: true,
      loading: () => _loadingPlaceholder(label, accent),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

Widget _loadingPlaceholder(String label, Color accent) {
  return ChecklistHabitCard(
    leadingIcon: ChecklistHabitIcon(
      accent: accent,
      child: const SizedBox(width: 20, height: 20),
    ),
    trailingAction: const SizedBox(width: 40, height: 40),
    title: label,
    subtitle: '',
    onTap: () {},
  );
}
