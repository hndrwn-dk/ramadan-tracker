import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/daily_quest_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/extensions.dart';

class DailyQuestsCard extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const DailyQuestsCard({
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
        final completed = state.progress.where((p) => p.completed).length;
        return PremiumCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.dailyQuestsTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                l10n.dailyQuestsProgress(completed, state.quests.length),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ...state.quests.map((quest) {
                final done = state.progress
                    .where((p) => p.questId == quest.id)
                    .map((p) => p.completed)
                    .firstOrNull ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        done ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: done
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_questTitle(l10n, quest))),
                    ],
                  ),
                );
              }),
            ],
          ),
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
