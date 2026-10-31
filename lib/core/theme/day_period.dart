import 'package:flutter/material.dart';

enum DayPeriod {
  morning,
  afternoon,
  evening;

  /// 5h-12h sáng, 12h-18h chiều, còn lại tối.
  static DayPeriod fromTime(DateTime t) {
    final h = t.hour;
    if (h >= 5 && h < 12) return DayPeriod.morning;
    if (h >= 12 && h < 18) return DayPeriod.afternoon;
    return DayPeriod.evening;
  }
}

/// Bảng màu theo buổi, gắn vào Theme qua ThemeExtension.
/// Mã màu là TẠM, thay bằng mã trong Figma.
class PeriodPalette extends ThemeExtension<PeriodPalette> {
  final Color background;
  final Color card;
  final Color chip;
  final Color textPrimary;
  final Color navIconInactive;
  final Color ringTrack;

  const PeriodPalette({
    required this.background,
    required this.card,
    required this.chip,
    required this.textPrimary,
    required this.navIconInactive,
    required this.ringTrack,
  });

  static const morning = PeriodPalette(
    background: Color(0xFFF7F9FC),
    card: Color(0xFFE6EAF1),
    chip: Color(0xFFEFF1F5),
    textPrimary: Color(0xFF111111),
    navIconInactive: Color(0xFF9AA5B8),
    ringTrack: Color(0xFFF0F0F0),
  );

  static const afternoon = PeriodPalette(
    background: Color(0xFFFFF3E0),
    card: Color(0xFFFFE0B2),
    chip: Color(0xFFFFE9CC),
    textPrimary: Color(0xFF111111),
    navIconInactive: Color(0xFFB8A58F),
    ringTrack: Color(0xFFFFF8EE),
  );

  static const evening = PeriodPalette(
    background: Color(0xFF3A3F4B),
    card: Color(0xFF4A505E),
    chip: Color(0xFF454B58),
    textPrimary: Color(0xFFF2F4F8),
    navIconInactive: Color(0xFF8A93A6),
    ringTrack: Color(0xFF5C6270),
  );

  static PeriodPalette of(DayPeriod p) => switch (p) {
        DayPeriod.morning => morning,
        DayPeriod.afternoon => afternoon,
        DayPeriod.evening => evening,
      };

  @override
  PeriodPalette copyWith({
    Color? background,
    Color? card,
    Color? chip,
    Color? textPrimary,
    Color? navIconInactive,
    Color? ringTrack,
  }) =>
      PeriodPalette(
        background: background ?? this.background,
        card: card ?? this.card,
        chip: chip ?? this.chip,
        textPrimary: textPrimary ?? this.textPrimary,
        navIconInactive: navIconInactive ?? this.navIconInactive,
        ringTrack: ringTrack ?? this.ringTrack,
      );

  @override
  PeriodPalette lerp(ThemeExtension<PeriodPalette>? other, double t) {
    if (other is! PeriodPalette) return this;
    return PeriodPalette(
      background: Color.lerp(background, other.background, t)!,
      card: Color.lerp(card, other.card, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      navIconInactive: Color.lerp(navIconInactive, other.navIconInactive, t)!,
      ringTrack: Color.lerp(ringTrack, other.ringTrack, t)!,
    );
  }
}

/// Cách gọi ngắn: context.palette.card
extension PaletteContext on BuildContext {
  PeriodPalette get palette => Theme.of(this).extension<PeriodPalette>()!;
}
