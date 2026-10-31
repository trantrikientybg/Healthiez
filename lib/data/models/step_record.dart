class StepRecord {
  final DateTime date;
  final int steps;
  final int goal;
  final int weeklyTotal; // tích lũy từ đầu tuần

  const StepRecord({
    required this.date,
    required this.steps,
    required this.goal,
    required this.weeklyTotal,
  });

  /// Tỉ lệ đạt mục tiêu, từ 0.0 đến 1.0 (vòng tròn không vượt quá đầy).
  double get percent => goal == 0 ? 0 : (steps / goal).clamp(0.0, 1.0);

  int get percentInt => (percent * 100).round();
}