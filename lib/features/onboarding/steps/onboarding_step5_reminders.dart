import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
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
              const SnackBar(content: Text('Location permissions denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions permanently denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        widget.data.latitude = position.latitude;
        widget.data.longitude = position.longitude;
        _loadingLocation = false;
        _showManualLocation = false;
      });
      _updatePreview();
    } catch (e) {
      setState(() {
        _loadingLocation = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _setManualLocation() {
    final lat = double.tryParse(_latitudeController.text);
    final lon = double.tryParse(_longitudeController.text);
    if (lat != null && lon != null) {
      setState(() {
        widget.data.latitude = lat;
        widget.data.longitude = lon;
        _showManualLocation = false;
      });
      _updatePreview();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid coordinates')),
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
      await NotificationService.testNotification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test notification sent')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Smart Reminders',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get notified for Sahur, Iftar, and your daily plan.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          SwitchListTile(
            title: const Text('Sahur reminder'),
            subtitle: Text('${widget.data.sahurOffsetMinutes} min before Fajr'),
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
                    'Offset:',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 15, label: Text('15 min')),
                        ButtonSegment(value: 30, label: Text('30 min')),
                        ButtonSegment(value: 45, label: Text('45 min')),
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
            title: const Text('Iftar reminder'),
            subtitle: const Text('At Maghrib'),
            value: widget.data.iftarEnabled,
            onChanged: (value) {
              setState(() {
                widget.data.iftarEnabled = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Night plan reminder'),
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
            'Location',
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
              label: const Text('Use my location'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showManualLocation = true;
                });
              },
              icon: const Icon(Icons.edit_location_alt),
              label: const Text('Set city manually'),
            ),
          ] else if (_showManualLocation) ...[
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City name (optional)',
                hintText: 'Jakarta',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      hintText: '-6.2088',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      hintText: '106.8456',
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
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _setManualLocation,
                    child: const Text('Set'),
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
                                'Location set',
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
            decoration: const InputDecoration(
              labelText: 'Calculation Method',
            ),
            items: const [
              DropdownMenuItem(value: 'mwl', child: Text('MWL')),
              DropdownMenuItem(value: 'isna', child: Text('ISNA')),
              DropdownMenuItem(value: 'egypt', child: Text('Egypt')),
              DropdownMenuItem(value: 'umm_al_qura', child: Text('Umm al-Qura')),
              DropdownMenuItem(value: 'karachi', child: Text('Karachi')),
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
                          'Prayer Times Preview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: _testNotification,
                          icon: const Icon(Icons.notifications_active, size: 18),
                          label: const Text('Test'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTimeRow('Fajr', _previewTimes!['fajr']!),
                    if (widget.data.sahurEnabled)
                      _buildTimeRow(
                        'Sahur reminder',
                        _previewTimes!['fajr']!.subtract(Duration(minutes: widget.data.sahurOffsetMinutes)),
                        isReminder: true,
                      ),
                    const SizedBox(height: 8),
                    _buildTimeRow('Maghrib', _previewTimes!['maghrib']!),
                    if (widget.data.iftarEnabled)
                      _buildTimeRow(
                        'Iftar reminder',
                        _previewTimes!['maghrib']!.add(Duration(minutes: widget.data.iftarOffsetMinutes)),
                        isReminder: true,
                      ),
                  ],
                ),
              ),
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onPrevious,
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onFinish,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Finish & Start'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, DateTime time, {bool isReminder = false}) {
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
