import 'package:flutter/material.dart';

/// Màu thương hiệu CỐ ĐỊNH của phần Home (không đổi theo buổi).
/// Đổi tên từ AppColors để không trùng với lib/constants/app_colors.dart của Login.
/// Màu đổi theo buổi (nền, thẻ, chip...) nằm trong PeriodPalette (day_period.dart).
class BrandColors {
  BrandColors._();

  static const Color purple = Color(0xFF6A4CFF);
  static const Color blue = Color(0xFF2D9CFF);

  static const Color orange = Color(0xFFFF8A65); // "Chào ngày mới", thẻ vé
  static const Color navy = Color(0xFF1F2A3C);   // nửa vé xanh đen

  // Chữ nằm trên ô trắng / nền cam (không đổi theo buổi)
  static const Color textPrimary = Color(0xFF111111);
  static const Color textOnDark = Color(0xFFFFFFFF);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
    colors: [purple, blue],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [purple, blue],
  );
}
