import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/custom_textfield.dart';
import '../../widgets/auth/header_wave.dart';
import '../../widgets/auth/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _newPasswordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _handleResetPassword() async {
    final newPassword = _newPasswordController.text;

    if (newPassword.isEmpty) {
      _showError('Vui lòng nhập mật khẩu mới!');
      return;
    }

    if (newPassword.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.updatePassword(newPassword);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text('Đổi mật khẩu thành công! Vui lòng đăng nhập lại bằng mật khẩu mới.'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          duration: const Duration(seconds: 4),
        ),
      );

      // Chuyển về màn hình đăng nhập và xóa sạch stack điều hướng
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError(AuthService.getErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Sóng Xanh
            HeaderWave(
              height: screenHeight * 0.36,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 18),

                  // 2. Tiêu đề: Icon Lock + "Mật khẩu mới"
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/forgot_password_icon.png',
                        width: 28,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.lock_reset_outlined,
                            size: 28,
                            color: AppColors.textPrimary,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Mật khẩu mới',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // 3. Ô nhập: Mật khẩu mới
                  CustomTextField(
                    hintText: 'Mật khẩu mới',
                    controller: _newPasswordController,
                    isPassword: true,
                  ),

                  const SizedBox(height: 36),

                  // 4. Nút "Tiếp tục"
                  if (_isLoading)
                    CircularProgressIndicator(color: AppColors.primary)
                  else
                    PrimaryButton(
                      text: 'Tiếp tục',
                      height: 50,
                      type: ButtonType.gradient,
                      onPressed: _handleResetPassword,
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
