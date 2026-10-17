import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';
import 'package:ramadan_tracker/domain/support/support_prompt_policy.dart';

void main() {
  final start = DateTime(2026, 2, 18);
  final dayTen = DateTime(2026, 2, 27);
  final lastTen = DateTime(2026, 3, 10);
  final eid = DateTime(2026, 3, 20);

  SeasonModel season({int id = 7, int days = 30}) {
    return SeasonModel(
      id: id,
      label: 'Ramadan',
      startDate: start,
      days: days,
      createdAt: start,
    );
  }

  SupportPromptPolicy policyAt(DateTime now) =>
      SupportPromptPolicy(clock: () => now);

  SupportMilestone dayTenMilestone({int id = 7}) {
    return SupportMilestone(
      kind: SupportMilestoneKind.dayTen,
      storageId: '$id:dayTen',
    );
  }

  group('ask window', () {
    test('ask waits 30 days after the last ask', () {
      final asked = dayTen.subtract(const Duration(days: 29));
      expect(policyAt(dayTen).askAllowed(lastAskAt: asked), isFalse);
      expect(
        policyAt(asked.add(const Duration(days: 30)))
            .askAllowed(lastAskAt: asked),
        isTrue,
      );
    });

    test('ask waits 90 days after a purchase', () {
      final bought = dayTen.subtract(const Duration(days: 89));
      expect(policyAt(dayTen).askAllowed(lastPurchaseAt: bought), isFalse);
      expect(
        policyAt(bought.add(const Duration(days: 90)))
            .askAllowed(lastPurchaseAt: bought),
        isTrue,
      );
    });

    test('a recent purchase blocks an ask even when the last ask is old', () {
      expect(
        policyAt(dayTen).askAllowed(
          lastAskAt: dayTen.subtract(const Duration(days: 40)),
          lastPurchaseAt: dayTen.subtract(const Duration(days: 10)),
        ),
        isFalse,
      );
    });
  });

  group('milestones', () {
    test('day 10 with 7 filled days asks once per season', () {
      final selected = selectSupportMilestone(
        seasons: [season()],
        today: dayTen,
        filledDaysInFirstTen: 7,
        recordedSunnahFastDays: 0,
      );
      expect(selected!.kind, SupportMilestoneKind.dayTen);

      final opened = policyAt(dayTen).present(
        current: null,
        shown: const {},
        inLastTenNights: false,
        milestone: selected,
      );
      expect(opened.card!.askVisible, isTrue);

      final dismissed = policyAt(dayTen).dismiss(opened);
      final again = policyAt(dayTen.add(const Duration(days: 31))).present(
        current: null,
        shown: dismissed.shown,
        inLastTenNights: false,
        milestone: selected,
        lastAskAt: dismissed.lastAskAt,
      );
      expect(again.card, isNull);

      final nextSeason = selectSupportMilestone(
        seasons: [season(id: 8)],
        today: dayTen,
        filledDaysInFirstTen: 7,
        recordedSunnahFastDays: 0,
      );
      final next = policyAt(dayTen).present(
        current: null,
        shown: dismissed.shown,
        inLastTenNights: false,
        milestone: nextSeason,
      );
      expect(next.card!.storageId, '8:dayTen');
    });

    test('six filled days do not open the day-ten greeting', () {
      expect(
        selectSupportMilestone(
          seasons: [season()],
          today: dayTen,
          filledDaysInFirstTen: 6,
          recordedSunnahFastDays: 12,
        ),
        isNull,
      );
    });

    test('the last ten nights block a new card, including a passed day ten',
        () {
      expect(isInLastTenNights([season()], lastTen), isTrue);
      expect(
        selectSupportMilestone(
          seasons: [season()],
          today: lastTen,
          filledDaysInFirstTen: 10,
          recordedSunnahFastDays: 12,
        ),
        isNull,
      );

      final blocked = policyAt(lastTen).present(
        current: null,
        shown: const {},
        inLastTenNights: true,
        milestone: dayTenMilestone(),
      );
      expect(blocked.card, isNull);
      expect(blocked.shown, isEmpty);
    });

    test('a day-ten card already on screen stays through the last ten nights',
        () {
      final opened = policyAt(dayTen).present(
        current: null,
        shown: const {},
        inLastTenNights: false,
        milestone: dayTenMilestone(),
      );
      final kept = policyAt(dayTen.add(const Duration(days: 2))).present(
        current: opened.card,
        shown: opened.shown,
        inLastTenNights: true,
      );
      expect(kept.card!.kind, SupportMilestoneKind.dayTen);
    });

    test(
        'eid greets on the first day after Ramadan and skips the ask after a purchase',
        () {
      final selected = selectSupportMilestone(
        seasons: [season()],
        today: eid,
        filledDaysInFirstTen: 10,
        recordedSunnahFastDays: 12,
      );
      expect(selected!.kind, SupportMilestoneKind.eid);
      expect(selected.storageId, '7:eid');

      final quiet = policyAt(eid).present(
        current: null,
        shown: const {},
        inLastTenNights: false,
        milestone: selected,
        lastPurchaseAt: eid.subtract(const Duration(days: 3)),
      );
      expect(quiet.card!.askVisible, isFalse);
      expect(policyAt(eid).dismiss(quiet).lastAskAt, isNull);
    });

    test('ten recorded sunnah fasts greet once per year outside Ramadan', () {
      final outside = DateTime(2026, 6, 1);
      final selected = selectSupportMilestone(
        seasons: [season()],
        today: outside,
        filledDaysInFirstTen: 0,
        recordedSunnahFastDays: 10,
      );
      expect(selected!.kind, SupportMilestoneKind.sunnahTen);
      expect(selected.storageId, '2026:sunnahTen');

      final opened = policyAt(outside).present(
        current: null,
        shown: const {},
        inLastTenNights: false,
        milestone: selected,
      );
      final dismissed = policyAt(outside).dismiss(opened);
      final again = policyAt(outside.add(const Duration(days: 40))).present(
        current: null,
        shown: dismissed.shown,
        inLastTenNights: false,
        milestone: selected,
        lastAskAt: dismissed.lastAskAt,
      );
      expect(again.card, isNull);

      final nextYear = selectSupportMilestone(
        seasons: [season()],
        today: DateTime(2027, 1, 4),
        filledDaysInFirstTen: 0,
        recordedSunnahFastDays: 10,
      );
      expect(nextYear!.storageId, '2027:sunnahTen');
    });

    test('an open card disappears after 3 days', () {
      final opened = policyAt(dayTen).present(
        current: null,
        shown: const {},
        inLastTenNights: false,
        milestone: dayTenMilestone(),
      );
      final expired = policyAt(dayTen.add(const Duration(days: 3))).present(
        current: opened.card,
        shown: opened.shown,
        inLastTenNights: false,
      );
      expect(expired.card, isNull);
      expect(expired.shown, contains('7:dayTen'));
    });
  });
}
