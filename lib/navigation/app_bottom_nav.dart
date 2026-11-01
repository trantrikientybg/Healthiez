import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_text_styles.dart';
import '../core/theme/brand_colors.dart';
import '../core/theme/day_period.dart';

class _NavItemData {
  final String label;
  final String iconAsset;
  const _NavItemData(this.label, this.iconAsset);
}

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  // Thứ tự phải khớp với _screens trong main_shell.dart
  static const List<_NavItemData> _items = [
    _NavItemData('Thể chất', 'assets/icons/nav_physical.svg'),
    _NavItemData('Trang chủ', 'assets/icons/nav_home.svg'),
    _NavItemData('Tinh thần', 'assets/icons/nav_mental.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Container(
      decoration: BoxDecoration(
        color: palette.chip,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    selected: i == currentIndex,
                    inactiveColor: palette.navIconInactive,
                    textColor: palette.textPrimary,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _NavItemData data;
  final bool selected;
  final Color inactiveColor;
  final Color textColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.inactiveColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveGradient = LinearGradient(
      colors: [inactiveColor, inactiveColor],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) =>
                (selected ? BrandColors.accentGradient : inactiveGradient)
                    .createShader(bounds),
            child: SvgPicture.asset(data.iconAsset, width: 36, height: 36),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            style: AppTextStyles.navLabel.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
