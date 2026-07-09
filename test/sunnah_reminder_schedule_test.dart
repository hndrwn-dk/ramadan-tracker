import 'package:flutter_test/flutter_test.dart';
import 'package:ramadan_tracker/domain/services/notification_service.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

void main() {
  group('shouldScheduleSunnahEveForFastDay', () {
    test('schedules eve for Monday outside Ramadan', () {
      // 2026-06-08 is a Monday, month 8 in Hijri (not Ramadan).
      final monday = DateTime(2026, 6, 8);
      expect(
        NotificationService.shouldScheduleSunnahEveForFastDay(monday),
        isTrue,
      );
    });

    test('skips non-sunnah days', () {
      // 2026-06-09 is Tuesday with no sunnah rule.
      final tuesday = DateTime(2026, 6, 9);
      expect(
        NotificationService.shouldScheduleSunnahEveForFastDay(tuesday),
        isFalse,
      );
    });

    test('skips fast days that fall inside Ramadan month', () {
      // Ramadan 1447 starts ~2026-02-18; 1 Ramadan is a sunnah-forbidden day anyway.
      // Use mid-Ramadan Monday if it exists — any date in Hijri month 9 is skipped.
      final ramadanMonday = DateTime(2026, 3, 2);
      expect(SunnahFastingRules.isRamadan(ramadanMonday), isTrue);
      expect(
        NotificationService.shouldScheduleSunnahEveForFastDay(ramadanMonday),
        isFalse,
      );
    });

    test('schedules eve for last sunnah day before Ramadan', () {
      // Day before Ramadan starts should still get eve if it is a sunnah day.
      // 2026-02-17 is Tuesday — not sunnah; pick a Monday before Ramadan.
      final mondayBeforeRamadan = DateTime(2026, 2, 16);
      expect(SunnahFastingRules.isRamadan(mondayBeforeRamadan), isFalse);
      expect(
        NotificationService.shouldScheduleSunnahEveForFastDay(mondayBeforeRamadan),
        isTrue,
      );
    });
  });
}
