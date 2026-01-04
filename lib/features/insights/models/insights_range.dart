enum InsightsRange {
  today,
  sevenDays,
  season,
}

extension InsightsRangeExtension on InsightsRange {
  String get label {
    switch (this) {
      case InsightsRange.today:
        return 'Today';
      case InsightsRange.sevenDays:
        return '7 Days';
      case InsightsRange.season:
        return 'Season';
    }
  }
}

