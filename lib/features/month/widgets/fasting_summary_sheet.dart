import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

class FastingSummarySheet extends ConsumerWidget {
  final int seasonId;
  final int totalDays;

  const FastingSummarySheet({
    super.key,
    required this.seasonId,
    required this.totalDays,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final database = ref.watch(databaseProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.fastingSummaryTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: FutureBuilder<Map<int, List<FastingDayInfo>>>(
              future: _loadFastingSummary(database),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final byStatus = snapshot.data!;
                final statusOrder = [
                  FastingStatus.fasted,
                  FastingStatus.excusedSick,
                  FastingStatus.excusedNifas,
                  FastingStatus.excusedHaid,
                  FastingStatus.excusedOther,
                  FastingStatus.notDone,
                ];
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: statusOrder.map((status) {
                    final list = byStatus[status] ?? [];
                    if (list.isEmpty && status != FastingStatus.notDone) {
                      return const SizedBox.shrink();
                    }
                    final label = _statusLabel(l10n, status);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label: ${list.length} ${list.length == 1 ? l10n.fastingSummaryDay : l10n.fastingSummaryDays}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: list.map((info) {
                                final hasNote = status == FastingStatus.excusedOther &&
                                    info.note != null &&
                                    info.note!.isNotEmpty;
                                return Tooltip(
                                  message: hasNote ? 'Day ${info.dayIndex}: ${info.note}' : 'Day ${info.dayIndex}',
                                  child: Chip(
                                    label: Text(
                                      hasNote ? '${info.dayIndex} (${info.note})' : '${info.dayIndex}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                                  ),
                                );
                              }).toList(),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<int, List<FastingDayInfo>>> _loadFastingSummary(database) async {
    final habit = await database.habitsDao.getHabitByKey('fasting');
    if (habit == null) return {};
    final entries = await database.dailyEntriesDao.getAllSeasonEntries(seasonId);
    final fastingByDay = <int, ({int? valueInt, bool? valueBool, String? note})>{};
    for (final e in entries) {
      if (e.habitId == habit.id) {
        fastingByDay[e.dayIndex] = (valueInt: e.valueInt, valueBool: e.valueBool, note: e.note);
      }
    }
    final byStatus = <int, List<FastingDayInfo>>{};
    for (int dayIndex = 1; dayIndex <= totalDays; dayIndex++) {
      final data = fastingByDay[dayIndex];
      final status = FastingStatus.fromEntry(data?.valueInt, data?.valueBool);
      byStatus.putIfAbsent(status, () => []).add(FastingDayInfo(dayIndex: dayIndex, note: data?.note));
    }
    return byStatus;
  }

  String _statusLabel(AppLocalizations l10n, int status) {
    switch (status) {
      case FastingStatus.fasted:
        return l10n.fastingStatusFasted;
      case FastingStatus.excusedSick:
        return l10n.fastingStatusExcusedSick;
      case FastingStatus.excusedNifas:
        return l10n.fastingStatusExcusedNifas;
      case FastingStatus.excusedHaid:
        return l10n.fastingStatusExcusedHaid;
      case FastingStatus.excusedOther:
        return l10n.fastingStatusExcusedOther;
      case FastingStatus.notDone:
        return l10n.fastingStatusNotDone;
      default:
        return l10n.fastingStatusNotDone;
    }
  }
}

class FastingDayInfo {
  final int dayIndex;
  final String? note;
  FastingDayInfo({required this.dayIndex, this.note});
}
