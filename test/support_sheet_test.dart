import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ramadan_tracker/data/providers/support_provider.dart';
import 'package:ramadan_tracker/domain/support/support_billing_client.dart';
import 'package:ramadan_tracker/domain/support/support_purchase_service.dart';
import 'package:ramadan_tracker/features/support/support_sheet.dart';
import 'package:ramadan_tracker/features/support/support_thanks_heart.dart';
import 'package:ramadan_tracker/l10n/app_localizations.dart';
import 'package:ramadan_tracker/widgets/donation_icon_button.dart';
import 'package:ramadan_tracker/widgets/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('loading sheet shows three price placeholders, not a spinner', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supportPurchaseProvider.overrideWith(
            (ref) => SupportPurchaseService(_HangingBilling()),
          ),
        ],
        child: const MaterialApp(
          locale: Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SupportSheet()),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
        find.byKey(const Key('support_price_placeholder')), findsNWidgets(3));
    expect(find.text('Segelas kopi'), findsOneWidget);
    expect(find.text('Makan siang'), findsOneWidget);
    expect(find.text('Dukung penuh'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('thank-you shows the product times quantity when it is above 1', (
    tester,
  ) async {
    await _pumpThanks(tester, quantity: 3, productId: 'support_10k');
    expect(find.text('Segelas kopi ×3'), findsOneWidget);
  });

  testWidgets('thank-you hides the quantity line for a single unit', (
    tester,
  ) async {
    await _pumpThanks(tester, quantity: 1, productId: 'support_10k');
    expect(find.textContaining('×'), findsNothing);
  });

  testWidgets('app bar keeps the existing support icon in light and dark', (
    tester,
  ) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(actions: const [DonationIconButton()]),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.volunteer_activism_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsNothing);
      expect(
        tester.widget<IconButton>(find.byType(IconButton)).tooltip,
        'Dukung aplikasi ini',
      );
    }
  });

  testWidgets('thanks heart uses primary in light and dark', (tester) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: SupportThanksHeart()),
          ),
        ),
      );
      await tester.pump();

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite_rounded));
      expect(icon.size, 36);
      expect(icon.color, theme.colorScheme.primary);
      expect(
          tester.getSize(find.byType(SupportThanksHeart)), const Size(72, 72));
    }
  });
}

Future<void> _pumpThanks(
  WidgetTester tester, {
  required int quantity,
  required String productId,
}) async {
  final service = SupportPurchaseService(_HangingBilling())
    ..phase = SupportUiPhase.thanks
    ..purchasedQuantity = quantity
    ..purchasedProductId = productId;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        supportPurchaseProvider.overrideWith((ref) => service),
      ],
      child: const MaterialApp(
        locale: Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SupportSheet()),
      ),
    ),
  );
  await tester.pump();
}

class _HangingBilling implements SupportBillingClient {
  final _updates = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) {
    return Completer<ProductDetailsResponse>().future;
  }

  @override
  Future<bool> buyConsumable({
    required PurchaseParam purchaseParam,
    bool autoConsume = true,
  }) async =>
      false;

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {}
}
