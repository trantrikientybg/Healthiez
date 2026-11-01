import 'package:flutter/material.dart';
import '../../core/theme/day_period.dart';

/// Chữ có gradient. Mặc định dùng gradient tiêu đề theo buổi.
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Gradient? gradient;

  const GradientText(
      this.text, {
        super.key,
        required this.style,
        this.gradient,
      });

  @override
  Widget build(BuildContext context) {
    final g = gradient ?? context.palette.titleGradient;
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => g.createShader(bounds),
      // Chữ gốc phải màu trắng để mặt nạ tô đúng
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}