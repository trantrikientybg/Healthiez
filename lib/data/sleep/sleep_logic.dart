import 'sleep_models.dart';

/// Các thao tác trên dữ liệu giấc ngủ. Hàm thuần túy (không đọc giờ hệ thống,
/// không đọc/ghi bộ nhớ) nên dễ kiểm thử.
class SleepLogic {
  SleepLogic._();

  /// Một lần tắt màn hình không được tính quá dài (phòng khi app bị tắt giữa đêm).
  static const Duration maxSegment = Duration(hours: 14);

  /// Phiên mở quá lâu mà quên kết thúc thì tự kết thúc.
  static const Duration autoFinishAfter = Duration(hours: 20);

  /// Bắt đầu một phiên mới (chờ tắt màn hình).
  static SleepData begin(SleepData d, DateTime now) => d.copyWith(
        active: SleepSession(
          startedAt: now,
          accumulated: Duration.zero,
          lastEventAt: now,
        ),
      );

  /// Màn hình tắt: bắt đầu đếm.
  static SleepData screenOff(SleepData d, DateTime now) {
    final s = d.active;
    if (s == null || s.runningSince != null) return d;
    return d.copyWith(active: s.copyWith(runningSince: now, lastEventAt: now));
  }

  /// Mở máy: chốt đoạn đang đếm và tạm dừng.
  static SleepData screenOn(SleepData d, DateTime now) {
    final s = d.active;
    if (s == null || s.runningSince == null) return d;
    var segment = now.difference(s.runningSince!);
    if (segment.isNegative) segment = Duration.zero;
    if (segment > maxSegment) segment = maxSegment;
    return d.copyWith(
      active: s.copyWith(
        accumulated: s.accumulated + segment,
        clearRunningSince: true,
        lastEventAt: now,
      ),
    );
  }

  /// Hủy phiên hiện tại, không lưu gì.
  static SleepData cancel(SleepData d) => d.copyWith(clearActive: true);

  /// Kết thúc phiên: lưu kết quả vào đúng "ngày ngủ". Trả về dữ liệu mới và kết quả
  /// (null nếu chưa ngủ được phút nào).
  static (SleepData, SleepEntry?) finish(SleepData d, DateTime now) {
    final closed = screenOn(d, now); // đóng đoạn đang đếm (nếu có)
    final s = closed.active;
    if (s == null) return (closed, null);
    if (s.accumulated <= Duration.zero) return (cancel(closed), null);

    final entry = SleepEntry(
      bedTime: s.startedAt,
      wakeTime: s.lastEventAt, // lần mở máy cuối cùng = lúc thức dậy
      asleep: s.accumulated,
    );
    final key = SleepDay.key(SleepDay.of(s.startedAt));
    final history = Map<String, SleepEntry>.from(closed.history);
    history[key] = history.containsKey(key) ? history[key]!.merge(entry) : entry;

    // Ngày ngủ này cần được đẩy lên DB
    final pending = Set<String>.from(closed.pending)..add(key);

    // Chỉ giữ vài ngày gần nhất
    final keys = history.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final old in keys.skip(SleepData.keepDays)) {
      history.remove(old);
      pending.remove(old);
    }
    return (
      closed.copyWith(clearActive: true, history: history, pending: pending),
      entry,
    );
  }

  /// Chốt phiên bị bỏ dở khi mở lại app (ví dụ app bị hệ thống tắt giữa đêm):
  /// coi như người dùng thức dậy lúc mở app.
  static SleepData settle(SleepData d, DateTime now) {
    var out = screenOn(d, now);
    final s = out.active;
    if (s != null && now.difference(s.startedAt) > autoFinishAfter) {
      out = finish(out, now).$1;
    }
    return out;
  }
}
