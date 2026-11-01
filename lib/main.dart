import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/physical/physical_screen.dart';
import 'features/physical/physical_store.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  if (!url.startsWith('https://') || !key.startsWith('sb_publishable_')) {
    throw StateError(
      'Pass a Supabase URL and publishable key with --dart-define-from-file.',
    );
  }
  await Supabase.initialize(url: url, publishableKey: key);

  runApp(HealthiezApp(client: Supabase.instance.client));
}

class HealthiezApp extends StatelessWidget {
  const HealthiezApp({super.key, this.client});

  final SupabaseClient? client;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthiez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6844FF)),
        useMaterial3: true,
      ),
      home: MainSkeleton(client: client),
      debugShowCheckedModeBanner: false, // Ẩn chữ Debug góc phải
    );
  }
}

class MainSkeleton extends StatefulWidget {
  const MainSkeleton({super.key, this.client});

  final SupabaseClient? client;

  @override
  State<MainSkeleton> createState() => _MainSkeletonState();
}

class _MainSkeletonState extends State<MainSkeleton> {
  int _currentIndex = 1; // Mặc định mở Tab 2 (Tổng thể) ở giữa

  // Danh sách các màn hình (Placeholder)
  List<Widget> get _screens => [
    if (widget.client case final client?)
      StreamBuilder<AuthState>(
        stream: client.auth.onAuthStateChange,
        builder: (context, _) => PhysicalScreen(
          key: ValueKey(client.auth.currentUser?.id),
          active: _currentIndex == 0,
          store: client.auth.currentUser == null
              ? null
              : PhysicalStore(client, client.auth.currentUser!.id),
        ),
      )
    else
      PhysicalScreen(active: _currentIndex == 0),
    const HomeScreen(),
    const MentalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Dùng IndexedStack để giữ nguyên trạng thái (State) của các Tab khi chuyển qua lại
      body: IndexedStack(index: _currentIndex, children: _screens),
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
