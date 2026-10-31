import 'package:flutter/material.dart';
import '../core/theme/day_period.dart';
import '../core/theme/theme_controller.dart';
import '../features/home/home_screen.dart';
import '../features/physical/physical_screen.dart';
// Màn Tinh thần của bạn cùng nhóm (giữ nguyên vị trí cũ), import có prefix
import '../screens/mental/mental_screen.dart' as mental;
import 'app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _homeIndex = 1; // mặc định mở tab giữa (Trang chủ)

  final PageController _pageController = PageController(initialPage: _homeIndex);
  int _currentIndex = _homeIndex;

  // Giữ trạng thái từng tab (ví dụ vị trí cuộn của trang Home)
  final List<Widget> _screens = const [
    _KeepAlivePage(child: PhysicalScreen()),
    _KeepAlivePage(child: HomeScreen()),
    _KeepAlivePage(child: mental.MentalScreen()),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Gắn bảng màu theo buổi cho Home + thanh điều hướng.
    // Chỉ thêm extension, KHÔNG đổi theme chung nên Tinh thần không bị ảnh hưởng.
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final palette = PeriodPalette.of(ThemeController.instance.period);
        return Theme(
          data: Theme.of(context).copyWith(extensions: [palette]),
          child: Scaffold(
            body: PageView(
              controller: _pageController,
              // Tắt vuốt ngang để không đụng với khung cuộn ngang của Tổng quan
              physics: const NeverScrollableScrollPhysics(),
              children: _screens,
            ),
            bottomNavigationBar: AppBottomNav(
              currentIndex: _currentIndex,
              onTap: _onTabSelected,
            ),
          ),
        );
      },
    );
  }
}

/// Giữ widget con "sống" khi chuyển tab, để không bị build lại từ đầu.
class _KeepAlivePage extends StatefulWidget {
  final Widget child;
  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
