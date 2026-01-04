class HabitStats {
  // For boolean habits (Fasting, Taraweeh, Itikaf)
  final int? doneDays;
  final int? totalDays;

  // For counter habits (Quran, Dhikr)
  final double? avgValue;
  final int? targetValue;
  final int? totalValue;
  final int? daysMetTarget;

  // For amount habits (Sedekah)
  final int? totalAmount;
  final double? avgAmount;
  final int? daysMetGoal;

  // For composite habits (5 Prayers)
  final int? all5Days;
  final Map<String, int>? perPrayerCounts; // fajr, dhuhr, asr, maghrib, isha

  // For Itikaf (last 10 nights)
  final int? nightsDone;
  final List<DateTime>? nightsCompletedDates;

  HabitStats({
    this.doneDays,
    this.totalDays,
    this.avgValue,
    this.targetValue,
    this.totalValue,
    this.daysMetTarget,
    this.totalAmount,
    this.avgAmount,
    this.daysMetGoal,
    this.all5Days,
    this.perPrayerCounts,
    this.nightsDone,
    this.nightsCompletedDates,
  });
}

