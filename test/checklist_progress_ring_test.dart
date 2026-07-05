import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_header.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist/checklist_progress_ring.dart';
import 'package:ramadan_tracker/features/today/widgets/checklist_habit_card.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChecklistProgressRing', () {
    testWidgets('pumps at 0%, partial, and 100% without error', (tester) async {
      for (final state in [(0, 7), (5, 7), (7, 7)]) {
        final progress = state.$2 > 0 ? state.$1 / state.$2 : 0.0;
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
            home: Scaffold(
              body: ChecklistProgressRing(
                progress: progress,
                completed: state.$1,
                total: state.$2,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.byType(ChecklistProgressRing), findsOneWidget);
      }
    });

    testWidgets('header uses proportional progress', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: ChecklistProgressHeader(completed: 5, total: 7),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('5'), findsWidgets);
      expect(find.byType(ChecklistProgressRing), findsOneWidget);

      final ring = tester.widget<ChecklistProgressRing>(find.byType(ChecklistProgressRing));
      expect(ring.completed, 5);
      expect(ring.total, 7);
      expect(ring.progress, closeTo(5 / 7, 0.001));
    });

    testWidgets('shows check icon when complete', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
          home: const Scaffold(
            body: ChecklistProgressRing(
              progress: 1.0,
              completed: 7,
              total: 7,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('golden: header 5/7 and 7/7', (tester) async {
      for (final state in [(5, 7), (7, 7)]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              backgroundColor: Colors.white,
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: ChecklistProgressHeader(
                  completed: state.$1,
                  total: state.$2,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(ChecklistProgressHeader),
          matchesGoldenFile('checklist_header_${state.$1}_of_${state.$2}.png'),
        );
      }
    });
  });

  group('ChecklistHabitCard fasting row', () {
    testWidgets('groups dots and checkbox at trailing edge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ChecklistHabitCard(
                leadingIcon: const ChecklistHabitIcon(
                  accent: Colors.blue,
                  child: Icon(Icons.no_meals_rounded, size: 20),
                ),
                trailingAction: const ChecklistToggleAction(done: true),
                title: 'Fasting',
                subtitle: 'Fasted',
                showOptionsHint: true,
                onTap: () {},
                onActionTap: () {},
              ),
            ),
          ),
        ),
      );

      final dots = find.text('···');
      final checkbox = find.byType(ChecklistToggleAction);
      final gap = tester.getTopLeft(checkbox).dx - tester.getTopRight(dots).dx;
      final cardRight = tester.getTopRight(find.byType(ChecklistHabitCard)).dx;

      expect(gap, lessThan(8));
      expect(gap, greaterThanOrEqualTo(4));
      expect(cardRight - tester.getTopRight(checkbox).dx, lessThan(16));
    });

    testWidgets('golden: fasting row trailing controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 360,
                child: ChecklistHabitCard(
                  leadingIcon: const ChecklistHabitIcon(
                    accent: Colors.teal,
                    child: Icon(Icons.no_meals_rounded, size: 20),
                  ),
                  trailingAction: const ChecklistToggleAction(done: true),
                  title: 'Fasting',
                  subtitle: 'Fasted',
                  showOptionsHint: true,
                  onTap: () {},
                  onActionTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ChecklistHabitCard),
        matchesGoldenFile('checklist_fasting_row.png'),
      );
    });

    testWidgets('golden: numeric row chevron only trailing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 360,
                child: ChecklistHabitCard(
                  leadingIcon: const ChecklistHabitIcon(
                    accent: Colors.teal,
                    child: Icon(Icons.menu_book_rounded, size: 20),
                  ),
                  title: 'Quran',
                  subtitle: '12 of 20 pages',
                  progress: 0.6,
                  showExpandHint: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ChecklistHabitCard),
        matchesGoldenFile('checklist_quran_row.png'),
      );
    });
  });
}
