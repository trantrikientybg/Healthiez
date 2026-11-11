import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_controller.dart';

enum AppThemeMode { day, noon, night }

class AppColors extends ChangeNotifier {
  static final AppColors instance = AppColors._();
  AppColors._();

  static AppThemeMode currentTheme = AppThemeMode.day;
  static bool autoRealTimeTheme = true;
  static Timer? _realtimeTimer;

  // Khai báo các màu động hiển thị trên ứng dụng
  static Color primary = const Color(0xFF6844FF);
  static Color primaryLight = const Color(0xFF229FFE);
  static Color background = const Color(0xFFF2F5F9);
  static Color textPrimary = const Color(0xFF1E293B);
  static Color textSecondary = const Color(0xFF64748B);
  static Color tealAccent = const Color(0xFF14B8A6);
  static Color tealLightBg = const Color(0xFFE6F7F5);
  static Color cardBackground = const Color(0xFFFFFFFF);

  // Đường dẫn tệp ảnh núi tương ứng với từng Theme
  static String get mountainImage {
    switch (currentTheme) {
      case AppThemeMode.day:
        return 'assets/images/mountain_day.png';
      case AppThemeMode.noon:
        return 'assets/images/mountain_noon.png';
      case AppThemeMode.night:
        return 'assets/images/mountain_night.png';
    }
  }

  // Gradient chuẩn: Top Left -> Bottom Right
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static Map<String, dynamic>? _rawJson;

  // Khởi tạo và đọc file màu JSON khi chạy ứng dụng
  static Future<void> loadFromPath([String path = 'assets/colors/app_colors.json']) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      _rawJson = jsonDecode(jsonString);

      final prefs = await SharedPreferences.getInstance();
      autoRealTimeTheme = prefs.getBool('auto_realtime_theme') ?? true;
      final savedThemeIndex = prefs.getInt('selected_theme_index') ?? 0;

      if (autoRealTimeTheme) {
        currentTheme = getRealTimeThemeMode();
        ThemeController.instance.setMode(ThemeModeSetting.auto);
      } else {
        currentTheme = AppThemeMode.values[savedThemeIndex.clamp(0, 2)];
        ThemeController.instance.setMode(_getThemeModeSetting(currentTheme));
      }

      applyTheme(currentTheme, notify: false);

      // Khởi chạy bộ đếm thời gian liên tục kiểm tra giờ hệ thống
      _startRealtimeCheckTimer();
    } catch (_) {}
  }

  static ThemeModeSetting _getThemeModeSetting(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.day:
        return ThemeModeSetting.morning;
      case AppThemeMode.noon:
        return ThemeModeSetting.afternoon;
      case AppThemeMode.night:
        return ThemeModeSetting.evening;
    }
  }

  // Bắt đầu bộ đếm tự động kiểm tra giờ hệ thống mỗi 30 giây
  static void _startRealtimeCheckTimer() {
    _realtimeTimer?.cancel();
    _realtimeTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkAndUpdateRealTimeTheme();
    });
  }

  // Kiểm tra giờ thực tế và tự động cập nhật Theme nếu đồng hồ vừa bước sang mốc mới
  static void checkAndUpdateRealTimeTheme() {
    if (autoRealTimeTheme) {
      final realTimeMode = getRealTimeThemeMode();
      if (realTimeMode != currentTheme) {
        setThemeMode(realTimeMode);
      }
    }
  }

  // Tính toán Theme theo thời gian thực (Giờ trên thiết bị)
  // Sáng: 6:00 -> 15:00
  // Chiều: 15:00 -> 22:00
  // Đêm: 22:00 -> 6:00
  static AppThemeMode getRealTimeThemeMode() {
    final hour = DateTime.now().hour;
    if (hour >= 6 && hour < 15) {
      return AppThemeMode.day;
    } else if (hour >= 15 && hour < 22) {
      return AppThemeMode.noon;
    } else {
      return AppThemeMode.night;
    }
  }

  // Bật/Tắt chế độ thay đổi theo thời gian thực
  static void setAutoRealTime(bool auto) async {
    autoRealTimeTheme = auto;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_realtime_theme', auto);

    if (auto) {
      ThemeController.instance.setMode(ThemeModeSetting.auto);
      setThemeMode(getRealTimeThemeMode());
    } else {
      ThemeController.instance.setMode(_getThemeModeSetting(currentTheme));
      instance.notifyListeners();
    }
  }

  // Đổi Theme thủ công (Ngày / Chiều / Đêm)
  static void setThemeMode(AppThemeMode mode) async {
    currentTheme = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selected_theme_index', mode.index);

    if (autoRealTimeTheme) {
      ThemeController.instance.setMode(ThemeModeSetting.auto);
    } else {
      ThemeController.instance.setMode(_getThemeModeSetting(mode));
    }

    applyTheme(mode);
  }

  // Áp dụng bảng màu tương ứng từ JSON
  static void applyTheme(AppThemeMode mode, {bool notify = true}) {
    if (_rawJson == null) return;

    final themeKey = mode.name; // 'day', 'noon', 'night'
    final Map<String, dynamic>? themeData = _rawJson![themeKey];

    if (themeData != null) {
      if (themeData.containsKey('primary')) primary = _hexToColor(themeData['primary']);
      if (themeData.containsKey('primaryLight')) primaryLight = _hexToColor(themeData['primaryLight']);
      if (themeData.containsKey('background')) background = _hexToColor(themeData['background']);
      if (themeData.containsKey('textPrimary')) textPrimary = _hexToColor(themeData['textPrimary']);
      if (themeData.containsKey('textSecondary')) textSecondary = _hexToColor(themeData['textSecondary']);
      if (themeData.containsKey('tealAccent')) tealAccent = _hexToColor(themeData['tealAccent']);
      if (themeData.containsKey('tealLightBg')) tealLightBg = _hexToColor(themeData['tealLightBg']);
      if (themeData.containsKey('cardBackground')) cardBackground = _hexToColor(themeData['cardBackground']);
    }

    if (notify) {
      instance.notifyListeners();
    }
  }

  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
