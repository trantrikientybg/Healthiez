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
    return _cachedFor(today);
  }

  /// Tâm trạng đã ghi nhận trong [days] ngày gần nhất (gồm hôm nay), theo từng ngày.
  Future<Map<DateTime, Mood>> getRecent({int days = 2}) async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    final from = today.subtract(Duration(days: days - 1));
    final result = <DateTime, Mood>{};
    try {
      final records = await _service.getRecords();
      for (final r in records) {
        final d = AppDateUtils.dateOnly(r.date);
        if (r.emotion != null && !d.isBefore(from) && !d.isAfter(today)) {
          result[d] = r.emotion!;
        }
      }
    } catch (_) {
      // bỏ qua
    }
    final cached = _cachedFor(today);
    if (cached != null && !result.containsKey(today)) result[today] = cached;
    return result;
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

  Mood? _cachedFor(DateTime today) =>
      _cachedDay != null && AppDateUtils.isSameDay(_cachedDay!, today)
          ? _cachedMood
          : null;

  void _remember(DateTime day, Mood mood) {
    _cachedDay = day;
    _cachedMood = mood;
  }
}
