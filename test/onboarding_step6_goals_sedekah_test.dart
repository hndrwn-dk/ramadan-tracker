import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step6_goals_sedekah.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

void main() {
  Future<void> pumpStep(
    WidgetTester tester, {
    required OnboardingData data,
    required VoidCallback onNext,
  }) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: OnboardingStep6GoalsSedekah(
            data: data,
            onNext: onNext,
            onPrevious: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('blocks continue when goal is on and amount is empty', (tester) async {
    var nextCalled = false;
    final data = OnboardingData()..sedekahGoalEnabled = true;

    await pumpStep(tester, data: data, onNext: () => nextCalled = true);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(nextCalled, isFalse);
    expect(
      find.text('Enter a daily amount, or turn the goal off.'),
      findsOneWidget,
    );
  });

  testWidgets('continues when goal is off without an amount', (tester) async {
    var nextCalled = false;
    final data = OnboardingData()..sedekahGoalEnabled = false;

    await pumpStep(tester, data: data, onNext: () => nextCalled = true);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(nextCalled, isTrue);
    expect(
      find.text('Enter a daily amount, or turn the goal off.'),
      findsNothing,
    );
  });
}
