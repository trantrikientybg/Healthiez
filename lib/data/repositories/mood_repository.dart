import '../../core/utils/date_utils.dart';
import '../models/mood_entry.dart';

/// DỮ LIỆU GIẢ (lưu trong bộ nhớ).
/// Khi nối thật: dùng chung DailyRecordService trong mental_screen.dart
/// (bảng mental_health_records) để Home và Tinh thần không lưu hai nơi.
class MoodRepository {
  static final List<MoodEntry> _entries = [];

  Future<MoodEntry?> getToday() async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    for (final e in _entries) {
      if (AppDateUtils.isSameDay(e.date, today)) return e;
    }
    return null;
  }

  /// Chọn lại trong cùng ngày thì ghi đè.
  Future<void> saveToday(MoodType mood) async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    _entries.removeWhere((e) => AppDateUtils.isSameDay(e.date, today));
    _entries.add(MoodEntry(date: today, mood: mood));
  }

  Future<List<MoodEntry>> getMonth(int year, int month) async {
    return _entries
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }
}
