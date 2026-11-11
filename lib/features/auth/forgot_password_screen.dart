import 'package:flutter/material.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_service.dart';
import '../../shared/widgets/app_header.dart';
import 'widgets/custom_textfield.dart';
import 'widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _inputController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleSendCode() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      _showError('Vui lòng nhập Tên tài khoản hoặc Email!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String emailToSend = input;
      if (!input.contains('@')) {
        final emailFromDb = await AuthService.getEmailByUsername(input);
        if (emailFromDb != null && emailFromDb.isNotEmpty) {
          emailToSend = emailFromDb;
        } else {
          _showError('Không tìm thấy Email gắn liền với Tên tài khoản này!');
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      await AuthService.sendPasswordResetCode(emailToSend);

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã xác minh đã được gửi về Email của bạn!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushNamed(
        context,
        '/code-confirmation',
        arguments: emailToSend,
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
            AppHeader(height: screenHeight * 0.36),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AppAssets.loginIcon,
                        width: 28,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.lock_reset, size: 28, color: AppColors.textPrimary);
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
                  const SizedBox(height: 24),
                  CustomTextField(
                    hintText: 'Tên tài khoản / e-mail',
                    controller: _inputController,
                  ),
                  const SizedBox(height: 24),
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
