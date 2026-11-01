import '../../core/utils/date_utils.dart';
import '../../screens/mental/mental_data.dart' show Mood;
import '../../screens/mental/mental_screen.dart' show DailyRecordService;

/// Cầu nối Home <-> bảng mental_health_records (dùng chung service của Tinh thần).
/// Nếu mạng/DB lỗi thì giữ tạm trong bộ nhớ để giao diện vẫn chạy.
class MoodRepository {
  final DailyRecordService _service = DailyRecordService();

  static Mood? _cachedMood;
  static DateTime? _cachedDay;

  Future<Mood?> getToday() async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    try {
      final records = await _service.getRecords();
      for (final r in records) {
        if (AppDateUtils.isSameDay(r.date, today) && r.emotion != null) {
          _remember(today, r.emotion!);
          return r.emotion;
        }
      }
    } catch (_) {
      // bỏ qua: dùng bản tạm bên dưới
    }
    return _cachedDay != null && AppDateUtils.isSameDay(_cachedDay!, today)
        ? _cachedMood
        : null;
  }

  /// Chọn lại trong cùng ngày thì ghi đè. Trả về false nếu lưu lên server thất bại.
  Future<bool> saveToday(Mood mood) async {
    _remember(AppDateUtils.dateOnly(DateTime.now()), mood);
    try {
      await _service.saveRecord(emotion: mood);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _remember(DateTime day, Mood mood) {
    _cachedDay = day;
    _cachedMood = mood;
  }
}