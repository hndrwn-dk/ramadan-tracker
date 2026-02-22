import 'package:flutter/material.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/insights/models.dart';
import 'package:ramadan_tracker/insights/task_registry.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/widgets/dhikr_icon.dart';
import 'package:ramadan_tracker/widgets/itikaf_icon.dart';
import 'package:ramadan_tracker/widgets/sedekah_icon.dart';
import 'package:ramadan_tracker/widgets/prayers_icon.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';
import 'package:ramadan_tracker/widgets/taraweeh_icon.dart';

class TaskCard extends StatelessWidget {
  final TaskKey taskKey;
  final TaskInsightSummary summary;
  final VoidCallback? onTap;
  final String? sedekahCurrency;

  const TaskCard({
    super.key,
    required this.taskKey,
    required this.summary,
    this.onTap,
    this.sedekahCurrency,
  });

  @override
  Widget build(BuildContext context) {
    final taskDef = TaskRegistry.getTask(taskKey);
    if (taskDef == null) return const SizedBox.shrink();

    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              taskKey == TaskKey.quran
                  ? QuranIcon(
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : taskKey == TaskKey.prayers5
                      ? PrayersIcon(
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : taskKey == TaskKey.itikaf
                          ? ItikafIcon(
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : taskKey == TaskKey.taraweeh
                              ? TaraweehIcon(
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : taskKey == TaskKey.dhikr
                                  ? DhikrIcon(
                                      size: 20,
                                      color: Theme.of(context).colorScheme.primary,
                                    )
                                  : taskKey == TaskKey.sedekah
                                      ? SedekahIcon(
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        )
                                      : Icon(
                                          taskDef.icon,
                                          size: 20,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  taskDef.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (summary.needAttention)
                Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPrimaryMetric(context, taskKey, summary),
          if (summary.chartSeries.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: _buildMiniChart(context, summary.chartSeries),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrimaryMetric(
    BuildContext context,
    TaskKey taskKey,
    TaskInsightSummary summary,
  ) {
    switch (taskKey) {
      case TaskKey.fasting:
        final days = summary.chartSeries.where((s) => s.y >= 100).length;
        final total = summary.chartSeries.length;
        return Text(
          'Done $days/$total days',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        );
      case TaskKey.taraweeh:
        final totalRakaat = summary.metadata['totalRakaat'] as int? ?? 0;
        final targetRakaat = summary.metadata['targetRakaat'] as int? ?? 0;
        if (targetRakaat > 0) {
          final l10n = AppLocalizations.of(context);
          final label = l10n?.taraweehRakaatProgress(totalRakaat, targetRakaat) ?? '$totalRakaat/$targetRakaat rakaat';
          return Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          );
        }
        final days = summary.chartSeries.where((s) => s.y >= 100).length;
        final total = summary.chartSeries.length;
        return Text(
          'Done $days/$total days',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        );

      case TaskKey.quran:
        final avg = summary.metadata['average'] as int? ?? 0;
        final target = summary.metadata['target'] as int? ?? 0;
        return Text(
          target > 0 ? 'Avg $avg/$target pages' : 'Avg $avg pages',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        );

      case TaskKey.dhikr:
        final avg = summary.metadata['average'] as int? ?? 0;
        final target = summary.metadata['target'] as int? ?? 0;
        return Text(
          target > 0 ? 'Avg $avg/$target' : 'Avg $avg',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        );

      case TaskKey.sedekah:
        final total = summary.metadata['total'] as int? ?? 0;
        final currency = sedekahCurrency ?? 'IDR';
        final normalizedCurrency = _normalizeCurrency(currency);
        return Text(
          'Total ${SedekahUtils.formatCurrency(total.toDouble(), normalizedCurrency)}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        );

      case TaskKey.prayers5:
        final allFiveDays = summary.metadata['allFiveDays'] as int? ?? 0;
        final totalDays = summary.metadata['totalDays'] as int? ?? 0;
        final totalPrayers = summary.metadata['totalPrayersCompleted'] as int?;
        final totalPossible = summary.metadata['totalPossible'] as int?;
        final completionRate = summary.metadata['completionRate'] as double?;
        final mostMissed = summary.metadata['mostMissed'] as String?;
        
        if (totalPrayers != null && totalPossible != null) {
          // Detailed mode: show total prayers and completion rate
          final rate = completionRate ?? (totalPossible > 0 ? totalPrayers / totalPossible : 0.0);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${totalPrayers}/${totalPossible} prayers (${(rate * 100).toStringAsFixed(0)}%)',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (allFiveDays > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'All-5: $allFiveDays/$totalDays days',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (mostMissed != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Most missed: ${mostMissed[0].toUpperCase() + mostMissed.substring(1)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
            ],
          );
        } else {
          // Simple mode: show all-5 days only
          return Text(
            'All-5: $allFiveDays/$totalDays days',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          );
        }

      case TaskKey.itikaf:
        final nightsDone = summary.metadata['nightsDone'] as int? ?? 0;
        final nightsRemaining = summary.metadata['nightsRemaining'] as int? ?? 0;
        return Text(
          '$nightsDone/10 nights',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        );
    }
  }

  Widget _buildMiniChart(BuildContext context, List<dynamic> chartSeries) {
    if (chartSeries.isEmpty) return const SizedBox.shrink();

    // Simple sparkline using Container bars
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children:       chartSeries.take(7).map((spot) {
        final height = ((spot.y as num) / 100).clamp(0.0, 1.0);
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            height: 40 * height,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _normalizeCurrency(String currency) {
    // Handle currency symbols that might be passed directly (S$, $, RM, Rp)
    String normalizedCurrency = currency.trim();
    final symbolToCode = {
      'S\$': 'SGD',
      '\$': 'USD',
      'RM': 'MYR',
      'Rp': 'IDR',
      'RP': 'IDR',
    };
    if (symbolToCode.containsKey(normalizedCurrency)) {
      normalizedCurrency = symbolToCode[normalizedCurrency]!;
    } else {
      normalizedCurrency = normalizedCurrency.toUpperCase();
    }
    return normalizedCurrency;
  }
}

