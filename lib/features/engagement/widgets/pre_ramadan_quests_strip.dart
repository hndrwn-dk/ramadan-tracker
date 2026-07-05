import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/app/settings_navigation.dart';
import 'package:ramadan_tracker/data/providers/engagement_providers.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/features/sunnah/widgets/fasting_status_sheet.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Pre-Ramadan prep quests shown inside the countdown banner.
class PreRamadanQuestsStrip extends ConsumerWidget {
  const PreRamadanQuestsStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(preRamadanQuestProgressProvider);

    return progressAsync.when(
      data: (progress) {
        if (progress.isEmpty) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context)!;
        final completed = progress.where((p) => p.completed).length;
        final total = progress.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Text(
              l10n.preRamadanQuestsTitle,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.dailyQuestsProgress(completed, total),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...progress.map((p) => _QuestRow(
                  progress: p,
                  title: _title(l10n, p.questId),
                  onTap: p.completed ? null : () => _onQuestTap(context, ref, p.questId),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _onQuestTap(BuildContext context, WidgetRef ref, String questId) {
    if (questId == 'prep_log_sunnah') {
      ref.read(tabIndexProvider.notifier).state = 3;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          showSunnahStatusSheet(context, ref, DateTime.now());
        }
      });
    } else if (questId == 'prep_setup_reminders') {
      openSettingsScreen(context, ref, section: 'reminders');
    } else if (questId == 'prep_review_plan' || questId == 'prep_create_season') {
      ref.read(tabIndexProvider.notifier).state = 2;
    }
    ref.invalidate(preRamadanQuestProgressProvider);
  }

  String _title(AppLocalizations l10n, String questId) {
    switch (questId) {
      case 'prep_review_plan':
        return l10n.preRamadanQuestReviewPlan;
      case 'prep_log_sunnah':
        return l10n.preRamadanQuestLogSunnah;
      case 'prep_setup_reminders':
        return l10n.preRamadanQuestReminders;
      case 'prep_create_season':
        return l10n.preRamadanQuestCreateSeason;
      default:
        return questId;
    }
  }
}

class _QuestRow extends StatelessWidget {
  final DailyQuestProgress progress;
  final String title;
  final VoidCallback? onTap;

  const _QuestRow({
    required this.progress,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                progress.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: progress.completed
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        decoration:
                            progress.completed ? TextDecoration.lineThrough : null,
                      ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: scheme.onSurface.withValues(alpha: 0.35),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
