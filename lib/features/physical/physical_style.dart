import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/day_period.dart';
import '../../shared/widgets/gradient_text.dart';

/// Material overrides so forms, cards and buttons follow the Home period palette.
ThemeData physicalTheme(ThemeData base, PeriodPalette palette) {
  final dark = palette.textPrimary.computeLuminance() > 0.5;
  final scheme = ColorScheme.fromSeed(
    seedColor: BrandColors.purple,
    brightness: dark ? Brightness.dark : Brightness.light,
  ).copyWith(primary: BrandColors.purple, secondary: BrandColors.blue);
  final rounded = OutlineInputBorder(
    borderRadius: BorderRadius.circular(20),
    borderSide: BorderSide.none,
  );
  return base.copyWith(
    colorScheme: scheme,
    textTheme: (dark ? ThemeData.dark() : ThemeData.light()).textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.chip,
      labelStyle: TextStyle(color: palette.textPrimary),
      border: rounded,
      enabledBorder: rounded,
      focusedBorder: rounded.copyWith(
        borderSide: const BorderSide(color: BrandColors.purple, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.purple,
        foregroundColor: BrandColors.textOnDark,
        minimumSize: const Size(48, 48),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.textAccent),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: BrandColors.blue,
      linearTrackColor: palette.ringTrack,
      linearMinHeight: 8,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
    ),
  );
}

/// Icon bubble + gradient title, shared by the physical cards.
class PhysicalCardTitle extends StatelessWidget {
  const PhysicalCardTitle(this.icon, this.title, {super.key});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      CircleAvatar(
        backgroundColor: BrandColors.purple.withValues(alpha: 0.15),
        child: Icon(icon, color: context.palette.textAccent),
      ),
      const SizedBox(width: 12),
      Flexible(child: GradientText(title, style: AppTextStyles.sectionTitle)),
    ],
  );
}
