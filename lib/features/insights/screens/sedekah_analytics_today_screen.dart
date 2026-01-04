import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/utils/sedekah_utils.dart';

/// Today-only financial review screen for Sedekah.
class SedekahAnalyticsTodayScreen extends ConsumerStatefulWidget {
  final int seasonId;
  final DateTime? selectedDate;

  const SedekahAnalyticsTodayScreen({
    super.key,
    required this.seasonId,
    this.selectedDate,
  });

  @override
  ConsumerState<SedekahAnalyticsTodayScreen> createState() => _SedekahAnalyticsTodayScreenState();
}

class _SedekahAnalyticsTodayScreenState extends ConsumerState<SedekahAnalyticsTodayScreen> {
  @override
  Widget build(BuildContext context) {
    final seasonAsync = ref.watch(currentSeasonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sedekah Today'),
      ),
      body: seasonAsync.when(
        data: (season) {
          if (season == null) return const Center(child: Text('No season found'));
          final selectedDate = widget.selectedDate ?? DateTime.now();
          final dayIndex = season.getDayIndex(selectedDate);
          
          return FutureBuilder<Map<String, dynamic>>(
            future: _loadTodayData(season, dayIndex),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(context, data, selectedDate, dayIndex),
                    const SizedBox(height: 24),
                    _buildTransactionsList(context, data),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  Future<Map<String, dynamic>> _loadTodayData(SeasonModel season, int dayIndex) async {
    final database = ref.read(databaseProvider);
    final habits = await ref.read(habitsProvider.future);
    final sedekahHabit = habits.firstWhere((h) => h.key == 'sedekah');
    
    final entries = await database.dailyEntriesDao.getDayEntries(widget.seasonId, dayIndex);
    final entry = entries.firstWhere(
      (e) => e.habitId == sedekahHabit.id,
      orElse: () => DailyEntry(seasonId: widget.seasonId, dayIndex: dayIndex, habitId: sedekahHabit.id, valueInt: 0, updatedAt: 0),
    );

    final currency = await database.kvSettingsDao.getValue('sedekah_currency') ?? 'IDR';
    final goalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final goalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');
    final target = goalEnabled == 'true' && goalAmount != null ? double.tryParse(goalAmount) : null;

    return {
      'amount': entry.valueInt ?? 0,
      'currency': currency,
      'target': target,
      'transactionCount': entry.valueInt != null && entry.valueInt! > 0 ? 1 : 0, // Simplified for now
    };
  }

  Widget _buildSummaryCard(BuildContext context, Map<String, dynamic> data, DateTime date, int dayIndex) {
    final amount = data['amount'] as int;
    final currency = data['currency'] as String;
    final target = data['target'] as double?;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('MMM d, yyyy').format(date)} • Day $dayIndex',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Today given',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    SedekahUtils.formatCurrency(amount.toDouble(), currency),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              if (target != null && target > 0) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      SedekahUtils.formatCurrency(target, currency),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(BuildContext context, Map<String, dynamic> data) {
    final amount = data['amount'] as int;
    final currency = data['currency'] as String;
    final transactionCount = data['transactionCount'] as int;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transactions',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          if (transactionCount == 0)
            Text(
              'No transactions recorded today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            )
          else
            ListTile(
              leading: Icon(Icons.volunteer_activism, color: Theme.of(context).colorScheme.primary),
              title: Text('Today\'s donation'),
              subtitle: Text(SedekahUtils.formatCurrency(amount.toDouble(), currency)),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          const SizedBox(height: 8),
          Text(
            'Note: Season trends available in 7 Days / Season tab later',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

}

