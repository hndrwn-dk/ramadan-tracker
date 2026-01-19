import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

final prayerDetailsProvider = FutureProvider.family<PrayerDetail?, ({int seasonId, int dayIndex})>((ref, params) async {
  final database = ref.read(databaseProvider);
  return await database.prayerDetailsDao.getPrayerDetails(params.seasonId, params.dayIndex);
});

class PrayerDetailsWidget extends ConsumerWidget {
  final int seasonId;
  final int dayIndex;

  const PrayerDetailsWidget({
    super.key,
    required this.seasonId,
    required this.dayIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayerDetailsAsync = ref.watch(prayerDetailsProvider((seasonId: seasonId, dayIndex: dayIndex)));

    return prayerDetailsAsync.when(
      data: (details) {
        final fajr = details?.fajr ?? false;
        final dhuhr = details?.dhuhr ?? false;
        final asr = details?.asr ?? false;
        final maghrib = details?.maghrib ?? false;
        final isha = details?.isha ?? false;
        final completedCount = [fajr, dhuhr, asr, maghrib, isha].where((p) => p).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.mosque,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  getHabitDisplayName(context, 'prayers'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildPrayerChip(context, ref, AppLocalizations.of(context)!.prayerFajr, fajr, Icons.wb_sunny),
                      _buildPrayerChip(context, ref, AppLocalizations.of(context)!.prayerDhuhr, dhuhr, Icons.wb_twilight),
                      _buildPrayerChip(context, ref, AppLocalizations.of(context)!.prayerAsr, asr, Icons.wb_sunny_outlined),
                      _buildPrayerChip(context, ref, AppLocalizations.of(context)!.maghrib, maghrib, Icons.nights_stay),
                      _buildPrayerChip(context, ref, AppLocalizations.of(context)!.prayerIsha, isha, Icons.nightlight_round),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completedCount/5',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: completedCount == 5
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const SizedBox(
        height: 40,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPrayerChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    bool completed,
    IconData icon,
  ) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _togglePrayer(ref, label.toLowerCase(), !completed);
      },
      child: Tooltip(
        message: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: completed
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
                border: Border.all(
                  color: completed
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: completed ? 2 : 1,
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: completed
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 48,
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
                      fontWeight: completed ? FontWeight.w600 : FontWeight.normal,
                      color: completed
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePrayer(WidgetRef ref, String prayerName, bool completed) async {
    final database = ref.read(databaseProvider);
    // Map localized prayer names to database field names
    final prayerKey = _mapPrayerNameToKey(prayerName);
    await database.prayerDetailsDao.setPrayer(seasonId, dayIndex, prayerKey, completed);
    ref.invalidate(prayerDetailsProvider((seasonId: seasonId, dayIndex: dayIndex)));
    
    // Also update the simple prayers entry if all 5 are completed
    final details = await database.prayerDetailsDao.getPrayerDetails(seasonId, dayIndex);
    if (details != null) {
      final allCompleted = details.fajr && details.dhuhr && details.asr && details.maghrib && details.isha;
      // Find prayers habit ID
      final habits = await database.habitsDao.getAllHabits();
      final prayersHabit = habits.where((h) => h.key == 'prayers').firstOrNull;
      if (prayersHabit != null) {
        await database.dailyEntriesDao.setBoolValue(seasonId, dayIndex, prayersHabit.id, allCompleted);
        // Invalidate dailyEntriesProvider to trigger completion score recalculation
        ref.invalidate(dailyEntriesProvider((seasonId: seasonId, dayIndex: dayIndex)));
      }
    }
  }

  /// Maps localized prayer names to database field names
  String _mapPrayerNameToKey(String prayerName) {
    final lowerName = prayerName.toLowerCase().trim();
    // Handle Indonesian names
    if (lowerName == 'subuh' || lowerName.contains('fajr')) return 'fajr';
    if (lowerName == 'dzuhur' || lowerName == 'dhuhur' || lowerName.contains('dhuhr') || lowerName.contains('zuhr')) return 'dhuhr';
    if (lowerName == 'ashar' || lowerName == 'ashr' || lowerName.contains('asr')) return 'asr';
    if (lowerName == 'maghrib' || lowerName.contains('maghrib')) return 'maghrib';
    if (lowerName == 'isya' || lowerName == 'isha' || lowerName.contains('isha')) return 'isha';
    // Fallback: assume it's already a key
    return lowerName;
  }
}

