import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'sleep_models.dart';

abstract class SleepStorage {
  Future<String?> read();
  Future<void> write(String value);
}

/// Lưu trên máy bằng SharedPreferences, mỗi tài khoản một khóa riêng
/// ('sleep.v1.<user_id>') để hai tài khoản dùng chung một máy không lẫn dữ liệu.
class PrefsSleepStorage implements SleepStorage {
  PrefsSleepStorage({String? userId}) : _key = '$_prefix.${userId ?? 'guest'}';

  static const String _prefix = 'sleep.v1';

  /// Khóa của phiên bản cũ (chung cho mọi tài khoản).
  static const String _legacyKey = 'sleep.v1';

  final String _key;

  @override
  Future<String?> read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final own = prefs.getString(_key);
      if (own != null) return own;

      // Chuyển dữ liệu của bản cũ cho tài khoản đầu tiên mở lại app
      final legacy = prefs.getString(_legacyKey);
      if (legacy != null) {
        await prefs.setString(_key, legacy);
        await prefs.remove(_legacyKey);
        return legacy;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String value) async {
    try {
      await (await SharedPreferences.getInstance()).setString(_key, value);
    } catch (_) {}
  }
}

/// Lưu trong bộ nhớ (dùng cho kiểm thử).
class MemorySleepStorage implements SleepStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String v) async => value = v;
}

class SleepStore {
  SleepStore({SleepStorage? storage})
      : _storage = storage ?? PrefsSleepStorage(userId: currentUserId());

  /// Id người dùng đang đăng nhập (null nếu chưa đăng nhập hoặc chưa khởi tạo Supabase).
  static String? currentUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  final SleepStorage _storage;

  // Mọi lần đọc/ghi đi qua một hàng đợi chung: các thao tác "đọc rồi sửa rồi ghi"
  // không ghi đè lên nhau (ví dụ đồng bộ DB chạy cùng lúc với màn Đi ngủ).
  static Future<void> _lock = Future.value();

  Future<T> _serial<T>(Future<T> Function() task) {
    final run = _lock.then((_) => task());
    _lock = run.then<void>((_) {}, onError: (_) {});
    return run;
  }

  Future<SleepData> load() =>
      _serial(() async => SleepData.decode(await _storage.read()));

  Future<void> save(SleepData data) =>
      _serial(() => _storage.write(data.encode()));

  /// Đọc dữ liệu mới nhất, áp dụng [change], ghi lại, rồi trả về kết quả.
  Future<SleepData> mutate(SleepData Function(SleepData latest) change) {
    return _serial(() async {
      final next = change(SleepData.decode(await _storage.read()));
      await _storage.write(next.encode());
      return next;
    });
  }
}
