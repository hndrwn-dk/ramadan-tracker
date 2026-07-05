import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/features/today/today_checklist_navigation.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_ring.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Sticky checklist summary above the tab bar on Today home.
///
/// Premium mockups use a persistent summary + CTA; the full checklist opens as a
/// pushed screen ([TodayScreen.checklistOnly]), not a bottom sheet.
class TodayChecklistStickyBar extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const TodayChecklistStickyBar({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

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

            return InkWell(
              onTap: () => openDayChecklist(
                context,
                ref,
                dayIndex: dayIndex,
                switchToTodayTab: false,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
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
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l10n.openTodayChecklist,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(alpha: 0.65),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ],
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
