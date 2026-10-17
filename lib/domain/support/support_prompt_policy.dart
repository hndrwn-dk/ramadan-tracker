import 'package:ramadan_tracker/domain/models/season_model.dart';

enum SupportMilestoneKind { dayTen, eid, sunnahTen }

class SupportMilestone {
  const SupportMilestone({required this.kind, required this.storageId});

  final SupportMilestoneKind kind;
  final String storageId;
}

class ActiveSupportCard {
  const ActiveSupportCard({
    required this.kind,
    required this.storageId,
    required this.shownAt,
    required this.askVisible,
  });

  final SupportMilestoneKind kind;
  final String storageId;
  final DateTime shownAt;
  final bool askVisible;
}

class SupportPromptStep {
  const SupportPromptStep({
    required this.card,
    required this.shown,
    required this.lastAskAt,
  });

  final ActiveSupportCard? card;
  final Set<String> shown;
  final DateTime? lastAskAt;
}

/// When the Today home may greet the user and, rarely, ask for support.
///
/// [filledDaysInFirstTen] counts days whose checklist is complete under
/// [CompletionService]: at least one habit done. The clock is injectable.
class SupportPromptPolicy {
  SupportPromptPolicy({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const askGap = Duration(days: 30);
  static const purchaseGap = Duration(days: 90);
  static const cardLifetime = Duration(days: 3);

  final DateTime Function() _clock;

  DateTime get now => _clock();

  bool askAllowed({DateTime? lastAskAt, DateTime? lastPurchaseAt}) {
    if (lastPurchaseAt != null &&
        now.difference(lastPurchaseAt) < purchaseGap) {
      return false;
    }
    if (lastAskAt != null && now.difference(lastAskAt) < askGap) {
      return false;
    }
    return true;
  }

  bool isExpired(ActiveSupportCard card) {
    return now.difference(card.shownAt) >= cardLifetime;
  }

  SupportPromptStep present({
    required ActiveSupportCard? current,
    required Set<String> shown,
    required bool inLastTenNights,
    SupportMilestone? milestone,
    DateTime? lastAskAt,
    DateTime? lastPurchaseAt,
  }) {
    if (current != null && isExpired(current)) {
      return present(
        current: null,
        shown: {...shown, current.storageId},
        inLastTenNights: inLastTenNights,
        milestone: milestone,
        lastAskAt: lastAskAt,
        lastPurchaseAt: lastPurchaseAt,
      );
    }
    if (current != null) {
      return SupportPromptStep(
          card: current, shown: shown, lastAskAt: lastAskAt);
    }
    if (milestone == null || shown.contains(milestone.storageId)) {
      return SupportPromptStep(card: null, shown: shown, lastAskAt: lastAskAt);
    }
    // The last ten nights stay quiet. A day-ten card already on screen is
    // kept above. A day-ten moment that was missed is not opened here.
    if (inLastTenNights) {
      return SupportPromptStep(card: null, shown: shown, lastAskAt: lastAskAt);
    }
    final card = ActiveSupportCard(
      kind: milestone.kind,
      storageId: milestone.storageId,
      shownAt: now,
      askVisible: askAllowed(
        lastAskAt: lastAskAt,
        lastPurchaseAt: lastPurchaseAt,
      ),
    );
    return SupportPromptStep(
      card: card,
      shown: {...shown, milestone.storageId},
      lastAskAt: lastAskAt,
    );
  }

  SupportPromptStep dismiss(SupportPromptStep step) {
    final card = step.card;
    if (card == null) return step;
    return SupportPromptStep(
      card: null,
      shown: {...step.shown, card.storageId},
      lastAskAt: card.askVisible ? now : step.lastAskAt,
    );
  }
}

/// Picks at most one milestone from the seasons already stored in the app.
///
/// Day ten is the days before the last ten nights, once seven of the first
/// ten checklist days are filled. Eid is the first calendar day after the
/// season. Sunnah is outside an active season.
SupportMilestone? selectSupportMilestone({
  required List<SeasonModel> seasons,
  required DateTime today,
  required int filledDaysInFirstTen,
  required int recordedSunnahFastDays,
}) {
  SeasonModel? active;
  SeasonModel? eid;
  for (final season in seasons) {
    final raw = season.getRawDayIndex(today);
    if (raw >= 1 && raw <= season.days) {
      active = season;
    } else if (raw == season.days + 1) {
      eid ??= season;
    }
  }
  if (active != null) {
    final raw = active.getRawDayIndex(today);
    final last10Start = active.days - 9;
    if (raw >= last10Start) return null;
    if (raw >= 10 && filledDaysInFirstTen >= 7) {
      return SupportMilestone(
        kind: SupportMilestoneKind.dayTen,
        storageId: '${active.id}:dayTen',
      );
    }
    return null;
  }
  if (eid != null) {
    return SupportMilestone(
      kind: SupportMilestoneKind.eid,
      storageId: '${eid.id}:eid',
    );
  }
  if (recordedSunnahFastDays >= 10) {
    return SupportMilestone(
      kind: SupportMilestoneKind.sunnahTen,
      storageId: '${today.year}:sunnahTen',
    );
  }
  return null;
}

bool isInLastTenNights(List<SeasonModel> seasons, DateTime today) {
  for (final season in seasons) {
    final raw = season.getRawDayIndex(today);
    if (raw >= 1 && raw <= season.days && raw >= season.days - 9) {
      return true;
    }
  }
  return false;
}
