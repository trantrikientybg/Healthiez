import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/day_period.dart';

/// Chip bo tròn: "Tổng quan", "Gợi ý hằng ngày"...
class SectionChip extends StatelessWidget {
  final String label;

  const SectionChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.chip.copyWith(color: palette.textPrimary),
      ),
    );
  }
}
