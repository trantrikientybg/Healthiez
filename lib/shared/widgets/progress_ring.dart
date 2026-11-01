import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/day_period.dart';

/// Vòng tròn hiển thị % đạt được, số % nằm giữa.
class ProgressRing extends StatelessWidget {
  final double percent; // 0.0 - 1.0
  final double size;
  final double strokeWidth;

  const ProgressRing({
    super.key,
    required this.percent,
    this.size = 96,
    this.strokeWidth = 16,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _RingPainter(
              percent: percent,
              strokeWidth: strokeWidth,
              trackColor: palette.ringTrack,
            ),
          ),
          Text(
            '${(percent * 100).round()}%',
            style: AppTextStyles.ringPercent.copyWith(color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double percent;
  final double strokeWidth;
  final Color trackColor;

  _RingPainter({
    required this.percent,
    required this.strokeWidth,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    if (percent <= 0) return; // 0% thì không vẽ, tránh hiện chấm tròn

    final progress = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [BrandColors.purple, BrandColors.blue],
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);

    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, progress);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.percent != percent ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor;
}
