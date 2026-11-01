import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/brand_colors.dart';
import '../../../core/theme/day_period.dart';
import '../../../screens/mental/mental_data.dart' show Mood;
import '../../../shared/widgets/gradient_text.dart';

/// Thẻ "Hôm nay bạn cảm thấy thế nào": hình ôm, 5 icon cảm xúc, link xem tháng.
class MoodSurveyCard extends StatelessWidget {
  final Mood? selected; // tâm trạng đã chọn hôm nay (null nếu chưa chọn)
  final ValueChanged<Mood> onSelected;
  final VoidCallback? onViewMonth;

  const MoodSurveyCard({
    super.key,
    required this.selected,
    required this.onSelected,
    this.onViewMonth,
  });

  // Thứ tự khớp thiết kế (trái -> phải)
  static const List<Mood> _order = [
    Mood.happy,
    Mood.tired,
    Mood.angry,
    Mood.neutral,
    Mood.cry,
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown, // màn nhỏ thì thu chữ, không xuống dòng
            child: GradientText(
              'Hôm nay bạn cảm thấy thế nào',
              style: AppTextStyles.sectionTitle,
            ),
          ),
          const SizedBox(height: 8),
          SvgPicture.asset(
            'assets/icons/hug.svg',
            height: 64,
            colorFilter: ColorFilter.mode(palette.textPrimary, BlendMode.srcIn),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final m in _order)
                _MoodButton(
                  mood: m,
                  selected: selected == m,
                  dimmed: selected != null && selected != m,
                  iconColor: palette.textPrimary,
                  onTap: () => onSelected(m),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: onViewMonth,
            child: const Text(
              'Xem lại cảm xúc của bạn tháng này',
              style: AppTextStyles.link,
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  final Mood mood;
  final bool selected;
  final bool dimmed;
  final Color iconColor;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.selected,
    required this.dimmed,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: mood.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? BrandColors.purple.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: selected ? BrandColors.purple : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: AnimatedScale(
              scale: selected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Opacity(
                opacity: dimmed ? 0.45 : 1.0,
                // Tô lại màu để hợp cả nền sáng lẫn nền tối
                child: Image.asset(
                  mood.asset,
                  width: 36,
                  height: 36,
                  color: iconColor,
                  colorBlendMode: BlendMode.srcIn,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}