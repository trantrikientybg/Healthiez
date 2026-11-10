import '../../core/constants/app_constants.dart';
import '../models/sleep_record.dart';
import '../sleep/sleep_logic.dart';
import '../sleep/sleep_models.dart';
import '../sleep/sleep_store.dart';

/// Đọc giấc ngủ cho Home.
class SleepRepository {
  SleepRepository({SleepStore? store, DateTime Function()? now})
      : _store = store ?? SleepStore(),
        _now = now ?? DateTime.now;

  final SleepStore _store;
  final DateTime Function() _now;

  /// Giấc ngủ gần nhất: ưu tiên "ngày ngủ" hiện tại (ví dụ 7h sáng thì là đêm vừa rồi),
  /// nếu chưa có thì lấy ngày ngủ trước đó. Không có dữ liệu thì trả về null.
  Future<SleepRecord?> getLastNightSleep() async {
    final now = _now();

    // Chốt phiên bị bỏ dở (nếu có) rồi lưu lại
    final loaded = await _store.load();
    final data = SleepLogic.settle(loaded, now);
    if (data.encode() != loaded.encode()) await _store.save(data);

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
