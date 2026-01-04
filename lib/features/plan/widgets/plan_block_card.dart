import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/domain/services/autopilot_service.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class PlanBlockCard extends ConsumerWidget {
  final String label;
  final TimelineBlock block;
  final IconData icon;
  final String? timeWindow;
  final int seasonId;
  final int dayIndex;

  const PlanBlockCard({
    super.key,
    required this.label,
    required this.block,
    required this.icon,
    this.timeWindow,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (timeWindow != null) ...[
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      timeWindow!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSecondaryContainer,
                          ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppLocalizations.of(context)!.minutes(block.totalMinutes),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          if (block.tasks.isEmpty) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                AppLocalizations.of(context)!.noTasksScheduled,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            ...block.tasks.map((task) {
              return Padding(
                padding: const EdgeInsets.only(left: 28, bottom: 12),
                child: _buildTaskRow(context, ref, task),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildTaskRow(BuildContext context, WidgetRef ref, Task task) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getLocalizedTaskName(context, task.name),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${task.minutes} min',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                      if (task.pages != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${task.pages} ${AppLocalizations.of(context)!.pages}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                          ],
                        ),
                      if (task.count != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '${task.count} ${AppLocalizations.of(context)!.count}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: _buildActionButton(context, ref, task),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, Task task) {
    if (task.name.toLowerCase().contains('quran')) {
      return _buildSmallButton(
        context,
        label: AppLocalizations.of(context)!.startReading,
        icon: Icons.menu_book,
        onTap: () {
          // Navigate to Today screen (Quran tracker is there)
          ref.read(tabIndexProvider.notifier).state = 0;
        },
      );
    } else if (task.name.toLowerCase().contains('dhikr')) {
      return _buildSmallButton(
        context,
        label: AppLocalizations.of(context)!.startCounter,
        icon: Icons.favorite,
        onTap: () {
          // Navigate to Today screen (Dhikr counter is there)
          ref.read(tabIndexProvider.notifier).state = 0;
        },
      );
    } else if (task.name.toLowerCase().contains('taraweeh')) {
      // Only show button for Taraweeh (has habit), not Qiyam
      return FutureBuilder<bool>(
        future: _isTaskDone(ref, task),
        builder: (context, snapshot) {
          final isDone = snapshot.data ?? false;
          return _buildSmallButton(
            context,
            label: isDone ? AppLocalizations.of(context)!.done : AppLocalizations.of(context)!.markDone,
            icon: isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            onTap: () {
              _toggleTaskDone(ref, task, !isDone);
            },
          );
        },
      );
    }
    // Qiyam doesn't have a habit, so no action button
    return const SizedBox.shrink();
  }

  Widget _buildSmallButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 10,
                      ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _isTaskDone(WidgetRef ref, Task task) async {
    final database = ref.read(databaseProvider);
    final entries = await database.dailyEntriesDao.getDayEntries(seasonId, dayIndex);
    final habits = await database.habitsDao.getAllHabits();

    if (task.name.toLowerCase().contains('taraweeh')) {
      final taraweehHabit = habits.where((h) => h.key == 'taraweeh').firstOrNull;
      if (taraweehHabit != null) {
        final entry = entries.where((e) => e.habitId == taraweehHabit.id).firstOrNull;
        return entry?.valueBool ?? false;
      }
    } else if (task.name.toLowerCase().contains('qiyam')) {
      // Qiyam might not have a direct habit, treat as optional
      return false;
    }

    return false;
  }

  Future<void> _toggleTaskDone(WidgetRef ref, Task task, bool done) async {
    final database = ref.read(databaseProvider);
    final habits = await database.habitsDao.getAllHabits();

    if (task.name.toLowerCase().contains('taraweeh')) {
      final taraweehHabit = habits.where((h) => h.key == 'taraweeh').firstOrNull;
      if (taraweehHabit != null) {
        await database.dailyEntriesDao.setBoolValue(seasonId, dayIndex, taraweehHabit.id, done);
        ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
      }
    }
  }

  String _getLocalizedTaskName(BuildContext context, String taskName) {
    final l10n = AppLocalizations.of(context)!;
    final lowerName = taskName.toLowerCase();
    
    if (lowerName.contains('quran') || lowerName.contains('reading')) {
      return l10n.taskQuranReading;
    } else if (lowerName.contains('dhikr')) {
      return l10n.habitDhikr;
    } else if (lowerName.contains('qiyam')) {
      return l10n.taskQiyam;
    } else if (lowerName.contains('taraweeh')) {
      return l10n.habitTaraweeh;
    }
    
    // Fallback to original name if no match
    return taskName;
  }
}

