class DayPoint {
  final DateTime date;
  final int score; // 0-100
  final double completionPercent; // 0.0-1.0

  DayPoint({
    required this.date,
    required this.score,
    required this.completionPercent,
  });
}

