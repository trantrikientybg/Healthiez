import 'package:flutter/material.dart';

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
            Text(
              'Bước chân hôm nay',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              '${controller.steps} bước',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Bắt đầu theo dõi để ghi nhận bước chân bằng điện thoại. Số bước có thể cập nhật trễ.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Ngày mới bắt đầu từ lần đọc cảm biến đầu tiên. Không đảm bảo đếm khi ứng dụng đóng.',
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
              onPressed: controller.busy || controller.tracking
                  ? null
                  : controller.ready
                  ? controller.start
                  : controller.load,
              icon: const Icon(Icons.directions_walk),
              label: Text(
                controller.busy
                    ? 'Đang chuẩn bị…'
                    : controller.tracking
                    ? 'Đang theo dõi bước chân'
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
