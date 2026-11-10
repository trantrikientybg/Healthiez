import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/day_period.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/progress_ring.dart';

/// Một dòng thông tin trong thẻ, ví dụ: "Tích lũy tuần: 27500 bước"
class MetricLine {
  final String label;  // chữ thường phía trước (có thể rỗng)
  final String value;  // số liệu màu tím, in đậm
  final String suffix; // đơn vị phía sau (có thể rỗng)

  const MetricLine(this.label, this.value, {this.suffix = ''});
}

/// Thẻ chỉ số: vòng tròn % bên trái, tiêu đề và số liệu bên phải.
class MetricCard extends StatelessWidget {
  final String title;
  final double percent; // 0.0 - 1.0
  final List<MetricLine> lines;

  const MetricCard({
    super.key,
    required this.title,
    required this.percent,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          ProgressRing(percent: percent, size: 92, strokeWidth: 15),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GradientText(title, style: AppTextStyles.cardTitle),
                const SizedBox(height: 6),
                for (final line in lines) _buildLine(line, palette.textPrimary, palette.textAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(MetricLine line, Color textColor, Color accentColor) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
        children: [
          if (line.label.isNotEmpty) TextSpan(text: '${line.label} '),
          TextSpan(
            text: line.value,
            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
          ),
          if (line.suffix.isNotEmpty) TextSpan(text: ' ${line.suffix}'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
