import 'package:flutter/material.dart';
import '../../core/theme/theme_controller.dart';

/// NÚT TẠM để thử đổi nền. Xóa khi màn Settings hoàn thiện.
class ThemeDebugSwitcher extends StatelessWidget {
  const ThemeDebugSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeController.instance;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return SegmentedButton<ThemeModeSetting>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: ThemeModeSetting.auto, label: Text('Auto')),
            ButtonSegment(value: ThemeModeSetting.morning, label: Text('Sáng')),
            ButtonSegment(value: ThemeModeSetting.afternoon, label: Text('Chiều')),
            ButtonSegment(value: ThemeModeSetting.evening, label: Text('Tối')),
          ],
          selected: {controller.mode},
          onSelectionChanged: (s) => controller.setMode(s.first),
        );
      },
    );
  }
}
