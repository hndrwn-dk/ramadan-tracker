import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/data/providers/season_provider.dart';
import 'package:ramadan_tracker/data/providers/habit_provider.dart';
import 'package:ramadan_tracker/data/providers/tab_provider.dart';
import 'package:ramadan_tracker/data/providers/theme_provider.dart';
import 'package:ramadan_tracker/data/providers/daily_entry_provider.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/features/settings/backup_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/features/settings/create_season_flow.dart';
import 'package:ramadan_tracker/insights/widgets/premium_card.dart';
import 'package:ramadan_tracker/features/settings/webview_screen.dart';
import 'package:ramadan_tracker/data/providers/locale_provider.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/log_service.dart';
import 'package:flutter/foundation.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final Map<String, bool> _expandedSections = {
    'appearance': false,
    'language': false,
    'season': false,
    'habits': false,
    'times': false,
    'backup': false,
    'debug': false,
    'about': false,
  };
  final _pendingCountKey = GlobalKey<_PendingNotificationCountState>();

  void _toggleSection(String key) {
    setState(() {
      _expandedSections[key] = !(_expandedSections[key] ?? false);
    });
    // Refresh pending count when debug section is expanded
    if (key == 'debug' && (_expandedSections[key] ?? false)) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _pendingCountKey.currentState?.refresh();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          onPressed: () => ref.read(tabIndexProvider.notifier).state = 0,
        ),
        title: Text(l10n.settingsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildAppearance(),
            const SizedBox(height: 16),
            _buildLanguage(),
            const SizedBox(height: 16),
            _buildSeasonManagement(),
            const SizedBox(height: 16),
            _buildHabitsSettings(),
            const SizedBox(height: 16),
            _buildTimesAndReminders(),
            const SizedBox(height: 16),
            _buildBackupRestore(),
            const SizedBox(height: 16),
            _buildDebugSection(),
            const SizedBox(height: 16),
            _buildAbout(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppearance() {
    final l10n = AppLocalizations.of(context)!;
    final themeModeAsync = ref.watch(themeModeProvider);
    final themeMode = themeModeAsync.when(
      data: (mode) => mode,
      loading: () => ThemeMode.system,
      error: (_, __) => ThemeMode.system,
    );
    String currentMode;
    switch (themeMode) {
      case ThemeMode.light:
        currentMode = 'light';
        break;
      case ThemeMode.dark:
        currentMode = 'dark';
        break;
      case ThemeMode.system:
      default:
        currentMode = 'system';
        break;
    }

    final isExpanded = _expandedSections['appearance'] ?? false;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('appearance'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appearanceTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appearanceSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          _buildThemeOption(
            l10n.themeLight,
            l10n.themeLightDesc,
            Icons.light_mode_outlined,
            'light',
            currentMode,
          ),
          const Divider(height: 1),
          _buildThemeOption(
            l10n.themeDark,
            l10n.themeDarkDesc,
            Icons.dark_mode_outlined,
            'dark',
            currentMode,
          ),
          const Divider(height: 1),
          _buildThemeOption(
            l10n.themeAuto,
            l10n.themeAutoDesc,
            Icons.brightness_auto_outlined,
            'system',
            currentMode,
          ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(
    String title,
    String subtitle,
    IconData icon,
    String value,
    String currentMode,
  ) {
    final isSelected = value == currentMode;
    return InkWell(
      onTap: () async {
        await ref.read(themeModeProvider.notifier).setThemeMode(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguage() {
    final l10n = AppLocalizations.of(context)!;
    final localeAsync = ref.watch(localeProvider);
    final locale = localeAsync.when(
      data: (loc) => loc,
      loading: () => const Locale('en', ''),
      error: (_, __) => const Locale('en', ''),
    );
    final currentLanguage = locale.languageCode;

    final isExpanded = _expandedSections['language'] ?? false;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('language'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.language_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.languageTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.languageSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _buildLanguageOption(
                  l10n.english,
                  'en',
                  currentLanguage,
                ),
                const Divider(height: 1),
                _buildLanguageOption(
                  l10n.indonesian,
                  'id',
                  currentLanguage,
                ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    String title,
    String value,
    String currentLanguage,
  ) {
    final isSelected = value == currentLanguage;
    return InkWell(
      onTap: () async {
        await ref.read(localeProvider.notifier).setLocale(value);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Icon(
              Icons.translate_outlined,
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonManagement() {
    final l10n = AppLocalizations.of(context)!;
    final seasonsAsync = ref.watch(allSeasonsProvider);
    final isExpanded = _expandedSections['season'] ?? false;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('season'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.seasonManagementTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.seasonManagementSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          seasonsAsync.when(
            data: (seasons) {
              return Column(
                children: [
                  ...seasons.map((season) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(season.label),
                        subtitle: Text(
                          '${DateFormat('MMM d, yyyy').format(season.startDate)} - ${l10n.days(season.days)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _deleteSeason(season.id),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.add_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(l10n.createNewSeason),
                    subtitle: Text(l10n.startNewRamadanTracking, style: const TextStyle(fontSize: 12)),
                    onTap: _showCreateSeasonDialog,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.refresh),
                    title: Text(l10n.resetOnboarding),
                    subtitle: Text(l10n.showSetupWizardAgain, style: const TextStyle(fontSize: 12)),
                    onTap: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(l10n.resetOnboarding),
                          content: Text(l10n.resetOnboardingConfirm),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(l10n.reset),
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
                        // Invalidate onboarding provider to show onboarding on next app start
                        ref.invalidate(shouldShowOnboardingProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.onboardingWillShowOnRestart)),
                          );
                        }
                      }
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.errorLoadingSeasons),
            ),
          ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesAndReminders() {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final isExpanded = _expandedSections['times'] ?? false;
    
    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('times'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.timesRemindersTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.timesRemindersSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          seasonAsync.when(
            data: (season) {
              if (season == null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noSeasonFound),
                );
              }
              return _buildTimesAndRemindersContent(season.id);
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.error),
            ),
          ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildTimesAndRemindersContent(int seasonId) {
    final l10n = AppLocalizations.of(context)!;
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
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.sahurReminder),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.minBeforeFajr(sahurOffset)),
                  Text(l10n.getNotifiedBeforeSuhoor, style: const TextStyle(fontSize: 11)),
                ],
              ),
              value: sahurEnabled,
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('sahur_enabled', value.toString());
                setState(() {});
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.iftarReminder),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.minAfterMaghrib(iftarOffset)),
                  Text(l10n.getNotifiedWhenBreakFast, style: const TextStyle(fontSize: 11)),
                ],
              ),
              value: iftarEnabled,
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('iftar_enabled', value.toString());
                setState(() {});
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.nightPlanReminder),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('21:00'),
                  Text(l10n.reminderToPlanNightActivities, style: const TextStyle(fontSize: 11)),
                ],
              ),
              value: nightPlanEnabled,
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('night_plan_enabled', value.toString());
                setState(() {});
              },
            ),
            const Divider(height: 24),
            // Goal Reminders Section
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.goalRemindersTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Text(
              l10n.goalRemindersSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.goalReminderQuran),
              subtitle: Text(l10n.goalReminderQuranDesc, style: const TextStyle(fontSize: 11)),
              value: settings['goal_reminder_quran_enabled'] != 'false',
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('goal_reminder_quran_enabled', value.toString());
                setState(() {});
                // Reschedule reminders when setting changes
                _rescheduleReminders();
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.goalReminderDhikr),
              subtitle: Text(l10n.goalReminderDhikrDesc, style: const TextStyle(fontSize: 11)),
              value: settings['goal_reminder_dhikr_enabled'] != 'false',
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('goal_reminder_dhikr_enabled', value.toString());
                setState(() {});
                _rescheduleReminders();
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.goalReminderSedekah),
              subtitle: Text(l10n.goalReminderSedekahDesc, style: const TextStyle(fontSize: 11)),
              value: settings['goal_reminder_sedekah_enabled'] != 'false',
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('goal_reminder_sedekah_enabled', value.toString());
                setState(() {});
                _rescheduleReminders();
              },
            ),
            const Divider(height: 1),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.goalReminderTaraweeh),
              subtitle: Text(l10n.goalReminderTaraweehDesc, style: const TextStyle(fontSize: 11)),
              value: settings['goal_reminder_taraweeh_enabled'] != 'false',
              onChanged: (value) async {
                await ref.read(databaseProvider).kvSettingsDao.setValue('goal_reminder_taraweeh_enabled', value.toString());
                setState(() {});
                _rescheduleReminders();
              },
            ),
            const Divider(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.calculationMethod),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getMethodLabel(method)),
                  Text(l10n.choosePrayerTimeMethod, style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showMethodDialog(method),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.fajrAdjustment),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$fajrAdj ${l10n.minutesUnit}'),
                  Text(l10n.adjustFajrManually, style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAdjustmentDialog('fajr', fajrAdj),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.maghribAdjustment),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$maghribAdj ${l10n.minutesUnit}'),
                  Text(l10n.adjustMaghribManually, style: const TextStyle(fontSize: 11)),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showAdjustmentDialog('maghrib', maghribAdj),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const Divider(height: 24),
            FutureBuilder<List<NotificationInfo>>(
              future: NotificationService.getPendingNotifications(),
              builder: (context, notifSnapshot) {
                if (notifSnapshot.hasData && notifSnapshot.data!.isNotEmpty) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l10n.nextReminders,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      ...notifSnapshot.data!.take(5).map((notif) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(notif.title ?? l10n.noTitle),
                            subtitle: Text(notif.body ?? l10n.noBody),
                            trailing: Text('ID: ${notif.id}', style: Theme.of(context).textTheme.bodySmall),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      }).toList(),
                      const Divider(height: 24),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context)!;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active),
                  title: Text(l10n.testNotification),
                  subtitle: Text(l10n.sendTestNotification, style: const TextStyle(fontSize: 12)),
                  onTap: () async {
                    try {
                      // Use scheduleTestNotification which shows immediate notification first
                      await NotificationService.scheduleTestNotification(seconds: 10);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent! Immediate notification should appear now. Scheduled notification may fail if there are corrupt notifications in database.'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      // Only show error if immediate notification also failed
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Error: Immediate notification failed. Check logs for details.'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _getMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'mwl':
        return 'MWL (Muslim World League)';
      case 'indonesia':
        return 'Indonesia (Kemenag)';
      case 'singapore':
        return 'Singapore';
      case 'umm_al_qura':
        return 'Umm al-Qura';
      case 'karachi':
        return 'Karachi';
      case 'egypt':
        return 'Egypt';
      case 'isna':
        return 'ISNA (North America)';
      default:
        return method.toUpperCase();
    }
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
      'goal_reminder_quran_enabled': await database.kvSettingsDao.getValue('goal_reminder_quran_enabled') ?? 'true',
      'goal_reminder_dhikr_enabled': await database.kvSettingsDao.getValue('goal_reminder_dhikr_enabled') ?? 'true',
      'goal_reminder_sedekah_enabled': await database.kvSettingsDao.getValue('goal_reminder_sedekah_enabled') ?? 'true',
      'goal_reminder_taraweeh_enabled': await database.kvSettingsDao.getValue('goal_reminder_taraweeh_enabled') ?? 'true',
    };
  }

  Future<void> _rescheduleReminders() async {
    try {
      final database = ref.read(databaseProvider);
      final l10n = AppLocalizations.of(context)!;
      await NotificationService.rescheduleAllReminders(
        database: database,
        sahurTitle: l10n.sahurReminder,
        sahurBody: l10n.getNotifiedBeforeSuhoor,
        iftarTitle: l10n.iftarReminder,
        iftarBody: l10n.getNotifiedWhenBreakFast,
        nightPlanTitle: l10n.nightPlanReminder,
        nightPlanBody: l10n.reminderToPlanNightActivities,
      );
      // Refresh pending count after rescheduling
      _pendingCountKey.currentState?.refresh();
    } catch (e) {
      debugPrint('Error rescheduling reminders: $e');
    }
  }

  void _showMethodDialog(String currentMethod) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.calculationMethod),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            {'value': 'mwl', 'label': 'MWL (Muslim World League)'},
            {'value': 'indonesia', 'label': 'Indonesia (Kemenag)'},
            {'value': 'singapore', 'label': 'Singapore'},
            {'value': 'umm_al_qura', 'label': 'Umm al-Qura'},
            {'value': 'karachi', 'label': 'Karachi'},
            {'value': 'egypt', 'label': 'Egypt'},
            {'value': 'isna', 'label': 'ISNA (North America)'},
          ].map((item) {
            return RadioListTile<String>(
              title: Text(item['label']!),
              value: item['value']!,
              groupValue: currentMethod,
              onChanged: (value) async {
                if (value != null) {
                  final database = ref.read(databaseProvider);
                  await database.kvSettingsDao.setValue('prayer_method', value);
                  // Clear prayer times cache when method changes
                  final seasonAsync = ref.read(currentSeasonProvider);
                  seasonAsync.whenData((season) async {
                    if (season != null) {
                      await database.prayerTimesCacheDao.clearCacheForSeason(season.id);
                    }
                  });
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: currentValue.toString());
    final title = type == 'fajr' ? l10n.fajrAdjustmentTitle : l10n.maghribAdjustmentTitle;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Minutes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final value = int.tryParse(controller.text) ?? 0;
              await ref.read(databaseProvider).kvSettingsDao.setValue('prayer_${type}_adj', value.toString());
              Navigator.pop(context);
              setState(() {});
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitsSettings() {
    final l10n = AppLocalizations.of(context)!;
    final seasonAsync = ref.watch(currentSeasonProvider);
    final habitsAsync = ref.watch(habitsProvider);
    final isExpanded = _expandedSections['habits'] ?? false;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('habits'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.habitsTargetsTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.habitsTargetsSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          seasonAsync.when(
            data: (season) {
              if (season == null) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noSeasonFound),
                );
              }
              return habitsAsync.when(
                data: (habits) {
                  return FutureBuilder<List<dynamic>>(
                    future: _ensureAllHabitsInitialized(season.id, habits),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ));
                      }

                      final seasonHabits = snapshot.data!;

                      return Column(
                        children: [
                          ...habits.map((habit) {
                            final sh = seasonHabits.where(
                              (s) => s.habitId == habit.id,
                            ).firstOrNull;

                            // Show all habits, even if not initialized yet
                            final isEnabled = sh?.isEnabled ?? false;

                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(_getHabitDisplayName(l10n, habit.key)),
                              value: isEnabled,
                              onChanged: (value) async {
                                await _toggleHabit(season.id, habit.id, value);
                                // Refresh the FutureBuilder
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.error),
                ),
              );
            },
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )),
            error: (_, __) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.error),
            ),
          ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupRestore() {
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedSections['backup'] ?? false;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('backup'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.backup_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.backupRestoreTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.backupRestoreSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.upload),
            title: Text(l10n.exportBackup),
            subtitle: Text(l10n.saveDataAsJson, style: const TextStyle(fontSize: 12)),
            onTap: _exportBackup,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download),
            title: Text(l10n.importBackup),
            subtitle: Text(l10n.restoreDataFromJson, style: const TextStyle(fontSize: 12)),
            onTap: _importBackup,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugSection() {
    final isExpanded = _expandedSections['debug'] ?? false;
    final logCount = LogService.getLogs().length;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('debug'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug & Logs',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$logCount log entries',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_download),
                  title: const Text('Export Logs'),
                  subtitle: const Text('Save logs to Downloads folder', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    try {
                      final file = await LogService.exportLogsToFile();
                      if (mounted) {
                        if (file != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logs exported to:\n${file.path}'),
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to export logs'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.share),
                  title: const Text('Share Logs'),
                  subtitle: const Text('Share logs via other apps', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    try {
                      final file = await LogService.exportLogsToFile();
                      if (file != null && mounted) {
                        await Share.shareXFiles(
                          [XFile(file.path)],
                          text: 'Ramadan Tracker Debug Logs',
                        );
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to export logs'),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                _PendingNotificationCount(key: _pendingCountKey),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.notifications_active),
                  title: const Text('Test Notification (10s)'),
                  subtitle: const Text('Send immediate + scheduled test notification', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    try {
                      await NotificationService.scheduleTestNotification(seconds: 10);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification sent! Immediate notification should appear now. Scheduled notification will appear in 10 seconds.'),
                            duration: Duration(seconds: 4),
                          ),
                        );
                        // Refresh pending count after scheduling test
                        _pendingCountKey.currentState?.refresh();
                      }
                    } catch (e) {
                      // Only show error if immediate notification also failed
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: Immediate notification failed. Check logs for details.'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: const Text('Schedule Test (60s)'),
                  subtitle: const Text('Schedule a test notification in 60 seconds', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    try {
                      await NotificationService.scheduleTestInSeconds(60);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test notification scheduled for 60s (alarm mode). If it does not appear: Settings > Apps > Ramadan Tracker > Battery > Unrestricted.'),
                            duration: Duration(seconds: 5),
                          ),
                        );
                        // Refresh pending count after scheduling test
                        _pendingCountKey.currentState?.refresh();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error scheduling test: $e'),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.healing, color: Colors.green),
                  title: const Text('Fix Notification Issues', style: TextStyle(color: Colors.green)),
                  subtitle: const Text('Fix corrupt notification database (won\'t delete your data)', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    // Show warning dialog first
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Fix Notification Issues'),
                        content: const Text(
                          'This will clear corrupt notification data. '
                          'Your app data (progress, settings) will NOT be deleted. '
                          'Continue?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Fix Now'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirm != true || !mounted) return;
                    
                    // Show loading
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                    
                    try {
                      // Clear database using native method
                      final success = await NotificationService.clearCorruptNotificationDatabase();
                      
                      // Hide loading
                      if (mounted) {
                        Navigator.pop(context);
                      }
                      
                      // Show result
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success 
                                ? 'Notification database fixed! Please restart the app for best results.'
                                : '✗ Failed to fix. Please try "Clear Corrupt Notifications" or clear app data manually.'
                            ),
                            backgroundColor: success ? Colors.green : Colors.orange,
                            duration: const Duration(seconds: 6),
                          ),
                        );
                      }
                    } catch (e) {
                      // Hide loading
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e\n\nPlease try "Clear Corrupt Notifications" or clear app data from Android Settings.'),
                            duration: const Duration(seconds: 8),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                  title: const Text('Clear Corrupt Notifications', style: TextStyle(color: Colors.orange)),
                  subtitle: const Text('Clear corrupt notifications from database (fallback method)', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Clearing notification database...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                    
                    try {
                      final success = await NotificationService.clearNotificationDatabase();
                      
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notification database cleared successfully! Please restart the app.'),
                              duration: Duration(seconds: 5),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✗ Database still corrupt. Please go to Android Settings > Apps > Ramadan Tracker > Storage > Clear Data, then reinstall the app.'),
                              duration: Duration(seconds: 8),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e\n\nPlease clear app data from Android Settings.'),
                            duration: const Duration(seconds: 8),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Clear Logs'),
                  subtitle: const Text('Clear all log entries', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    LogService.clearLogs();
                    if (mounted) {
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logs cleared'),
                        ),
                      );
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.refresh, color: Colors.red),
                  title: const Text('Reset App Data', style: TextStyle(color: Colors.red)),
                  subtitle: const Text('Clear all data and reset onboarding', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Reset App Data?'),
                        content: const Text(
                          'This will delete all your data including seasons, habits, goals, and entries. '
                          'This action cannot be undone. Are you sure?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true && mounted) {
                      try {
                        final database = ref.read(databaseProvider);
                        
                        // Try to clear notification database first
                        await NotificationService.clearNotificationDatabase();
                        
                        // Completely wipe the database file to ensure clean state
                        // This will delete the database file and all its data
                        await database.wipeDatabase();
                        
                        // Invalidate providers to refresh UI
                        ref.invalidate(shouldShowOnboardingProvider);
                        ref.invalidate(currentSeasonProvider);
                        ref.invalidate(databaseProvider);
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('App data completely wiped. Please restart the app to ensure notification database is cleared.'),
                              duration: Duration(seconds: 6),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error resetting data: $e\n\nIf notifications still don\'t work, please clear app data from Android Settings.'),
                              duration: const Duration(seconds: 8),
                            ),
                          );
                        }
                      }
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    final l10n = AppLocalizations.of(context)!;
    final isExpanded = _expandedSections['about'] ?? false;

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleSection('about'),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.aboutSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.version),
            subtitle: const Text('1.0.0'),
          ),
          const Divider(height: 24),
          _buildLinkTile(
            l10n.supportDeveloper,
            l10n.buyMeACoffee,
            Icons.favorite_outline,
            'https://buymeacoffee.com/hendrawan',
          ),
          const Divider(height: 1),
          _buildLinkTile(
            l10n.privacyPolicy,
            l10n.readPrivacyPolicy,
            Icons.privacy_tip_outlined,
            'https://www.tursinalab.com/privacy',
          ),
          const Divider(height: 1),
          _buildLinkTile(
            l10n.termsOfService,
            l10n.readTermsOfService,
            Icons.description_outlined,
            'https://www.tursinalab.com/terms',
          ),
              ],
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile(String title, String subtitle, IconData icon, String url) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: () => _openUrl(url),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WebViewScreen(
            url: url,
            title: 'Loading...',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorOpeningUrl(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteSeason(int seasonId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteSeason),
        content: Text(l10n.deleteSeasonWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final database = ref.read(databaseProvider);
      await database.ramadanSeasonsDao.deleteSeason(seasonId);
      ref.invalidate(allSeasonsProvider);
      ref.invalidate(currentSeasonProvider);
      
      // Check if there are any seasons left
      final remainingSeasons = await database.ramadanSeasonsDao.getAllSeasons();
      if (remainingSeasons.isEmpty) {
        // No seasons left, navigate to onboarding immediately
        ref.invalidate(shouldShowOnboardingProvider);
        if (mounted) {
          // Navigate to onboarding flow and clear navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const OnboardingFlow(),
            ),
            (route) => false,
          );
        }
      }
    }
  }

  Future<void> _showCreateSeasonDialog() async {
    // Navigate to create season flow instead of simple dialog
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateSeasonFlow(),
      ),
    );
    
    // Refresh after returning
    setState(() {});
  }

  Future<List<dynamic>> _ensureAllHabitsInitialized(int seasonId, List<HabitModel> habits) async {
    final database = ref.read(databaseProvider);
    final allHabits = await database.habitsDao.getAllHabits();
    
    // Ensure all habits are initialized for this season
    await database.seasonHabitsDao.initializeSeasonHabits(seasonId, allHabits);
    
    // Return the season habits
    return await database.seasonHabitsDao.getSeasonHabits(seasonId);
  }

  Future<void> _toggleHabit(int seasonId, int habitId, bool enabled) async {
    final database = ref.read(databaseProvider);
    final sh = await database.seasonHabitsDao.getSeasonHabit(seasonId, habitId);
    
    if (sh != null) {
      // Update existing season habit
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
    } else {
      // Create new season habit if it doesn't exist
      final habit = await database.habitsDao.getHabitById(habitId);
      if (habit != null) {
        await database.seasonHabitsDao.setSeasonHabit(
          SeasonHabit(
            seasonId: seasonId,
            habitId: habitId,
            isEnabled: enabled,
            targetValue: habit.defaultTarget,
            reminderEnabled: false,
            reminderTime: null,
          ),
        );
      }
    }
    
    // Invalidate providers to refresh UI
    ref.invalidate(seasonHabitsProvider(seasonId));
  }

  Future<void> _exportBackup() async {
    try {
      final database = ref.read(databaseProvider);
      final backupData = await BackupService.exportBackup(database);

      await Share.share(backupData);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importBackup),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.pasteBackupJson),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: l10n.pasteJsonBackupData,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.import),
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
            SnackBar(content: Text(l10n.backupImportedSuccessfully)),
          );
          ref.invalidate(allSeasonsProvider);
          ref.invalidate(currentSeasonProvider);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.importFailed(e.toString()))),
          );
        }
      }
    }
  }

  String _getHabitDisplayName(AppLocalizations l10n, String habitKey) {
    switch (habitKey) {
      case 'fasting':
        return l10n.habitFasting;
      case 'quran_pages':
        return l10n.habitQuran;
      case 'dhikr':
        return l10n.habitDhikr;
      case 'taraweeh':
        return l10n.habitTaraweeh;
      case 'sedekah':
        return l10n.habitSedekah;
      case 'itikaf':
        return l10n.habitItikaf;
      case 'prayers':
        return l10n.habitPrayers;
      default:
        // Fallback to original name if translation not found
        return habitKey;
    }
  }
}

class _PendingNotificationCount extends StatefulWidget {
  const _PendingNotificationCount({super.key});

  @override
  State<_PendingNotificationCount> createState() => _PendingNotificationCountState();
}

class _PendingNotificationCountState extends State<_PendingNotificationCount> {
  int _pendingCount = -1;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  void refresh() {
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final pending = await NotificationService.getPendingNotifications();
      if (mounted) {
        setState(() {
          _pendingCount = pending.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        Icons.schedule,
        color: _pendingCount > 0 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
      ),
      title: const Text('Pending Notifications'),
      subtitle: _isLoading
        ? const Text('Loading...', style: TextStyle(fontSize: 12))
        : _error != null
          ? Text('Error: $_error', style: TextStyle(fontSize: 12, color: Colors.red))
          : Text(
              _pendingCount == -1 
                ? 'Unknown' 
                : _pendingCount == 0
                  ? 'No pending notifications'
                  : '$_pendingCount notification${_pendingCount == 1 ? '' : 's'} scheduled',
              style: TextStyle(
                fontSize: 12,
                color: _pendingCount > 0 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: _pendingCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
      trailing: IconButton(
        icon: _isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 20),
        onPressed: _isLoading ? null : _loadPendingCount,
        tooltip: 'Refresh count',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

