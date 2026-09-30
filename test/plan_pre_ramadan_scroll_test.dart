import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/features/plan/plan_screen.dart';
import 'package:ramadan_tracker/features/year_round/widgets/pre_ramadan_banner.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.test();
    await db.initialize();
  });

  tearDown(() async {
    await db.close();
  });

  testWidgets('pre-Ramadan countdown banner scrolls with Plan content', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await db.ramadanSeasonsDao.createSeason(
      label: 'Ramadan 1448',
      startDate: DateTime.now().add(const Duration(days: 131)),
      days: 30,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PlanScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final banner = find.byType(PreRamadanBanner);
    expect(banner, findsOneWidget);
    expect(
      find.ancestor(of: banner, matching: find.byType(SingleChildScrollView)),
      findsOneWidget,
    );
  });
}
