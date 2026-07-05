import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/location_helper.dart';
import 'package:timezone/timezone.dart' as tz;

/// Live prayer-time preview driven by [OnboardingData] location + calculation method.
class OnboardingPrayerTimesPreview extends StatefulWidget {
  final OnboardingData data;
  final bool showTestButton;

  const OnboardingPrayerTimesPreview({
    super.key,
    required this.data,
    this.showTestButton = false,
  });

  @override
  State<OnboardingPrayerTimesPreview> createState() =>
      _OnboardingPrayerTimesPreviewState();
}

class _OnboardingPrayerTimesPreviewState
    extends State<OnboardingPrayerTimesPreview> {
  Map<String, DateTime>? _previewTimes;

  @override
  void initState() {
    super.initState();
    _updatePreview();
  }

  @override
  void didUpdateWidget(OnboardingPrayerTimesPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.latitude != widget.data.latitude ||
        oldWidget.data.longitude != widget.data.longitude ||
        oldWidget.data.calculationMethod != widget.data.calculationMethod ||
        oldWidget.data.timezone != widget.data.timezone ||
        oldWidget.data.sahurOffsetMinutes != widget.data.sahurOffsetMinutes ||
        oldWidget.data.sahurEnabled != widget.data.sahurEnabled ||
        oldWidget.data.iftarEnabled != widget.data.iftarEnabled ||
        oldWidget.data.iftarOffsetMinutes != widget.data.iftarOffsetMinutes) {
      _updatePreview();
    }
  }

  Future<void> _updatePreview() async {
    if (widget.data.latitude == null || widget.data.longitude == null) return;

    if (widget.data.timezone == 'UTC' || widget.data.timezone.isEmpty) {
      var tzName = LocationHelper.detectTimezone(
        widget.data.latitude!,
        widget.data.longitude!,
      );
      if (tzName == 'UTC' || tzName.isEmpty) {
        try {
          tzName = await FlutterTimezone.getLocalTimezone();
        } catch (_) {}
      }
      if (mounted) {
        setState(() => widget.data.timezone = tzName);
      }
    }

    try {
      final times = PrayerTimeService.getFajrAndMaghrib(
        date: DateTime.now(),
        latitude: widget.data.latitude!,
        longitude: widget.data.longitude!,
        timezone: widget.data.timezone,
        method: widget.data.calculationMethod,
        highLatRule: widget.data.highLatRule,
        fajrAdjust: widget.data.fajrAdjust,
        maghribAdjust: widget.data.maghribAdjust,
      );
      if (mounted) {
        setState(() => _previewTimes = times);
      }
    } catch (_) {}
  }

  Future<void> _testNotification() async {
    try {
      final l10n = AppLocalizations.of(context)!;
      await NotificationService.testNotification(
        title: l10n.testNotification,
        body: l10n.appTitle,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.testNotificationSent)),
        );
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_previewTimes == null) return const SizedBox.shrink();

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.prayerTimesPreview,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.showTestButton)
                  TextButton.icon(
                    onPressed: _testNotification,
                    icon: const Icon(Icons.notifications_active, size: 18),
                    label: Text(l10n.test),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTimeRow(context, l10n.fajr, _previewTimes!['fajr']!),
            if (widget.data.sahurEnabled)
              _buildTimeRow(
                context,
                l10n.sahurReminderLabel,
                _previewTimes!['fajr']!
                    .subtract(Duration(minutes: widget.data.sahurOffsetMinutes)),
                isReminder: true,
              ),
            const SizedBox(height: 8),
            _buildTimeRow(context, l10n.maghrib, _previewTimes!['maghrib']!),
            if (widget.data.iftarEnabled)
              _buildTimeRow(
                context,
                l10n.iftarReminderLabel,
                _previewTimes!['maghrib']!
                    .add(Duration(minutes: widget.data.iftarOffsetMinutes)),
                isReminder: true,
              ),
            const SizedBox(height: 8),
            Text(
              l10n.prayerTimesVaryDaily,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    DateTime time, {
    bool isReminder = false,
  }) {
    DateTime displayTime = time;
    try {
      if (widget.data.timezone != 'UTC' && widget.data.timezone.isNotEmpty) {
        final targetLocation = tz.getLocation(widget.data.timezone);
        final timeUtc = time.isUtc ? time : time.toUtc();
        final timeTz = tz.TZDateTime.from(timeUtc, targetLocation);
        displayTime = DateTime(
          timeTz.year,
          timeTz.month,
          timeTz.day,
          timeTz.hour,
          timeTz.minute,
          timeTz.second,
        );
      }
    } catch (_) {
      displayTime = time;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isReminder ? FontWeight.normal : FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('HH:mm').format(displayTime),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

List<DropdownMenuItem<String>> onboardingCalculationMethodItems(
  AppLocalizations l10n,
) {
  return [
    DropdownMenuItem(value: 'mwl', child: Text(l10n.mwlMuslimWorldLeague)),
    DropdownMenuItem(value: 'indonesia', child: Text(l10n.indonesiaKemenag)),
    DropdownMenuItem(value: 'singapore', child: Text(l10n.singapore)),
    DropdownMenuItem(value: 'umm_al_qura', child: Text(l10n.ummAlQura)),
    DropdownMenuItem(value: 'karachi', child: Text(l10n.karachi)),
    DropdownMenuItem(value: 'egypt', child: Text(l10n.egypt)),
    DropdownMenuItem(value: 'isna', child: Text(l10n.isnaNorthAmerica)),
  ];
}
