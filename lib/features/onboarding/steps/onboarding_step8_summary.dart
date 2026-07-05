import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/features/onboarding/widgets/onboarding_prayer_times_preview.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Step 9 of 9 — summary with live prayer preview and finish.
class OnboardingStep8Summary extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onPrevious;
  final VoidCallback onFinish;

  const OnboardingStep8Summary({
    super.key,
    required this.data,
    required this.onPrevious,
    required this.onFinish,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
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
                Icons.event_available_outlined,
                size: 44,
                color: scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingReadyTitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: OnboardingPrayerTimesPreview(
                data: data,
                showTestButton: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onPrevious,
                  child: Text(l10n.back),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FilledButton(
                  onPressed: onFinish,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(l10n.finishAndStart),
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
