class SleepRecord {
  final DateTime date;
  final DateTime bedTime;
  final DateTime wakeTime;
  final double goalHours;

  const SleepRecord({
    required this.date,
    required this.bedTime,
    required this.wakeTime,
    required this.goalHours,
  });

  double get hours => wakeTime.difference(bedTime).inMinutes / 60;

  double get percent => goalHours == 0 ? 0 : (hours / goalHours).clamp(0.0, 1.0);

  int get percentInt => (percent * 100).round();

  /// Ví dụ: "23h - 7h30"
  String get rangeLabel => '${_fmt(bedTime)} - ${_fmt(wakeTime)}';

  String get status {
    if (hours >= 7) return 'Tốt';
    if (hours >= 6) return 'Trung bình';
    return 'Kém';
  }

  static String _fmt(DateTime t) =>
      t.minute == 0 ? '${t.hour}h' : '${t.hour}h${t.minute.toString().padLeft(2, '0')}';
}
