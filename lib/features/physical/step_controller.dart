import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepController extends ChangeNotifier {
  StepController({
    DateTime Function()? now,
    Future<String?> Function()? read,
    Future<bool> Function(String)? write,
    Future<Stream<int>> Function()? connect,
  }) : _now = now ?? DateTime.now,
       _read = read ?? _readPreferences,
       _write = write ?? _writePreferences,
       _connect = connect ?? _connectSensor;

  static const storageKey = 'healthiez.steps.v1';
  final DateTime Function() _now;
  final Future<String?> Function() _read;
  final Future<bool> Function(String) _write;
  final Future<Stream<int>> Function() _connect;
  StreamSubscription<int>? _subscription;
  Future<void> _pending = Future.value();
  bool _disposed = false;
  bool ready = false;
  bool busy = false;
  bool tracking = false;
  int steps = 0;
  // Past days' totals ('YYYY-MM-DD' → steps), kept so a new day doesn't erase them.
  // ponytail: unbounded (~8 KB/year); prune or move to rows if it ever matters.
  Map<String, int> history = {};
  int? _last;
  String? _day;
  String? error;

  static String _date(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static Future<String?> _readPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getString(storageKey);
  }

  static Future<bool> _writePreferences(String value) async =>
      (await SharedPreferences.getInstance()).setString(storageKey, value);

  static Future<Stream<int>> _connectSensor() async {
    if (const bool.fromEnvironment('FAKE_PEDOMETER')) {
      // Debug only: simulated cumulative sensor (~1 step/s, with pauses).
      final random = Random();
      var total = 120000;
      return Stream.periodic(
        const Duration(seconds: 2),
        (_) => total += random.nextInt(4),
      );
    }
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError('Step sensor requires a phone');
    }
    final permission =
        await (defaultTargetPlatform == TargetPlatform.android
                ? Permission.activityRecognition
                : Permission.sensors)
            .request();
    if (!permission.isGranted) {
      throw StateError('Motion permission denied');
    }
    return Pedometer.stepCountStream.map((event) => event.steps);
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy || ready || _disposed) return;
    busy = true;
    error = null;
    _changed();
    try {
      final raw = await _read();
      if (_disposed) return;
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        final count = data['steps'] as int;
        final last = data['last'] as int;
        final day = data['date'] as String;
        final parsed = DateTime.tryParse(day);
        if (count < 0 || last < 0 || parsed == null || _date(parsed) != day) {
          throw const FormatException('Invalid step record');
        }
        steps = count;
        // Paused: steps walked while stopped must not count on the next start.
        _last = data['paused'] == true ? null : last;
        _day = day;
        history = {
          for (final entry
              in ((data['history'] as Map<String, dynamic>?) ?? {}).entries)
            entry.key: entry.value as int,
        };
      }
      ready = true;
      refreshDay();
    } catch (_) {
      error = 'Không thể đọc bước chân đã lưu. Vui lòng thử lại.';
    } finally {
      busy = false;
      _changed();
    }
  }

  void refreshDay() {
    if (!ready || _disposed) return;
    final today = _date(_now());
    if (_day == today) return;
    if (_day != null && steps > 0) history[_day!] = steps;
    _day = today;
    steps = 0;
    // A cumulative reading cannot split steps across an unobserved midnight.
    _last = null;
    _changed();
  }

  Future<void> start() async {
    if (!ready || busy || tracking || _disposed) return;
    busy = true;
    error = null;
    _changed();
    try {
      await _subscription?.cancel();
      final stream = await _connect();
      if (_disposed) return;
      tracking = true;
      _subscription = stream.listen(
        (count) {
          final day = _date(_now());
          _pending = _pending.then((_) => _record(count, day));
        },
        onError: (Object _) => _sensorStopped(),
        onDone: _sensorStopped,
        cancelOnError: true,
      );
    } on UnsupportedError {
      error = 'Đếm bước chân chỉ hỗ trợ điện thoại Android và iPhone.';
    } catch (_) {
      error = 'Không thể bật cảm biến. Kiểm tra quyền vận động trong Cài đặt rồi thử lại.';
    } finally {
      busy = false;
      _changed();
    }
  }

  Future<void> stop() async {
    if (!tracking || _disposed) return;
    await _subscription?.cancel();
    _subscription = null;
    tracking = false;
    _changed();
    // Queued after in-flight readings so none of them re-set the baseline.
    _pending = _pending.then((_) async {
      if (_disposed) return;
      refreshDay();
      _last = null;
      try {
        if (!await _write(_payload(_day!, steps, 0, paused: true))) {
          throw StateError('Step write failed');
        }
      } catch (_) {
        error = 'Không thể lưu trạng thái dừng. Vui lòng thử lại.';
        _changed();
      }
    });
    await _pending;
  }

  String _payload(String day, int count, int last, {bool paused = false}) =>
      jsonEncode({
        'date': day,
        'steps': count,
        'last': last,
        'history': history,
        if (paused) 'paused': true,
      });

  void _sensorStopped() {
    _subscription = null;
    tracking = false;
    error = 'Không đọc được cảm biến. Kiểm tra quyền vận động và cảm biến của điện thoại rồi thử lại.';
    _changed();
  }

  Future<void> _record(int count, String day) async {
    if (_disposed || count < 0) return;
    refreshDay();
    if (day != _day) return;
    final delta = _last == null || count < _last! ? 0 : count - _last!;
    if (count == _last) return;
    final next = steps + delta;
    try {
      final saved = await _write(_payload(day, next, count));
      if (!saved) throw StateError('Step write failed');
      if (_disposed) return;
      refreshDay();
      if (_day != day) return;
      steps = next;
      _last = count;
      error = null;
    } catch (_) {
      error = 'Không thể lưu bước chân. Sẽ thử lại khi cảm biến cập nhật.';
    }
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    super.dispose();
  }
}
