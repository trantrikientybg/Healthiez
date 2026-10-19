import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class HeaderWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 45);

    // Đường cong gợn sóng thứ 1
    var firstControlPoint = Offset(size.width * 0.3, size.height + 12);
    var firstEndPoint = Offset(size.width * 0.55, size.height - 25);
    path.quadraticBezierTo(
      firstControlPoint.dx,
      firstControlPoint.dy,
      firstEndPoint.dx,
      firstEndPoint.dy,
    );

    // Đường cong gợn sóng thứ 2
    var secondControlPoint = Offset(size.width * 0.8, size.height - 60);
    var secondEndPoint = Offset(size.width, size.height - 25);
    path.quadraticBezierTo(
      secondControlPoint.dx,
      secondControlPoint.dy,
      secondEndPoint.dx,
      secondEndPoint.dy,
    );

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HeaderWave extends StatelessWidget {
  final double height;
  final Widget? extraContent;

  const HeaderWave({
    super.key,
    this.height = 240,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: HeaderWaveClipper(),
      child: Container(
        height: height,
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
                'assets/images/logo.png',
                height: 48,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Hiển thị fallback nếu chưa tìm thấy ảnh
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Health',
                        style: TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Icon(Icons.fitness_center, color: Colors.white, size: 28),
                      const Text(
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
