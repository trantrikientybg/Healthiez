import 'dart:async';

import 'package:flutter/material.dart';

import 'physical_controller.dart';
import 'step_card.dart';
import 'step_controller.dart';

class PhysicalScreen extends StatefulWidget {
  const PhysicalScreen({super.key, this.active = true});

  final bool active;

  @override
  State<PhysicalScreen> createState() => _PhysicalScreenState();
}

class _PhysicalScreenState extends State<PhysicalScreen>
    with WidgetsBindingObserver {
  final _controller = PhysicalController();
  final _steps = StepController();
  final _form = GlobalKey<FormState>();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            PhysicalController.parseMeasurement(value ?? '') == null
            ? 'Nhập số lớn hơn 0.'
            : null,
      );

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final textTheme = Theme.of(context).textTheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Sức khỏe thể chất', style: textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text(
                      'Theo dõi chỉ số cơ thể, lượng nước và bước chân mỗi ngày.',
                    ),
                    const SizedBox(height: 16),
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
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Chỉ số cơ thể',
                                  style: textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                _measurementField('Chiều cao (cm)', _height),
                                const SizedBox(height: 16),
                                _measurementField('Cân nặng (kg)', _weight),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _controller.busy
                                      ? null
                                      : _saveMeasurements,
                                  child: const Text('Lưu chỉ số'),
                                ),
                                const SizedBox(height: 12),
                                Semantics(
                                  liveRegion: true,
                                  child: Text(
                                    _controller.bmi == null
                                        ? 'Nhập và lưu chiều cao, cân nặng để xem BMI.'
                                        : 'BMI: ${_controller.bmi!.toStringAsFixed(1)}',
                                    style: textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Nước uống hôm nay',
                                style: textTheme.titleLarge,
                              ),
                              const SizedBox(height: 12),
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  '${_controller.waterMl} ml',
                                  style: textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value:
                                    (_controller.waterMl /
                                            PhysicalController.waterReference)
                                        .clamp(0.0, 1.0),
                                semanticsLabel: 'Tiến độ uống nước hôm nay',
                              ),
                              const SizedBox(height: 8),
                              const Text('Mốc tham khảo: 2.000 ml mỗi ngày.'),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: _controller.busy
                                        ? null
                                        : _controller.addWater,
                                    icon: const Icon(Icons.water_drop_outlined),
                                    label: const Text('Thêm 250 ml'),
                                  ),
                                  TextButton(
                                    onPressed:
                                        _controller.busy || !_controller.canUndo
                                        ? null
                                        : _controller.undoWater,
                                    child: const Text('Hoàn tác'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Dữ liệu được lưu trên thiết bị này.'),
                    ],
                    const SizedBox(height: 12),
                    StepCard(controller: _steps),
                  ],
                ),
              ),
            ),
          );
        },
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
