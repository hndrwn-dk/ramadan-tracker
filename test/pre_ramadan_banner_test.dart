import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
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

  Future<void> pumpBanner(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: PreRamadanBanner()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with upcoming season shows manage CTA instead of create', (tester) async {
    await db.ramadanSeasonsDao.createSeason(
      label: 'Ramadan 1448',
      startDate: DateTime.now().add(const Duration(days: 1)),
      days: 30,
    );

    await pumpBanner(tester);

    expect(find.text('Siapkan musim Ramadan'), findsNothing);
    expect(find.textContaining('Kelola'), findsOneWidget);
  });
}
