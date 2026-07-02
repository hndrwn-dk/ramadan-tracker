import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/daily_quest_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

/// Inline quest progress for the Today hero card (replaces full quest card).
class CompactDailyQuestsStrip extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const CompactDailyQuestsStrip({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(dailyQuestsProvider((seasonId: seasonId, dayIndex: dayIndex)));

    return async.when(
      data: (state) {
        if (state.quests.isEmpty) return const SizedBox.shrink();
        final completed = state.progress.where((p) => p.completed).length;
        final scheme = Theme.of(context).colorScheme;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Text(
              l10n.dailyQuestsProgress(completed, state.quests.length),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: state.quests.map((quest) {
                final done = state.progress
                        .where((p) => p.questId == quest.id)
                        .map((p) => p.completed)
                        .firstOrNull ??
                    false;
                return _QuestChip(
                  label: _questTitle(l10n, quest),
                  done: done,
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _questTitle(AppLocalizations l10n, DailyQuest quest) {
    switch (quest.titleKey) {
      case 'questLogFasting':
        return l10n.questLogFasting;
      case 'questLogQuran':
        return l10n.questLogQuran;
      case 'questLogPrayers':
        return l10n.questLogPrayers;
      case 'questLogDhikr':
        return l10n.questLogDhikr;
      case 'questLogTaraweeh':
        return l10n.questLogTaraweeh;
      case 'questScore60':
        return l10n.questScore60;
      default:
        return quest.titleKey;
    }
  }
}

class _QuestChip extends StatelessWidget {
  final String label;
  final bool done;

  const _QuestChip({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: done
            ? scheme.primaryContainer.withValues(alpha: 0.5)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: done
              ? scheme.primary.withValues(alpha: 0.4)
              : scheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: done ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: done ? FontWeight.w600 : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
