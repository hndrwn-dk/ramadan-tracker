/// What a primary tap on the Today fasting checklist row should do.
enum FastingChecklistTapAction {
  toggleToFasted,
  toggleToNotDone,
  openStatusSheet,
}

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

  /// Imsak intention only (KV); not persisted to daily_entries until iftar confirm.
  static const int intentPendingFast = 6;

  static const List<int> all = [
    notDone,
    fasted,
    excusedSick,
    excusedNifas,
    excusedHaid,
    excusedOther,
    intentPendingFast,
  ];

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

  static bool isPendingIntent(int status) => status == intentPendingFast;

  /// Binary quick-toggle is only valid between [notDone] and [fasted].
  /// Excused variants, pending intent, and a live pending KV flag open the sheet.
  static FastingChecklistTapAction checklistTapAction({
    required int currentStatus,
    bool hasPendingIntent = false,
  }) {
    if (hasPendingIntent || isExcused(currentStatus) || isPendingIntent(currentStatus)) {
      return FastingChecklistTapAction.openStatusSheet;
    }
    if (currentStatus == fasted) {
      return FastingChecklistTapAction.toggleToNotDone;
    }
    return FastingChecklistTapAction.toggleToFasted;
  }

  /// True when status is haid or nifas (day is excused from prayers, tahajud, quran, taraweeh).
  static bool isHaidOrNifas(int status) =>
      status == excusedHaid || status == excusedNifas;

  /// Habit keys that are excused (not required) on haid/nifas days.
  static const List<String> habitKeysExcusedOnHaidNifas = [
    'prayers',
    'tahajud',
    'quran_pages',
    'taraweeh',
  ];
}
