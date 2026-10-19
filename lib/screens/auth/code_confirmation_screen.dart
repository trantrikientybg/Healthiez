import 'dart:async';
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/custom_textfield.dart';
import '../../widgets/auth/header_wave.dart';
import '../../widgets/auth/primary_button.dart';

class CodeConfirmationScreen extends StatefulWidget {
  const CodeConfirmationScreen({super.key});

  @override
  State<CodeConfirmationScreen> createState() => _CodeConfirmationScreenState();
}

class _CodeConfirmationScreenState extends State<CodeConfirmationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;

  Timer? _timer;
  int _secondsRemaining = 15;
  bool _canResend = false;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('email')) {
      _email = args['email'] as String;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
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

  void _handleResendCode() async {
    if (!_canResend || _email.isEmpty) return;

    try {
      await AuthService.sendPasswordResetCode(_email);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Text('Đã gửi lại mã xác minh tới $_email!'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );

      _startTimer();
    } catch (e) {
      if (!mounted) return;
      _showError(AuthService.getErrorMessage(e));
    }
  }

  void _handleVerifyCode() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showError('Vui lòng nhập mã xác minh!');
      return;
    }

    if (_email.isEmpty) {
      _showError('Không tìm thấy thông tin email. Vui lòng thử lại!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.verifyResetCode(
        email: _email,
        code: code,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.session != null || response.user != null) {
        Navigator.pushNamed(
          context,
          '/reset-password',
          arguments: {'email': _email},
        );
      } else {
        _showError('Mã xác minh không hợp lệ. Vui lòng kiểm tra lại!');
      }
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

                  // 2. Tiêu đề: Icon Lock + "Mã xác minh!"
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
                        'Mã xác minh!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 36),

                  // 3. Ô nhập: Nhập mã xác minh được gửi qua e-mail
                  CustomTextField(
                    hintText: 'Nhập mã xác minh được gửi qua e-mail',
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                  ),

                  const SizedBox(height: 16),

                  // 4. Timer đếm ngược / Gửi lại
                  GestureDetector(
                    onTap: _canResend ? _handleResendCode : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Gửi lại  ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          _canResend ? 'Bấm để gửi lại' : '${_secondsRemaining}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 5. Nút "Tiếp tục"
                  if (_isLoading)
                    CircularProgressIndicator(color: AppColors.primary)
                  else
                    PrimaryButton(
                      text: 'Tiếp tục',
                      height: 50,
                      type: ButtonType.gradient,
                      onPressed: _handleVerifyCode,
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
