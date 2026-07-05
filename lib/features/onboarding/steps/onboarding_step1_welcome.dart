import 'package:flutter/material.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/features/onboarding/widgets/onboarding_shared_widgets.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/app_surface.dart';

class OnboardingStep1Welcome extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onNext;

  const OnboardingStep1Welcome({
    super.key,
    required this.data,
    required this.onNext,
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
          const SizedBox(height: 8),
          OnboardingBrandHero(
            title: l10n.appTitle,
            subtitle: l10n.trackYourRamadanInSeconds,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onboardingWelcomeNudge,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.78),
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 24),
          OnboardingFeatureSurface(
            icon: Icons.touch_app_outlined,
            text: l10n.oneTapDailyChecklist,
          ),
          const SizedBox(height: 10),
          OnboardingFeatureSurface(
            icon: Icons.auto_awesome_outlined,
            text: l10n.autopilotQuranPlan,
          ),
          const SizedBox(height: 10),
          OnboardingFeatureSurface(
            icon: Icons.notifications_active_outlined,
            text: l10n.sahurIftarRemindersAutomatic,
          ),
          const Spacer(),
          AppSurface(
            padding: const EdgeInsets.all(14),
            child: Text(
              l10n.noAccountNoAdsStored,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.65),
                  ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(l10n.startSetup),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.takesAbout1Minute,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
          ),
        ],
      ),
    );
  }
}
