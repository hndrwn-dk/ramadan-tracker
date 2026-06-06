# Rancangan: Pengingat "Ramadan Tahun Depan" (Next Ramadan Reminder)

## 1. Tujuan

Agar user tidak lupa membuka app setelah Ramadan selesai: app mengirim **satu notifikasi lokal** beberapa minggu sebelum Ramadan tahun depan (2027, 2028, dst.) dengan ajakan buka app dan buat musim baru. Tanpa server; semua di device.

---

## 2. Kapan notifikasi dijadwalkan

| Trigger | Tindakan |
|--------|----------|
| **Saat app startup** (setelah `rescheduleAllReminders` selesai atau terpisah) | Cek apakah perlu jadwalkan "next Ramadan reminder" untuk tahun yang belum punya reminder. |
| **Opsi tambahan: saat musim disimpan** (onboarding selesai / Create Season selesai) | Setelah season tersimpan, panggil logic yang sama: ensure reminder untuk tahun-tahun depan terjadwalkan. |

Rekomendasi: **cukup di app startup**. Setiap kali user buka app, kita pastikan notifikasi "Ramadan 20XX" untuk tahun-tahun yang relevan sudah terjadwalkan (dan belum lewat). Tidak perlu trigger khusus saat simpan musim.

---

## 3. Kapan notifikasi dikirim (fire date)

- **Offset:** **7 hari** sebelum tanggal mulai Ramadan tahun tersebut (konstanta `daysBeforeRamadan = 7`).
- **Waktu:** Jam **09:00 waktu lokal device**.

Contoh:
- Ramadan 2027 (start 8 Feb 2027) → notifikasi dijadwalkan **1 Feb 2027 09:00** (7 hari sebelum).
- Ramadan 2028 (start 28 Jan 2028) → notifikasi **21 Jan 2028 09:00**.

---

## 4. Sumber tanggal mulai Ramadan (Gregorian)

Pakai **tabel lookup** per tahun Gregorian. Tanggal berdasarkan kalender Umm al-Qura / perhitungan umum (bisa disesuaikan).

| Tahun | Tanggal mulai Ramadan (perkiraan) |
|-------|-----------------------------------|
| 2025  | 2025-03-01 |
| 2026  | 2026-02-18 |
| 2027  | 2027-02-08 |
| 2028  | 2028-01-28 |
| 2029  | 2029-01-16 |
| 2030  | 2030-01-06 |
| 2031  | 2030-12-26 (akhir Des) |
| 2032  | 2031-12-16 |
| 2033  | 2032-12-05 |
| 2034  | 2033-11-24 |
| 2035  | 2034-11-14 |

Implementasi: map `int year` → `DateTime(year, month, day)`. Untuk tahun di luar tabel (e.g. 2036+), bisa hitung aproksimasi (Hijri ~354 hari/tahun) atau skip (user tetap bisa buat musim manual).

---

## 5. Siapa yang dapat reminder

- Jadwalkan reminder hanya untuk **tahun di mana tanggal fire (Ramadan start − 7 hari) masih di masa depan**.
- **Skip** tahun di mana user **sudah punya musim** yang overlap dengan Ramadan tahun itu (mis. season.startDate tahun 2027 → tidak perlu reminder "Ramadan 2027").
- **Satu notifikasi per tahun**: maksimal satu reminder per Ramadan (e.g. 2027, 2028). ID notifikasi per tahun (lihat bawah).

---

## 6. ID notifikasi & bentrok dengan reminder lain

- Base ID khusus agar tidak bentrok dengan Sahur/Iftar/Goal/Night Plan: gunakan **6.000.000** (enam juta).
- **Tidak bentrok:** reminder ini keluar **sebelum** Ramadan (7 hari sebelum start). Sahur/Iftar/Goal dijadwalkan **selama** musim (tanggal di dalam season). Jadi jangka waktunya beda; ID juga beda (1M–5M vs 6M). Aman pakai 7 hari.
- Format: `6000000 + year` (e.g. 6002027 untuk Ramadan 2027).
- Jadi ID unik per tahun; saat reschedule kita replace by ID yang sama.

---

## 7. Isi notifikasi (copy)

**English**
- Title: `Ramadan [year] is coming`
- Body: `Open the app to create your new season and start tracking.`

**Indonesian**
- Title: `Ramadan [tahun] sebentar lagi`
- Body: `Buka app untuk buat musim baru dan mulai tracking.`

L10n: tambah 2 string (title + body) dengan parameter tahun, atau 2 string tanpa parameter dan isi tahun di body.

---

## 8. Tap action

- **Default:** Tap notifikasi → buka app (launch app). Tidak wajib deep link.
- **Opsi nanti:** Deep link ke Settings > My Ramadan atau langsung ke flow "Buat musim baru" (CreateSeasonFlow). Bisa fase 2.

---

## 9. Alur logic (pseudocode)

```
on App Startup (setelah reschedule biasa):
  timezone = baca prayer_timezone dari DB ATAU device local
  now = today (date only)

  for year in [next_ramadan_year .. next_ramadan_year + 5]:  // e.g. 2027..2032
    ramadan_start = lookup_ramadan_start(year)
    fire_date = ramadan_start - 7 days, at 09:00 (local)
    if fire_date <= now: continue  // sudah lewat, skip
    if user already has season for this ramadan (startDate in that year): continue

    schedule_notification(
      id: 6000000 + year,
      title: l10n.nextRamadanReminderTitle(year),
      body: l10n.nextRamadanReminderBody(year),
      scheduled: fire_date 09:00 in timezone
    )
```

- **next_ramadan_year**: tahun Gregorian dari Ramadan "berikutnya" yang belum lewat. Contoh: hari ini Juni 2026 → next = 2027; hari ini Maret 2027 → next = 2028.
- Cek "user already has season for this ramadan": ambil semua season dari DB, lihat `startDate`; jika ada season yang startDate-nya di tahun yang sama dengan `ramadan_start` (atau overlap dengan bulan Ramadan), anggap user sudah punya musim untuk tahun itu → skip.

---

## 10. Edge cases

| Kasus | Perilaku |
|-------|----------|
| User belum punya musim sama sekali | Tetap jadwalkan reminder untuk tahun-tahun depan (2027, 2028, ...). |
| User sudah buat musim 2027 | Jangan kirim reminder untuk 2027; tetap jadwalkan 2028, 2029, ... |
| Tanggal fire sudah lewat | Jangan jadwalkan untuk tahun itu. |
| App pertama kali install (belum ada season) | Tetap jadwalkan reminder 2027, 2028, ... supaya user diingatkan. |
| Banyak musim (e.g. 2025, 2026, 2027) | Cek setiap tahun: kalau ada musim yang overlap Ramadan tahun itu, skip tahun itu. |
| Device timezone berubah | Notifikasi sudah dijadwalkan dengan TZ saat jadwal; jika user pindah timezone, next startup akan reschedule (bisa tambah logic cancel + reschedule jika perlu; fase 1 cukup jadwalkan sekali per tahun). |

---

## 11. Lokasi di codebase

| Item | Lokasi |
|------|--------|
| Lookup tabel Ramadan start | Util baru, e.g. `lib/utils/ramadan_dates.dart` (pure function `DateTime? getRamadanStartForGregorianYear(int year)`). |
| Logic "should we schedule for year X" + schedule one notification | Service baru atau tambah di `NotificationService`, e.g. `scheduleNextRamadanReminders(AppDatabase database)` yang dipanggil dari `rescheduleAllReminders` **setelah** scheduling Sahur/Iftar/Goal selesai, ATAU dipanggil terpisah di `_rescheduleNotifications` (app.dart) setelah `rescheduleAllReminders`. |
| L10n | `app_en.arb` / `app_id.arb` + generate: `nextRamadanReminderTitle(int year)`, `nextRamadanReminderBody(int year)` (atau tanpa param kalau copy fix). |
| Cancel lama | Saat jadwalkan ID 6002027, `zonedSchedule` dengan ID yang sama akan replace notifikasi lama; tidak perlu cancel eksplisit selama ID konsisten. |

---

## 12. Ringkasan

- **Satu notifikasi per tahun** (Ramadan 2027, 2028, ...), **7 hari sebelum** tanggal mulai Ramadan, jam **09:00 waktu lokal**.
- **Tanggal Ramadan** dari **tabel lookup** Gregorian (2025–2035).
- **Skip** tahun yang sudah punya musim.
- **ID** `6000000 + year`; **copy** EN/ID seperti di atas.
- **Trigger:** pastikan jadwal di **app startup** (setelah atau bersamaan dengan reschedule reminder lain).

Dokumen ini bisa dipakai untuk implementasi bertahap (fase 1: tabel + schedule di startup; fase 2: deep link ke Buat musim baru jika perlu).
