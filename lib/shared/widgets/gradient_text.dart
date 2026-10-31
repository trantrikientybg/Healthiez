import 'package:flutter/material.dart';
import '../../core/theme/brand_colors.dart';

/// Chữ có gradient (mặc định tím -> xanh).
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    required this.style,
    this.gradient = BrandColors.accentGradient,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(bounds),
      // Chữ gốc phải màu trắng để mặt nạ tô đúng
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}
