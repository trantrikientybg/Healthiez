import 'package:flutter/foundation.dart';
import 'day_period.dart';

/// Chế độ nền: tự động theo giờ, hoặc chọn tay.
enum ThemeModeSetting { auto, morning, afternoon, evening }

/// Nơi DUY NHẤT quyết định buổi đang dùng.
/// Màn Settings sau này chỉ cần gọi ThemeController.instance.setMode(...).
class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  ThemeModeSetting _mode = ThemeModeSetting.auto;
  ThemeModeSetting get mode => _mode;

  DayPeriod get period => switch (_mode) {
        ThemeModeSetting.auto => DayPeriod.fromTime(DateTime.now()),
        ThemeModeSetting.morning => DayPeriod.morning,
        ThemeModeSetting.afternoon => DayPeriod.afternoon,
        ThemeModeSetting.evening => DayPeriod.evening,
      };

  void setMode(ThemeModeSetting mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
