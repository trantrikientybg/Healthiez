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

  const OverviewSection({super.key, this.steps, this.sleep, this.screenTime});

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
    return MetricCard(
      title: 'Giấc ngủ',
      percent: s?.percent ?? 0,
      lines: s == null
          ? const [MetricLine('', '...')]
          : [
              MetricLine('Thời gian:', s.rangeLabel),
              MetricLine('Trạng thái:', s.status),
            ],
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
