class ScreenTimeRecord {
  final DateTime date;
  final int minutes;      // tổng thời gian dùng điện thoại
  final int limitMinutes; // giới hạn mong muốn

  /// false khi không đọc được (chưa cấp quyền, lỗi cảm biến...). Khi đó minutes = 0
  /// chỉ là giá trị giữ chỗ, KHÔNG phải "đã dùng 0 phút".
  final bool available;

  const ScreenTimeRecord({
    required this.date,
    required this.minutes,
    required this.limitMinutes,
    this.available = true,
  });

  factory ScreenTimeRecord.unavailable({
    required DateTime date,
    required int limitMinutes,
  }) =>
      ScreenTimeRecord(
        date: date,
        minutes: 0,
        limitMinutes: limitMinutes,
        available: false,
      );

  double get percent =>
      limitMinutes == 0 ? 0 : (minutes / limitMinutes).clamp(0.0, 1.0);

  int get percentInt => (percent * 100).round();

  /// Ví dụ: "3h 20m"
  String get totalLabel =>
      '${minutes ~/ 60}h ${(minutes % 60).toString().padLeft(2, '0')}m';

  String get status {
    if (minutes <= limitMinutes * 0.75) return 'Tốt';
    if (minutes <= limitMinutes) return 'Khá';
    return 'Quá mức';
  }
}
