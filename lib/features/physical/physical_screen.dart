import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/brand_colors.dart';
import '../../core/theme/day_period.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/progress_ring.dart';
import '../../shared/widgets/section_chip.dart';
import 'physical_controller.dart';
import 'physical_store.dart';
import 'physical_style.dart';
import 'step_card.dart';
import 'step_controller.dart';

class PhysicalScreen extends StatefulWidget {
  const PhysicalScreen({super.key, this.active = true, this.store});

  final bool active;
  final PhysicalStore? store;

  @override
  State<PhysicalScreen> createState() => _PhysicalScreenState();
}

class _PhysicalScreenState extends State<PhysicalScreen>
    with WidgetsBindingObserver {
  late final PhysicalController _controller;
  late final StepController _steps;
  final _form = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    final store = widget.store;
    _controller = PhysicalController(
      read: store == null ? null : () => store.read('physical'),
      write: store == null ? null : (value) => store.write('physical', value),
      writeMeasurements: store?.writeMeasurements,
    );
    _steps = StepController(
      read: store == null ? null : () => store.read('steps'),
      write: store == null ? null : (value) => store.write('steps', value),
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(_load());
    unawaited(_steps.load());
    _scheduleMidnight();
  }

  Future<void> _load() async {
    await _controller.load();
    if (!mounted || !_controller.ready) return;
    _height.text = _controller.heightCm?.toString() ?? '';
    _weight.text = _controller.weightKg?.toString() ?? '';
  }

  void _scheduleMidnight() {
    _midnight?.cancel();
    final now = DateTime.now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(nextDay.difference(now), () {
      _controller.refreshDay();
      _steps.refreshDay();
      _scheduleMidnight();
    });
  }

  @override
  void didUpdateWidget(covariant PhysicalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.refreshDay();
      _steps.refreshDay();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshDay();
      _steps.refreshDay();
      _scheduleMidnight();
    }
  }

  Future<void> _saveMeasurements() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final saved = await _controller.saveMeasurements(
      PhysicalController.parseMeasurement(_height.text)!,
      PhysicalController.parseMeasurement(_weight.text)!,
    );
    if (!mounted || !saved) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu chỉ số cơ thể.')));
  }

  Widget _measurementField(String label, TextEditingController controller) =>
      TextFormField(
        controller: controller,
        enabled: !_controller.busy,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textInputAction: controller == _height
            ? TextInputAction.next
            : TextInputAction.done,
        decoration: InputDecoration(labelText: label),
        validator: (value) =>
            PhysicalController.parseMeasurement(value ?? '') == null
            ? 'Nhập số lớn hơn 0.'
            : null,
      );

  Widget _bodyCard(TextStyle accent) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PhysicalCardTitle(
              Icons.monitor_weight_outlined,
              'Chỉ số cơ thể',
            ),
            const SizedBox(height: 16),
            _measurementField('Chiều cao (cm)', _height),
            const SizedBox(height: 16),
            _measurementField('Cân nặng (kg)', _weight),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _controller.busy ? null : _saveMeasurements,
              child: const Text('Lưu chỉ số'),
            ),
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                _controller.bmi == null
                    ? 'Nhập và lưu chiều cao, cân nặng để xem BMI.'
                    : 'BMI: ${_controller.bmi!.toStringAsFixed(1)}',
                style: _controller.bmi == null ? null : accent,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _waterCard(TextStyle accent) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PhysicalCardTitle(
            Icons.water_drop_outlined,
            'Nước uống hôm nay',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ProgressRing(
                percent:
                    (_controller.waterMl / PhysicalController.waterReference)
                        .clamp(0.0, 1.0),
                size: 92,
                strokeWidth: 15,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      liveRegion: true,
                      child: Text('${_controller.waterMl} ml', style: accent),
                    ),
                    const SizedBox(height: 4),
                    const Text('Mốc tham khảo: 2.000 ml mỗi ngày.'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _controller.busy ? null : _controller.addWater,
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('Thêm 250 ml'),
              ),
              TextButton(
                onPressed: _controller.busy || !_controller.canUndo
                    ? null
                    : _controller.undoWater,
                child: const Text('Hoàn tác'),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final accent = AppTextStyles.metricValue.copyWith(
      color: palette.textAccent,
    );
    return Theme(
      data: physicalTheme(Theme.of(context), palette),
      child: ColoredBox(
        color: palette.background,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) => SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppHeader(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sức khỏe thể chất',
                        style: AppTextStyles.cardTitle.copyWith(
                          color: BrandColors.textOnDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Theo dõi chỉ số cơ thể, lượng nước và bước chân mỗi ngày.',
                        style: AppTextStyles.mentalSubtitle.copyWith(
                          color: BrandColors.textOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: SectionChip('Hôm nay'),
                          ),
                          const SizedBox(height: 12),
                          if (_controller.busy) const LinearProgressIndicator(),
                          if (_controller.error != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _controller.error!,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                            if (!_controller.ready)
                              TextButton(
                                onPressed: _controller.busy ? null : _load,
                                child: const Text('Thử lại'),
                              ),
                            const SizedBox(height: 12),
                          ],
                          if (_controller.ready) ...[
                            _bodyCard(accent),
                            const SizedBox(height: 16),
                            _waterCard(accent),
                            const SizedBox(height: 12),
                            Text(
                              widget.store == null
                                  ? 'Dữ liệu được lưu trên thiết bị này.'
                                  : 'Dữ liệu được lưu vào tài khoản. Bước chân lưu riêng theo thiết bị.',
                            ),
                          ],
                          const SizedBox(height: 16),
                          StepCard(controller: _steps),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnight?.cancel();
    _height.dispose();
    _weight.dispose();
    _controller.dispose();
    _steps.dispose();
    super.dispose();
  }
}
