import '../../core/constants/app_constants.dart';
import '../models/sleep_record.dart';
import '../sleep/sleep_logic.dart';
import '../sleep/sleep_models.dart';
import '../sleep/sleep_store.dart';
import '../sleep/sleep_sync.dart';

/// Đọc giấc ngủ cho Home.
class SleepRepository {
  SleepRepository({
    SleepStore? store,
    DateTime Function()? now,
    SleepSyncService? sync,
  })  : _store = store ?? SleepStore(),
        _now = now ?? DateTime.now {
    _sync = sync ?? SleepSyncService.forCurrentUser(_store, now: _now);
  }

  final SleepStore _store;
  final DateTime Function() _now;
  late final SleepSyncService? _sync;

  /// Đọc NHANH từ dữ liệu trên máy (không chờ mạng).
  /// Giấc ngủ gần nhất: ưu tiên "ngày ngủ" hiện tại (ví dụ 7h sáng thì là đêm vừa rồi),
  /// chưa có thì lấy ngày ngủ trước đó. Không có dữ liệu thì trả về null.
  Future<SleepRecord?> getLastNightSleep() async {
    final now = _now();
    // Chốt phiên bị bỏ dở (nếu có) rồi lưu lại
    final data = await _store.mutate((d) => SleepLogic.settle(d, now));
    return _pick(data, now);
  }

  /// Đồng bộ với Supabase (đẩy lên + kéo về) rồi đọc lại.
  /// Chưa đăng nhập hoặc mất mạng thì chỉ trả về dữ liệu trên máy.
  Future<SleepRecord?> syncAndGetLastNightSleep() async {
    await _sync?.sync();
    return getLastNightSleep();
  }

  SleepRecord? _pick(SleepData data, DateTime now) {
    final today = SleepDay.of(now);
    final yesterday = DateTime(today.year, today.month, today.day - 1);
    for (final day in [today, yesterday]) {
      final e = data.history[SleepDay.key(day)];
      if (e != null) {
        return SleepRecord(
          date: day,
          bedTime: e.bedTime,
          wakeTime: e.wakeTime,
          goalHours: AppConstants.sleepGoalHours,
          asleep: e.asleep,
        );
      }
    }
    return null;
  }
}
