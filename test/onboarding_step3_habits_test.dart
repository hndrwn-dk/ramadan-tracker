import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/features/onboarding/onboarding_flow.dart';
import 'package:ramadan_tracker/features/onboarding/steps/onboarding_step3_habits.dart';
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
          body: OnboardingStep3Habits(
            data: data,
            onNext: onNext,
            onPrevious: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks before expanding Advanced the first time', (tester) async {
    await pumpStep(tester, data: OnboardingData(), onNext: () {});

    await tester.ensureVisible(find.text('Advanced'));
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();

    expect(find.text('Track extra habits?'), findsOneWidget);
    expect(find.text('5 Prayers'), findsNothing);
  });

  testWidgets('reminds about Advanced when Continue is tapped without opening it', (tester) async {
    var nextCalled = false;

    await pumpStep(tester, data: OnboardingData(), onNext: () => nextCalled = true);
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(nextCalled, isFalse);
    expect(find.text('Track extra habits?'), findsOneWidget);
    expect(find.text('5 Prayers'), findsNothing);
  });

  testWidgets('confirms Continue when an Advanced habit is selected', (tester) async {
    var nextCalled = false;
    final data = OnboardingData()..selectedHabits.add('tahajud');

    await pumpStep(tester, data: data, onNext: () => nextCalled = true);
    await tester.ensureVisible(find.text('Advanced'));
    await tester.tap(find.text('Advanced'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show options'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(nextCalled, isFalse);
    expect(find.text('Use Advanced tracking?'), findsOneWidget);
    expect(find.text('You turned on: Tahajud.'), findsOneWidget);
  });
}
