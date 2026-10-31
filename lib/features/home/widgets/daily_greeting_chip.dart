import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/brand_colors.dart';

/// Chip cam "Chào ngày mới !" (màu cố định ở mọi buổi)
class DailyGreetingChip extends StatelessWidget {
  const DailyGreetingChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        color: BrandColors.orange,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'Chào ngày mới !',
        style: AppTextStyles.chip.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
