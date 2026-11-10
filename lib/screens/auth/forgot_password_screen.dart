import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/custom_textfield.dart';
import '../../widgets/auth/header_wave.dart';
import '../../widgets/auth/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
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

  void _handleSendCode() async {
    final input = _identifierController.text.trim();

    if (input.isEmpty) {
      _showError('Vui lòng nhập Tên tài khoản hoặc Email!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String visibleEmail;
      String targetEmail = input;

      // Nếu không chứa '@', coi đây là tên tài khoản và tra cứu Email
      if (!input.contains('@')) {
        final foundEmail = await AuthService.getEmailByUsername(input);
        if (foundEmail == null || foundEmail.isEmpty) {
          if (!mounted) return;
          setState(() {
            _isLoading = false;
          });
          _showError('Không tìm thấy tài khoản với tên người dùng "$input"!');
          return;
        }
        targetEmail = foundEmail;
        visibleEmail = '${foundEmail[0]}${foundEmail[1]}*****';
      } else {
        visibleEmail = targetEmail;
      }

      await AuthService.sendPasswordResetCode(targetEmail);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Đã gửi mã xác minh tới email $visibleEmail!'),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );

      // Chuyển sang màn hình nhập mã xác minh và truyền Email
      Navigator.pushNamed(
        context,
        '/code-confirmation',
        arguments: {'email': targetEmail},
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

                  // 2. Tiêu đề: Icon Lock + "Quên mật khẩu!"
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
                        'Quên mật khẩu!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // 3. Ô nhập: Tên tài khoản / e-mail
                  CustomTextField(
                    hintText: 'Tên tài khoản / e-mail',
                    controller: _identifierController,
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
                      onPressed: _handleSendCode,
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
