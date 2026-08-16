import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/services/prayer_time_service.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/aladhan_client.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/myquran_client.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/myquran_parser.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_http.dart';
import 'package:ramadan_tracker/domain/services/prayer_times/prayer_time_source.dart';

class PrayerTimeSyncService {
  PrayerTimeSyncService({
    PrayerHttpGet? get,
    AladhanClient? aladhanClient,
    MyQuranClient? myQuranClient,
  })  : aladhanClient = aladhanClient ?? AladhanClient(get: get),
        myQuranClient = myQuranClient ?? MyQuranClient(get: get);

  static const lastSyncedKey = 'prayer_times_last_synced_at';
  static const sourceKey = 'prayer_time_source';
  static const myquranCityIdKey = 'prayer_myquran_city_id';
  static const myquranCityNameKey = 'prayer_myquran_city_name';
  static const myquranVersionKey = 'prayer_myquran_source_version';

  final AladhanClient aladhanClient;
  final MyQuranClient myQuranClient;

  Future<int> syncMonth({
    required AppDatabase database,
    required int seasonId,
    required DateTime month,
    required double latitude,
    required double longitude,
    required String timezone,
    required String method,
    required String locale,
    int fajrAdjust = 0,
    int maghribAdjust = 0,
  }) async {
    final preference = PrayerTimeSourceKindCodec.parse(
      await database.kvSettingsDao.getValue(sourceKey),
    );
    if (preference == PrayerTimeSourceKind.local) return 0;

    final rawCityId = await database.kvSettingsDao.getValue(myquranCityIdKey);
    final cityId = MyQuranParser.isV3CityId(rawCityId) ? rawCityId : null;
    final effective = PrayerTimeSourceResolver.resolve(
      preference: preference,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      locale: locale,
      method: method,
      myquranCityId: cityId,
    );
    if (effective == PrayerTimeSourceKind.local) return 0;

    List<RemotePrayerDay> days = const [];
    String source = 'aladhan';
    String? sourceRef;

    if (effective == PrayerTimeSourceKind.myquran &&
        cityId != null &&
        cityId.isNotEmpty) {
      days = await myQuranClient.fetchMonth(
        cityId: cityId,
        year: month.year,
        month: month.month,
        timezone: timezone,
      );
      source = 'myquran';
      sourceRef = cityId;
      await database.kvSettingsDao.setValue(
        myquranVersionKey,
        MyQuranParser.sourceVersion,
      );
    } else {
      days = await aladhanClient.fetchMonth(
        latitude: latitude,
        longitude: longitude,
        year: month.year,
        month: month.month,
        method: method,
      );
      source = 'aladhan';
      sourceRef = AladhanClient.methodIdFor(method).toString();
    }

    if (days.isEmpty) return 0;

    final now = DateTime.now().millisecondsSinceEpoch;
    for (final day in days) {
      final dateParts = day.dateYyyyMmDd.split('-');
      if (dateParts.length != 3) continue;
      final date = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        int.parse(dateParts[2]),
      );
      var fajr = day.fajrUtc.toUtc().add(Duration(minutes: fajrAdjust));
      var maghrib = day.maghribUtc.toUtc().add(Duration(minutes: maghribAdjust));
      final offset = day.utcOffsetMinutes ??
          PrayerTimeService.utcOffsetForDate(timezone: timezone, date: date)
              .inMinutes;
      await database.prayerTimesCacheDao.cacheTime(
        PrayerTimesCacheData(
          seasonId: seasonId,
          dateYyyyMmDd: day.dateYyyyMmDd,
          fajrIso: fajr.toIso8601String(),
          maghribIso: maghrib.toIso8601String(),
          method: method,
          lat: latitude,
          lon: longitude,
          timezone: timezone,
          fajrAdj: fajrAdjust,
          maghribAdj: maghribAdjust,
          utcOffsetMinutes: offset,
          source: source,
          sourceRef: sourceRef,
          fetchedAt: now,
          updatedAt: now,
        ),
      );
    }
    await database.kvSettingsDao.setValue(lastSyncedKey, now.toString());
    return days.length;
  }
}
