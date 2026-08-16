class RemotePrayerDay {
  const RemotePrayerDay({
    required this.dateYyyyMmDd,
    required this.fajrUtc,
    required this.maghribUtc,
    this.utcOffsetMinutes,
  });

  final String dateYyyyMmDd;
  final DateTime fajrUtc;
  final DateTime maghribUtc;
  final int? utcOffsetMinutes;
}

class MyQuranCity {
  const MyQuranCity({required this.id, required this.name});

  final String id;
  final String name;
}

enum PrayerTimeSourceKind {
  local,
  aladhan,
  myquran,
  auto,
}

class PrayerTimeSourceKindCodec {
  static PrayerTimeSourceKind parse(String? raw) {
    switch ((raw ?? 'auto').toLowerCase()) {
      case 'local':
        return PrayerTimeSourceKind.local;
      case 'aladhan':
        return PrayerTimeSourceKind.aladhan;
      case 'myquran':
        return PrayerTimeSourceKind.myquran;
      default:
        return PrayerTimeSourceKind.auto;
    }
  }

  static String encode(PrayerTimeSourceKind kind) {
    switch (kind) {
      case PrayerTimeSourceKind.local:
        return 'local';
      case PrayerTimeSourceKind.aladhan:
        return 'aladhan';
      case PrayerTimeSourceKind.myquran:
        return 'myquran';
      case PrayerTimeSourceKind.auto:
        return 'auto';
    }
  }
}
