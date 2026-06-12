import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

/// Layout regression checks at 360px width (small phone, Indonesian).
void main() {
  group('narrow screen layout (360px, id)', () {
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
    });

    Future<void> pumpIdApp(WidgetTester tester, Widget home) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: home,
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('navigation settings label uses short Atur in Indonesian', (tester) async {
      await pumpIdApp(
        tester,
        Scaffold(
          bottomNavigationBar: NavigationBar(
            selectedIndex: 5,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.today), label: 'Hari Ini'),
              NavigationDestination(icon: Icon(Icons.calendar_month), label: 'Bulan'),
              NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'Rencana'),
              NavigationDestination(icon: Icon(Icons.nightlight), label: 'Sunnah'),
              NavigationDestination(icon: Icon(Icons.insights), label: 'Wawasan'),
              NavigationDestination(icon: Icon(Icons.tune), label: 'Atur'),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Atur'), findsOneWidget);
      expect(find.text('Pengaturan'), findsNothing);
    });
  });
}
