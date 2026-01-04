import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

class OnboardingWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const OnboardingWrapper({super.key, required this.child});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  bool? _cachedShouldShowOnboarding;

  @override
  Widget build(BuildContext context) {
    // If we've already cached the result, use it and don't watch provider anymore
    // This prevents re-checks that cause glitches
    if (_cachedShouldShowOnboarding != null) {
      if (_cachedShouldShowOnboarding == true) {
        return const OnboardingFlow();
      }
      return widget.child;
    }

    // First time: check onboarding status and cache result
    final shouldShowOnboarding = ref.watch(shouldShowOnboardingProvider);

    return shouldShowOnboarding.when(
      data: (show) {
        // Cache immediately to prevent future watches
        _cachedShouldShowOnboarding ??= show;
        
        if (show) {
          return const OnboardingFlow();
        }
        return widget.child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        debugPrint('Onboarding check error: $error');
        // Cache error result as "show onboarding" to be safe
        _cachedShouldShowOnboarding ??= true;
        return const OnboardingFlow();
      },
    );
  }
}

