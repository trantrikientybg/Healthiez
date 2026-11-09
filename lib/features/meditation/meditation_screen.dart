import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/brand_colors.dart';
import 'meditation_controller.dart';
import 'meditation_sounds.dart';

/// Màn thiền: đồng hồ đếm lùi + vòng tròn hướng dẫn hít thở (hít 4 giây, thở 6 giây).
/// Giao diện tối cố định (không đổi theo buổi) cho dễ thư giãn.
/// Không dùng context.palette vì màn này được mở bằng Navigator.push.
class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const List<int> _durations = [5, 10, 15, 20];
  static const double _inhaleShare = 0.4; // 4s hít / 10s mỗi nhịp

  late final MeditationController _c;
  late final AnimationController _breath;
  final MeditationSounds _sounds = MeditationSounds();
  MeditationStatus _lastStatus = MeditationStatus.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c = MeditationController()..addListener(_onChanged);
    _breath = AnimationController(vsync: this, duration: const Duration(seconds: 10));
    _sounds.load().then((_) {
      if (mounted) setState(() {}); // cập nhật biểu tượng loa
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onChanged);
    _c.dispose();
    _breath.dispose();
    _sounds.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quay lại từ nền / mở khóa máy: tính lại thời gian còn lại
    if (state == AppLifecycleState.resumed) _c.tick();
  }

  void _onChanged() {
    final status = _c.status;
    final prev = _lastStatus;
    if (status == MeditationStatus.running) {
      if (!_breath.isAnimating) _breath.repeat();
    } else if (status == MeditationStatus.paused) {
      _breath.stop();
    } else {
      _breath.stop();
      _breath.value = 0;
    }
    // Chuông bắt đầu: khi bắt đầu mới (không phát khi tiếp tục sau tạm dừng)
    if (status == MeditationStatus.running &&
        (prev == MeditationStatus.idle || prev == MeditationStatus.finished)) {
      _sounds.playStart();
    }
    // Chuông kết thúc + rung nhẹ khi hết giờ
    if (status == MeditationStatus.finished && prev != MeditationStatus.finished) {
      HapticFeedback.heavyImpact();
      _sounds.playEnd();
    }
    _lastStatus = status;
  }

  // ---------------- Thoát ----------------

  Future<bool> _confirmExit() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Dừng buổi thiền?'),
        content: const Text('Thời gian đang đếm sẽ bị hủy.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tiếp tục thiền'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Dừng'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _onBackPressed() async {
    if (_c.isActive && !await _confirmExit()) return;
    if (mounted) Navigator.of(context).pop();
  }

  // ---------------- Hít thở ----------------

  double get _phase {
    final t = _breath.value;
    if (t < _inhaleShare) return Curves.easeInOut.transform(t / _inhaleShare);
    return 1 - Curves.easeInOut.transform((t - _inhaleShare) / (1 - _inhaleShare));
  }

  String get _centerLabel {
    switch (_c.status) {
      case MeditationStatus.idle:
        return 'Sẵn sàng';
      case MeditationStatus.paused:
        return 'Tạm dừng';
      case MeditationStatus.finished:
        return 'Hoàn thành';
      case MeditationStatus.running:
        return _breath.value < _inhaleShare ? 'Hít vào' : 'Thở ra';
    }
  }

  static String _mmss(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------------- Giao diện ----------------

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_c, _breath]),
      builder: (context, _) {
        return PopScope(
          canPop: !_c.isActive,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            await _onBackPressed();
          },
          child: Scaffold(
            body: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF263252), BrandColors.navy, Color(0xFF0F1626)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _topBar(),
                    const Spacer(),
                    _clock(),
                    const SizedBox(height: 28),
                    _bottomArea(),
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
            onPressed: _onBackPressed,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            tooltip: 'Quay lại',
          ),
          const Text(
            'Thiền',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: _sounds.enabled ? 'Tắt tiếng chuông' : 'Bật tiếng chuông',
            onPressed: () async {
              await _sounds.setEnabled(!_sounds.enabled);
              if (mounted) setState(() {});
            },
            icon: Icon(
              _sounds.enabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _clock() {
    const double ringSize = 270;
    const double stroke = 14;
    const double inner = ringSize - 2 * stroke - 16;
    final phase = _c.isRunning || _c.status == MeditationStatus.paused ? _phase : 0.0;
    final circle = inner * (0.62 + 0.38 * phase); // phình ra khi hít vào, thu lại khi thở ra
    final seconds = _c.remainingSeconds;

    return SizedBox(
      width: ringSize,
      height: ringSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(ringSize),
            painter: _TimerRingPainter(
              progress: _c.elapsedFraction,
              strokeWidth: stroke,
            ),
          ),
          Container(
            width: circle,
            height: circle,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  BrandColors.blue.withValues(alpha: 0.55),
                  BrandColors.purple.withValues(alpha: 0.25),
                ],
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _mmss(seconds),
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _centerLabel,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomArea() {
    switch (_c.status) {
      case MeditationStatus.idle:
        return Column(
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final m in _durations) _durationChip(m),
              ],
            ),
            const SizedBox(height: 24),
            _mainButton('Bắt đầu', Icons.play_arrow_rounded, _c.start),
          ],
        );
      case MeditationStatus.running:
        return Column(
          children: [
            _mainButton('Tạm dừng', Icons.pause_rounded, _c.pause),
            const SizedBox(height: 8),
            _textButton('Kết thúc', () async {
              if (await _confirmExit()) _c.reset();
            }),
          ],
        );
      case MeditationStatus.paused:
        return Column(
          children: [
            _mainButton('Tiếp tục', Icons.play_arrow_rounded, _c.resume),
            const SizedBox(height: 8),
            _textButton('Đặt lại', _c.reset),
          ],
        );
      case MeditationStatus.finished:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Bạn đã thiền xong ${_c.minutes} phút.\nHít thở sâu thêm một lần nữa nhé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.4,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _mainButton('Thiền lại', Icons.replay_rounded, _c.start),
            const SizedBox(height: 8),
            _textButton('Đóng', () => Navigator.of(context).pop()),
          ],
        );
    }
  }

  Widget _durationChip(int minutes) {
    final selected = _c.minutes == minutes;
    return Material(
      // Màu đặc (không dùng độ trong suốt) để không bị theme trộn màu
      color: selected ? BrandColors.purple : const Color(0xFF34415E),
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? BrandColors.purple : Colors.white24,
        ),
      ),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: () => _c.setMinutes(minutes),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(
            '$minutes phút',
            style: TextStyle(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? Colors.white : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
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
        minimumSize: const Size(180, 52),
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

/// Vòng thời gian: cung gradient thu ngắn dần theo thời gian còn lại.
class _TimerRingPainter extends CustomPainter {
  final double progress; // đã trôi qua, 0.0 - 1.0
  final double strokeWidth;

  _TimerRingPainter({required this.progress, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = Colors.white.withValues(alpha: 0.12),
    );

    final sweep = 2 * math.pi * (1 - progress);
    if (sweep <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [BrandColors.purple, BrandColors.blue],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
