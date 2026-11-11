import 'package:flutter/material.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/code_confirmation_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/username_setup_screen.dart';
import 'features/auth/welcome_screen.dart';
import 'features/settings/edit_profile_screen.dart';
import 'features/settings/setting_screen.dart';
import 'navigation/main_shell.dart';

class HealthiezApp extends StatefulWidget {
  final bool isLoggedIn;

  const HealthiezApp({
    super.key,
    this.isLoggedIn = false,
  });

  @override
  State<HealthiezApp> createState() => _HealthiezAppState();
}

class _HealthiezAppState extends State<HealthiezApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      AppColors.checkAndUpdateRealTimeTheme();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppColors.instance,
      builder: (context, child) {
        return MaterialApp(
          title: 'Healthiez',
          theme: AppTheme.themeData,
          home: widget.isLoggedIn ? const MainShell() : const WelcomeScreen(),
          routes: {
            '/welcome': (context) => const WelcomeScreen(),
            '/register': (context) => const RegisterScreen(),
            '/login': (context) => const LoginScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/code-confirmation': (context) => const CodeConfirmationScreen(),
            '/reset-password': (context) => const ResetPasswordScreen(),
            '/username-setup': (context) => const UsernameSetupScreen(),
            '/settings': (context) => const SettingScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/main': (context) => const MainShell(),
          },
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
