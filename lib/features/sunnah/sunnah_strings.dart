import 'package:flutter/widgets.dart';

/// Lightweight bilingual strings for the Sunnah / Qadha feature set.
/// Mirrors the labelId/labelEn pattern used by SunnahType and IslamicEvent
/// so we avoid regenerating the large l10n catalogue for this module.
class SunnahStrings {
  final bool id;
  const SunnahStrings(this.id);

  factory SunnahStrings.of(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode;
    return SunnahStrings(code == 'id');
  }

  String t(String idText, String enText) => id ? idText : enText;

  String get sunnahTitle => t('Puasa Sunnah', 'Sunnah Fasting');
  String get hubSubtitle =>
      t('Lanjutkan ibadah sepanjang tahun', 'Keep going all year round');
  String get today => t('Hari ini', 'Today');
  String get todaySunnahPrompt =>
      t('Hari ini waktunya puasa sunnah', 'A sunnah fast is recommended today');
  String get noSunnahToday =>
      t('Tidak ada puasa sunnah hari ini', 'No sunnah fast today');
  String get fasted => t('Berpuasa', 'Fasted');
  String get notFasted => t('Belum', 'Not yet');
  String get markFast => t('Tandai puasa', 'Mark fast');
  String get setStatus => t('Atur status puasa', 'Set fasting status');
  String get statusFasted => t('Berpuasa', 'Fasted');
  String get statusNotDone => t('Tidak puasa', 'Not fasting');
  String get statusSick => t('Uzur: sakit', 'Excused: sick');
  String get statusHaid => t('Uzur: haid', 'Excused: menstruation');
  String get statusNifas => t('Uzur: nifas', 'Excused: postnatal');
  String get statusOther => t('Uzur: lainnya', 'Excused: other');
  String get markAsQadha =>
      t('Hitung sebagai qadha Ramadan', 'Count as Ramadan make-up (qadha)');
  String get clear => t('Hapus', 'Clear');
  String get streak => t('Streak S/K', 'Mon–Thu');
  String get weeksUnit => t('kali', 'times');
  String get thisYear => t('Tahun ini', 'This year');
  String get allTime => t('Total', 'All time');
  String get daysUnit => t('hari', 'days');
  String get upcomingEvents => t('Acara Islam berikutnya', 'Upcoming Islamic events');
  String get inDays => t('hari lagi', 'days');
  String get tomorrow => t('Besok', 'Tomorrow');
  String get monthLog => t('Catatan bulan ini', 'This month');
  String get qadhaTitle => t('Qadha & Fidyah', 'Qadha & Fidyah');
  String get qadhaRemaining => t('Sisa qadha', 'Qadha remaining');
  String get qadhaOwed => t('Total utang', 'Total owed');
  String get qadhaPaid => t('Sudah diganti', 'Made up');
  String get addOwed => t('Tambah utang', 'Add owed');
  String get addPaid => t('Catat ganti', 'Log make-up');
  String get fidyahTitle => t('Kalkulator Fidyah', 'Fidyah calculator');
  String get fidyahDaysLabel => t('Jumlah hari', 'Number of days');
  String get fidyahRate => t('Tarif per hari', 'Rate per day');
  String get fidyahTotal => t('Total fidyah', 'Total fidyah');
  String get markFidyahPaid => t('Tandai sudah dibayar', 'Mark as paid');
  String get history => t('Riwayat', 'History');
  String get noHistory => t('Belum ada catatan', 'No entries yet');
  String get syawalTitle => t('Puasa 6 Hari Syawal', 'Six Days of Shawwal');
  String get syawalSubtitle => t('Sempurnakan Ramadanmu',
      'Complete your Ramadan');
  String get share => t('Bagikan', 'Share');
  String get shareStreakTitle => t('Puasa Sunnahku', 'My Sunnah Fasting');
  String get approxNote => t(
      'Tanggal Hijriah adalah perkiraan; ikuti pengumuman setempat.',
      'Hijri dates are approximate; follow local announcements.');
  String get amountHint => t('Jumlah hari', 'Number of days');
  String get save => t('Simpan', 'Save');
  String get cancel => t('Batal', 'Cancel');
  String get qadhaSeedPrompt => t(
      'Tambahkan hari puasa yang terlewat ke daftar qadha?',
      'Add your missed fasting days to qadha?');

  // Combined obligations hub (Zakat Fitrah + Fidyah + Qadha)
  String get obligationsTitle => t('Zakat, Fidyah & Qadha', 'Zakat, Fidyah & Qadha');
  String get obligationsSubtitle =>
      t('Kewajiban Ramadan', 'Ramadan obligations');
  String get qadhaSection => t('Qadha puasa', 'Qadha fasting');
  String get zakatTitle => t('Zakat Fitrah', 'Zakat al-Fitr');
  String get zakatPeopleLabel => t('Jumlah jiwa', 'Number of people');
  String get zakatRate => t('Zakat per jiwa', 'Rate per person');
  String get zakatTotal => t('Total zakat', 'Total zakat');
  String get markZakatPaid => t('Tandai sudah dibayar', 'Mark as paid');
  String get zakatPaidStat => t('Zakat dibayar', 'Zakat paid');
  String get peopleUnit => t('jiwa', 'people');

  String yearBreakdownTitleFor(int year) => id
      ? 'Ringkasan puasa sunnah $year'
      : 'Sunnah fasts in $year';
  String get yearBreakdownHint => t(
        'Lacak jenis puasa sunnah per tahun—bandingkan tahun ini dengan tahun depan.',
        'Track each sunnah fast type per year—compare and grow year over year.',
      );
  String timesCount(int n) => id ? '$n×' : '${n}x';
  String get syawalTarget => t('target 6 hari', 'goal: 6 days');
}
