/// Localized copy for goal reminder notifications (no BuildContext in scheduler).
class GoalReminderStrings {
  GoalReminderStrings._();

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
}
