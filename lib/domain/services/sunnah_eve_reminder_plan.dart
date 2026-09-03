import 'package:ramadan_tracker/domain/services/notification_ids.dart';
import 'package:ramadan_tracker/utils/sunnah_fasting_rules.dart';

/// One evening-before reminder to schedule.
class SunnahEveReminder {
  const SunnahEveReminder({
    required this.id,
    required this.fastDay,
    required this.fireAt,
    required this.title,
    required this.body,
  });

  final int id;
  final DateTime fastDay;
  final DateTime fireAt;
  final String title;
  final String body;
}

/// Builds the next sunnah eve reminders without stacking duplicate Mondays.
abstract final class SunnahEveReminderPlan {
  static const int horizonDays = 14;
  static const int reminderHour = 19;

  static bool shouldScheduleForFastDay(DateTime fastDay) {
    if (SunnahFastingRules.typesFor(fastDay).isEmpty) return false;
    if (SunnahFastingRules.isRamadan(fastDay)) return false;
    return true;
  }

  static List<SunnahEveReminder> build({
    required DateTime today,
    required DateTime now,
    required bool isId,
  }) {
    final todayDate = DateTime(today.year, today.month, today.day);
    SunnahEveReminder? nextMonday;
    SunnahEveReminder? nextThursday;
    final specials = <SunnahEveReminder>[];

    for (var i = 1; i <= horizonDays; i++) {
      final fastDay = DateTime(todayDate.year, todayDate.month, todayDate.day + i);
      if (!shouldScheduleForFastDay(fastDay)) continue;

      final eve = DateTime(fastDay.year, fastDay.month, fastDay.day - 1);
      final fireAt = DateTime(eve.year, eve.month, eve.day, reminderHour);
      if (!fireAt.isAfter(now)) continue;

      final types = SunnahFastingRules.typesFor(fastDay);
      final isMonday = fastDay.weekday == DateTime.monday;
      final isThursday = fastDay.weekday == DateTime.thursday;
      final hasSeninKamis = types.contains(SunnahType.seninKamis);

      if (hasSeninKamis && isMonday && nextMonday == null) {
        nextMonday = _weekdayReminder(
          id: NotificationIds.sunnahEveMonday,
          fastDay: fastDay,
          fireAt: fireAt,
          isId: isId,
          monday: true,
        );
      } else if (hasSeninKamis && isThursday && nextThursday == null) {
        nextThursday = _weekdayReminder(
          id: NotificationIds.sunnahEveThursday,
          fastDay: fastDay,
          fireAt: fireAt,
          isId: isId,
          monday: false,
        );
      } else if (!hasSeninKamis) {
        specials.add(
          _specialReminder(
            fastDay: fastDay,
            fireAt: fireAt,
            type: types.first,
            isId: isId,
          ),
        );
      }
    }

    return [
      if (nextMonday != null) nextMonday,
      if (nextThursday != null) nextThursday,
      ...specials,
    ];
  }

  static SunnahEveReminder _weekdayReminder({
    required int id,
    required DateTime fastDay,
    required DateTime fireAt,
    required bool isId,
    required bool monday,
  }) {
    final title = isId ? 'Puasa sunnah besok' : 'Sunnah fast tomorrow';
    final body = isId
        ? (monday
            ? 'Besok: Puasa Senin. Niatkan puasa malam ini.'
            : 'Besok: Puasa Kamis. Niatkan puasa malam ini.')
        : (monday
            ? 'Tomorrow: Monday fast. Set your intention tonight.'
            : 'Tomorrow: Thursday fast. Set your intention tonight.');
    return SunnahEveReminder(
      id: id,
      fastDay: fastDay,
      fireAt: fireAt,
      title: title,
      body: body,
    );
  }

  static SunnahEveReminder _specialReminder({
    required DateTime fastDay,
    required DateTime fireAt,
    required SunnahType type,
    required bool isId,
  }) {
    final label = isId ? type.labelId() : type.labelEn();
    final title = isId ? 'Puasa sunnah besok' : 'Sunnah fast tomorrow';
    final body = isId
        ? 'Besok: $label. Niatkan puasa malam ini.'
        : 'Tomorrow: $label. Set your intention tonight.';
    final ymd = fastDay.year * 10000 + fastDay.month * 100 + fastDay.day;
    return SunnahEveReminder(
      id: NotificationIds.baseSunnah + ymd,
      fastDay: fastDay,
      fireAt: fireAt,
      title: title,
      body: body,
    );
  }
}
