/// Fasting status for daily entry.
/// Stored in DailyEntry.valueInt for habit "fasting".
/// valueBool: true only when [fasted]; false for [notDone] and excused.
class FastingStatus {
  FastingStatus._();

  static const int notDone = 0;
  static const int fasted = 1;
  static const int excusedSick = 2;
  static const int excusedNifas = 3;
  static const int excusedHaid = 4;
  static const int excusedOther = 5;

  static const List<int> all = [notDone, fasted, excusedSick, excusedNifas, excusedHaid, excusedOther];

  /// Day counts as "completed" for score (fasted or excused).
  static bool isCompletedForDay(int? valueInt, bool? valueBool) {
    if (valueInt != null && valueInt >= fasted && valueInt <= excusedOther) return true;
    return valueBool == true;
  }

  /// Resolve status from entry (handles legacy: only valueBool set).
  static int fromEntry(int? valueInt, bool? valueBool) {
    if (valueInt != null && valueInt >= notDone && valueInt <= excusedOther) return valueInt;
    return valueBool == true ? fasted : notDone;
  }

  static bool isExcused(int status) =>
      status == excusedSick || status == excusedNifas || status == excusedHaid || status == excusedOther;
}
