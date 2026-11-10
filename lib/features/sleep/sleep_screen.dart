import 'package:flutter/material.dart';
import '../../core/theme/brand_colors.dart';
import '../../data/sleep/sleep_models.dart';
import 'sleep_controller.dart';

/// Màn Chế độ ngủ. Bấm "Bắt đầu", rồi tắt màn hình bằng nút nguồn:
/// đồng hồ chỉ đếm lúc màn hình tắt và tạm dừng khi bạn mở máy.
/// Giao diện tối cố định; không dùng context.palette vì mở bằng Navigator.push.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> with WidgetsBindingObserver {
  final SleepController _c = SleepController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_c.loaded) return;
    switch (state) {
      case AppLifecycleState.paused:
        _c.screenOff(); // màn hình tắt (hoặc app xuống nền)
      case AppLifecycleState.resumed:
        _c.screenOn(); // mở máy lại
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }

  // ---------------- Thoát ----------------

  bool get _hasProgress => _c.phase == SleepPhase.awake;

  Future<void> _onBack() async {
    if (_c.phase == SleepPhase.armed) _c.cancel(); // chưa ngủ phút nào: bỏ luôn
    if (_hasProgress) {
      final finish = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kết thúc giấc ngủ?'),
          content: const Text('Giấc ngủ sẽ được lưu lại với thời gian đã đếm.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tiếp tục ngủ'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kết thúc'),
            ),
          ],
        ),
      );
      if (finish != true) return;
      _c.finish();
    }
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------- Giao diện ----------------

  static String _duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '$m phút';
    return '$h giờ ${m.toString().padLeft(2, '0')} phút';
  }

  static String _clock(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _c,
      builder: (context, _) {
        final saved = _c.lastFinished;
        final phase = _c.phase;
        return PopScope(
          canPop: phase == null, // đang trong phiên thì tự xử lý khi quay lại
          onPopInvokedWithResult: (didPop, result) async {
            if (!didPop) await _onBack();
          },
          child: Scaffold(
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A2038), Color(0xFF0F1626), Color(0xFF080B14)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(),
                    const Spacer(),
                    _body(phase, saved),
                    const Spacer(flex: 2),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: _onBack,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Quay lại',
          ),
          const Text(
            'Đi ngủ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _body(SleepPhase? phase, SleepEntry? saved) {
    // Vừa kết thúc: màn tóm tắt
    if (phase == null && saved != null) {
      return _panel(
        icon: Icons.check_circle_rounded,
        title: 'Đã lưu giấc ngủ',
        big: _duration(saved.asleep),
        message: 'Từ ${_clock(saved.bedTime)} đến ${_clock(saved.wakeTime)}.\n'
            'Chúc bạn một ngày mới thật tốt!',
        actions: [_mainButton('Xong', Icons.check_rounded, () => Navigator.of(context).pop())],
      );
    }

    switch (phase) {
      case null:
        return _panel(
          icon: Icons.bedtime_rounded,
          title: 'Chuẩn bị đi ngủ',
          message: 'Nhấn Bắt đầu rồi tắt màn hình bằng nút nguồn.\n'
              'Đồng hồ chỉ đếm khi màn hình tắt và tạm dừng khi bạn mở máy.',
          actions: [_mainButton('Bắt đầu đi ngủ', Icons.nightlight_round, _c.begin)],
        );
      case SleepPhase.armed:
        return _panel(
          icon: Icons.power_settings_new_rounded,
          title: 'Sẵn sàng',
          message: 'Hãy tắt màn hình điện thoại bằng nút nguồn để bắt đầu đếm giờ.\n'
              'Không bấm nút Home, vì như vậy sẽ không tính là đã tắt màn hình.',
          actions: [_textButton('Hủy', () {
            _c.cancel();
          })],
        );
      case SleepPhase.sleeping:
        return _panel(
          icon: Icons.bedtime_rounded,
          title: 'Đang ngủ',
          message: 'Đồng hồ đang đếm.',
          actions: const [],
        );
      case SleepPhase.awake:
        return _panel(
          icon: Icons.pause_circle_rounded,
          title: 'Đồng hồ đang tạm dừng',
          big: _duration(_c.session!.accumulated),
          message: 'Tắt màn hình lại để tiếp tục đếm,\nhoặc bấm Dậy rồi để lưu giấc ngủ.',
          actions: [
            _mainButton('Dậy rồi', Icons.wb_sunny_rounded, () => _c.finish()),
            const SizedBox(height: 8),
            _textButton('Hủy giấc ngủ này', () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Hủy giấc ngủ này?'),
                  content: const Text('Thời gian đã đếm sẽ không được lưu.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Giữ lại')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy')),
                  ],
                ),
              );
              if (ok == true) _c.cancel();
            }),
          ],
        );
    }
  }

  Widget _panel({
    required IconData icon,
    required String title,
    required String message,
    required List<Widget> actions,
    String? big,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: const Color(0xFFA3AEC2)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          if (big != null) ...[
            const SizedBox(height: 12),
            Text(
              big,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w300, color: Colors.white),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.45,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 28),
          ...actions,
        ],
      ),
    );
  }

  Widget _mainButton(String label, IconData icon, VoidCallback onPressed) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: BrandColors.purple,
        foregroundColor: Colors.white,
        minimumSize: const Size(200, 52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      ),
    );
  }

  Widget _textButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(foregroundColor: Colors.white70),
      child: Text(label),
    );
  }
}
