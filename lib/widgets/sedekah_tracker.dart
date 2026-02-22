import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';
import 'package:ramadan_tracker/utils/habit_helpers.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/sedekah_icon.dart';

final _sedekahCurrencyProvider = FutureProvider.autoDispose<String>((ref) async {
  final database = ref.watch(databaseProvider);
  final currency = await database.kvSettingsDao.getValue('sedekah_currency');
  return currency ?? 'IDR';
});

final _sedekahGoalProvider = FutureProvider.autoDispose<({bool enabled, double amount})>((ref) async {
  final database = ref.watch(databaseProvider);
  final enabledStr = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
  final amountStr = await database.kvSettingsDao.getValue('sedekah_goal_amount');
  final enabled = enabledStr == 'true';
  final amount = enabled && amountStr != null ? double.tryParse(amountStr) ?? 0.0 : 0.0;
  return (enabled: enabled, amount: amount);
});

class SedekahTracker extends ConsumerStatefulWidget {
  final int seasonId;
  final int dayIndex;
  final int habitId;

  const SedekahTracker({
    super.key,
    required this.seasonId,
    required this.dayIndex,
    required this.habitId,
  });

  @override
  ConsumerState<SedekahTracker> createState() => _SedekahTrackerState();
}

class _SedekahTrackerState extends ConsumerState<SedekahTracker> {
  double? _lastSelectedChip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entriesAsync = ref.watch(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
    final currencyAsync = ref.watch(_sedekahCurrencyProvider);
    final goalAsync = ref.watch(_sedekahGoalProvider);
    final currency = currencyAsync.valueOrNull ?? 'IDR';
    final goal = goalAsync.valueOrNull;
    // Normalize currency - handle legacy values
    final normalizedCurrency = _normalizeCurrency(currency);

    return entriesAsync.when(
      data: (entries) {
        final sedekahEntry = entries.where((e) => e.habitId == widget.habitId).firstOrNull;
        final amount = (sedekahEntry?.valueInt ?? 0).toDouble();
        final goalAmount = goal?.amount ?? 0.0;
        final goalEnabled = goal?.enabled ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SedekahIcon(size: 20),
                const SizedBox(width: 12),
                Text(
                  getHabitDisplayName(context, 'sedekah'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Today amount display with progress
            if (goalEnabled && goalAmount > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.todayAmountGoal(
                      SedekahUtils.formatCurrency(amount, normalizedCurrency),
                      SedekahUtils.formatCurrency(goalAmount, normalizedCurrency),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (goalAmount > 0)
                    Text(
                      '${((amount / goalAmount * 100).clamp(0, 100)).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: goalAmount > 0 ? (amount / goalAmount).clamp(0.0, 1.0) : 0.0,
                backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (amount > 0) {
                      final step = _getStepAmount(currency, goalAmount);
                      _updateAmount(ref, (amount - step).clamp(0.0, double.infinity));
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
                      SedekahUtils.formatCurrency(amount, normalizedCurrency),
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () {
                    final step = _getStepAmount(currency, goalAmount);
                    _updateAmount(ref, amount + step);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  style: IconButton.styleFrom(
                    backgroundColor: Theme.of(context).cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Quick add chips with currency-aware increments
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._getCurrencyAwareChips(normalizedCurrency).map((chip) {
                  final isSelected = _lastSelectedChip == chip;
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _lastSelectedChip = chip;
                        });
                        // Add chip amount to current total
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
                              '+${SedekahUtils.formatCurrency(chip, normalizedCurrency)}',
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
                // Custom button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showCustomAmountDialog(ref, amount, normalizedCurrency);
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n.custom,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.edit,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error'),
    );
  }

  void _updateAmount(WidgetRef ref, double newAmount) {
    final database = ref.read(databaseProvider);
    // Store as integer (multiply by 100 for cents/decimals if needed, or round)
    final amountInt = newAmount.round();
    database.dailyEntriesDao.setIntValue(widget.seasonId, widget.dayIndex, widget.habitId, amountInt);
    ref.invalidate(dailyEntriesProvider((seasonId: widget.seasonId, dayIndex: widget.dayIndex)));
  }

  List<double> _getCurrencyAwareChips(String currency) {
    final normalizedCurrency = _normalizeCurrency(currency);
    final isIDR = normalizedCurrency == 'IDR' || normalizedCurrency == 'RP';
    final isMajorCurrency = ['SGD', 'MYR', 'USD', 'EUR', 'GBP'].contains(normalizedCurrency);
    // 3 presets + Custom = 4 options total
    if (isIDR) {
      return [2000.0, 5000.0, 10000.0];
    } else if (isMajorCurrency) {
      return [2.0, 5.0, 10.0];
    } else {
      return [2.0, 5.0, 10.0];
    }
  }

  void _showCustomAmountDialog(WidgetRef ref, double currentAmount, String currency) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentAmount > 0 ? currentAmount.toStringAsFixed(0) : '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customAmount),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l10n.amount,
            prefixText: '${SedekahUtils.formatCurrency(0, currency).split(' ')[0]} ',
            hintText: l10n.enterAmount,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 0) {
                _updateAmount(ref, value);
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }

  double _getStepAmount(String currency, double goalAmount) {
    // Determine step amount based on currency and goal
    final normalizedCurrency = _normalizeCurrency(currency);
    if (normalizedCurrency == 'IDR' || normalizedCurrency == 'RP') {
      return 1000.0;
    } else if (['SGD', 'MYR', 'USD'].contains(normalizedCurrency)) {
      if (goalAmount < 10) return 1.0;
      if (goalAmount < 50) return 5.0;
      return 10.0;
    }
    return 1000.0; // Default for other currencies
  }

  String _normalizeCurrency(String currency) {
    // Handle legacy currency values and symbols
    final symbolToCode = {
      'Rp': 'IDR',
      'RP': 'IDR',
      'S\$': 'SGD',
      '\$': 'USD',
      'RM': 'MYR',
    };
    return symbolToCode[currency] ?? currency.toUpperCase();
  }
}

