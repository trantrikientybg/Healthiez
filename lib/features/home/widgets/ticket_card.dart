import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/brand_colors.dart';

/// Thẻ "vé": nửa trái màu cam (chữ), nửa phải màu xanh đen (icon/ảnh),
/// có hai khuyết tròn ở mép trái và phải. Màu cố định ở mọi buổi trong ngày.
class TicketCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget right; // nội dung nửa xanh đen
  final bool isWarning;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const TicketCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.right,
    this.isWarning = false,
    this.onTap,
    this.onDismiss,
  });

  static const double height = 140;

  @override
  Widget build(BuildContext context) {
    final leftColor =
        isWarning ? const Color(0xFFFF6B57) : BrandColors.orange;

    return GestureDetector(
      onTap: onTap,
      child: ClipPath(
        clipper: _TicketClipper(),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Row(
                children: [
                  // Nửa cam: chữ
                  Expanded(
                    child: Container(
                      color: leftColor,
                      padding: const EdgeInsets.fromLTRB(22, 14, 12, 14),
                      alignment: Alignment.centerLeft,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.ticketTitle.copyWith(fontSize: 17),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              subtitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: BrandColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 3), // khe hở giữa hai nửa vé
                  // Nửa xanh đen: icon hoặc ảnh
                  Expanded(
                    child: Container(
                      color: BrandColors.navy,
                      padding: const EdgeInsets.fromLTRB(12, 14, 22, 14),
                      child: Center(child: right),
                    ),
                  ),
                ],
              ),
              if (onDismiss != null)
                Positioned(
                  top: 6,
                  right: 12,
                  child: InkWell(
                    onTap: onDismiss,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xFFA3AEC2),
                        semanticLabel: 'Ẩn gợi ý hôm nay',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bo góc và khoét hai nửa hình tròn ở giữa mép trái, mép phải.
class _TicketClipper extends CustomClipper<Path> {
  static const double radius = 28;
  static const double notchRadius = 12;

  @override
  Path getClip(Size size) {
    final body = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Offset.zero & size,
        const Radius.circular(radius),
      ));
    final notches = Path()
      ..addOval(Rect.fromCircle(
        center: Offset(0, size.height / 2),
        radius: notchRadius,
      ))
      ..addOval(Rect.fromCircle(
        center: Offset(size.width, size.height / 2),
        radius: notchRadius,
      ));
    return Path.combine(PathOperation.difference, body, notches);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
