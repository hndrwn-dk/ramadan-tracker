import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:ramadan_tracker/main.dart' as app;

import 'support/app_harness.dart';

/// Emulator regression: simulates completed Ramadan (uzur haid/sakit) + 6 Syawal
/// fasts via REGRESSION_SEED, then verifies Wawasan season cards render data.
///
/// Run: scripts/run_regression_emulator.sh
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const regressionSeed = bool.fromEnvironment('REGRESSION_SEED');

  testWidgets('Ramadan simulation + Wawasan season regression', (tester) async {
    expect(
      regressionSeed,
      isTrue,
      reason: 'Set --dart-define=REGRESSION_SEED=true (use scripts/run_regression_emulator.sh)',
    );

    app.main();
    await AppHarness.completeStartup(tester);

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(AppHarness.hasNoSeason(tester), isFalse,
        reason: 'Seeded season must exist');

    // Sunnah tab: post-Ramadan year-round mode (not active Ramadan focus)
    await AppHarness.tapNavIndex(tester, 3);
    expect(AppHarness.isRamadanFocusMode(tester), isFalse);
    expect(find.text('Puasa Sunnah'), findsOneWidget);

    // Wawasan > Ramadan tab: season analytics must show seeded data
    await AppHarness.openWawasanSeasonView(tester);

    expect(find.text('Tidak ada musim ditemukan'), findsNothing);

    final year = DateTime.now().year;
    final seasonCards = [
      find.textContaining('Zakat & Fidyah'),
      find.textContaining('Sedekah'),
      find.textContaining('Puasa Sunnah $year'),
    ];
    for (final card in seasonCards) {
      await AppHarness.scrollUntilVisible(tester, card);
      expect(card, findsWidgets);
    }

    // 6 Syawal fasts seeded for this year
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
