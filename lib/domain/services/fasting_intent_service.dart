import 'dart:convert';

import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/utils/fasting_status.dart';

/// Stored imsak intention until iftar confirmation (KV only for pending fast).
class FastingIntentRecord {
  final int status;
  final String? note;
  final DateTime recordedAt;

  const FastingIntentRecord({
    required this.status,
    this.note,
    required this.recordedAt,
  });

  Map<String, dynamic> toJson() => {
        'status': status,
        if (note != null && note!.isNotEmpty) 'note': note,
        'at': recordedAt.toIso8601String(),
      };

  factory FastingIntentRecord.fromJson(Map<String, dynamic> json) {
    return FastingIntentRecord(
      status: json['status'] as int,
      note: json['note'] as String?,
      recordedAt: DateTime.parse(json['at'] as String),
    );
  }
}

/// Persists imsak intentions and applies iftar confirmations.
class FastingIntentService {
  FastingIntentService._();

  static String ramadanKey(int seasonId, int dayIndex) =>
      'fast_intent_ramadan_${seasonId}_$dayIndex';

  static String sunnahKey(DateTime date) =>
      'fast_intent_sunnah_${_dateKey(date)}';

  static String _dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<FastingIntentRecord?> getRamadanIntent(
    AppDatabase database, {
    required int seasonId,
    required int dayIndex,
  }) async {
    return _read(database, ramadanKey(seasonId, dayIndex));
  }

  static Future<FastingIntentRecord?> getSunnahIntent(
    AppDatabase database, {
    required DateTime date,
  }) async {
    return _read(database, sunnahKey(date));
  }

  static Future<void> setRamadanIntent(
    AppDatabase database, {
    required int seasonId,
    required int dayIndex,
    required int status,
    String? note,
  }) async {
    if (status == FastingStatus.intentPendingFast) {
      await _write(
        database,
        ramadanKey(seasonId, dayIndex),
        FastingIntentRecord(
          status: status,
          note: note,
          recordedAt: DateTime.now(),
        ),
      );
      return;
    }
    await clearRamadanIntent(database, seasonId: seasonId, dayIndex: dayIndex);
  }

  static Future<void> setSunnahIntent(
    AppDatabase database, {
    required DateTime date,
    required int status,
    String? note,
  }) async {
    if (status == FastingStatus.intentPendingFast) {
      await _write(
        database,
        sunnahKey(date),
        FastingIntentRecord(
          status: status,
          note: note,
          recordedAt: DateTime.now(),
        ),
      );
      return;
    }
    await clearSunnahIntent(database, date: date);
  }

  static Future<void> clearRamadanIntent(
    AppDatabase database, {
    required int seasonId,
    required int dayIndex,
  }) async {
    await database.kvSettingsDao.deleteValue(ramadanKey(seasonId, dayIndex));
  }

  static Future<void> clearSunnahIntent(
    AppDatabase database, {
    required DateTime date,
  }) async {
    await database.kvSettingsDao.deleteValue(sunnahKey(date));
  }

  static Future<bool> hasPendingRamadanIntent(
    AppDatabase database, {
    required int seasonId,
    required int dayIndex,
  }) async {
    final intent = await getRamadanIntent(
      database,
      seasonId: seasonId,
      dayIndex: dayIndex,
    );
    return intent?.status == FastingStatus.intentPendingFast;
  }

  static Future<bool> hasPendingSunnahIntent(
    AppDatabase database, {
    required DateTime date,
  }) async {
    final intent = await getSunnahIntent(database, date: date);
    return intent?.status == FastingStatus.intentPendingFast;
  }

  static Future<FastingIntentRecord?> _read(AppDatabase database, String key) async {
    final raw = await database.kvSettingsDao.getValue(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return FastingIntentRecord.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(
    AppDatabase database,
    String key,
    FastingIntentRecord record,
  ) async {
    await database.kvSettingsDao.setValue(key, jsonEncode(record.toJson()));
  }
}
