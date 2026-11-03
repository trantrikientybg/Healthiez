import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get themeData => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          surface: AppColors.background,
        ),
        scaffoldBackgroundColor: AppColors.background,
        useMaterial3: true,
      );
}
