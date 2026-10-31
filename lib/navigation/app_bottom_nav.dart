import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.chip,
        // Bo cong hai góc trên giống thiết kế
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000), // đen, độ mờ ~20%
            blurRadius: 12,
            offset: Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false, // chỉ chừa chỗ cho thanh cử chỉ phía dưới
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Row(
            children: [
              for (int i = 0; i < _items.length; i++)
                Expanded(
                  child: _NavItem(
                    data: _items[i],
                    selected: i == currentIndex,
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
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  static const LinearGradient _inactiveGradient = LinearGradient(
    colors: [AppColors.iconInactive, AppColors.iconInactive],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, // bấm vào vùng trống cũng ăn
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ShaderMask tô màu/gradient lên hình dạng của icon SVG
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => (selected
                ? AppColors.accentGradient
                : _inactiveGradient)
                .createShader(bounds),
            child: SvgPicture.asset(data.iconAsset, width: 36, height: 36),
          ),
          const SizedBox(height: 4),
          Text(data.label, style: AppTextStyles.navLabel),
        ],
      ),
    );
  }
}