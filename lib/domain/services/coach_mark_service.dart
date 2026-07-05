import 'package:ramadan_tracker/data/database/app_database.dart';

/// One-time feature tips stored in KV (no overlay package).
class CoachMarkService {
  CoachMarkService._();

  static const String todayQuests = 'coach_mark_today_quests';
  static const String todayJourney = 'coach_mark_today_journey';
  static const String monthCalendar = 'coach_mark_month_calendar';

  static Future<bool> isSeen(AppDatabase database, String key) async {
    return await database.kvSettingsDao.getValue(key) == 'true';
  }

  static Future<void> markSeen(AppDatabase database, String key) async {
    await database.kvSettingsDao.setValue(key, 'true');
  }
}
