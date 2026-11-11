import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/day_period.dart';
import '../../shared/widgets/progress_ring.dart';
import 'physical_style.dart';
import 'step_controller.dart';

class StepCard extends StatelessWidget {
  const StepCard({super.key, required this.controller});

  final StepController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const PhysicalCardTitle(Icons.directions_walk, 'Bước chân hôm nay'),
            const SizedBox(height: 16),
            Row(
              children: [
                ProgressRing(
                  percent: (controller.steps / AppConstants.stepGoal).clamp(
                    0.0,
                    1.0,
                  ),
                  size: 92,
                  strokeWidth: 15,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${controller.steps} bước',
                        style: AppTextStyles.metricValue.copyWith(
                          color: context.palette.textAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Mục tiêu: ${AppConstants.stepGoal} bước mỗi ngày.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Bật theo dõi khi muốn đếm bước, dừng bất cứ lúc nào. Số bước có thể cập nhật trễ.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Bước đi khi đã dừng sẽ không được tính. Nếu ứng dụng bị đóng, hãy bật lại để tiếp tục.',
            ),
            if (controller.error != null) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  controller.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: controller.busy
                  ? null
                  : controller.tracking
                  ? controller.stop
                  : controller.ready
                  ? controller.start
                  : controller.load,
              icon: Icon(
                controller.tracking ? Icons.stop : Icons.directions_walk,
              ),
              label: Text(
                controller.busy
                    ? 'Đang chuẩn bị…'
                    : controller.tracking
                    ? 'Dừng theo dõi'
                    : controller.ready
                    ? 'Bắt đầu theo dõi'
                    : 'Thử lại',
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
