import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/features/today/today_checklist_navigation.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_ring.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Sticky checklist summary above the tab bar on Today home.
///
/// The entire row is tappable — opens today's checklist. The trailing
/// "Checklist" pill is visual only (not a separate button).
class TodayChecklistStickyBar extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const TodayChecklistStickyBar({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  static String _subtitle(
    AppLocalizations l10n,
    int completed,
    int total,
  ) {
    if (total <= 0) return l10n.openTodayChecklist;
    if (completed >= total) return l10n.todayStickyReviewToday;
    return l10n.todayStickyRemaining(total - completed);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final progressAsync = ref.watch(
      checklistProgressProvider((seasonId: seasonId, dayIndex: dayIndex)),
    );

    return Material(
      elevation: 8,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: progressAsync.when(
          data: (progress) {
            final completed = progress.completed;
            final total = progress.total;
            final fraction = total > 0 ? completed / total : 0.0;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => openDayChecklist(
                  context,
                  ref,
                  dayIndex: dayIndex,
                  switchToTodayTab: false,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    children: [
                      ChecklistProgressRing(
                        progress: fraction,
                        completed: completed,
                        total: total,
                        size: 44,
                        strokeWidth: 4.5,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.checklistProgressDone(completed, total),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _subtitle(l10n, completed, total),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          l10n.todayChecklistButton,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const SizedBox(
            height: 64,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
