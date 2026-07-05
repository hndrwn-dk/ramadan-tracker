import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/achievement_provider.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/achievement_model.dart';
import 'package:ramadan_tracker/domain/services/habit_mastery_service.dart';
import 'package:ramadan_tracker/features/engagement/widgets/celebration_listener.dart';
import 'package:ramadan_tracker/features/engagement/widgets/season_share_card.dart';
import 'package:ramadan_tracker/features/insights/models/insights_data.dart';
import 'package:ramadan_tracker/features/insights/providers/insights_provider.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/widgets/app_back_button.dart';

class SeasonReportScreen extends ConsumerWidget {
  final int seasonId;

  const SeasonReportScreen({
    super.key,
    required this.seasonId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final insightsAsync = ref.watch(seasonInsightsDataProvider(seasonId));
    final comparisonAsync = ref.watch(seasonComparisonForIdProvider(seasonId));
    final unlockedAsync = ref.watch(unlockedAchievementsProvider);
    final seasonFuture = ref.read(seasonRepositoryProvider).getSeasonById(seasonId);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l10n.seasonReportTitle),
        actions: [
          insightsAsync.when(
            data: (insightsData) => unlockedAsync.when(
              data: (unlocked) => FutureBuilder(
                future: seasonFuture,
                builder: (context, seasonSnap) {
                  if (!seasonSnap.hasData || seasonSnap.data == null) {
                    return const SizedBox.shrink();
                  }
                  final season = seasonSnap.data!;
                  return IconButton(
                    icon: const Icon(Icons.share_outlined),
                    tooltip: l10n.shareAction,
                    onPressed: () {
                      final keys = unlocked.map((u) => u.achievementKey).toSet();
                      final highlights = AchievementCatalog.all
                          .where((d) => keys.contains(d.key))
                          .take(3)
                          .toList();
                      showSeasonShareDialog(
                        context: context,
                        seasonLabel: season.label,
                        avgScore: insightsData.avgScore.round(),
                        strongDays:
                            (insightsData.completionRate * insightsData.daysCount).round(),
                        totalDays: insightsData.daysCount,
                        longestStreak: insightsData.bestStreak,
                        unlockedCount: unlocked.length,
                        highlights: highlights,
                      );
                    },
                  );
                },
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: FutureBuilder(
        future: seasonFuture,
        builder: (context, seasonFuture) {
          if (seasonFuture.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final season = seasonFuture.data;
          if (season == null) {
            return Center(child: Text(l10n.errorMessage('No season')));
          }

          return insightsAsync.when(
            data: (insightsData) {
              return FutureBuilder<Map<String, HabitMasteryTier>>(
                future: HabitMasteryService.tiersForSeason(
                  ref.read(databaseProvider),
                  season.id,
                  season.days,
                ),
                builder: (context, masterySnap) {
                  final mastery = masterySnap.data ?? {};
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSeasonSummary(context, l10n, season.label, insightsData),
                        const SizedBox(height: 16),
                        unlockedAsync.when(
                          data: (unlocked) => _buildTrophyGrid(
                            context,
                            l10n,
                            unlocked.map((u) => u.achievementKey).toSet(),
                          ),
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 16),
                        _buildHabitMastery(context, l10n, insightsData, mastery),
                        const SizedBox(height: 16),
                        comparisonAsync.when(
                          data: (comparison) {
                            if (comparison == null) return const SizedBox.shrink();
                            return _buildComparisonSection(context, l10n, comparison);
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(l10n.errorMessage(error.toString()))),
          );
        },
      ),
    );
  }

  Widget _buildSeasonSummary(
    BuildContext context,
    AppLocalizations l10n,
    String seasonLabel,
    InsightsData insightsData,
  ) {
    final perfectDays = (insightsData.completionRate * insightsData.daysCount).round();
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            seasonLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.seasonReportSummary,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(l10n.seasonReportAvgScore(insightsData.avgScore.toStringAsFixed(0))),
          Text(l10n.seasonReportPerfectDays(perfectDays, insightsData.daysCount)),
          Text(l10n.seasonReportLongestStreak(insightsData.bestStreak)),
        ],
      ),
    );
  }

  Widget _buildTrophyGrid(
    BuildContext context,
    AppLocalizations l10n,
    Set<String> unlockedKeys,
  ) {
    if (unlockedKeys.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.seasonReportTrophies,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: AchievementCatalog.all.length,
            itemBuilder: (context, index) {
              final def = AchievementCatalog.all[index];
              final unlocked = unlockedKeys.contains(def.key);
              final title = CelebrationListenerHelper.titleFor(
                AppLocalizations.of(context)!,
                def.titleKey,
              );
              return Column(
                children: [
                  Icon(
                    def.icon,
                    color: unlocked ? scheme.primary : scheme.onSurface.withValues(alpha: 0.25),
                    size: 28,
                  ),
                  if (unlocked)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHabitMastery(
    BuildContext context,
    AppLocalizations l10n,
    InsightsData insightsData,
    Map<String, HabitMasteryTier> mastery,
  ) {
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.seasonReportHabits,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...insightsData.perHabitStats.entries.map((entry) {
            final tier = mastery[entry.key] ?? HabitMasteryTier.none;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(getHabitDisplayName(context, entry.key))),
                  if (tier != HabitMasteryTier.none) _tierChip(context, l10n, tier),
                  const SizedBox(width: 8),
                  Text(_formatHabitStat(entry.value)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tierChip(BuildContext context, AppLocalizations l10n, HabitMasteryTier tier) {
    final label = switch (tier) {
      HabitMasteryTier.bronze => l10n.habitMasteryBronze,
      HabitMasteryTier.silver => l10n.habitMasterySilver,
      HabitMasteryTier.gold => l10n.habitMasteryGold,
      HabitMasteryTier.none => '',
    };
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }

  Widget _buildComparisonSection(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, dynamic> comparison,
  ) {
    final current = comparison['current'] as InsightsData;
    final previous = comparison['previous'] as InsightsData;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.seasonReportComparison,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            context,
            l10n.seasonComparisonAvgScore,
            current.avgScore.round(),
            previous.avgScore.round(),
          ),
          _buildComparisonRow(
            context,
            l10n.seasonComparisonStrongDays,
            (current.completionRate * current.daysCount).round(),
            (previous.completionRate * previous.daysCount).round(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(BuildContext context, String label, int current, int previous) {
    final delta = current - previous;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label.trim(), style: Theme.of(context).textTheme.bodyMedium)),
          Row(
            children: [
              Text('$current', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Text(
                delta >= 0 ? '+$delta' : '$delta',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: delta >= 0 ? Colors.green : Colors.red,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHabitStat(habitStats) {
    if (habitStats.totalValue != null) {
      return 'Total: ${habitStats.totalValue}';
    } else if (habitStats.doneDays != null) {
      return '${habitStats.doneDays}/${habitStats.totalDays}';
    }
    return '';
  }
}
