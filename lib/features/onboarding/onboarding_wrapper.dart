import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/locale_provider.dart';
import 'package:ramadan_tracker/data/providers/onboarding_provider.dart';
import 'package:ramadan_tracker/features/onboarding/language_selection_screen.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';

class OnboardingWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const OnboardingWrapper({super.key, required this.child});

  @override
  ConsumerState<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends ConsumerState<OnboardingWrapper> {
  @override
  Widget build(BuildContext context) {
    final shouldShowOnboarding = ref.watch(shouldShowOnboardingProvider);
    final languageChosen = ref.watch(languageChosenProvider);

    return shouldShowOnboarding.when(
      data: (show) {
        if (!show) {
          return widget.child;
        }
        return languageChosen.when(
          data: (chosen) {
            if (chosen) {
              return const OnboardingFlow();
            }
            return const LanguageSelectionScreen();
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (_, __) => const LanguageSelectionScreen(),
        );
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

