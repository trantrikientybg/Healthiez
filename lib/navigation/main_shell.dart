import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/theme/day_period.dart';
import '../core/theme/theme_controller.dart';
import '../features/home/home_screen.dart';
import '../features/physical/physical_screen.dart';
import '../features/physical/physical_store.dart';
// Màn Tinh thần của bạn cùng nhóm (giữ nguyên vị trí cũ), import có prefix
import '../screens/mental/mental_screen.dart' as mental;
import 'app_bottom_nav.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _physicalIndex = 0;
  static const int _homeIndex = 1; // mặc định mở tab giữa (Trang chủ)
  static const int _mentalIndex = 2;

  final PageController _pageController = PageController(initialPage: _homeIndex);
  int _currentIndex = _homeIndex;

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

  // Getter (không phải const): Thể chất cần biết tab nào đang mở (active)
  // và tài khoản hiện tại (store), nên phải dựng lại khi các giá trị này đổi.
  List<Widget> get _screens {
    final client = Supabase.instance.client;
    return [
      _KeepAlivePage(
        child: StreamBuilder<AuthState>(
          stream: client.auth.onAuthStateChange,
          builder: (context, _) {
            final user = client.auth.currentUser;
            return PhysicalScreen(
              key: ValueKey(user?.id), // đổi tài khoản thì màn Thể chất làm mới
              active: _currentIndex == _physicalIndex,
              store: user == null ? null : PhysicalStore(client, user.id),
            );
          },
        ),
      ),
      _KeepAlivePage(
        child: HomeScreen(
          onOpenMental: () => _onTabSelected(_mentalIndex),
          onOpenPhysical: () => _onTabSelected(_physicalIndex),
        ),
      ),
      const _KeepAlivePage(child: mental.MentalScreen()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Gắn bảng màu theo buổi cho Home + thanh điều hướng.
    // Chỉ thêm extension, KHÔNG đổi theme chung nên Tinh thần/Thể chất không bị ảnh hưởng.
    return ListenableBuilder(
      listenable: ThemeController.instance,
      builder: (context, _) {
        final palette = PeriodPalette.of(ThemeController.instance.period);
        return Theme(
          data: Theme.of(context).copyWith(extensions: [palette]),
          child: Scaffold(
            // Tab Trang chủ: nền Scaffold = nền theo buổi để hai góc bo của
            // thanh nav lộ ra đúng màu. Tab khác giữ nền mặc định.
            backgroundColor:
                _currentIndex == _homeIndex ? palette.background : null,
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
