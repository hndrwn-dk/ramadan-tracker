import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/support/support_billing_client.dart';
import 'package:ramadan_tracker/domain/support/support_moment.dart';
import 'package:ramadan_tracker/domain/support/support_prompt_controller.dart';
import 'package:ramadan_tracker/domain/support/support_purchase_service.dart';

final supportPromptProvider =
    ChangeNotifierProvider<SupportPromptController>((ref) {
  return SupportPromptController();
});

final supportPurchaseProvider =
    ChangeNotifierProvider<SupportPurchaseService>((ref) {
  return SupportPurchaseService(
    PlaySupportBillingClient(InAppPurchase.instance),
    onPurchased: () {
      ref.read(supportPromptProvider).recordPurchase();
    },
  );
});

final supportMomentProvider = FutureProvider<SupportMoment>((ref) async {
  final database = ref.watch(databaseProvider);
  return loadSupportMoment(database, DateTime.now());
});
