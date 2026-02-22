import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/quran_provider.dart';
import 'package:ramadan_tracker/domain/services/quran_service.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/quran_icon.dart';

class QuranTracker extends ConsumerStatefulWidget {
  final int seasonId;
  final int dayIndex;
  final int habitId;

  const QuranTracker({
    super.key,
    required this.seasonId,
    required this.dayIndex,
    required this.habitId,
  });

  @override
  ConsumerState<QuranTracker> createState() => _QuranTrackerState();
}

class _QuranTrackerState extends ConsumerState<QuranTracker> {
  int? _lastSelectedChip;

  @override
  Widget build(BuildContext context) {
    final quranPlanAsync = ref.watch(quranPlanProvider(widget.seasonId));
    final quranDailyAsync = ref.watch(quranDailyProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));

    return quranPlanAsync.when(
      data: (quranPlan) => quranDailyAsync.when(
        data: (quranDaily) {
          final pagesRead = quranDaily?.pagesRead ?? 0;
          final pagesPerJuz = QuranService.getPagesPerJuz(plan: quranPlan);
          final juzTarget = QuranService.getJuzTarget(plan: quranPlan);
          final juzProgress = QuranService.calculateJuzProgress(
            pagesRead: pagesRead,
            pagesPerJuz: pagesPerJuz,
          );
          final dailyTargetPages = quranPlan?.dailyTargetPages ?? (pagesPerJuz * juzTarget);
          final juzDisplay = _formatJuzDisplay(juzProgress);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const QuranIcon(size: 20),
                      const SizedBox(width: 12),
                      Text(
                        getHabitDisplayName(context, 'quran_pages'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.juzProgress(juzDisplay, juzTarget),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (pagesRead > 0) {
                        _updatePages(ref, pagesRead - 1);
                      }
                    },
                    icon: const Icon(Icons.remove_circle_outline),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$pagesRead',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            AppLocalizations.of(context)!.ofPages(dailyTargetPages),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      _updatePages(ref, pagesRead + 1);
                    },
                    icon: const Icon(Icons.add_circle_outline),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [5, 10, 20].map((chip) {
                  final isSelected = _lastSelectedChip == chip;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _lastSelectedChip = chip;
                        });
                        _updatePages(ref, pagesRead + chip);
                        // Reset selection after 1 second
                        Future.delayed(const Duration(seconds: 1), () {
                          if (mounted) {
                            setState(() {
                              _lastSelectedChip = null;
                            });
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+$chip',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 6),
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(),
        error: (_, __) => const Text('Error'),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error'),
    );
  }

  /// Format juz for display: max 30, no "30.2" (juz is 1-30 only).
  static String _formatJuzDisplay(double juzProgress) {
    if (juzProgress >= 30) return '30';
    if (juzProgress >= 1) return juzProgress.floor().toString();
    if (juzProgress > 0) return juzProgress.toStringAsFixed(1);
    return '0';
  }

  void _updatePages(WidgetRef ref, int newPages) {
    final database = ref.read(databaseProvider);
    database.quranDailyDao.setPages(widget.seasonId, widget.dayIndex, newPages);
    ref.invalidate(quranDailyProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
  }
}

