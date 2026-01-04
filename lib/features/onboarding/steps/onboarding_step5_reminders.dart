import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/utils/location_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'dart:io';

class OnboardingStep5Reminders extends ConsumerStatefulWidget {
  final OnboardingData data;
  final VoidCallback onPrevious;
  final VoidCallback onFinish;

  const OnboardingStep5Reminders({
    super.key,
    required this.data,
    required this.onPrevious,
    required this.onFinish,
  });

  @override
  ConsumerState<OnboardingStep5Reminders> createState() => _OnboardingStep5RemindersState();
}

class _OnboardingStep5RemindersState extends ConsumerState<OnboardingStep5Reminders> {
  bool _loadingLocation = false;
  Map<String, DateTime>? _previewTimes;
  bool _showManualLocation = false;
  late TextEditingController _cityController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController();
    _latitudeController = TextEditingController();
    _longitudeController = TextEditingController();
    _loadTimezone();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _loadTimezone() async {
    String tz = 'UTC';
    try {
      if (Platform.isAndroid) {
        final result = await Process.run('getprop', ['persist.sys.timezone']);
        if (result.exitCode == 0) {
          tz = result.stdout.toString().trim();
        }
      } else if (Platform.isIOS) {
        tz = 'UTC';
      }
    } catch (e) {
      tz = 'UTC';
    }
    setState(() {
      widget.data.timezone = tz;
    });
    _updatePreview();
  }

  Future<void> _useLocation() async {
    setState(() {
      _loadingLocation = true;
    });

    try {
      final l10n = AppLocalizations.of(context)!;
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationServicesDisabled)),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.locationPermissionsDenied)),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationPermissionsPermanentlyDenied)),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      
      // Auto-detect calculation method and timezone based on location
      final detectedMethod = LocationHelper.detectCalculationMethod(
        position.latitude,
        position.longitude,
      );
      final detectedTimezone = LocationHelper.detectTimezone(
        position.latitude,
        position.longitude,
      );
      
      setState(() {
        widget.data.latitude = position.latitude;
        widget.data.longitude = position.longitude;
        widget.data.calculationMethod = detectedMethod;
        widget.data.timezone = detectedTimezone;
        _loadingLocation = false;
        _showManualLocation = false;
      });
      _updatePreview();
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _loadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString()))),
        );
      }
    }
  }

  void _setManualLocation() {
    final lat = double.tryParse(_latitudeController.text);
    final lon = double.tryParse(_longitudeController.text);
    if (lat != null && lon != null) {
      // Auto-detect calculation method and timezone based on location
      final detectedMethod = LocationHelper.detectCalculationMethod(lat, lon);
      final detectedTimezone = LocationHelper.detectTimezone(lat, lon);
      
      setState(() {
        widget.data.latitude = lat;
        widget.data.longitude = lon;
        widget.data.calculationMethod = detectedMethod;
        widget.data.timezone = detectedTimezone;
        _showManualLocation = false;
      });
      _updatePreview();
    } else {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseEnterValidCoordinates)),
      );
    }
  }

  Future<void> _updatePreview() async {
    if (widget.data.latitude == null || widget.data.longitude == null) return;

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

      setState(() {
        _previewTimes = times;
      });
    } catch (e) {
      // Ignore preview errors
    }
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(
            l10n.smartReminders,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.getNotifiedForSahurIftar,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: Text(l10n.sahurReminder),
            subtitle: Text(l10n.minBeforeFajr(widget.data.sahurOffsetMinutes)),
            value: widget.data.sahurEnabled,
            onChanged: (value) {
              setState(() {
                widget.data.sahurEnabled = value;
              });
            },
          ),
          if (widget.data.sahurEnabled) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Row(
                children: [
                  Text(
                    l10n.offset,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: [
                        ButtonSegment(value: 15, label: Text(l10n.minutesShort(15))),
                        ButtonSegment(value: 30, label: Text(l10n.minutesShort(30))),
                        ButtonSegment(value: 45, label: Text(l10n.minutesShort(45))),
                      ],
                      selected: {widget.data.sahurOffsetMinutes},
                      onSelectionChanged: (Set<int> newSelection) {
                        setState(() {
                          widget.data.sahurOffsetMinutes = newSelection.first;
                        });
                        _updatePreview();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          SwitchListTile(
            title: Text(l10n.iftarReminder),
            subtitle: Text(l10n.atMaghrib),
            value: widget.data.iftarEnabled,
            onChanged: (value) {
              setState(() {
                widget.data.iftarEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: Text(l10n.nightPlanReminder),
            subtitle: const Text('21:00'),
            value: widget.data.nightPlanEnabled,
            onChanged: (value) {
              setState(() {
                widget.data.nightPlanEnabled = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Text(
            l10n.location,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (widget.data.latitude == null && !_showManualLocation) ...[
            ElevatedButton.icon(
              onPressed: _loadingLocation ? null : _useLocation,
              icon: _loadingLocation
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_on),
              label: Text(l10n.useMyLocation),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showManualLocation = true;
                });
              },
              icon: const Icon(Icons.edit_location_alt),
              label: Text(l10n.setCityManually),
            ),
          ] else if (_showManualLocation) ...[
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: l10n.cityNameOptional,
                hintText: l10n.jakartaHint,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.latitude,
                      hintText: l10n.latitudeHint,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.longitude,
                      hintText: l10n.longitudeHint,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _showManualLocation = false;
                        _cityController.clear();
                        _latitudeController.clear();
                        _longitudeController.clear();
                      });
                    },
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setManualLocation,
                    child: Text(l10n.set),
                  ),
                ),
              ],
            ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.locationSet,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text(
                                '${widget.data.latitude!.toStringAsFixed(4)}, ${widget.data.longitude!.toStringAsFixed(4)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _showManualLocation = true;
                              _latitudeController.text = widget.data.latitude!.toString();
                              _longitudeController.text = widget.data.longitude!.toString();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: widget.data.calculationMethod,
            decoration: InputDecoration(
              labelText: l10n.calculationMethod,
            ),
            items: [
              DropdownMenuItem(value: 'mwl', child: Text(l10n.mwlMuslimWorldLeague)),
              DropdownMenuItem(value: 'indonesia', child: Text(l10n.indonesiaKemenag)),
              DropdownMenuItem(value: 'singapore', child: Text(l10n.singapore)),
              DropdownMenuItem(value: 'umm_al_qura', child: Text(l10n.ummAlQura)),
              DropdownMenuItem(value: 'karachi', child: Text(l10n.karachi)),
              DropdownMenuItem(value: 'egypt', child: Text(l10n.egypt)),
              DropdownMenuItem(value: 'isna', child: Text(l10n.isnaNorthAmerica)),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.data.calculationMethod = value;
                });
                _updatePreview();
              }
            },
          ),
          if (_previewTimes != null) ...[
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.prayerTimesPreview,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
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
                        _previewTimes!['fajr']!.subtract(Duration(minutes: widget.data.sahurOffsetMinutes)),
                        isReminder: true,
                      ),
                    const SizedBox(height: 8),
                    _buildTimeRow(context, l10n.maghrib, _previewTimes!['maghrib']!),
                    if (widget.data.iftarEnabled)
                      _buildTimeRow(
                        context,
                        l10n.iftarReminderLabel,
                        _previewTimes!['maghrib']!.add(Duration(minutes: widget.data.iftarOffsetMinutes)),
                        isReminder: true,
                      ),
                  ],
                ),
              ),
            ),
          ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onPrevious,
                      child: Text(l10n.back),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onFinish,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(l10n.finishAndStart),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(BuildContext context, String label, DateTime time, {bool isReminder = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: isReminder ? FontWeight.normal : FontWeight.w500,
                ),
          ),
          Text(
            DateFormat('HH:mm').format(time),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
