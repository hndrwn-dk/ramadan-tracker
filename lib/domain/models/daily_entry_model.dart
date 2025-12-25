class DailyEntryModel {
  final int seasonId;
  final int dayIndex;
  final int habitId;
  final bool? valueBool;
  final int? valueInt;
  final String? note;
  final DateTime updatedAt;

  DailyEntryModel({
    required this.seasonId,
    required this.dayIndex,
    required this.habitId,
    this.valueBool,
    this.valueInt,
    this.note,
    required this.updatedAt,
  });

  bool get isCompleted {
    if (valueBool != null) return valueBool!;
    if (valueInt != null && valueInt! > 0) return true;
    return false;
  }
}

