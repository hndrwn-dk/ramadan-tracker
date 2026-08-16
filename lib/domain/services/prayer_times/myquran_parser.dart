import 'dart:convert';

import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_models.dart';
import 'package:timezone/timezone.dart' as tz;

class MyQuranParser {
  static const sourceVersion = 'v3';

  static List<MyQuranCity> parseSearch(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final data = decoded['data'];
    if (data is! List) return const [];
    final cities = <MyQuranCity>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id']?.toString();
      final name = item['lokasi']?.toString();
      if (id == null || name == null || id.isEmpty) continue;
      cities.add(MyQuranCity(id: id, name: name));
    }
    return cities;
  }

  /// Only an exact lokasi match (case-insensitive) is accepted.
  /// A bare keyword that matches multiple cities must not pick an id.
  static MyQuranCity? pickVerified(List<MyQuranCity> cities, String query) {
    final needle = _normalize(query);
    if (needle.isEmpty) return null;
    final exact = cities.where((c) => _normalize(c.name) == needle).toList();
    if (exact.length == 1) return exact.single;
    return null;
  }

  static List<RemotePrayerDay> parseMonthly(
    String body, {
    required String timezone,
  }) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final data = decoded['data'];
    if (data is! Map<String, dynamic>) return const [];
    final jadwal = data['jadwal'];
    if (jadwal is! Map) return const [];
    final days = <RemotePrayerDay>[];
    for (final entry in jadwal.entries) {
      final dateKey = entry.key.toString();
      final value = entry.value;
      if (value is! Map) continue;
      final map = Map<String, dynamic>.from(value);
      final subuh = map['subuh']?.toString();
      final maghrib = map['maghrib']?.toString();
      if (subuh == null || maghrib == null) continue;
      final date = DateTime.tryParse(dateKey);
      if (date == null) continue;
      days.add(
        RemotePrayerDay(
          dateYyyyMmDd: dateKey,
          fajrUtc: hhMmToUtc(subuh, date, timezone),
          maghribUtc: hhMmToUtc(maghrib, date, timezone),
          utcOffsetMinutes: tz
              .TZDateTime(tz.getLocation(timezone), date.year, date.month, date.day)
              .timeZoneOffset
              .inMinutes,
        ),
      );
    }
    return days;
  }

  static DateTime hhMmToUtc(String hhmm, DateTime date, String timezone) {
    final parts = hhmm.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final location = tz.getLocation(timezone);
    return tz
        .TZDateTime(location, date.year, date.month, date.day, hour, minute)
        .toUtc();
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isV3CityId(String? id) {
    if (id == null || id.isEmpty) return false;
    return RegExp(r'^[a-fA-F0-9]{32}$').hasMatch(id);
  }
}
