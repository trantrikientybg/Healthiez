import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/custom_textfield.dart';
import '../../widgets/auth/header_wave.dart';
import '../../widgets/auth/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
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

  void _handleRegister() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final email = _emailController.text.trim();

    if (username.isEmpty || password.isEmpty || confirmPassword.isEmpty || email.isEmpty) {
      _showError('Vui lòng điền đầy đủ các thông tin!');
      return;
    }

    if (password != confirmPassword) {
      _showError('Mật khẩu nhập lại không khớp!');
      return;
    }

    if (password.length < 6) {
      _showError('Mật khẩu phải có ít nhất 6 ký tự!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (response.user != null) {
        if (response.session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Text('Đăng ký tài khoản thành công!'),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          );
          Navigator.pushReplacementNamed(context, '/main');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.mark_email_read_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Đăng ký thành công! Vui lòng kiểm tra email để xác nhận tài khoản trước khi đăng nhập.',
                      style: TextStyle(fontSize: 13, color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF3B82F6),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.pushReplacementNamed(context, '/login');
        }
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
            // 1. Header Sóng Xanh - Giữ đúng tỉ lệ 36% đồng nhất với WelcomeScreen
            HeaderWave(
              height: screenHeight * 0.36,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 18),

                    // 2. Tiêu đề: Icon register_icon.png + "Đăng ký!"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/images/register_icon.png',
                          width: 26,
                          height: 30,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 28,
                              color: AppColors.textPrimary,
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Đăng ký!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Ô 1: Tên tài khoản
                    CustomTextField(
                      hintText: 'Tên tài khoản',
                      controller: _usernameController,
                    ),

                    const SizedBox(height: 11),

                    // 4. Ô 2: Mật khẩu
                    CustomTextField(
                      hintText: 'Mật khẩu',
                      controller: _passwordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 11),

                    // 5. Ô 3: Nhập lại mật khẩu
                    CustomTextField(
                      hintText: 'Nhập lại mật khẩu',
                      controller: _confirmPasswordController,
                      isPassword: true,
                    ),

                    const SizedBox(height: 11),

                    // 6. Ô 4: Nhập email
                    CustomTextField(
                      hintText: 'Nhập email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 22),

                    // 7. Nút "Tiếp tục"
                    if (_isLoading)
                      CircularProgressIndicator(color: AppColors.primary)
                    else
                      PrimaryButton(
                        text: 'Tiếp tục',
                        height: 50,
                        type: ButtonType.gradient,
                        onPressed: _handleRegister,
                      ),

                    const SizedBox(height: 16),

                    // 8. Footer: "Đã có tài khoản? [Đăng nhập]"
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Đã có tài khoản? ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          borderRadius: BorderRadius.circular(15),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
