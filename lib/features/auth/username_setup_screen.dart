import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/app_header.dart';
import 'widgets/custom_textfield.dart';
import 'widgets/primary_button.dart';

class UsernameSetupScreen extends StatefulWidget {
  const UsernameSetupScreen({super.key});

  @override
  State<UsernameSetupScreen> createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleSaveUsername() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showError('Vui lòng nhập Tên tài khoản mong muốn!');
      return;
    }

    if (username.length < 3) {
      _showError('Tên tài khoản phải có ít nhất 3 ký tự!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _showError('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại!');
        return;
      }

      // 1. Kiểm tra Username đã có ai sử dụng chưa
      final existingUser = await Supabase.instance.client
          .from('profiles')
          .select('id')
          .ilike('username', username)
          .maybeSingle();

      if (existingUser != null && existingUser['id'] != user.id) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
        });
        _showError('Tên tài khoản này đã có người sử dụng. Vui lòng chọn tên khác!');
        return;
      }

      // 2. Cập nhật Username vào Supabase CSDL và Metadata
      await UserRepository.syncUserProfile(
        userId: user.id,
        username: username,
        email: user.email ?? '',
      );

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(data: {'username': username}),
      );

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
              Text('Tạo Tên tài khoản thành công!'),
            ],
          ),
          backgroundColor: AppColors.tealAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      );

      // Tiến thẳng vào Màn hình chính
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showError('Lưu Tên tài khoản thất bại: $e');
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
                        AppAssets.registerIcon,
                        width: 28,
                        height: 32,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.badge_outlined, size: 28, color: AppColors.textPrimary);
                        },
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tạo Tên tài khoản',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Đây là lần đầu bạn đăng nhập qua Mạng xã hội. Vui lòng tạo Tên tài khoản (Username) để định danh ứng dụng:',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    hintText: 'Nhập Tên tài khoản (ID mong muốn)',
                    controller: _usernameController,
                  ),
                  const SizedBox(height: 24),
                  if (_isLoading)
                    CircularProgressIndicator(color: AppColors.primary)
                  else
                    PrimaryButton(
                      text: 'Hoàn tất & Tiếp tục',
                      height: 50,
                      type: ButtonType.gradient,
                      onPressed: _handleSaveUsername,
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
