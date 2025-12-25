import 'package:ramadan_tracker/data/database/app_database.dart';

class SeasonModel {
  final int id;
  final String label;
  final DateTime startDate;
  final int days;
  final DateTime createdAt;

  SeasonModel({
    required this.id,
    required this.label,
    required this.startDate,
    required this.days,
    required this.createdAt,
  });

  factory SeasonModel.fromDb(RamadanSeason season) {
    return SeasonModel(
      id: season.id,
      label: season.label,
      startDate: DateTime.parse(season.startDate),
      days: season.days,
      createdAt: DateTime.fromMillisecondsSinceEpoch(season.createdAt),
    );
  }

  int getDayIndex(DateTime date) {
    final diff = date.difference(startDate).inDays;
    final index = diff + 1;
    return index.clamp(1, days);
  }

  int getRawDayIndex(DateTime date) {
    final diff = date.difference(startDate).inDays;
    return diff + 1;
  }

  SeasonState getState(DateTime date) {
    final rawIndex = getRawDayIndex(date);
    if (rawIndex < 1) return SeasonState.preRamadan;
    if (rawIndex > days) return SeasonState.postRamadan;
    return SeasonState.active;
  }

  bool isDateInSeason(DateTime date) {
    final index = getDayIndex(date);
    return index >= 1 && index <= days;
  }
}

enum SeasonState {
  preRamadan,
  active,
  postRamadan,
}

