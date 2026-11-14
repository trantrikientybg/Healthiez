import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/sleep/sleep_logic.dart';
import '../../data/sleep/sleep_models.dart';
import '../../data/sleep/sleep_store.dart';
import '../../data/sleep/sleep_sync.dart';

/// Trạng thái màn Chế độ ngủ. Mọi thay đổi được lưu ngay vào bộ nhớ,
/// để không mất dữ liệu nếu app bị hệ thống tắt giữa đêm.
class SleepController extends ChangeNotifier {
  SleepController({
    SleepStore? store,
    DateTime Function()? now,
    SleepSyncService? sync,
  })  : _store = store ?? SleepStore(),
        _now = now ?? DateTime.now {
    _sync = sync ?? SleepSyncService.forCurrentUser(_store, now: _now);
  }

  final SleepStore _store;
  final DateTime Function() _now;
  late final SleepSyncService? _sync; // null nếu chưa đăng nhập

  SleepData _data = const SleepData();
  Future<void> _pendingSave = Future.value();
  bool _loaded = false;

  /// Kết quả của lần kết thúc gần nhất (để hiện màn tóm tắt).
  SleepEntry? lastFinished;

  bool get loaded => _loaded;
  SleepSession? get session => _data.active;
  SleepPhase? get phase => _data.active?.phase;

  Future<void> load() async {
    _data = SleepLogic.settle(await _store.load(), _now());
    _loaded = true;
    notifyListeners();
    _save();
  }

  void begin() {
    lastFinished = null;
    _apply(SleepLogic.begin(_data, _now()));
  }

  /// App rời khỏi màn hình (màn hình tắt): bắt đầu đếm.
  void screenOff() => _apply(SleepLogic.screenOff(_data, _now()));

  /// App quay lại (mở máy): tạm dừng đồng hồ.
  void screenOn() => _apply(SleepLogic.screenOn(_data, _now()));

  void cancel() => _apply(SleepLogic.cancel(_data));

  /// Kết thúc và lưu giấc ngủ. Trả về kết quả (null nếu chưa ngủ được phút nào).
  SleepEntry? finish() {
    final (data, entry) = SleepLogic.finish(_data, _now());
    lastFinished = entry;
    _apply(data);

    // Giấc ngủ vừa lưu trên máy: đẩy lên DB ở nền (thất bại thì lần mở app sau thử lại)
    final sync = _sync;
    if (entry != null && sync != null) {
      unawaited(_pendingSave.then((_) => sync.sync()).catchError((_) {}));
    }
    return entry;
  }

  void _apply(SleepData next) {
    if (identical(next, _data)) return;
    _data = next;
    notifyListeners();
    _save();
  }

  void _save() {
    // Ghi tuần tự, luôn ghi bản mới nhất
    _pendingSave = _pendingSave.then((_) => _store.save(_data));
  }
}
