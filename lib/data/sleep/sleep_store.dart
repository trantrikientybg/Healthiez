import 'package:shared_preferences/shared_preferences.dart';
import 'sleep_models.dart';

abstract class SleepStorage {
  Future<String?> read();
  Future<void> write(String value);
}

/// Lưu trên máy bằng SharedPreferences.
class PrefsSleepStorage implements SleepStorage {
  static const String _key = 'sleep.v1';

  @override
  Future<String?> read() async {
    try {
      return (await SharedPreferences.getInstance()).getString(_key);
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
  SleepStore({SleepStorage? storage}) : _storage = storage ?? PrefsSleepStorage();

  final SleepStorage _storage;

  Future<SleepData> load() async => SleepData.decode(await _storage.read());

  Future<void> save(SleepData data) => _storage.write(data.encode());
}
