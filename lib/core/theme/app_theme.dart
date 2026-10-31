import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.purple,
        primary: AppColors.purple,
        secondary: AppColors.blue,
        tertiary: AppColors.orange,
        surface: AppColors.background,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.chip,
        indicatorColor: Colors.transparent, // thiết kế không có nền tròn quanh icon
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.navLabel),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 32,
            color: selected ? AppColors.blue : AppColors.iconInactive,
          );
        }),
      ),
    );
  }
}