import 'package:flutter/material.dart';
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
        if (!show) {
          return child;
        }
        return const OnboardingFlow();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        debugPrint('Onboarding check error: $error');
        return const OnboardingFlow();
      },
    );
  }
}
