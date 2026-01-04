import 'package:ramadan_tracker/data/database/app_database.dart';
import 'package:ramadan_tracker/domain/models/daily_entry_model.dart';
import 'package:ramadan_tracker/domain/models/habit_model.dart';
import 'package:ramadan_tracker/domain/models/season_model.dart';

/// Centralized scoring service for Insights screen.
/// Uses weighted scoring model:
/// - Fasting: 25
/// - 5 Prayers: 25 (5 each)
/// - Quran: 20 (proportional, cap at 100%)
/// - Dhikr: 10 (proportional, cap at 100%)
/// - Taraweeh: 10 (binary)
/// - Sedekah: 5 (proportional vs daily goal, 0 if no goal)
/// - I'tikaf: 5 (only last 10 nights, excluded otherwise)
class InsightsScoringService {
  // Weights
  static const int weightFasting = 25;
  static const int weightPrayers = 25;
  static const int weightQuran = 20;
  static const int weightDhikr = 10;
  static const int weightTaraweeh = 10;
  static const int weightSedekah = 5;
  static const int weightItikaf = 5;

  /// Calculate daily score (0-100) for a specific day.
  /// Returns the score and the total applicable weight for normalization.
  static Future<Map<String, dynamic>> calculateDailyScore({
    required int seasonId,
    required int dayIndex,
    required SeasonModel season,
    required List<HabitModel> allHabits,
    required List<SeasonHabitModel> seasonHabits,
    required List<DailyEntryModel> entries,
    required AppDatabase database,
    QuranDailyData? quranDaily,
    PrayerDetail? prayerDetail,
  }) async {
    // Check if in last 10 nights
    final last10Start = season.days - 9;
    final isInLast10Days = dayIndex >= last10Start && dayIndex > 0;

    // Load plans and settings
    final quranPlan = await database.quranPlanDao.getPlan(seasonId);
    final dhikrPlan = await database.dhikrPlanDao.getPlan(seasonId);
    final sedekahGoalEnabled = await database.kvSettingsDao.getValue('sedekah_goal_enabled');
    final sedekahGoalAmount = await database.kvSettingsDao.getValue('sedekah_goal_amount');

    int totalApplicableWeight = 0;
    int earnedWeight = 0;

    // Process each enabled habit
    for (final seasonHabit in seasonHabits.where((sh) => sh.isEnabled)) {
      final habit = allHabits.firstWhere((h) => h.id == seasonHabit.habitId);
      final habitKey = habit.key;

      // Skip Itikaf if not in last 10 nights
      if (habitKey == 'itikaf' && !isInLast10Days) {
        continue;
      }

      final entry = entries.firstWhere(
        (e) => e.habitId == habit.id,
        orElse: () => DailyEntryModel(
          seasonId: seasonId,
          dayIndex: dayIndex,
          habitId: habit.id,
          updatedAt: DateTime.now(),
        ),
      );

      int weight = 0;
      double progress = 0.0;

      // Calculate weight and progress based on habit type
      if (habitKey == 'fasting') {
        weight = weightFasting;
        progress = entry.valueBool == true ? 1.0 : 0.0;
      } else if (habitKey == 'prayers') {
        weight = weightPrayers;
        if (prayerDetail != null) {
          final completedCount = [
            prayerDetail.fajr,
            prayerDetail.dhuhr,
            prayerDetail.asr,
            prayerDetail.maghrib,
            prayerDetail.isha,
          ].where((p) => p).length;
          progress = completedCount / 5.0;
        } else {
          progress = entry.valueBool == true ? 1.0 : 0.0;
        }
      } else if (habitKey == 'quran_pages') {
        weight = weightQuran;
        final target = quranPlan?.dailyTargetPages ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 20;
        if (target > 0) {
          final currentValue = quranDaily?.pagesRead ?? 0;
          progress = (currentValue / target).clamp(0.0, 1.0);
        } else {
          progress = (quranDaily?.pagesRead ?? 0) > 0 ? 1.0 : 0.0;
        }
      } else if (habitKey == 'dhikr') {
        weight = weightDhikr;
        final target = dhikrPlan?.dailyTarget ?? seasonHabit.targetValue ?? habit.defaultTarget ?? 100;
        if (target > 0) {
          final currentValue = entry.valueInt ?? 0;
          progress = (currentValue / target).clamp(0.0, 1.0);
        } else {
          progress = (entry.valueInt ?? 0) > 0 ? 1.0 : 0.0;
        }
      } else if (habitKey == 'taraweeh') {
        weight = weightTaraweeh;
        progress = entry.valueBool == true ? 1.0 : 0.0;
      } else if (habitKey == 'sedekah') {
        if (sedekahGoalEnabled == 'true' && sedekahGoalAmount != null) {
          weight = weightSedekah;
          final target = double.tryParse(sedekahGoalAmount) ?? 0;
          if (target > 0) {
            final currentValue = (entry.valueInt ?? 0).toDouble();
            progress = (currentValue / target).clamp(0.0, 1.0);
          } else {
            progress = (entry.valueInt ?? 0) > 0 ? 1.0 : 0.0;
          }
        } else {
          // Sedekah goal disabled, contributes 0 weight
          weight = 0;
          progress = 0.0;
        }
      } else if (habitKey == 'itikaf') {
        if (isInLast10Days) {
          weight = weightItikaf;
          progress = entry.valueBool == true ? 1.0 : 0.0;
        } else {
          // Not in last 10 nights, excluded
          continue;
        }
      }

      totalApplicableWeight += weight;
      earnedWeight += (weight * progress).round();
    }

    // Normalize to 0-100
    final score = totalApplicableWeight > 0
        ? ((earnedWeight / totalApplicableWeight) * 100).round()
        : 0;

    return {
      'score': score,
      'totalWeight': totalApplicableWeight,
      'earnedWeight': earnedWeight,
    };
  }
}

