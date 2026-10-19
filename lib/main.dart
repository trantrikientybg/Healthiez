import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/app_colors.dart';
import 'screens/auth/code_confirmation_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Load bảng màu động từ tệp JSON
  await AppColors.loadFromPath();

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://tzdbowjwsewwzmxvcfqk.supabase.co',
    publishableKey: 'sb_publishable_RgNJjOg7dyXBpHJxA5yDoA_9LTzNSB2',
  );

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
      // Màn hình khởi đầu: Nếu đã đăng nhập thì đi thẳng vào MainSkeleton, ngược lại là WelcomeScreen
      home: isLoggedIn ? const MainSkeleton() : const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/code-confirmation': (context) => const CodeConfirmationScreen(),
        '/reset-password': (context) => const ResetPasswordScreen(),
        '/main': (context) => const MainSkeleton(),
      },
      debugShowCheckedModeBanner: false, // Ẩn chữ Debug góc phải
    );
  }
}

class MainSkeleton extends StatefulWidget {
  const MainSkeleton({super.key});

  @override
  State<MainSkeleton> createState() => _MainSkeletonState();
}

class _MainSkeletonState extends State<MainSkeleton> {
  int _currentIndex = 1; // Mặc định mở Tab 2 (Tổng thể) ở giữa

  // Danh sách các màn hình (Placeholder)
  final List<Widget> _screens = [
    const PhysicalScreen(),
    const HomeScreen(),
    const MentalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ nguyên trạng thái (State) của các Tab khi chuyển qua lại
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index; // Cập nhật vị trí Tab khi người dùng bấm
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Thể chất',
          ),
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Tổng thể',
          ),
          NavigationDestination(
            icon: Icon(Icons.psychology_outlined),
            selectedIcon: Icon(Icons.psychology),
            label: 'Tinh thần',
          ),
        ],
      ),
    );
  }
}

// ==============================================================
// CÁC PLACEHOLDER - CHỖ TRỐNG ĐỂ CHIA VIỆC CHO TEAM
// ==============================================================

class PhysicalScreen extends StatelessWidget {
  const PhysicalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'TAB 1: THỂ CHẤT\n(Theo dõi giấc ngủ, thể thao, nước)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'TAB 2: TRANG CHỦ\n(Avatar cơ thể, Streak, Thông số tổng quan)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class MentalScreen extends StatelessWidget {
  const MentalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'TAB 3: TINH THẦN\n(Chat AI tâm lý, Gợi ý nhạc & Sách)',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
