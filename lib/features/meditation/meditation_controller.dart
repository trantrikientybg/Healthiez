import 'dart:async';
import 'package:flutter/foundation.dart';

enum MeditationStatus { idle, running, paused, finished }

/// Bộ đếm giờ thiền.
/// Tính thời gian còn lại theo MỐC KẾT THÚC (không đếm số lần timer chạy), nên vẫn
/// đúng khi màn hình tắt hoặc app bị đưa xuống nền rồi quay lại (gọi tick()).
class MeditationController extends ChangeNotifier {
  MeditationController({DateTime Function()? now, int minutes = 10})
      : _now = now ?? DateTime.now,
        _minutes = minutes,
        _remaining = Duration(minutes: minutes);

  final DateTime Function() _now;
  Timer? _timer;

  int _minutes;
  Duration _remaining;
  DateTime? _endsAt;
  MeditationStatus _status = MeditationStatus.idle;

  int get minutes => _minutes;
  Duration get total => Duration(minutes: _minutes);
  Duration get remaining => _remaining;
  MeditationStatus get status => _status;

  bool get isRunning => _status == MeditationStatus.running;
  bool get isActive =>
      _status == MeditationStatus.running || _status == MeditationStatus.paused;

  /// Số giây còn lại, làm tròn lên (đồng hồ hiện 00:01 cho tới khi hết hẳn).
  int get remainingSeconds => (_remaining.inMilliseconds + 999) ~/ 1000;

  /// Phần đã trôi qua, từ 0.0 đến 1.0.
  double get elapsedFraction {
    final t = total.inMilliseconds;
    if (t == 0) return 0;
    return (1 - _remaining.inMilliseconds / t).clamp(0.0, 1.0);
  }

  /// Chọn thời lượng (chỉ khi chưa bắt đầu hoặc đã xong).
  void setMinutes(int minutes) {
    if (isActive || minutes <= 0) return;
    _minutes = minutes;
    _remaining = Duration(minutes: minutes);
    _status = MeditationStatus.idle;
    notifyListeners();
  }

  /// Bắt đầu từ đầu (từ trạng thái chờ hoặc đã xong).
  void start() {
    if (isActive) return;
    _remaining = total;
    _run();
  }

  void pause() {
    if (!isRunning) return;
    tick(); // cập nhật lần cuối rồi mới dừng
    if (!isRunning) return; // vừa hết giờ
    _timer?.cancel();
    _status = MeditationStatus.paused;
    notifyListeners();
  }

  void resume() {
    if (_status != MeditationStatus.paused) return;
    _run();
  }

  /// Hủy buổi thiền, về lại đủ thời lượng đã chọn.
  void reset() {
    _timer?.cancel();
    _endsAt = null;
    _remaining = total;
    _status = MeditationStatus.idle;
    notifyListeners();
  }

  /// Cập nhật thời gian còn lại. Gọi định kỳ và mỗi khi app quay lại từ nền.
  void tick() {
    if (!isRunning) return;
    final left = _endsAt!.difference(_now());
    if (left <= Duration.zero) {
      _timer?.cancel();
      _remaining = Duration.zero;
      _status = MeditationStatus.finished;
    } else {
      _remaining = left;
    }
    notifyListeners();
  }

  void _run() {
    _endsAt = _now().add(_remaining);
    _status = MeditationStatus.running;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => tick());
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
