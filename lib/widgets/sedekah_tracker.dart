import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:intl/intl.dart';

final _sedekahCurrencyProvider = FutureProvider.autoDispose<String>((ref) async {
  final database = ref.watch(databaseProvider);
  final currency = await database.kvSettingsDao.getValue('sedekah_currency');
  return currency ?? 'Rp';
});

class SedekahTracker extends ConsumerStatefulWidget {
  final int seasonId;
  final int dayIndex;
  final int habitId;
  final String currency;

  const SedekahTracker({
    super.key,
    required this.seasonId,
    required this.dayIndex,
    required this.habitId,
    this.currency = 'Rp',
  });

  @override
  ConsumerState<SedekahTracker> createState() => _SedekahTrackerState();
}

class _SedekahTrackerState extends ConsumerState<SedekahTracker> {
  int? _lastSelectedChip;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
    final currencyAsync = ref.watch(_sedekahCurrencyProvider);
    final currency = currencyAsync.valueOrNull ?? widget.currency;

    return entriesAsync.when(
      data: (entries) {
        final sedekahEntry = entries.where((e) => e.habitId == widget.habitId).firstOrNull;
        final amount = sedekahEntry?.valueInt ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism, size: 20),
                const SizedBox(width: 12),
                Text(
                  'Sedekah',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (amount > 0) {
                      _updateAmount(ref, amount - 1000);
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
                    child: Text(
                      _formatAmount(amount, currency),
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    _updateAmount(ref, amount + 1000);
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
              children: [5000, 10000, 20000].map((chip) {
                final isSelected = _lastSelectedChip == chip;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _lastSelectedChip = chip;
                      });
                      _updateAmount(ref, amount + chip);
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
                            '+${_formatAmount(chip, currency)}',
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
    );
  }

  String _formatAmount(int amount, String currency) {
    final formatter = NumberFormat.currency(
      symbol: currency,
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  void _updateAmount(WidgetRef ref, int newAmount) {
    final database = ref.read(databaseProvider);
    database.dailyEntriesDao.setIntValue(widget.seasonId, widget.dayIndex, widget.habitId, newAmount);
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
  }
}

