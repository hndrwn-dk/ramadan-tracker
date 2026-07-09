/// Localized copy for goal reminder notifications (no BuildContext in scheduler).
class GoalReminderStrings {
  GoalReminderStrings._();

  static const _order = ['quran', 'dhikr', 'sedekah'];

  static ({String title, String body}) forType(
    String type,
    String locale,
    int current,
    int target,
  ) {
    final id = locale.toLowerCase() == 'id';
    switch (type) {
      case 'quran':
        return (
          title: id ? 'Pengingat Target Quran' : 'Quran Goal Reminder',
          body: id
              ? 'Target Quran hari ini belum tercapai ($current/$target halaman). Terus semangat!'
              : 'Haven\'t reached today\'s Quran target ($current/$target pages). Keep going!',
        );
      case 'dhikr':
        return (
          title: id ? 'Pengingat Target Dzikir' : 'Dhikr Goal Reminder',
          body: id
              ? 'Target dzikir belum tercapai ($current/$target). Terus istiqamah!'
              : 'Dhikr target not reached ($current/$target). Keep it up!',
        );
      case 'sedekah':
        return (
          title: id ? 'Pengingat Target Sedekah' : 'Sedekah Goal Reminder',
          body: id
              ? 'Target sedekah hari ini belum tercapai. Jangan lupa berbagi kebaikan!'
              : 'Today\'s Sedekah target not reached. Don\'t forget to share goodness!',
        );
      case 'taraweeh':
        return (
          title: id ? 'Pengingat Tarawih' : 'Taraweeh Reminder',
          body: id
              ? 'Waktunya Tarawih! Persiapkan diri untuk sholat malam.'
              : 'Taraweeh time is approaching! Prepare yourself for night prayer.',
        );
      default:
        return (
          title: id ? 'Pengingat Ramadan' : 'Ramadan Reminder',
          body: id ? 'Ingatkan ibadah harianmu.' : 'Remember your daily worship.',
        );
    }
  }

  /// Combined digest copy for pending Quran / dhikr / sedekah goals.
  static ({String title, String body}) forDigest(
    List<String> pendingTypes,
    String locale,
  ) {
    final id = locale.toLowerCase() == 'id';
    final sorted = _order.where(pendingTypes.contains).toList();

    if (sorted.length >= 3) {
      return (
        title: id ? 'Menjelang Maghrib 🌇' : 'Almost Maghrib 🌇',
        body: id
            ? 'Tilawah, dzikir, dan sedekah hari ini masih bisa kamu tunaikan.'
            : 'Qur\'an, dhikr, and sedekah today are still within reach.',
      );
    }

    if (sorted.length == 2) {
      final labels = sorted.map((t) => _habitLabel(t, id)).toList();
      final joined = '${labels[0]} & ${labels[1]}';
      return (
        title: id ? 'Hampir Maghrib' : 'Almost Maghrib',
        body: id
            ? 'Masih ada waktu untuk $joined sebelum hari berganti.'
            : 'Still time for $joined before the day ends.',
      );
    }

    if (sorted.length == 1) {
      return _singleDigest(sorted.first, id);
    }

    return (
      title: id ? 'Pengingat Ramadan' : 'Ramadan Reminder',
      body: id ? 'Ingatkan ibadah harianmu.' : 'Remember your daily worship.',
    );
  }

  static String _habitLabel(String type, bool id) {
    switch (type) {
      case 'quran':
        return id ? 'tilawah' : 'Qur\'an';
      case 'dhikr':
        return id ? 'dzikir' : 'dhikr';
      case 'sedekah':
        return 'sedekah';
      default:
        return type;
    }
  }

  static ({String title, String body}) _singleDigest(String type, bool id) {
    switch (type) {
      case 'sedekah':
        return (
          title: id ? 'Sedekah hari ini 💛' : 'Sedekah today 💛',
          body: id
              ? 'Sekecil apapun, masih ada waktu untuk berbagi hari ini.'
              : 'Even a small amount — there\'s still time to share today.',
        );
      case 'quran':
        return (
          title: id ? 'Waktu tilawah 📖' : 'Tilawah time 📖',
          body: id
              ? 'Beberapa ayat hari ini masih menunggu kamu.'
              : 'A few verses are still waiting for you today.',
        );
      case 'dhikr':
        return (
          title: id ? 'Waktu dzikir 🤲' : 'Dhikr time 🤲',
          body: id
              ? 'Sejenak berdzikir sore ini, yuk.'
              : 'Take a moment for dhikr this evening.',
        );
      default:
        return (
          title: id ? 'Pengingat Ramadan' : 'Ramadan Reminder',
          body: id ? 'Ingatkan ibadah harianmu.' : 'Remember your daily worship.',
        );
    }
  }
}
