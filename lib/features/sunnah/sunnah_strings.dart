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
  String get markSunnahFast =>
      t('Berpuasa sunnah', 'Completed sunnah fast');
  String get markQadhaFast =>
      t('Puasa qadha (ganti Ramadan)', 'Ramadan make-up fast (qadha)');
  String get notFastingExcusedSection =>
      t('Tidak puasa karena uzur', 'Not fasting (excused)');
  String get excusedSectionHint => t(
        'Bukan puasa sunnah dan bukan qadha — hanya catat alasan tidak puasa.',
        'Not a sunnah or qadha fast — only records why you did not fast.',
      );
  String get savedSunnahFast => t('Dicatat: berpuasa sunnah', 'Saved: sunnah fast');
  String get savedQadhaFast =>
      t('Dicatat: puasa qadha', 'Saved: qadha make-up fast');
  String savedExcused(String reason) =>
      t('Dicatat: tidak puasa ($reason)', 'Saved: did not fast ($reason)');
  String get savedCleared => t('Catatan dihapus', 'Entry cleared');
  String get statusSheetHint => t(
        'Pilih salah satu dari 3 opsi berikut:',
        'Choose one of the 3 options below:',
      );
  String get option1Subtitle => t(
        'Puasa sunnah di hari ini',
        'Sunnah fast on this day',
      );
  String get option2Subtitle => t(
        'Berpuasa hari ini sebagai ganti puasa Ramadan',
        'Fast today as Ramadan make-up (qadha)',
      );
  String get option3PickReason => t('Pilih alasan:', 'Pick a reason:');
  String get excusedSickShort => t('Sakit', 'Sick');
  String get excusedHaidShort => t('Haid', 'Menstruation');
  String get excusedNifasShort => t('Nifas', 'Postnatal');
  String get excusedOtherShort => t('Lainnya', 'Other');
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
  String recentDaysStripTitle(int days) => id
      ? '$days hari terakhir'
      : 'Last $days days';
  String get openFullMonthCalendar =>
      t('Buka kalender bulan', 'Open month calendar');
  String get monthTabHint => t(
        'Geser bulan untuk meninjau dan mencatat puasa sunnah kapan saja.',
        'Swipe months to review and log sunnah fasts any time.',
      );
  String get monthPostRamadanHint => t(
        'Musim Ramadan terakhir selesai. Gunakan kalender ini untuk puasa sunnah sepanjang tahun.',
        'Your last Ramadan season is complete. Use this calendar for year-round sunnah fasting.',
      );
  String get monthSummaryFasted => t('Berpuasa', 'Fasted');
  String get monthSummaryExcused => t('Uzur', 'Excused');
  String get monthSummarySunnahDays => t('Hari sunnah', 'Sunnah days');
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
  String get obligationsSubtitleYearRound => t(
        'Zakat, fidyah, dan qadha sepanjang tahun',
        'Zakat, fidyah, and qadha year-round',
      );
  String get qadhaSection => t('Qadha puasa', 'Qadha fasting');
  String get zakatTitle => t('Zakat Fitrah', 'Zakat al-Fitr');
  String get zakatPeopleLabel => t('Jumlah jiwa', 'Number of people');
  String get zakatRate => t('Zakat per jiwa', 'Rate per person');
  String get zakatTotal => t('Total zakat', 'Total zakat');
  String get markZakatPaid => t('Tandai sudah dibayar', 'Mark as paid');
  String get zakatPaidStat => t('Zakat dibayar', 'Zakat paid');
  String get fidyahPaidStat => t('Fidyah dibayar', 'Fidyah paid');
  String get peopleUnit => t('jiwa', 'people');
  String get currencyLabel => t('Mata uang', 'Currency');
  String get rateHint =>
      t('Sesuai ketetapan setempat', 'Per local authority');
  String get enterRateFirst => t(
        'Masukkan tarif sesuai ketetapan setempat',
        'Enter the rate set by your local authority',
      );
  String get paymentSummary => t('Ringkasan pembayaran', 'Payment summary');
  String get paymentHistory => t('Riwayat pembayaran', 'Payment history');
  String get obligationsSeasonTitle =>
      t('Zakat & Fidyah (Musim)', 'Zakat & Fidyah (Season)');
  String get viewObligationsDetails =>
      t('Lihat riwayat lengkap', 'View full history');
  String get paymentTimeline =>
      t('Pembayaran selama Ramadan', 'Payments during Ramadan');
  String get obligationsTotalPaid =>
      t('Total dibayar', 'Total paid');
  String get obligationsPaymentCountLabel =>
      t('transaksi', 'payments');
  String get obligationsChartEmpty => t(
        'Belum ada pembayaran zakat/fidyah untuk mata uang ini.',
        'No zakat/fidyah payments for this currency yet.',
      );
  String get obligationsChartBreakdownTitle =>
      t('Zakat vs Fidyah', 'Zakat vs Fidyah');
  String get obligationsChartSeasonTimelineTitle =>
      t('Timeline Ramadan', 'Ramadan timeline');
  String get obligationsChartMonthlyTimelineTitle =>
      t('Timeline per bulan', 'Monthly timeline');
  String get obligationsChartPeriodTimelineTitle =>
      t('Timeline periode', 'Period timeline');
  String get obligationsReviewTitle =>
      t('Tinjauan Zakat & Fidyah', 'Zakat & Fidyah review');
  String get obligationsTodayCardTitle =>
      t('Zakat & Fidyah Hari Ini', 'Zakat & Fidyah today');
  String get obligationsWeeklyCardTitle =>
      t('Zakat & Fidyah (7 hari)', 'Zakat & Fidyah (7 days)');
  String get obligationsAddPayment =>
      t('Catat pembayaran', 'Log payment');

  String yearBreakdownTitleFor(int year) => id
      ? 'Ringkasan puasa sunnah $year'
      : 'Sunnah fasts in $year';
  String get yearBreakdownHint => t(
        'Lacak jenis puasa sunnah per tahun—bandingkan tahun ini dengan tahun depan.',
        'Track each sunnah fast type per year—compare and grow year over year.',
      );
  String timesCount(int n) => id ? '$n×' : '${n}x';
  String get syawalTarget => t('target 6 hari', 'goal: 6 days');

  String insightsSunnahTitleFor(int year) => id
      ? 'Puasa Sunnah $year'
      : 'Sunnah Fasting $year';
  String get viewSunnahInsights =>
      t('Lihat detail lengkap', 'View full breakdown');
  String get monthlyFastsChart =>
      t('Puasa per bulan (tahun ini)', 'Fasts per month (this year)');
  String qadhaFastsThisYear(int n) => id
      ? '$n puasa qadha tercatat tahun ini'
      : '$n qadha fasts logged this year';
  String get ramadanFocusTitle =>
      t('Ramadan sedang berlangsung', 'Ramadan is underway');
  String ramadanDaysLeft(int n) =>
      t('$n hari lagi', '$n days to go');
  String get ramadanFocusBody => t(
        'Fokuskan ibadah Ramadan di tab Hari Ini. Puasa sunnah (Senin/Kamis, dll.) dilacak kembali setelah Ramadan.',
        'Focus on Ramadan in the Today tab. Sunnah fasts (Mon/Thu, etc.) are tracked again after Ramadan.',
      );
  String get openTodayTab => t('Buka Hari Ini', 'Open Today');
  String get wawasanSunnahBanner => t(
        'Ringkasan puasa sunnah ada di Wawasan',
        'Full sunnah summary is in Insights',
      );
  String get openWawasan => t('Buka Wawasan', 'Open Insights');
  String get sunnahInsightsTabLabel => t('Sunnah', 'Sunnah');
  String get duringRamadanSunnahInsightsHint => t(
        'Riwayat puasa sunnah sepanjang tahun — termasuk catatan sebelum Ramadan. Puasa wajib Ramadan ada di tab Hari Ini / 7 Hari / Ramadan.',
        'Year-round sunnah fast history — including logs from before Ramadan. Obligatory Ramadan fasting is under Today / 7 Days / Ramadan.',
      );
  String get viewSunnahHistoryDuringRamadan => t(
        'Riwayat puasa sunnah',
        'Sunnah fast history',
      );
  String get viewPastRamadanInsights =>
      t('Lihat ringkasan Ramadan', 'View Ramadan summary');
  String get compareSeasonsTitle =>
      t('Bandingkan musim Ramadan', 'Compare Ramadan seasons');
  String compareSeasonsSubtitle(int current, int previous, String delta) => id
      ? 'Skor rata-rata: $current vs $previous ($delta poin)'
      : 'Average score: $current vs $previous ($delta pts)';
  String get viewSeasonComparison =>
      t('Lihat perbandingan lengkap', 'View full comparison');
  String get postRamadanReviewBanner => t(
        'Musim Ramadan terakhir sudah selesai. Lihat ringkasan musim kapan saja.',
        'Your last Ramadan season is complete. Review the season summary anytime.',
      );
  String get sunnahInsightsEmpty => t(
        'Belum ada catatan puasa sunnah tahun ini.',
        'No sunnah fasts logged this year yet.',
      );
  String preRamadanBanner(int days) => id
      ? 'Ramadan dimulai $days hari lagi — persiapkan diri!'
      : 'Ramadan starts in $days days — get ready!';
  String get preRamadanTodayHint => t(
        'Buat atau lengkapi musim Ramadan dari tab Hari Ini — kebiasaan, pengingat Sahur/Iftar, dan pelacakan harian.',
        'Create or finish your Ramadan season from the Today tab — habits, Sahur/Iftar reminders, and daily tracking.',
      );
  String get preRamadanAutopilotHint => t(
        'Atur target Quran, dzikir, dan blok waktu harian. Autopilot aktif otomatis saat Ramadan dimulai.',
        'Set your Quran, dhikr, and daily time-block targets. Autopilot activates when Ramadan starts.',
      );
  String get yearRoundModeTitle =>
      t('Mode sepanjang tahun', 'Year-round mode');
  String get yearRoundIntro => t(
        'Belum ada musim Ramadan. Lanjutkan ibadah harian dengan puasa sunnah, qadha, dan pantau acara Islam.',
        'No Ramadan season yet. Keep up daily worship with sunnah fasts, qadha, and Islamic events.',
      );
  String get planNoSeasonIntro => t(
        'Buat musim Ramadan untuk mengatur rencana Quran, dzikir, dan blok waktu harian.',
        'Create a Ramadan season to set up your Quran, dhikr, and daily time-block plan.',
      );
  String get createRamadanSeason =>
      t('Buat musim Ramadan', 'Create Ramadan season');
  String get ramadanIsHere => t('Ramadan sudah tiba!', 'Ramadan is here!');
  String ramadanCountdown(int days) => id
      ? 'Ramadan tinggal $days hari lagi'
      : 'Ramadan is in $days days';
  String get ramadanNearSetupHint => t(
        'Siapkan musimmu sekarang untuk Quran plan, Taraweeh, dan pengingat Sahur/Iftar.',
        'Set up your season now for the Quran plan, Taraweeh, and Sahur/Iftar reminders.',
      );
  String get setupRamadanSeason =>
      t('Siapkan musim Ramadan', 'Set up Ramadan season');
  String get planPreRamadanPreviewHint => t(
        'Pratinjau rencana hari pertama — autopilot aktif otomatis saat Ramadan dimulai.',
        'Preview of day-one plan — autopilot activates automatically when Ramadan starts.',
      );

  String get sunnahMonthViewTitle =>
      t('Kalender Puasa Sunnah', 'Sunnah Fast Calendar');
  String get sunnahMonthViewHint => t(
        'Ketuk tanggal untuk tandai puasa sunnah atau uzur.',
        'Tap a date to log a sunnah fast or excused day.',
      );
  String get noSeasonSunnahMonthHint => t(
        'Belum ada musim Ramadan. Gunakan kalender ini untuk lacak puasa sunnah sepanjang tahun.',
        'No Ramadan season yet. Use this calendar to track sunnah fasts year-round.',
      );
  String get noSeasonSunnahInsightsHint => t(
        'Belum ada musim Ramadan. Wawasan puasa sunnah tetap aktif — mulai catat dari tab Sunnah atau tombol di bawah.',
        'No Ramadan season yet. Sunnah insights are still available — start logging from the Sunnah tab or the button below.',
      );
  String get sunnahInsightsFallbackTitle =>
      t('Wawasan Puasa Sunnah', 'Sunnah Fasting Insights');
  String get sunnahInsightsFallbackSubtitle => t(
        'Sebelum Ramadan tiba, tab ini menampilkan ringkasan puasa sunnah. Setelah Ramadan, kembali ke wawasan musim plus puasa sunnah.',
        'Before Ramadan starts, this tab shows your sunnah fasting summary. After Ramadan, season insights return alongside sunnah analytics.',
      );
  String get openSunnahTab => t('Buka tab Sunnah', 'Open Sunnah tab');
  String get legendFasted => t('Berpuasa', 'Fasted');
  String get legendExcused => t('Uzur', 'Excused');
  String get legendSunnahDay => t('Hari sunnah', 'Sunnah day');
  String get legendToday => t('Hari ini', 'Today');
  String get legendNone => t('Kosong', 'Empty');
  String get legendTypeCodesTitle =>
      t('Kode di kalender', 'Codes on calendar');
  String typeCodeEntry(String code, String label) => '$code = $label';
  List<(String, String)> get calendarTypeCodeLegend {
    if (id) {
      return [
        ('S/K', 'Senin & Kamis'),
        ('AB', 'Ayyamul Bidh'),
        ('SY', 'Puasa Syawal'),
        ('AR', 'Arafah'),
        ('AS', 'Asyura'),
        ('TS', "Tasu'a"),
        ('SB', "Sya'ban"),
      ];
    }
    return [
      ('M/T', 'Mon & Thu fast'),
      ('AB', 'Ayyamul Bidh'),
      ('SY', 'Shawwal fast'),
      ('AR', 'Arafah'),
      ('AS', 'Ashura'),
      ('TS', "Tasu'a"),
      ('SB', "Sha'ban"),
    ];
  }
  String get qadhaShort => t('Qadha', 'Qadha');
  String get sunnahHeroTitle =>
      t('Bagaimana puasa sunnahmu?', 'How is your sunnah fasting?');
  String sunnahHeroSub(int allTime, int streak) => id
      ? 'Total $allTime · streak S/K $streak'
      : '$allTime all-time · Mon–Thu streak $streak';
  String get weeklyFastsChart =>
      t('Puasa per minggu (8 minggu)', 'Fasts per week (8 weeks)');
  String get recentFastsHeatmap => t('35 hari terakhir', 'Last 35 days');
  String get typeBreakdownTitle =>
      t('Per jenis puasa', 'By fast type');
  String get sunnahChartEmptyHint => t(
        'Belum ada data — tandai puasa sunnah untuk melihat grafik.',
        'No data yet — log sunnah fasts to see charts.',
      );
  String get ramadanFastedTitle => t('Berpuasa', 'Fasting');
  String get ramadanFastedSubtitle => t(
        'Menyelesaikan puasa wajib hari ini',
        'Completed obligatory fast today',
      );
  String get ramadanExcusedHint => t(
        'Hanya mencatat uzur — qadha dilacak terpisah di tab Sunnah.',
        'Records excused day only — qadha is tracked in the Sunnah tab.',
      );
  String get ramadanStatusSheetHint => t(
        'Pilih salah satu dari 2 opsi berikut:',
        'Choose one of the 2 options below:',
      );
  String get ramadanSavedFasted =>
      t('Dicatat: berpuasa Ramadan', 'Saved: Ramadan fast');
}
