import '../../core/utils/date_utils.dart';
import '../models/step_record.dart';

/// Tính số bước hôm nay và tổng bước trong tuần từ các dòng của bảng
/// physical_health_records (mọi kind, mọi thiết bị).
///
/// Mỗi dòng kind = 'steps' của một điện thoại có payload:
///   { date: 'YYYY-MM-DD', steps: <bước của ngày đó>, history: { 'YYYY-MM-DD': <bước>, ... } }
/// - `date` + `steps`: ngày gần nhất điện thoại đó đã ghi.
/// - `history`: tổng bước các ngày trước đó (StepController ghi lại khi qua ngày mới).
///
/// Tuần tính từ thứ Hai đến hết hôm nay.
class StepAggregator {
  StepAggregator._();

  static const String stepKind = 'steps';

  static String formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static int _int(Object? v) {
    final n = v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0);
    return n < 0 ? 0 : n;
  }

  static StepRecord fromRows(
    List<Map<String, dynamic>> rows,
    DateTime now, {
    required int goal,
  }) {
    final today = AppDateUtils.dateOnly(now);
    final todayStr = formatDate(today);
    final startOfWeek = AppDateUtils.startOfWeek(today);

    var todaySteps = 0;
    var weeklyTotal = 0;

    for (final row in rows) {
      if (row['kind'] != stepKind) continue;
      final payload = row['payload'];
      if (payload is! Map) continue;

      final dateStr = payload['date'];
      final recordDate = dateStr is String ? DateTime.tryParse(dateStr) : null;
      final rowDay = recordDate == null ? null : AppDateUtils.dateOnly(recordDate);
      final rowKey = rowDay == null ? null : formatDate(rowDay);

      // Ngày ghi gần nhất của điện thoại này
      if (rowDay != null) {
        final steps = _int(payload['steps']);
        if (!rowDay.isBefore(startOfWeek) && !rowDay.isAfter(today)) {
          weeklyTotal += steps;
        }
        if (rowKey == todayStr) todaySteps += steps;
      }

      // Các ngày trước đó trong tuần (không tính lại ngày đã có ở trên)
      final history = payload['history'];
      if (history is Map) {
        for (final entry in history.entries) {
          final key = entry.key;
          if (key is! String || key == rowKey) continue;
          final parsed = DateTime.tryParse(key);
          if (parsed == null) continue;
          final day = AppDateUtils.dateOnly(parsed);
          if (!day.isBefore(startOfWeek) && day.isBefore(today)) {
            weeklyTotal += _int(entry.value);
          }
        }
      }
    }

    return StepRecord(
      date: today,
      steps: todaySteps,
      goal: goal,
      weeklyTotal: weeklyTotal,
    );
  }
}
