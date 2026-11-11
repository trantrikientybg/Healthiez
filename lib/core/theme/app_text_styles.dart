import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'brand_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle get titleLarge => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get titleMedium => TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
      );

  static TextStyle get caption => TextStyle(
        fontSize: 12,
        color: AppColors.textSecondary,
      );

  static const TextStyle greeting = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
  );

  static const TextStyle username = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: BrandColors.purple,
  );

  static const TextStyle badge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: BrandColors.textPrimary,
  );

  static const TextStyle chip = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: BrandColors.textPrimary,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BrandColors.purple,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: BrandColors.purple,
  );

  static const TextStyle metricLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
  );

  static const TextStyle metricValue = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BrandColors.purple,
  );

  static const TextStyle metricValue2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: BrandColors.purple,
  );

  static const TextStyle ringPercent = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: BrandColors.textPrimary,
  );

  static const TextStyle link = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: BrandColors.purple,
    decoration: TextDecoration.underline,
    decorationColor: BrandColors.purple,
  );

  static const TextStyle mentalSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: BrandColors.navy,
    decorationColor: BrandColors.navy,
  );

  static const TextStyle index = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: BrandColors.textPrimary,
    decorationColor: BrandColors.textPrimary,
  );

  static const TextStyle happiness = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: BrandColors.textPrimary,
    decorationColor: BrandColors.textPrimary,
  );

  static const TextStyle ticketTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: BrandColors.textPrimary,
  );

  static const TextStyle ticketOnDark = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: BrandColors.textOnDark,
  );

  static const TextStyle navLabel = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: BrandColors.textPrimary,
  );
}
