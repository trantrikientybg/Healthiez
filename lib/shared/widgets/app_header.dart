import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/brand_colors.dart';

class AppHeader extends StatelessWidget {
  final Widget? child;
  final double? height;
  final Widget? extraContent;
  final VoidCallback? onSettingsPressed;

  const AppHeader({
    super.key,
    this.child,
    this.height,
    this.extraContent,
    this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      final topInset = MediaQuery.of(context).padding.top;

      return ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          width: double.infinity,
          decoration: const BoxDecoration(gradient: BrandColors.headerGradient),
          padding: EdgeInsets.fromLTRB(20, topInset + 8, 12, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/icons/logo.svg',
                    height: 26,
                    errorBuilder: (context, error, stackTrace) {
                      return const SizedBox();
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.settings_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                    tooltip: 'Cài đặt',
                    onPressed: () async {
                      if (onSettingsPressed != null) {
                        onSettingsPressed!();
                      } else {
                        await Navigator.pushNamed(context, '/settings');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              child!,
            ],
          ),
        ),
      );
    }

    return ClipPath(
      clipper: _WaveClipper(),
      child: Container(
        height: height ?? 240,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 10),
              Image.asset(
                AppAssets.logo,
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Health',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Icon(Icons.fitness_center, color: Colors.white, size: 28),
                      Text(
                        'ez',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (extraContent != null) ...[
                const SizedBox(height: 12),
                extraContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

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
