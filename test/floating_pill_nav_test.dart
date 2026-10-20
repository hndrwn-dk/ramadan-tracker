import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/providers/checklist_progress_provider.dart';
import 'package:ramadan_tracker/features/today/widgets/today_checklist_sticky_bar.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/floating_pill_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('reserved height is the pill stack plus the system inset', (tester) async {
    late double plain;
    late double withCard;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewPadding: EdgeInsets.only(bottom: 30)),
        child: Builder(
          builder: (context) {
            plain = FloatingPillNavBar.reservedHeight(context);
            withCard = FloatingPillNavBar.reservedHeight(
              context,
              withAccessory: true,
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(plain, 64 + 20 + 30);
    expect(withCard, plain + 60 + 8);
  });

  testWidgets('indonesian labels fit five tabs at 320dp without overflow', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatefulBuilder(
          builder: (context, setState) {
            final l10n = AppLocalizations.of(context)!;
            return Scaffold(
              bottomNavigationBar: FloatingPillNavBar(
                selectedIndex: selected,
                onSelected: (index) => setState(() => selected = index),
                items: [
                  FloatingPillNavItem(
                    icon: Icons.today_outlined,
                    selectedIcon: Icons.today,
                    label: l10n.today,
                  ),
                  FloatingPillNavItem(
                    icon: Icons.calendar_month_outlined,
                    selectedIcon: Icons.calendar_month,
                    label: l10n.month,
                  ),
                  FloatingPillNavItem(
                    icon: Icons.auto_awesome_outlined,
                    selectedIcon: Icons.auto_awesome,
                    label: l10n.plan,
                  ),
                  FloatingPillNavItem(
                    icon: Icons.nightlight_outlined,
                    selectedIcon: Icons.nightlight,
                    label: l10n.sunnah,
                  ),
                  FloatingPillNavItem(
                    icon: Icons.insights_outlined,
                    selectedIcon: Icons.insights,
                    label: l10n.insights,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Bulan'), findsNothing);
    expect(find.byTooltip('Bulan'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('floating-pill-nav-1')));
    await tester.pumpAndSettle();

    expect(selected, 1);
    expect(find.text('Bulan'), findsOneWidget);
    expect(find.text('Hari Ini'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist card is a glass row without its own safe area', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checklistProgressProvider.overrideWith(
            (ref, params) async => (completed: 2, total: 5),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TodayChecklistStickyBar(seasonId: 1, dayIndex: 1),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SafeArea), findsNothing);
    expect(find.text('2 dari 5 selesai'), findsOneWidget);
    expect(find.text('Checklist'), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is Material && widget.elevation > 0),
      findsNothing,
    );
  });
}
