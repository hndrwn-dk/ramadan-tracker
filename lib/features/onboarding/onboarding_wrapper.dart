import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

class OnboardingWrapper extends ConsumerWidget {
  final Widget child;

  const OnboardingWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shouldShowOnboarding = ref.watch(shouldShowOnboardingProvider);

    return shouldShowOnboarding.when(
      data: (show) {
        debugPrint('Should show onboarding: $show');
        if (show) {
          return const OnboardingFlow();
        }
        return child;
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        // On error, show onboarding to be safe
        debugPrint('Onboarding check error: $error');
        debugPrint('Stack: $stack');
        return const OnboardingFlow();
      },
    );
  }
}

