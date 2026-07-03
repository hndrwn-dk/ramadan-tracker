import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_days_provider.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/features/engagement/achievements_screen.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Surfaces achievements unlocked this week on the 7-day Insights tab.
class WeeklyAchievementsCard extends ConsumerWidget {
  const WeeklyAchievementsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recentAsync = ref.watch(recentWeeklyAchievementKeysProvider);

    return recentAsync.when(
      data: (keys) {
        if (keys.isEmpty) return const SizedBox.shrink();

        final titles = keys
            .map((k) {
              final def = AchievementCatalog.byKey(k);
              if (def == null) return null;
              return CelebrationListenerHelper.titleFor(l10n, def.titleKey);
            })
            .whereType<String>()
            .take(3)
            .toList();

        return AppSurface(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const AchievementsScreen()),
            );
          },
          child: Row(
            children: [
              Icon(Icons.military_tech_outlined, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weeklyAchievementsTitle(keys.length),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (titles.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        titles.join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
