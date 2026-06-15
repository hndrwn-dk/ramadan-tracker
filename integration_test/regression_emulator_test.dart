import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ramadan_tracker/main.dart' as app;

import 'support/app_harness.dart';

/// Emulator regression: completed Ramadan (uzur haid/sakit) + 6 Syawal fasts via
/// REGRESSION_SEED, then verifies year-round UI after the season ends.
///
/// Run: flutter test integration_test/regression_emulator_test.dart -d <device> --dart-define=REGRESSION_SEED=true
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const regressionSeed = bool.fromEnvironment('REGRESSION_SEED');

  testWidgets('Post-Ramadan year-round regression', (tester) async {
    expect(
      regressionSeed,
      isTrue,
      reason:
          'Set --dart-define=REGRESSION_SEED=true when running this test',
    );

    app.main();
    await AppHarness.completeStartup(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(AppHarness.hasNoSeason(tester), isFalse,
        reason: 'Seeded season must exist');

    final year = DateTime.now().year;

    // Today: post-Ramadan season ended card + year-round CTAs (not daily tracking)
    expect(AppHarness.isSeasonEndedToday(tester), isTrue);
    expect(find.textContaining('Puasa Sunnah'), findsWidgets);

    // Month: sunnah calendar, not 30-day Ramadan grid legend
    await AppHarness.tapNavIndex(tester, 1);
    expect(find.text('Kalender Puasa Sunnah'), findsOneWidget);
    expect(find.textContaining('Cincin = penyelesaian'), findsNothing);

    // Sunnah tab: year-round mode (not Ramadan focus card)
    await AppHarness.tapNavIndex(tester, 3);
    expect(AppHarness.isRamadanFocusMode(tester), isFalse);
    expect(find.text('Puasa Sunnah'), findsOneWidget);

    // Wawasan: sunnah year-round view + link to past season report
    await AppHarness.openWawasanYearRoundView(tester);
    expect(AppHarness.hasRamadanInsightsTabs(tester), isFalse);
    expect(find.textContaining('Puasa Sunnah $year'), findsWidgets);
    expect(find.text('Lihat ringkasan Ramadan'), findsOneWidget);

    // 6 Syawal fasts seeded for this year appear in sunnah hero/stats
    expect(find.text('6'), findsWidgets);

    // Zakat/Fidyah hub still opens from Sunnah tab
    await AppHarness.tapNavIndex(tester, 3);
    await AppHarness.scrollUntilVisible(
      tester,
      find.textContaining('Zakat, Fidyah'),
    );
    final zakatTile = find.textContaining('Zakat, Fidyah');
    expect(zakatTile, findsWidgets);
    await tester.tap(zakatTile.first);
    await AppHarness.settle(tester);
    expect(find.text('Mata uang'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await AppHarness.settle(tester);

    expect(tester.takeException(), isNull);
  });
}
