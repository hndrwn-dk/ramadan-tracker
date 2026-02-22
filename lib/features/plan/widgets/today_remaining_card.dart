import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_icon.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';
import 'package:ramadan_tracker/widgets/tahajud_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';

class TodayRemainingCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const TodayRemainingCard({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final database = ref.watch(databaseProvider);

    return FutureBuilder<Map<String, dynamic>?>(
      future: _getTodayRemaining(database),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final remaining = snapshot.data!;
        final items = <Widget>[];

        // Quran
        if (remaining['quranEnabled'] == true) {
          final quranRemaining = remaining['quranRemaining'] as int;
          final l10n = AppLocalizations.of(context)!;
          items.add(_buildRemainingItem(
            context,
            icon: Icons.menu_book,
            iconWidget: QuranIcon(
              size: 20,
              color: quranRemaining <= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            label: getHabitDisplayName(context, 'quran_pages'),
            value: quranRemaining > 0 ? '$quranRemaining ${l10n.pages}' : l10n.done,
            isCompleted: quranRemaining <= 0,
          ));
        }

        // Dhikr
        if (remaining['dhikrEnabled'] == true) {
          final dhikrRemaining = remaining['dhikrRemaining'] as int;
          final l10n = AppLocalizations.of(context)!;
          items.add(_buildRemainingItem(
            context,
            icon: Icons.favorite,
            iconWidget: DhikrIcon(
              size: 20,
              color: dhikrRemaining <= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            label: getHabitDisplayName(context, 'dhikr'),
            value: dhikrRemaining > 0 ? l10n.remaining(dhikrRemaining) : l10n.done,
            isCompleted: dhikrRemaining <= 0,
          ));
        }

        // Sedekah (only if goal enabled)
        if (remaining['sedekahEnabled'] == true && remaining['sedekahGoalEnabled'] == true) {
          final sedekahRemaining = remaining['sedekahRemaining'] as double;
          final currency = remaining['sedekahCurrency'] as String;
          if (sedekahRemaining > 0) {
            items.add(_buildRemainingItem(
              context,
              icon: Icons.volunteer_activism,
              iconWidget: SedekahIcon(
                size: 20,
                color: sedekahRemaining > 0
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
                    : Theme.of(context).colorScheme.primary,
              ),
              label: getHabitDisplayName(context, 'sedekah'),
              value: SedekahUtils.formatCurrency(sedekahRemaining, currency),
              isCompleted: false,
            ));
          }
        }

        // 5 Prayers
        if (remaining['prayersEnabled'] == true) {
          final prayersRemaining = remaining['prayersRemaining'] as int;
          final l10n = AppLocalizations.of(context)!;
          items.add(_buildRemainingItem(
            context,
            icon: Icons.mosque,
            iconWidget: PrayersIcon(
              size: 20,
              color: prayersRemaining <= 0
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            label: getHabitDisplayName(context, 'prayers'),
            value: prayersRemaining > 0 ? l10n.remaining(prayersRemaining) : l10n.allDone,
            isCompleted: prayersRemaining <= 0,
          ));
        }

        // Taraweeh
        if (remaining['taraweehEnabled'] == true) {
          final taraweehDone = remaining['taraweehDone'] as bool;
          final l10n = AppLocalizations.of(context)!;
          items.add(_buildRemainingItem(
            context,
            icon: Icons.nights_stay,
            iconWidget: TaraweehIcon(
              size: 20,
              color: taraweehDone
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            label: getHabitDisplayName(context, 'taraweeh'),
            value: taraweehDone ? l10n.done : l10n.notDone,
            isCompleted: taraweehDone,
          ));
        }

        // Tahajud (part of Qiyam / night)
        if (remaining['tahajudEnabled'] == true) {
          final tahajudDone = remaining['tahajudDone'] as bool;
          final l10n = AppLocalizations.of(context)!;
          items.add(_buildRemainingItem(
            context,
            icon: Icons.self_improvement,
            iconWidget: TahajudIcon(
              size: 20,
              color: tahajudDone
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            label: getHabitDisplayName(context, 'tahajud'),
            value: tahajudDone ? l10n.done : l10n.notDone,
            isCompleted: tahajudDone,
          ));
        }

        // Itikaf (only in last 10 nights)
        if (remaining['itikafEnabled'] == true && remaining['showItikaf'] == true) {
          final itikafDone = remaining['itikafDone'] as bool;
          final l10n = AppLocalizations.of(context)!;
          items.add(_buildRemainingItem(
            context,
            icon: Icons.stars,
            iconWidget: ItikafIcon(
              size: 20,
              color: itikafDone
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            label: getHabitDisplayName(context, 'itikaf'),
            value: itikafDone ? l10n.done : l10n.notDone,
            isCompleted: itikafDone,
          ));
        }

        if (items.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.today,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.todayRemaining,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...items,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRemainingItem(
    BuildContext context, {
    required IconData icon,
    Widget? iconWidget,
    required String label,
    required String value,
    required bool isCompleted,
  }) {
    final iconColor = isCompleted
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCompleted
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: iconWidget ?? Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>?> _getTodayRemaining(AppDatabase database) async {
    // Get enabled habits
    final habits = await database.habitsDao.getAllHabits();
    final seasonHabits = await database.seasonHabitsDao.getSeasonHabits(seasonId);
    
    final enabledHabits = <String, bool>{};
    for (final habit in habits) {
      final sh = seasonHabits.where((s) => s.habitId == habit.id).firstOrNull;
      enabledHabits[habit.key] = sh?.isEnabled ?? false;
    }

    // Get today's progress
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final quranDaily = await database.quranDailyDao.getDaily(seasonId, dayIndex);
    final prayerDetails = await database.prayerDetailsDao.getPrayerDetails(seasonId, dayIndex);

    // Get targets
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled') == 'true';
    final sedekahGoalAmountStr = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final sedekahGoalAmount = sedekahGoalAmountStr != null ? double.tryParse(sedekahGoalAmountStr) ?? 0.0 : 0.0;
    final sedekahCurrency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';

    // Check if in last 10 days
    final season = await database.ramadanSeasonsDao.getSeasonById(seasonId);
    final last10Start = season != null ? season.days - 9 : 0;
    final showItikaf = dayIndex >= last10Start && dayIndex > 0;

    // Calculate remaining
    final quranPagesRead = quranDaily?.pagesRead ?? 0;
    final quranTarget = quranPlan?.dailyTargetPages ?? 20;
    final quranRemaining = (quranTarget - quranPagesRead).clamp(0, quranTarget);

    final dhikrHabit = habits.where((h) => h.key == 'dhikr').firstOrNull;
    final dhikrEntry = dhikrHabit != null
        ? entries.where((e) => e.habitId == dhikrHabit.id).firstOrNull
        : null;
    final dhikrCount = dhikrEntry?.valueInt ?? 0;
    final dhikrTarget = dhikrPlan?.dailyTarget ?? 100;
    final dhikrRemaining = (dhikrTarget - dhikrCount).clamp(0, dhikrTarget);

    final sedekahHabit = habits.where((h) => h.key == 'sedekah').firstOrNull;
    final sedekahEntry = sedekahHabit != null
        ? entries.where((e) => e.habitId == sedekahHabit.id).firstOrNull
        : null;
    final sedekahAmount = (sedekahEntry?.valueInt ?? 0).toDouble();
    final sedekahRemaining = (sedekahGoalAmount - sedekahAmount).clamp(0.0, sedekahGoalAmount);

    // Prayers
    int prayersRemaining = 5;
    if (prayerDetails != null) {
      final completed = [
        prayerDetails.fajr,
        prayerDetails.dhuhr,
        prayerDetails.asr,
        prayerDetails.maghrib,
        prayerDetails.isha,
      ].where((p) => p).length;
      prayersRemaining = 5 - completed;
    } else {
      // Check simple prayers entry
      final prayersHabit = habits.where((h) => h.key == 'prayers').firstOrNull;
      if (prayersHabit != null) {
        final prayersEntry = entries.where((e) => e.habitId == prayersHabit.id).firstOrNull;
        if (prayersEntry?.valueBool == true) {
          prayersRemaining = 0;
        }
      }
    }

    final taraweehHabit = habits.where((h) => h.key == 'taraweeh').firstOrNull;
    final taraweehEntry = taraweehHabit != null
        ? entries.where((e) => e.habitId == taraweehHabit.id).firstOrNull
        : null;
    final taraweehDone = taraweehEntry?.valueBool ?? false;

    final tahajudHabit = habits.where((h) => h.key == 'tahajud').firstOrNull;
    final tahajudEntry = tahajudHabit != null
        ? entries.where((e) => e.habitId == tahajudHabit.id).firstOrNull
        : null;
    final tahajudDone = tahajudEntry?.valueBool ?? false;

    final itikafHabit = habits.where((h) => h.key == 'itikaf').firstOrNull;
    final itikafEntry = itikafHabit != null
        ? entries.where((e) => e.habitId == itikafHabit.id).firstOrNull
        : null;
    final itikafDone = itikafEntry?.valueBool ?? false;

    return {
      'quranEnabled': enabledHabits['quran_pages'] ?? false,
      'dhikrEnabled': enabledHabits['dhikr'] ?? false,
      'sedekahEnabled': enabledHabits['sedekah'] ?? false,
      'prayersEnabled': enabledHabits['prayers'] ?? false,
      'taraweehEnabled': enabledHabits['taraweeh'] ?? false,
      'tahajudEnabled': enabledHabits['tahajud'] ?? false,
      'itikafEnabled': enabledHabits['itikaf'] ?? false,
      'quranRemaining': quranRemaining,
      'dhikrRemaining': dhikrRemaining,
      'sedekahRemaining': sedekahRemaining,
      'sedekahGoalEnabled': sedekahGoalEnabled,
      'sedekahCurrency': sedekahCurrency,
      'prayersRemaining': prayersRemaining,
      'taraweehDone': taraweehDone,
      'tahajudDone': tahajudDone,
      'itikafDone': itikafDone,
      'showItikaf': showItikaf,
    };
  }
}

