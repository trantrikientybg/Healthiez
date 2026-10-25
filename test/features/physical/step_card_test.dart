import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/features/physical/step_card.dart';
import 'package:healthiez/features/physical/step_controller.dart';

void main() {
  testWidgets('start updates steps and shows a retry after sensor failure', (
    tester,
  ) async {
    final events = StreamController<int>.broadcast();
    final controller = StepController(
      read: () async => null,
      write: (_) async => true,
      connect: () async => events.stream,
    );
    await controller.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: StepCard(controller: controller)),
      ),
    );
    expect(find.text('0 bước'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu theo dõi'));
    await tester.pumpAndSettle();
    expect(find.text('Đang theo dõi bước chân'), findsOneWidget);
    events.add(100);
    await tester.pumpAndSettle();
    events.add(112);
    await tester.pumpAndSettle();
    expect(find.text('12 bước'), findsOneWidget);
    events.addError(StateError('Sensor failure'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không đọc được cảm biến'), findsOneWidget);
    await tester.tap(find.text('Bắt đầu theo dõi'));
    await tester.pumpAndSettle();
    expect(find.text('Đang theo dõi bước chân'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await events.close();
  });

  testWidgets(
    'unsupported device displays a useful message in a narrow layout',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = StepController(
        read: () async => null,
        connect: () async => throw UnsupportedError('Desktop'),
      );
      await controller.load();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StepCard(controller: controller),
            ),
          ),
        ),
      );
      await tester.ensureVisible(find.text('Bắt đầu theo dõi'));
      await tester.tap(find.text('Bắt đầu theo dõi'));
      await tester.pumpAndSettle();
      expect(find.textContaining('chỉ hỗ trợ điện thoại'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );
}
