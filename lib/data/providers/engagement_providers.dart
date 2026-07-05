import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ramadan_tracker/data/providers/database_provider.dart';
import 'package:ramadan_tracker/domain/models/daily_quest.dart';
import 'package:ramadan_tracker/domain/services/pre_ramadan_quest_service.dart';
import 'package:ramadan_tracker/domain/services/sunnah_monthly_challenge_service.dart';

/// Pre-Ramadan prep quest progress; invalidate after sunnah log or settings changes.
final preRamadanQuestProgressProvider =
    FutureProvider<List<DailyQuestProgress>>((ref) async {
  final db = ref.watch(databaseProvider);
  return PreRamadanQuestService.evaluateProgress(db);
});

/// Sunnah monthly challenge progress; invalidate after logging a fast.
final sunnahMonthlyChallengeProvider =
    FutureProvider<SunnahMonthlyChallengeProgress>((ref) async {
  final db = ref.watch(databaseProvider);
  return SunnahMonthlyChallengeService.progress(db, DateTime.now());
});
