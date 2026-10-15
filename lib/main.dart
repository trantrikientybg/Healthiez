import 'package:flutter/material.dart';

void main() {
  runApp(const HealthiezApp());
}

class HealthiezApp extends StatelessWidget {
  const HealthiezApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Healthiez',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal), // Màu chủ đạo (Xanh mòng két healing)
        useMaterial3: true,
      ),
      home: const MainSkeleton(),
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