import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/floating_pill_nav_bar.dart';

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

    testWidgets('bottom navigation has five primary tabs (settings via app bar)', (tester) async {
      await pumpIdApp(
        tester,
        Scaffold(
          bottomNavigationBar: FloatingPillNavBar(
            selectedIndex: 0,
            onSelected: (_) {},
            items: const [
              FloatingPillNavItem(
                icon: Icons.today_outlined,
                selectedIcon: Icons.today,
                label: 'Hari Ini',
              ),
              FloatingPillNavItem(
                icon: Icons.calendar_month_outlined,
                selectedIcon: Icons.calendar_month,
                label: 'Bulan',
              ),
              FloatingPillNavItem(
                icon: Icons.auto_awesome_outlined,
                selectedIcon: Icons.auto_awesome,
                label: 'Rencana',
              ),
              FloatingPillNavItem(
                icon: Icons.nightlight_outlined,
                selectedIcon: Icons.nightlight,
                label: 'Sunnah',
              ),
              FloatingPillNavItem(
                icon: Icons.insights_outlined,
                selectedIcon: Icons.insights,
                label: 'Wawasan',
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Atur'), findsNothing);
    });
  });
}
