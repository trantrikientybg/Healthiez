import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // không cho tạo đối tượng

  // Màu thương hiệu (gradient header: tím -> xanh dương)
  static const Color purple = Color(0xFF6A4CFF);
  static const Color blue = Color(0xFF2D9CFF);

  // Nền & thẻ
  static const Color background = Color(0xFFF7F9FC); // nền trang
  static const Color card = Color(0xFFE6EAF1);       // thẻ xám xanh nhạt
  static const Color chip = Color(0xFFEFF1F5);       // chip "Tổng quan"
  static const Color ringTrack = Color(0xFFF0F0F0);  // phần chưa đạt của vòng tròn

  // Màu nhấn
  static const Color orange = Color(0xFFFF8A65);     // "Chào ngày mới", thẻ vé
  static const Color navy = Color(0xFF1F2A3C);       // nửa vé xanh đen

  // Chữ & icon
  static const Color textPrimary = Color(0xFF111111);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color iconInactive = Color(0xFF9AA5B8);

  // Gradient dùng chung
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
    colors: [purple, blue],
  );

  // Gradient cho chữ/vòng tròn (tím -> xanh)
  static const LinearGradient accentGradient = LinearGradient(
    colors: [purple, blue],
  );
}