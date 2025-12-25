import 'package:ramadan_tracker/data/database/app_database.dart';

class QuranService {
  static double calculateJuzProgress({
    required int pagesRead,
    required int pagesPerJuz,
  }) {
    if (pagesPerJuz <= 0) return 0.0;
    return pagesRead / pagesPerJuz;
  }

  static int getCurrentJuz({
    required int pagesRead,
    required int pagesPerJuz,
  }) {
    if (pagesPerJuz <= 0) return 0;
    return (pagesRead / pagesPerJuz).floor();
  }

  static int getJuzTarget({
    required QuranPlanData? plan,
  }) {
    return plan?.juzTargetPerDay ?? 1;
  }

  static int getPagesPerJuz({
    required QuranPlanData? plan,
  }) {
    return plan?.pagesPerJuz ?? 20;
  }
}

