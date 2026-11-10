import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppColors {
  // Mã màu mặc định khởi tạo
  static Color primary = const Color(0xFF6844FF);
  static Color primaryLight = const Color(0xFF229FFE);
  static Color background = const Color(0xFFF8FAFC);
  static Color textPrimary = const Color(0xFF1E293B);
  static Color textSecondary = const Color(0xFF64748B);

  // Gradient chuẩn: Top Left (Primary #6844FF) -> Bottom Right (Primary Light #229FFE)
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primary, primaryLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Hàm load màu động từ tệp JSON
  static Future<void> loadFromPath([String path = 'assets/colors/app_colors.json']) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);

      if (jsonMap.containsKey('primary')) {
        primary = _hexToColor(jsonMap['primary']);
      }
      if (jsonMap.containsKey('primaryLight')) {
        primaryLight = _hexToColor(jsonMap['primaryLight']);
      }
      if (jsonMap.containsKey('background')) {
        background = _hexToColor(jsonMap['background']);
      }
      if (jsonMap.containsKey('textPrimary')) {
        textPrimary = _hexToColor(jsonMap['textPrimary']);
      }
      if (jsonMap.containsKey('textSecondary')) {
        textSecondary = _hexToColor(jsonMap['textSecondary']);
      }
    } catch (_) {}
  }

  // Chuyển mã Hex String dạng "#6844FF" thành đối tượng Color của Flutter
  static Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }
}
