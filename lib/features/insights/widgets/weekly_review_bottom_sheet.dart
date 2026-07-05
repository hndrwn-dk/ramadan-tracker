import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/services/daily_quest_service.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';
import 'package:ramadan_tracker/features/insights/services/weekly_insights_service.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';

/// Weekly Review Bottom Sheet for missed days + quest summary.
class WeeklyReviewBottomSheet extends ConsumerWidget {
  final List<WeeklyDayStatus> dayStatuses;
  final SeasonModel season;
  final int endDayIndex;
  final Function(int dayIndex) onAuditDay;

  const WeeklyReviewBottomSheet({
    super.key,
    required this.dayStatuses,
    required this.season,
    required this.endDayIndex,
    required this.onAuditDay,
  });

  static void show(
    BuildContext context, {
    required List<WeeklyDayStatus> dayStatuses,
    required SeasonModel season,
    required int endDayIndex,
    required Function(int dayIndex) onAuditDay,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => WeeklyReviewBottomSheet(
        dayStatuses: dayStatuses,
        season: season,
        endDayIndex: endDayIndex,
        onAuditDay: onAuditDay,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final missedDays = dayStatuses
        .where((d) => d.status != 'Done' || d.missedTasks.isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppSurface.borderColor(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.weeklyReviewTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                FutureBuilder<WeeklyQuestSummary>(
                  future: DailyQuestService.weeklySummary(
                    database: ref.read(databaseProvider),
                    seasonId: season.id,
                    endDayIndex: endDayIndex,
                  ),
                  builder: (context, snap) {
                    if (!snap.hasData || snap.data!.total == 0) {
                      return const SizedBox.shrink();
                    }
                    final s = snap.data!;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.weeklyQuestSummary(s.completed, s.total),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    );
                  },
                ),
                if (missedDays.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        l10n.weeklyReviewNoMissed,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: missedDays.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final dayStatus = missedDays[index];
                      final dayNumber = dayStatus.dayIndex;
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppSurface.borderColor(context),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          title: Row(
                            children: [
                              Text(
                                DateFormat.yMMMd().format(dayStatus.date),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.weeklyReviewDayLabel(dayNumber),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: dayStatus.missedTasks.isNotEmpty
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: dayStatus.missedTasks.map((taskKey) {
                                      return Chip(
                                        label: Text(
                                          _habitName(l10n, taskKey),
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        padding: EdgeInsets.zero,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }).toList(),
                                  ),
                                )
                              : null,
                          trailing: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onAuditDay(dayStatus.dayIndex);
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            child: Text(l10n.weeklyReviewAudit),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _habitName(AppLocalizations l10n, String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return l10n.habitFasting;
      case 'prayers':
        return l10n.habitPrayers;
      case 'quran_pages':
        return l10n.habitQuran;
      case 'dhikr':
        return l10n.habitDhikr;
      case 'taraweeh':
        return l10n.habitTaraweeh;
      case 'sedekah':
        return l10n.habitSedekah;
      case 'itikaf':
        return l10n.habitItikaf;
      case 'tahajud':
        return l10n.habitTahajud;
      default:
        return habitKey;
    }
  }
}
