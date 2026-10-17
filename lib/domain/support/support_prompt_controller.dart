import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ramadan_tracker/domain/support/support_prompt_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists which support greetings have been shown and when the last ask
/// or purchase happened.
class SupportPromptController extends ChangeNotifier {
  SupportPromptController({
    SharedPreferences? prefs,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now {
    _policy = SupportPromptPolicy(clock: _clock);
    _ready = _load(prefs);
  }

  static const shownKey = 'support_milestones_shown_v1';
  static const cardKey = 'support_active_card_v1';
  static const lastAskKey = 'support_last_ask_at_v1';
  static const lastPurchaseKey = 'support_last_purchase_at_v1';

  final DateTime Function() _clock;
  late final SupportPromptPolicy _policy;
  late final Future<void> _ready;

  SharedPreferences? _prefs;
  Set<String> _shown = {};
  ActiveSupportCard? _card;
  DateTime? _lastAskAt;
  DateTime? _lastPurchaseAt;

  ActiveSupportCard? get card => _card;

  Future<void> sync({
    required SupportMilestone? milestone,
    required bool inLastTenNights,
  }) async {
    await _ready;
    final previousId = _card?.storageId;
    final previousShown = _shown.length;
    final step = _policy.present(
      current: _card,
      shown: _shown,
      inLastTenNights: inLastTenNights,
      milestone: milestone,
      lastAskAt: _lastAskAt,
      lastPurchaseAt: _lastPurchaseAt,
    );
    _shown = step.shown;
    _card = step.card;
    if (_card?.storageId == previousId && _shown.length == previousShown) {
      return;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> dismiss() async {
    await _ready;
    if (_card == null) return;
    final step = _policy.dismiss(
      SupportPromptStep(card: _card, shown: _shown, lastAskAt: _lastAskAt),
    );
    _card = null;
    _shown = step.shown;
    _lastAskAt = step.lastAskAt;
    await _persist();
    notifyListeners();
  }

  Future<void> recordPurchase() async {
    await _ready;
    _lastPurchaseAt = _clock();
    await _prefs?.setInt(
      lastPurchaseKey,
      _lastPurchaseAt!.millisecondsSinceEpoch,
    );
  }

  Future<void> _load(SharedPreferences? injected) async {
    final prefs = injected ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    _shown = (prefs.getStringList(shownKey) ?? const []).toSet();
    _card = _decodeCard(prefs.getString(cardKey));
    final askMs = prefs.getInt(lastAskKey);
    final purchaseMs = prefs.getInt(lastPurchaseKey);
    _lastAskAt =
        askMs == null ? null : DateTime.fromMillisecondsSinceEpoch(askMs);
    _lastPurchaseAt = purchaseMs == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(purchaseMs);
    final step = _policy.present(
      current: _card,
      shown: _shown,
      inLastTenNights: false,
      lastAskAt: _lastAskAt,
      lastPurchaseAt: _lastPurchaseAt,
    );
    _shown = step.shown;
    _card = step.card;
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setStringList(shownKey, _shown.toList());
    final encoded = _encodeCard(_card);
    if (encoded == null) {
      await prefs.remove(cardKey);
    } else {
      await prefs.setString(cardKey, encoded);
    }
    if (_lastAskAt == null) {
      await prefs.remove(lastAskKey);
    } else {
      await prefs.setInt(lastAskKey, _lastAskAt!.millisecondsSinceEpoch);
    }
  }

  String? _encodeCard(ActiveSupportCard? card) {
    if (card == null) return null;
    return jsonEncode({
      'kind': card.kind.name,
      'id': card.storageId,
      'shownAt': card.shownAt.millisecondsSinceEpoch,
      'ask': card.askVisible,
    });
  }

  ActiveSupportCard? _decodeCard(String? raw) {
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final kindName = json['kind'] as String?;
      final kind = SupportMilestoneKind.values
          .where((value) => value.name == kindName)
          .firstOrNull;
      final id = json['id'] as String?;
      final shownAt = json['shownAt'];
      if (kind == null || id == null || shownAt is! int) return null;
      return ActiveSupportCard(
        kind: kind,
        storageId: id,
        shownAt: DateTime.fromMillisecondsSinceEpoch(shownAt),
        askVisible: json['ask'] == true,
      );
    } catch (_) {
      return null;
    }
  }
}
