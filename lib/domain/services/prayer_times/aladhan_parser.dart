import 'dart:convert';

import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';

class AladhanParser {
  static List<RemotePrayerDay> parseCalendar(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final data = decoded['data'];
    if (data is! List) return const [];
    final days = <RemotePrayerDay>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = _parseDay(item);
      if (parsed != null) days.add(parsed);
    }
    return days;
  }

  static RemotePrayerDay? _parseDay(Map<String, dynamic> item) {
    final timings = item['timings'];
    if (timings is! Map<String, dynamic>) return null;
    final fajrRaw = timings['Fajr']?.toString();
    final maghribRaw = timings['Maghrib']?.toString();
    if (fajrRaw == null || maghribRaw == null) return null;
    final fajrIso = _stripParenthetical(fajrRaw);
    final maghribIso = _stripParenthetical(maghribRaw);
    final fajr = DateTime.tryParse(fajrIso);
    final maghrib = DateTime.tryParse(maghribIso);
    if (fajr == null || maghrib == null) return null;
    final dateYyyyMmDd = _gregorianYyyyMmDd(item) ?? fajrIso.substring(0, 10);
    return RemotePrayerDay(
      dateYyyyMmDd: dateYyyyMmDd,
      fajrUtc: fajr.toUtc(),
      maghribUtc: maghrib.toUtc(),
      utcOffsetMinutes: offsetMinutesFromIso(fajrIso),
    );
  }

  static String _stripParenthetical(String raw) {
    final idx = raw.indexOf(' (');
    return idx >= 0 ? raw.substring(0, idx).trim() : raw.trim();
  }

  static String? _gregorianYyyyMmDd(Map<String, dynamic> item) {
    final date = item['date'];
    if (date is! Map<String, dynamic>) return null;
    final gregorian = date['gregorian'];
    if (gregorian is! Map<String, dynamic>) return null;
    final raw = gregorian['date']?.toString();
    if (raw == null) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    if (parts[0].length == 4) {
      return '${parts[0]}-${parts[1].padLeft(2, '0')}-${parts[2].padLeft(2, '0')}';
    }
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  static int? offsetMinutesFromIso(String iso) {
    final match = RegExp(r'([+-])(\d{2}):(\d{2})$').firstMatch(iso);
    if (match == null) return null;
    final sign = match.group(1) == '-' ? -1 : 1;
    return sign *
        (int.parse(match.group(2)!) * 60 + int.parse(match.group(3)!));
  }
}
