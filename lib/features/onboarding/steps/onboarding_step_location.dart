import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/utils/device_timezone.dart';
import 'package:ramadan_tracker/utils/location_helper.dart';
import 'package:ramadan_tracker/features/onboarding/widgets/onboarding_prayer_times_preview.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

/// Step 4 of 9 — location + calculation method for prayer times.
class OnboardingStepLocation extends ConsumerStatefulWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const OnboardingStepLocation({
    super.key,
    required this.data,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  ConsumerState<OnboardingStepLocation> createState() =>
      _OnboardingStepLocationState();
}

class _OnboardingStepLocationState extends ConsumerState<OnboardingStepLocation> {
  bool _loadingLocation = false;
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
    _ensureTimezone();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _ensureTimezone() async {
    if (widget.data.timezone != 'UTC' && widget.data.timezone.isNotEmpty) {
      return;
    }
    String tz = 'UTC';
    try {
      if (Platform.isAndroid) {
        final result = await Process.run('getprop', ['persist.sys.timezone']);
        if (result.exitCode == 0) {
          tz = result.stdout.toString().trim();
        }
      } else if (Platform.isIOS) {
        tz = await resolveDeviceTimezone();
      }
    } catch (_) {
      tz = 'UTC';
    }
    if ((tz == 'UTC' || tz.isEmpty) &&
        widget.data.latitude != null &&
        widget.data.longitude != null) {
      tz = LocationHelper.detectTimezone(
        widget.data.latitude!,
        widget.data.longitude!,
      );
    }
    if (mounted) {
      setState(() => widget.data.timezone = tz);
    }
  }

  Future<void> _useLocation() async {
    setState(() => _loadingLocation = true);
    try {
      final l10n = AppLocalizations.of(context)!;
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.locationServicesDisabled)),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
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

      final position = await Geolocator.getCurrentPosition();
      final detectedMethod = LocationHelper.detectCalculationMethod(
        position.latitude,
        position.longitude,
      );
      var detectedTimezone = LocationHelper.detectTimezone(
        position.latitude,
        position.longitude,
      );
      if (detectedTimezone == 'UTC' || detectedTimezone.isEmpty) {
        try {
          detectedTimezone = await FlutterTimezone.getLocalTimezone();
        } catch (_) {}
      }

      setState(() {
        widget.data.latitude = position.latitude;
        widget.data.longitude = position.longitude;
        widget.data.calculationMethod = detectedMethod;
        widget.data.timezone = detectedTimezone;
        _loadingLocation = false;
        _showManualLocation = false;
      });
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingLocation = false);
      }
    }
  }

  Future<void> _setManualLocation() async {
    final lat = double.tryParse(_latitudeController.text);
    final lon = double.tryParse(_longitudeController.text);
    if (lat == null || lon == null) return;

    final detectedMethod = LocationHelper.detectCalculationMethod(lat, lon);
    var detectedTimezone = LocationHelper.detectTimezone(lat, lon);
    if (detectedTimezone == 'UTC' || detectedTimezone.isEmpty) {
      try {
        detectedTimezone = await FlutterTimezone.getLocalTimezone();
      } catch (_) {}
    }

    setState(() {
      widget.data.latitude = lat;
      widget.data.longitude = lon;
      widget.data.calculationMethod = detectedMethod;
      widget.data.timezone = detectedTimezone;
      _showManualLocation = false;
    });
  }

  bool get _hasLocation =>
      widget.data.latitude != null && widget.data.longitude != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primaryContainer.withValues(alpha: 0.45),
                border: Border.all(color: scheme.primary.withValues(alpha: 0.35)),
              ),
              child: Icon(
                Icons.location_on_outlined,
                size: 44,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingLocationTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingLocationSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 32),
          if (_hasLocation && !_showManualLocation) ...[
            AppSurface(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: scheme.primary, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.locationSet,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Text(
                          '${widget.data.latitude!.toStringAsFixed(4)}, '
                          '${widget.data.longitude!.toStringAsFixed(4)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      setState(() {
                        _showManualLocation = true;
                        _latitudeController.text =
                            widget.data.latitude!.toString();
                        _longitudeController.text =
                            widget.data.longitude!.toString();
                      });
                    },
                  ),
                ],
              ),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                  child: FilledButton(
                    onPressed: _setManualLocation,
                    child: Text(l10n.set),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _loadingLocation ? null : _useLocation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: scheme.primary),
                ),
                child: _loadingLocation
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: scheme.primary,
                        ),
                      )
                    : Text(
                        l10n.onboardingAllowLocation,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _showManualLocation = true),
                icon: const Icon(Icons.edit_location_alt_outlined, size: 18),
                label: Text(l10n.setCityManually),
              ),
            ),
          ],
          const SizedBox(height: 28),
          DropdownButtonFormField<String>(
            value: widget.data.calculationMethod,
            decoration: InputDecoration(
              labelText: l10n.calculationMethod,
            ),
            items: onboardingCalculationMethodItems(l10n),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  widget.data.calculationMethod = value;
                  if (value == 'indonesia' &&
                      widget.data.fajrAdjust == 0 &&
                      widget.data.maghribAdjust == 0) {
                    widget.data.fajrAdjust = 0;
                    widget.data.maghribAdjust = 0;
                  }
                });
              }
            },
          ),
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
                child: FilledButton(
                  onPressed: widget.onNext,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.continueButton),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
