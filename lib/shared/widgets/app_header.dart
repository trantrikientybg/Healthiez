import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/theme/brand_colors.dart';

/// Nền gradient tím -> xanh, đáy lượn sóng, logo ở góc trên trái.
/// [child] là nội dung nằm dưới logo (ví dụ avatar + lời chào).
class AppHeader extends StatelessWidget {
  final Widget child;

  const AppHeader({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top; // thanh trạng thái

    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(gradient: BrandColors.headerGradient),
        padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 44),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset('assets/icons/logo.svg', height: 26),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

/// Cắt đáy thành đường lượn sóng.
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 22)
      ..quadraticBezierTo(
        size.width * 0.25, size.height,
        size.width * 0.5, size.height - 14,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height - 28,
        size.width, size.height - 8,
      )
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
