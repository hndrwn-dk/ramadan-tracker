import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/season_state_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/features/today/today_checklist_navigation.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_ring.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/floating_pill_nav_bar.dart';

/// Season day whose checklist card should float above the pill on Today.
class TodayChecklistTarget {
  final int seasonId;
  final int dayIndex;

  const TodayChecklistTarget({
    required this.seasonId,
    required this.dayIndex,
  });
}

final todayChecklistTargetProvider = Provider<TodayChecklistTarget?>((ref) {
  if (ref.watch(seasonStateProvider) != SeasonState.active) return null;
  final season = ref.watch(currentSeasonProvider).valueOrNull;
  if (season == null) return null;
  return TodayChecklistTarget(
    seasonId: season.id,
    dayIndex: ref.watch(activeDayIndexForUIProvider),
  );
});

/// Floating checklist summary stacked above the pill nav on Today.
///
/// The entire row is tappable and opens today's checklist. The trailing
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
    final progressAsync = ref.watch(
      checklistProgressProvider((seasonId: seasonId, dayIndex: dayIndex)),
    );

    return progressAsync.when(
      data: (progress) {
        final completed = progress.completed;
        final total = progress.total;
        final fraction = total > 0 ? completed / total : 0.0;
        return _ChecklistCardFrame(
          child: _ChecklistCardContents(
            completed: completed,
            total: total,
            fraction: fraction,
            subtitle: _subtitle(l10n, completed, total),
            onTap: () => openDayChecklist(
              context,
              ref,
              dayIndex: dayIndex,
              switchToTodayTab: false,
            ),
          ),
        );
      },
      loading: () => const _ChecklistCardFrame(
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ChecklistCardFrame extends StatelessWidget {
  final Widget child;

  const _ChecklistCardFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FloatingPillNavBar.horizontalMargin,
      ),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: FloatingPillNavBar.maxBarWidth,
          ),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: 0,
            maxScaleFactor: 1.3,
            child: FloatingGlassPanel(
              height: FloatingPillNavBar.accessoryHeight,
              radius: 24,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChecklistCardContents extends StatelessWidget {
  final int completed;
  final int total;
  final double fraction;
  final String subtitle;
  final VoidCallback onTap;

  const _ChecklistCardContents({
    required this.completed,
    required this.total,
    required this.fraction,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: l10n.todayChecklistButton,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 10, 0),
          child: Row(
            children: [
              ChecklistProgressRing(
                progress: fraction,
                completed: completed,
                total: total,
                size: 40,
                strokeWidth: 4,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.checklistProgressDone(completed, total),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  l10n.todayChecklistButton,
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
