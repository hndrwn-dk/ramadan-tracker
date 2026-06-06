# Rancangan: Sunnah Fasting, Qadha/Fidyah, Puasa Syawal, Hijri/Islamic Events & Shareable Report

Status: Draft / proposal. Belum diimplementasi.
Tujuan dokumen: blueprint teknis untuk 5 fitur pertumbuhan (growth) yang mengubah app dari "tool 30 hari" jadi "companion sepanjang tahun", tanpa server (semua di device).

---

## 0. Masalah inti & strategi

Saat ini **semua fitur terikat pada `RamadanSeason`** (lihat `lib/data/database/tables.dart`). Setiap data harian disimpan dengan primary key `(seasonId, dayIndex, habitId)` di tabel `DailyEntries`. Artinya: kalau tidak ada musim aktif, app praktis "mati" ~11 bulan/tahun.

Lima fitur di bawah punya satu benang merah: **butuh lapisan tracking berbasis tanggal (Gregorian date) yang TIDAK bergantung pada season.** Maka rancangan ini menambahkan:

1. **Hijri calendar utility** (fondasi untuk Ayyamul Bidh, Syawal, Arafah, Asyura, events).
2. **Date-based fasting store** (`SunnahFasts`) lepas dari `seasonId`.
3. **Qadha/Fidyah ledger** (utang & bayar puasa Ramadan).
4. **Sunnah fasting calendar engine** (menentukan jenis sunnah untuk tanggal apa pun).
5. **Share-as-image** util (report card).

Urutan implementasi yang disarankan (tiap fase berdiri sendiri & bisa rilis):
- **Fase 1:** Hijri util + Date-based store + Puasa Senin-Kamis (core).
- **Fase 2:** Qadha/Fidyah tracker.
- **Fase 3:** Puasa Syawal (bridge tepat setelah Ramadan).
- **Fase 4:** Hijri date + Islamic events (in-app) + home screen widget.
- **Fase 5:** Shareable report card.

---

## 1. Fondasi A — Hijri Calendar Utility

### 1.1 Kebutuhan
Dipakai oleh: Ayyamul Bidh (13/14/15 Hijri), Syawal (bulan 10), Arafah (9 Dzulhijjah), Asyura/Tasua (10/9 Muharram), Nisfu Sya'ban (15 Sya'ban), dan daftar Islamic events.

### 1.2 Pendekatan
Tambah util murni (pure functions), tanpa dependency jaringan:
- Opsi A (disarankan, ringan): algoritma **tabular/aritmetika Umm al-Qura** atau Kuwaiti algorithm untuk `gregorianToHijri(DateTime)` dan `hijriToGregorian(int hy, int hm, int hd)`.
- Opsi B: pakai package (mis. `hijri`) bila ingin cepat. Trade-off: dependency tambahan; akurasi tetap aproksimasi.

Akurasi bersifat aproksimasi (hilal aktual bisa beda 1 hari). Karena itu setiap tanggal sunnah otomatis **boleh digeser manual** oleh user (lihat 2.5).

### 1.3 Lokasi
- `lib/utils/hijri_calendar.dart` (baru). Selaras dengan `lib/utils/ramadan_dates.dart` yang sudah ada (extend, bukan ganti — `RamadanDates` tetap dipakai untuk reminder Ramadan).

```dart
class HijriDate {
  final int year, month, day; // month 1..12 (1=Muharram, 9=Ramadan, 10=Syawal, 12=Dzulhijjah)
  const HijriDate(this.year, this.month, this.day);
}

class HijriCalendar {
  static HijriDate fromGregorian(DateTime date); // date-only
  static DateTime toGregorian(int hy, int hm, int hd);
  static String monthNameId(int hm); // "Muharram", "Syawal", ...
}
```

---

## 2. Fondasi B + Fitur 1 — Sunnah Fasting (year-round)

### 2.1 Konsep data (lepas dari season)
Tabel baru, **keyed by tanggal Gregorian**, bukan `(seasonId, dayIndex)`:

```dart
class SunnahFasts extends Table {
  TextColumn get dateYmd => text()();          // 'YYYY-MM-DD' (local date)
  IntColumn  get status  => integer()();        // reuse FastingStatus: 0 notDone, 1 fasted, 2..5 excused
  TextColumn get type    => text().nullable()(); // 'senin','kamis','ayyamul_bidh','syawal','arafah','asyura','tasua','daud','syaban','qadha','custom'
  BoolColumn get isQadha => boolean().withDefault(const Constant(false))(); // tandai sbg pengganti Ramadan
  TextColumn get note    => text().nullable()();
  IntColumn  get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {dateYmd};
}
```

Catatan desain:
- **Reuse `FastingStatus`** (`lib/utils/fasting_status.dart`) apa adanya untuk `status` (termasuk excused haid/nifas/sick). Tidak perlu enum baru.
- `type` boleh multi-label di UI, tapi storage cukup satu tanggal = satu record. Jenis sunnah utama untuk tanggal itu ditentukan engine (2.3); `type` di sini menyimpan "niat utama" user.
- Satu record per hari; kalau user batal, set `status = notDone` (atau hapus row).

### 2.2 DAO & provider
- `SunnahFastsDao` (pola sama seperti DAO lain di `lib/data/database/daos.dart`): `upsert`, `getByDate`, `getRange(start,end)`, `getStreak()`.
- Riverpod provider: `sunnahFastsProvider` (range bulan berjalan) + `sunnahStreakProvider`.

### 2.3 Sunnah Fasting Calendar Engine
Pure function: untuk tanggal apa pun, kembalikan daftar jenis sunnah + flag hari terlarang.

```dart
enum SunnahType { seninKamis, ayyamulBidh, syawal, arafah, asyura, tasua, syaban, daud }

class SunnahFastingRules {
  // Jenis sunnah yang berlaku pada tanggal ini (berdasar weekday + Hijri).
  static List<SunnahType> typesFor(DateTime date);
  // Hari DILARANG puasa: Idul Fitri (1 Syawal), Idul Adha (10 Dzulhijjah), Tasyriq (11-13 Dzulhijjah).
  static bool isForbidden(DateTime date);
}
```

Aturan:
| Sunnah | Penentu |
|--------|---------|
| Senin-Kamis | `weekday == DateTime.monday || weekday == DateTime.thursday` |
| Ayyamul Bidh | Hijri day in {13,14,15} (skip jika jatuh di hari terlarang) |
| Syawal | Hijri month == 10, hari ke-2..akhir (1 Syawal = Idul Fitri, terlarang) |
| Arafah | Hijri 9 Dzulhijjah |
| Tasua / Asyura | Hijri 9 / 10 Muharram |
| Sya'ban | Hijri month == 8 |
| Daud | selang-seling (pola dihitung dari log user, bukan kalender) |

### 2.4 UI
- **Today / Home card:** kalau `typesFor(today)` tidak kosong dan bukan musim Ramadan aktif → tampilkan kartu "Hari ini Senin — puasa sunnah?" dengan toggle status (reuse pola `fasting_status.dart`).
- **Sunnah tab/section baru** atau sub-screen "Puasa Sunnah": kalender bulanan yang highlight hari-hari sunnah (warna per jenis), tap hari → bottom sheet set status + note (reuse pola `day_summary_bottom_sheet.dart`).
- **Streak & stats:** "Senin-Kamis streak: 12 minggu", total hari puasa sunnah tahun ini. Reuse style insights cards.

### 2.5 Reminder
- Base ID baru: **`_baseIdSunnah = 7000000`** (lihat 7).
- Senin-Kamis: notifikasi **Minggu malam** & **Rabu malam** (mis. 20:00 lokal): "Besok puasa Senin/Kamis?".
- Ayyamul Bidh: malam sebelum hari ke-13.
- Arafah / Asyura: malam sebelumnya.
- Toggle on/off per jenis di Settings. Reuse infra `zonedSchedule` + timezone yang sudah ada di `NotificationService`.

---

## 3. Fitur 2 — Qadha & Fidyah Tracker

### 3.1 Konsep
- **Qadha**: utang puasa Ramadan yang wajib diganti (karena haid, nifas, sakit, safar, dll.).
- **Fidyah**: pembayaran (mis. memberi makan fakir miskin) bagi yang tidak mampu mengganti (lansia, sakit menahun, sebagian pendapat: hamil/menyusui).

### 3.2 Data
Ledger sederhana (debit/kredit) supaya transparan & auditable:

```dart
class QadhaLedger extends Table {
  IntColumn  get id        => integer().autoIncrement()();
  TextColumn get kind      => text()();          // 'qadha' | 'fidyah'
  TextColumn get direction => text()();          // 'owed' (nambah utang) | 'paid' (bayar/ganti)
  IntColumn  get days      => integer().withDefault(const Constant(0))(); // jumlah hari (qadha) atau hari yg difidyah
  IntColumn  get amount    => integer().withDefault(const Constant(0))(); // nominal fidyah (mata uang lokal)
  TextColumn get dateYmd   => text().nullable()();
  IntColumn  get sourceSeasonId => integer().nullable()(); // asal utang (Ramadan tahun X)
  TextColumn get note      => text().nullable()();
  IntColumn  get createdAt => integer()();
}
```

Saldo dihitung: `owed - paid` (per kind).

### 3.3 Auto-seed dari Ramadan
Saat sebuah `RamadanSeason` berakhir (atau saat user buka app pasca-musim), hitung hari fasting yang **missed/excused** dari `DailyEntries` (pakai `FastingStatus.isExcused`/notDone untuk habit `fasting`). Tawarkan: "Kamu punya N hari puasa yang perlu diganti. Tambahkan ke Qadha?" → buat entri `owed` dengan `sourceSeasonId`.

### 3.4 Integrasi dengan Sunnah store
Saat user log puasa di hari non-Ramadan dan menandai **isQadha = true** (2.1), otomatis buat entri ledger `direction='paid', days=1, kind='qadha'`. Saldo qadha berkurang. Ini menyatukan "puasa hari ini" dengan "bayar utang".

### 3.5 Fidyah calculator
- Input: jumlah hari × tarif per hari (1 mud makanan pokok, dikonversi ke mata uang lokal; nilai default editable di Settings).
- Output: total + tombol "Tandai sudah dibayar" → entri `kind='fidyah', direction='paid', amount=...`.

### 3.6 UI
- Screen "Qadha & Fidyah" (entry dari Settings atau tab Sunnah): kartu saldo (Owed: X hari, Paid: Y, **Sisa: Z**), tombol +Owed / +Paid, kalkulator fidyah, riwayat ledger.

---

## 4. Fitur 3 — Puasa Syawal (retention bridge)

Secara teknis ini **subset dari Sunnah store** (`type='syawal'`), tapi diberi UX khusus karena timing-nya emas: tepat saat Ramadan selesai dan app biasanya mulai sepi.

### 4.1 Trigger
- Deteksi `RamadanSeason` aktif berakhir (hari setelah `startDate + days`). Karena hari ke-1 Syawal = Idul Fitri (terlarang puasa), tawarkan mulai dari hari ke-2 Syawal.
- Tampilkan kartu di Home: "Sempurnakan Ramadanmu — Puasa 6 hari Syawal" + progress.

### 4.2 Tracker
- Mini-challenge: 6 slot. Tiap hari user puasa di bulan Syawal dengan `type='syawal'` menambah progress (1/6 ... 6/6).
- Progress ring + sisa waktu sampai akhir Syawal (pakai Hijri util untuk akhir bulan 10).
- Tidak harus berturut-turut (sesuai pendapat umum).

### 4.3 Reminder
- 1 notifikasi hari ke-2 Syawal: "Yuk mulai puasa Syawal".
- Reminder lanjutan reuse mekanisme Senin-Kamis selama bulan Syawal (opsional).

---

## 5. Fitur 4 — Hijri Date + Islamic Events + Home Screen Widget

### 5.1 In-app: Hijri date
- Tampilkan tanggal Hijri di header Today/Home (mis. "15 Ramadan 1448 H") via `HijriCalendar.fromGregorian(today)`.

### 5.2 Islamic events
- Daftar event + countdown, dihitung dari Hijri util:
  - 1 Ramadan, Idul Fitri (1 Syawal), Hari Arafah (9 Dzulhijjah), Idul Adha (10 Dzulhijjah), Tahun Baru Hijriah (1 Muharram), Asyura (10 Muharram), Maulid (12 Rabiul Awwal), Isra Mi'raj (27 Rajab), Nisfu Sya'ban (15 Sya'ban).
- UI: list "Acara Islam berikutnya" dengan badge "X hari lagi". Sumber tunggal: util, tanpa data hard-code per tahun (kecuali Ramadan yang sudah ada di `RamadanDates`).

### 5.3 Home screen widget (Android)
Ini **pendorong utama buka-app harian**. Butuh native widget.
- Package: `home_widget` (tambah ke `pubspec.yaml`). iOS off (proyek saat ini `ios: false` di launcher icons).
- Isi widget: tanggal Hijri hari ini + "Hari ini: Senin (puasa sunnah)" / event terdekat + (opsional) countdown Maghrib/Subuh dari `PrayerTimeService` yang sudah ada.
- Update: saat app foreground & via background callback harian. Tap widget → buka app (opsi deep link ke Sunnah/Today).
- Catatan: butuh layout XML native Android + provider; dokumen implementasi terpisah saat fase 4.

---

## 6. Fitur 5 — Shareable Report Card (organic growth)

### 6.1 Tujuan
Word-of-mouth: user share ringkasan musim / streak sunnah sebagai **gambar** ke WhatsApp/IG/Telegram.

### 6.2 Implementasi
- Tidak perlu dependency baru: `share_plus` + `path_provider` **sudah ada** di `pubspec.yaml`.
- Bungkus widget kartu dalam `RepaintBoundary`, render ke image:

```dart
final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
final image = await boundary.toImage(pixelRatio: 3.0);
final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
// tulis ke temp dir (path_provider) lalu:
await Share.shareXFiles([XFile(path)]);
```

### 6.3 Sumber data
- Reuse `SeasonReportScreen` / `insightsDataProvider` (`lib/features/insights/...`) untuk angka: hari puasa, halaman Quran, skor, streak, sedekah.
- Variasi kartu:
  - **Season Report Card** (akhir Ramadan): nama musim + statistik utama + skor.
  - **Sunnah Streak Card**: "Senin-Kamis 12 minggu" / total puasa sunnah tahun ini.
- Desain kartu: branding app (nama + ikon) di pojok supaya share = promosi.

### 6.4 UI
- Tombol "Bagikan" (share) di `SeasonReportScreen` (app bar) dan di Sunnah stats. Preview kartu → share.

---

## 7. Notifikasi: alokasi ID (hindari bentrok)

Base ID existing di `NotificationService` (`lib/domain/services/notification_service.dart`):

| Base ID | Dipakai |
|---------|---------|
| 1.000.000 | Sahur |
| 2.000.000 | Iftar |
| 3.000.000 | Night plan |
| 4.000.000 | Habit reminder |
| 5.000.000 | Goal |
| 6.000.000 | Next Ramadan reminder |
| **7.000.000** | **Sunnah fasting (BARU)** — Senin-Kamis, Ayyamul Bidh, Arafah, Asyura, Syawal |
| **8.000.000** | **Qadha/Fidyah reminder (opsional, BARU)** |

Pola ID per-tanggal: `baseId + yyyymmdd` (konsisten dengan `_getNotificationId`). Jadwalkan di `rescheduleAllReminders` setelah reminder existing.

---

## 8. Database: migrasi

`AppDatabase.schemaVersion` saat ini **5** (`lib/data/database/app_database.dart`). Naikkan ke **6**:

```dart
if (from < 6) {
  await migrator.createTable(sunnahFasts);
  await migrator.createTable(qadhaLedger);
}
```

- Tambah `SunnahFasts` & `QadhaLedger` ke list `@DriftDatabase(tables: [...])` + DAO-nya.
- Backup/restore: pastikan export/import (fitur backup lokal yang sudah ada) menyertakan 2 tabel baru.

---

## 9. Lokasi di codebase (ringkas)

| Item | Lokasi |
|------|--------|
| Hijri util | `lib/utils/hijri_calendar.dart` (baru) |
| Sunnah rules engine | `lib/utils/sunnah_fasting_rules.dart` (baru) |
| Tabel baru | `lib/data/database/tables.dart` (+ DAO di `daos.dart`) |
| Migrasi v6 | `lib/data/database/app_database.dart` |
| Providers | `lib/data/providers/sunnah_fasts_provider.dart`, `qadha_provider.dart` (baru) |
| Sunnah UI | `lib/features/sunnah/...` (baru) |
| Qadha/Fidyah UI | `lib/features/qadha/...` (baru) atau di Settings |
| Reminder | `NotificationService` (+ base ID 7M/8M) |
| Hijri date + events | `lib/features/today/...` (header) + screen events baru |
| Home widget | `home_widget` package + native Android (fase 4) |
| Share image | util baru `lib/utils/share_card.dart` + tombol di `SeasonReportScreen` |
| L10n | `app_en.arb` / `app_id.arb` (+ generate) untuk semua copy baru |

---

## 10. Dampak vs effort (ringkas)

| Fitur | Dampak growth | Effort | Ketergantungan |
|-------|---------------|--------|----------------|
| Sunnah Senin-Kamis (Fase 1) | Tinggi | Sedang | Hijri util, date store |
| Qadha/Fidyah (Fase 2) | Tinggi | Rendah | date store, FastingStatus |
| Puasa Syawal (Fase 3) | Tinggi | Rendah | Sunnah store (subset) |
| Hijri + events + widget (Fase 4) | Sedang-Tinggi | Sedang-Tinggi | Hijri util, native widget |
| Shareable report (Fase 5) | Sedang | Rendah | share_plus (sudah ada) |

Rekomendasi mulai: **Fase 1 + Fase 2** (nilai tertinggi, reuse model `FastingStatus`, mengubah app jadi companion harian).

---

## 11. Catatan akurasi & adab

- Tanggal Hijri = aproksimasi; selalu izinkan **override manual** + disclaimer kecil ("Perkiraan; ikuti pengumuman setempat").
- Hari terlarang puasa (Idul Fitri, Idul Adha, Tasyriq) **wajib** di-handle engine: jangan tawarkan toggle puasa di hari itu.
- Fidyah/qadha menyangkut fikih: sediakan teks netral + saran "konsultasikan dengan ustadz/otoritas setempat" untuk kasus khusus (hamil/menyusui).
