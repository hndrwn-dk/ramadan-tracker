import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_ring.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class ChecklistProgressHeader extends StatelessWidget {
  final int completed;
  final int total;

  const ChecklistProgressHeader({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          ChecklistProgressRing(
            progress: progress,
            completed: completed,
            total: total,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.checklistProgressDone(completed, total),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  _nudgeMessage(l10n, completed, total),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _nudgeMessage(AppLocalizations l10n, int completed, int total) {
    if (total <= 0 || completed <= 0) return l10n.checklistNudgeStart;
    if (completed >= total) return l10n.checklistNudgeDone;
    if (completed >= total - 1) return l10n.checklistNudgeAlmost;
    return l10n.checklistNudgePartial;
  }
}
