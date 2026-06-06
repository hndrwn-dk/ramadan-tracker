/// Copy for "next Ramadan" reminder notification.
/// Used when scheduling in background (no BuildContext/L10n).
/// Locale: 'en' or 'id' (from app_language).
class NextRamadanReminderStrings {
  NextRamadanReminderStrings._();

  static String getTitle(String locale, int year) {
    switch (locale.toLowerCase()) {
      case 'id':
        return 'Ramadan $year sebentar lagi';
      default:
        return 'Ramadan $year is coming';
    }
  }

  static String getBody(String locale) {
    switch (locale.toLowerCase()) {
      case 'id':
        return 'Buka app untuk buat musim baru dan mulai tracking.';
      default:
        return 'Open the app to create your new season and start tracking.';
    }
  }
}
