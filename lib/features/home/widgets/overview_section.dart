import 'package:flutter/material.dart';
import '../../../data/models/screen_time_record.dart';
import '../../../data/models/sleep_record.dart';
import '../../../data/models/step_record.dart';
import 'metric_card.dart';

/// Khung cuộn ngang gồm 3 thẻ: Bước chân, Giấc ngủ, On-screen.
/// Các record là null khi dữ liệu đang tải.
class OverviewSection extends StatefulWidget {
  final StepRecord? steps;
  final SleepRecord? sleep;
  final ScreenTimeRecord? screenTime;

  /// true khi đã đọc xong mà chưa có dữ liệu giấc ngủ nào.
  final bool sleepEmpty;

  /// Bấm vào thẻ Giấc ngủ (mở chế độ ngủ). Lối vào luôn có, không phụ thuộc thẻ gợi ý.
  final VoidCallback? onSleepTap;

  const OverviewSection({
    super.key,
    this.steps,
    this.sleep,
    this.screenTime,
    this.sleepEmpty = false,
    this.onSleepTap,
  });

  @override
  State<OverviewSection> createState() => _OverviewSectionState();
}

class _OverviewSectionState extends State<OverviewSection> {
  // viewportFraction < 1: thẻ kế tiếp lấp ló bên phải, báo hiệu có thể vuốt
  final PageController _controller = PageController(viewportFraction: 0.92);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[
      _stepsCard(),
      _sleepCard(),
      _screenTimeCard(),
    ];

    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: PageView.builder(
          controller: _controller,
          padEnds: false,
          itemCount: cards.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: cards[i],
          ),
        ),
      ),
    );
  }

  Widget _stepsCard() {
    final s = widget.steps;
    return MetricCard(
      title: 'Bước chân',
      percent: s?.percent ?? 0,
      lines: s == null
          ? const [MetricLine('', '...')]
          : [
              MetricLine('', '${s.steps}/${s.goal}', suffix: 'bước'),
              MetricLine('Tích lũy tuần:', '${s.weeklyTotal}', suffix: 'bước'),
            ],
    );
  }

  Widget _sleepCard() {
    final s = widget.sleep;
    final card = MetricCard(
      title: 'Giấc ngủ',
      percent: s?.percent ?? 0,
      lines: s == null
          ? [MetricLine('', widget.sleepEmpty ? 'Chưa có dữ liệu' : '...')]
          : [
              MetricLine('Thời gian:', s.rangeLabel),
              MetricLine('Trạng thái:', s.status),
            ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onSleepTap,
      child: card,
    );
  }

  Widget _screenTimeCard() {
    final s = widget.screenTime;
    return MetricCard(
      title: 'On-screen',
      percent: s?.percent ?? 0,
      lines: s == null
          ? const [MetricLine('', '...')]
          : [
              MetricLine('Tổng thời gian:', s.totalLabel),
              MetricLine('Trạng thái:', s.status),
            ],
    );
  }
}
