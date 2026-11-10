import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth/header_wave.dart';
import '../../widgets/auth/primary_button.dart';
import '../../widgets/auth/social_buttons.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      final Session? session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        await AuthService.saveCurrentSessionState();
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đăng nhập thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        Navigator.pushReplacementNamed(context, '/main');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLoading) {
      Future.delayed(const Duration(seconds: 1), () {
        final currentSession = Supabase.instance.client.auth.currentSession;
        if (currentSession == null && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _handleSocialLogin(Future<bool> Function() loginMethod, String providerName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final launched = await loginMethod();
      if (!launched && mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể mở trình duyệt $providerName'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kích hoạt $providerName: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
            // 1. Header Sóng Xanh - Chiếm 36% màn hình chuẩn thiết kế
            HeaderWave(
              height: screenHeight * 0.36,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 36),

                  // 2. Tiêu đề "Chào mừng!"
                  Text(
                    'Chào mừng!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 36),

                  if (_isLoading) ...[
                    CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Đang chờ xác thực đăng nhập...',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 30),
                  ] else ...[
                    // 3. Nút "Tạo tài khoản" (Màu Gradient)
                    PrimaryButton(
                      text: 'Tạo tài khoản',
                      height: 52,
                      type: ButtonType.gradient,
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                    ),

                    const SizedBox(height: 14),

                    // 4. Nút "Đăng nhập" (Màu Outlined viền tím)
                    PrimaryButton(
                      text: 'Đăng nhập',
                      height: 52,
                      type: ButtonType.outlined,
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                    ),

                    const SizedBox(height: 32),

                    // 5. Text "hoặc đăng nhập bằng"
                    Text(
                      'hoặc đăng nhập bằng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 6. Cụm Icon Facebook & Google
                    SocialButtonsRow(
                      onFacebookPressed: () {
                        _handleSocialLogin(
                          AuthService.signInWithFacebook,
                          'Facebook',
                        );
                      },
                      onGooglePressed: () {
                        _handleSocialLogin(
                          AuthService.signInWithGoogle,
                          'Google',
                        );
                      },
                    ),

                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
