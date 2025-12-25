import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/features/settings/backup_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          _buildSeasonManagement(),
          _buildHabitsSettings(),
          _buildTimesAndReminders(),
          _buildBackupRestore(),
          _buildAbout(),
        ],
      ),
    );
  }

  Widget _buildSeasonManagement() {
    final seasonsAsync = ref.watch(allSeasonsProvider);

    return ExpansionTile(
      title: const Text('Season Management'),
      children: [
        seasonsAsync.when(
          data: (seasons) {
            return Column(
              children: [
                ...seasons.map((season) {
                  return ListTile(
                    title: Text(season.label),
                    subtitle: Text(
                      '${DateFormat('MMM d, yyyy').format(season.startDate)} - ${season.days} days',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteSeason(season.id),
                    ),
                    onTap: () {}, // Make ListTile tappable
                  );
                }),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Create New Season'),
                  onTap: _showCreateSeasonDialog,
                ),
              ],
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error loading seasons'),
        ),
      ],
    );
  }

  Widget _buildTimesAndReminders() {
    final seasonAsync = ref.watch(currentSeasonProvider);
    
    return ExpansionTile(
      title: const Text('Times & Reminders'),
      children: [
        seasonAsync.when(
          data: (season) {
            if (season == null) {
              return const ListTile(title: Text('No season found'));
            }
            return _buildTimesAndRemindersContent(season.id);
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error'),
        ),
      ],
    );
  }

  Widget _buildTimesAndRemindersContent(int seasonId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadReminderSettings(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final settings = snapshot.data!;
        final sahurEnabled = settings['sahur_enabled'] == 'true';
        final sahurOffset = int.tryParse(settings['sahur_offset'] ?? '30') ?? 30;
        final iftarEnabled = settings['iftar_enabled'] == 'true';
        final iftarOffset = int.tryParse(settings['iftar_offset'] ?? '0') ?? 0;
        final nightPlanEnabled = settings['night_plan_enabled'] == 'true';
        final method = settings['prayer_method'] ?? 'mwl';
        final fajrAdj = int.tryParse(settings['prayer_fajr_adj'] ?? '0') ?? 0;
        final maghribAdj = int.tryParse(settings['prayer_maghrib_adj'] ?? '0') ?? 0;

        return Column(
          children: [
            SwitchListTile(
              title: const Text('Sahur reminder'),
              subtitle: Text('$sahurOffset min before Fajr'),
              value: sahurEnabled,
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('sahur_enabled', value.toString());
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Iftar reminder'),
              subtitle: Text('$iftarOffset min after Maghrib'),
              value: iftarEnabled,
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('iftar_enabled', value.toString());
                setState(() {});
              },
            ),
            SwitchListTile(
              title: const Text('Night plan reminder'),
              subtitle: const Text('21:00'),
              value: nightPlanEnabled,
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('night_plan_enabled', value.toString());
                setState(() {});
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Calculation Method'),
              subtitle: Text(method.toUpperCase()),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMethodDialog(method),
            ),
            ListTile(
              title: const Text('Fajr Adjustment'),
              subtitle: Text('$fajrAdj minutes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAdjustmentDialog('fajr', fajrAdj),
            ),
            ListTile(
              title: const Text('Maghrib Adjustment'),
              subtitle: Text('$maghribAdj minutes'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAdjustmentDialog('maghrib', maghribAdj),
            ),
            const Divider(),
            FutureBuilder<List<NotificationInfo>>(
              future: NotificationService.getPendingNotifications(),
              builder: (context, notifSnapshot) {
                if (notifSnapshot.hasData && notifSnapshot.data!.isNotEmpty) {
                  return ExpansionTile(
                    title: const Text('Next Reminders'),
                    children: notifSnapshot.data!.take(5).map((notif) {
                      return ListTile(
                        title: Text(notif.title ?? 'No title'),
                        subtitle: Text(notif.body ?? 'No body'),
                        trailing: Text('ID: ${notif.id}'),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: const Text('Test Notification'),
              onTap: () async {
                await NotificationService.testNotification();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Test notification sent')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadReminderSettings() async {
    final database = ref.read(databaseProvider);
    return {
      'sahur_enabled': await database.kvSettingsDao.getValue('sahur_enabled') ?? 'true',
      'sahur_offset': await database.kvSettingsDao.getValue('sahur_offset') ?? '30',
      'iftar_enabled': await database.kvSettingsDao.getValue('iftar_enabled') ?? 'true',
      'iftar_offset': await database.kvSettingsDao.getValue('iftar_offset') ?? '0',
      'night_plan_enabled': await database.kvSettingsDao.getValue('night_plan_enabled') ?? 'true',
      'prayer_method': await database.kvSettingsDao.getValue('prayer_method') ?? 'mwl',
      'prayer_fajr_adj': await database.kvSettingsDao.getValue('prayer_fajr_adj') ?? '0',
      'prayer_maghrib_adj': await database.kvSettingsDao.getValue('prayer_maghrib_adj') ?? '0',
    };
  }

  void _showMethodDialog(String currentMethod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Calculation Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['mwl', 'isna', 'egypt', 'umm_al_qura', 'karachi'].map((method) {
            return RadioListTile<String>(
              title: Text(method.toUpperCase()),
              value: method,
              groupValue: currentMethod,
              onChanged: (value) async {
                if (value != null) {
                  await ref.read(databaseProvider).kvSettingsDao.setValue('prayer_method', value);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showAdjustmentDialog(String type, int currentValue) {
    final controller = TextEditingController(text: currentValue.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${type[0].toUpperCase()}${type.substring(1)} Adjustment'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Minutes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final value = int.tryParse(controller.text) ?? 0;
              await ref.read(databaseProvider).kvSettingsDao.setValue('prayer_${type}_adj', value.toString());
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSettings() {
    final seasonAsync = ref.watch(currentSeasonProvider);
    final habitsAsync = ref.watch(habitsProvider);

    return ExpansionTile(
      title: const Text('Habits & Targets'),
      children: [
        seasonAsync.when(
          data: (season) {
            if (season == null) {
              return const ListTile(title: Text('No season found'));
            }
            return habitsAsync.when(
              data: (habits) {
                return FutureBuilder<List<dynamic>>(
                  future: ref.read(databaseProvider).seasonHabitsDao.getSeasonHabits(season.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final seasonHabits = snapshot.data!;

                    return Column(
                      children: habits.map((habit) {
                        final sh = seasonHabits.where(
                          (s) => s.habitId == habit.id,
                        ).firstOrNull;

                        if (sh == null) return const SizedBox.shrink();

                        return SwitchListTile(
                          title: Text(habit.name),
                          value: sh.isEnabled,
                          onChanged: (value) {
                            _toggleHabit(season.id, habit.id, value);
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text('Error'),
            );
          },
          loading: () => const CircularProgressIndicator(),
          error: (_, __) => const Text('Error'),
        ),
      ],
    );
  }

  Widget _buildBackupRestore() {
    return ExpansionTile(
      title: const Text('Backup & Restore'),
      children: [
        ListTile(
          leading: const Icon(Icons.upload),
          title: const Text('Export Backup'),
          onTap: _exportBackup,
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: const Text('Import Backup'),
          onTap: _importBackup,
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return ExpansionTile(
      title: const Text('About'),
      children: [
        ListTile(
          title: const Text('Version'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          title: const Text('Privacy'),
          subtitle: const Text('Offline only. No tracking.'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Reset Onboarding'),
          subtitle: const Text('Show onboarding again on next launch'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Reset Onboarding'),
                content: const Text('This will show the onboarding screen again when you restart the app. Continue?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Reset'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              final database = ref.read(databaseProvider);
              final seasons = await database.ramadanSeasonsDao.getAllSeasons();
              for (final season in seasons) {
                await database.kvSettingsDao.deleteValue('onboarding_done_season_${season.id}');
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Onboarding will show on next app restart')),
                );
              }
            }
          },
        ),
      ],
    );
  }

  Future<void> _deleteSeason(int seasonId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Season?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final database = ref.read(databaseProvider);
      await database.ramadanSeasonsDao.deleteSeason(seasonId);
      ref.invalidate(allSeasonsProvider);
      ref.invalidate(currentSeasonProvider);
    }
  }

  Future<void> _showCreateSeasonDialog() async {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    int days = 30;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Season'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'Ramadan 2025',
              ),
              controller: TextEditingController(text: 'Ramadan ${now.year}'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: days,
              decoration: const InputDecoration(labelText: 'Days'),
              items: const [
                DropdownMenuItem(value: 29, child: Text('29 days')),
                DropdownMenuItem(value: 30, child: Text('30 days')),
              ],
              onChanged: (value) {
                days = value ?? 30;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, {
                'label': 'Ramadan ${now.year}',
                'days': days,
              });
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (result != null) {
      final database = ref.read(databaseProvider);
      final seasonId = await database.ramadanSeasonsDao.createSeason(
        label: result['label'] as String,
        startDate: startDate,
        days: result['days'] as int,
      );

      final habits = await database.habitsDao.getAllHabits();
      await database.seasonHabitsDao.initializeSeasonHabits(seasonId, habits);

      ref.invalidate(allSeasonsProvider);
      ref.invalidate(currentSeasonProvider);
    }
  }

  Future<void> _toggleHabit(int seasonId, int habitId, bool enabled) async {
    final database = ref.read(databaseProvider);
    final sh = await database.seasonHabitsDao.getSeasonHabit(seasonId, habitId);
    if (sh != null) {
      await database.seasonHabitsDao.setSeasonHabit(
        SeasonHabit(
          seasonId: sh.seasonId,
          habitId: sh.habitId,
          isEnabled: enabled,
          targetValue: sh.targetValue,
          reminderEnabled: sh.reminderEnabled,
          reminderTime: sh.reminderTime,
        ),
      );
    }
  }

  Future<void> _exportBackup() async {
    try {
      final database = ref.read(databaseProvider);
      final backupData = await BackupService.exportBackup(database);

      await Share.share(backupData);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final controller = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Paste your backup JSON below:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: const InputDecoration(
                hintText: 'Paste JSON backup data...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed == true && controller.text.isNotEmpty) {
      try {
        final database = ref.read(databaseProvider);
        await BackupService.importBackup(database, controller.text);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup imported successfully')),
          );
          ref.invalidate(allSeasonsProvider);
          ref.invalidate(currentSeasonProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Import failed: $e')),
          );
        }
      }
    }
  }
}

