import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_colors.dart';
import 'navigation/main_shell.dart';
import 'screens/auth/code_confirmation_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/auth_service.dart';

// Khóa Supabase KHÔNG ghi cứng trong code, truyền qua:
//   --dart-define-from-file=supabase.local.json
// (copy từ supabase.example.json, file local nằm trong .gitignore)
const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

Future<void> main() async {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Thiếu cấu hình thì báo rõ trên màn hình, không để app đứng ở logo Flutter
  if (!_supabaseUrl.startsWith('https://') ||
      !_supabaseKey.startsWith('sb_publishable_')) {
    runApp(const _ConfigErrorApp());
    return;
  }

  // Load bảng màu động từ tệp JSON
  await AppColors.loadFromPath();

  // Khởi tạo Supabase
  await Supabase.initialize(url: _supabaseUrl, publishableKey: _supabaseKey);

  // Kiểm tra trạng thái đăng nhập từ trước
  final bool isLoggedIn = await AuthService.isLoggedIn();

  runApp(HealthiezApp(isLoggedIn: isLoggedIn));
}

class HealthiezApp extends StatelessWidget {
  final bool isLoggedIn;

  const HealthiezApp({
    super.key,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthiez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      // Đã đăng nhập thì vào thẳng MainShell, ngược lại là WelcomeScreen
      home: isLoggedIn ? const MainShell() : const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/code-confirmation': (context) => const CodeConfirmationScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/main': (context) => const MainShell(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Hiện khi chạy mà thiếu --dart-define-from-file.
class _ConfigErrorApp extends StatelessWidget {
  const _ConfigErrorApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Thiếu cấu hình Supabase.\n\n'
              '1. Copy supabase.example.json thành supabase.local.json '
              'và điền URL + publishable key.\n'
              '2. Chạy lại với:\n'
              '--dart-define-from-file=supabase.local.json',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
