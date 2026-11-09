import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tiếng chuông của màn thiền (assets/sounds/bell_start.wav, bell_end.wav).
/// Mọi lỗi âm thanh đều được bỏ qua, không bao giờ làm hỏng buổi thiền.
class MeditationSounds {
  MeditationSounds() : _player = AudioPlayer();

  static const String _prefKey = 'meditation.sound_enabled';
  static const String _startAsset = 'sounds/bell_start.wav';
  static const String _endAsset = 'sounds/bell_end.wav';

  final AudioPlayer _player;

  /// Bật/tắt tiếng chuông (được nhớ cho các lần sau).
  bool enabled = true;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_prefKey) ?? true;
    } catch (_) {
      // dùng mặc định: bật
    }
  }

  Future<void> setEnabled(bool value) async {
    enabled = value;
    try {
      if (!value) await _player.stop();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
    } catch (_) {}
  }

  Future<void> playStart() => _play(_startAsset);

  Future<void> playEnd() => _play(_endAsset);

  Future<void> _play(String asset) async {
    if (!enabled) return;
    try {
      await _player.stop(); // tiếng cũ đang ngân thì dừng trước khi phát tiếng mới
      await _player.play(AssetSource(asset));
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player.dispose();
    } catch (_) {}
  }
}
