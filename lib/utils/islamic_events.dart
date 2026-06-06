import 'package:ramadan_tracker/utils/hijri_calendar.dart';

/// A notable Islamic event computed from the Hijri calendar.
class IslamicEvent {
  final String nameId;
  final String nameEn;

  /// Hijri month (1..12) and day on which the event falls.
  final int hijriMonth;
  final int hijriDay;

  const IslamicEvent({
    required this.nameId,
    required this.nameEn,
    required this.hijriMonth,
    required this.hijriDay,
  });
}

class UpcomingEvent {
  final IslamicEvent event;
  final DateTime date;
  final int daysUntil;

  const UpcomingEvent({
    required this.event,
    required this.date,
    required this.daysUntil,
  });
}

class IslamicEvents {
  IslamicEvents._();

  static const List<IslamicEvent> all = [
    IslamicEvent(
        nameId: 'Tahun Baru Hijriah',
        nameEn: 'Islamic New Year',
        hijriMonth: 1,
        hijriDay: 1),
    IslamicEvent(
        nameId: 'Hari Asyura',
        nameEn: 'Day of Ashura',
        hijriMonth: 1,
        hijriDay: 10),
    IslamicEvent(
        nameId: 'Maulid Nabi',
        nameEn: 'Mawlid an-Nabi',
        hijriMonth: 3,
        hijriDay: 12),
    IslamicEvent(
        nameId: "Isra Mi'raj",
        nameEn: "Isra and Mi'raj",
        hijriMonth: 7,
        hijriDay: 27),
    IslamicEvent(
        nameId: "Nisfu Sya'ban",
        nameEn: "Mid-Sha'ban",
        hijriMonth: 8,
        hijriDay: 15),
    IslamicEvent(
        nameId: 'Awal Ramadan',
        nameEn: 'First day of Ramadan',
        hijriMonth: 9,
        hijriDay: 1),
    IslamicEvent(
        nameId: 'Lailatul Qadar (perkiraan)',
        nameEn: 'Laylat al-Qadr (estimated)',
        hijriMonth: 9,
        hijriDay: 27),
    IslamicEvent(
        nameId: 'Idul Fitri',
        nameEn: 'Eid al-Fitr',
        hijriMonth: 10,
        hijriDay: 1),
    IslamicEvent(
        nameId: 'Hari Arafah',
        nameEn: 'Day of Arafah',
        hijriMonth: 12,
        hijriDay: 9),
    IslamicEvent(
        nameId: 'Idul Adha',
        nameEn: 'Eid al-Adha',
        hijriMonth: 12,
        hijriDay: 10),
  ];

  /// Returns upcoming events (today inclusive) sorted by soonest first.
  /// Computes the next Gregorian occurrence for each event across the current
  /// and next Hijri year so wrap-around is handled.
  static List<UpcomingEvent> upcoming(DateTime from, {int limit = 6}) {
    final today = DateTime(from.year, from.month, from.day);
    final currentHijri = HijriCalendar.fromGregorian(today);
    final candidates = <UpcomingEvent>[];

    for (final event in all) {
      for (final hYear in [currentHijri.year, currentHijri.year + 1]) {
        final date = HijriCalendar.toGregorian(hYear, event.hijriMonth, event.hijriDay);
        final dateOnly = DateTime(date.year, date.month, date.day);
        final diff = dateOnly.difference(today).inDays;
        if (diff >= 0) {
          candidates.add(UpcomingEvent(event: event, date: dateOnly, daysUntil: diff));
          break;
        }
      }
    }

    candidates.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    if (candidates.length > limit) {
      return candidates.sublist(0, limit);
    }
    return candidates;
  }
}
