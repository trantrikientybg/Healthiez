import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/features/physical/step_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late String? stored;
  late StreamController<int> sensor;
  late StepController controller;
  late bool failWrite;

  Future<void> emit(int count) async {
    sensor.add(count);
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() async {
    now = DateTime(2026, 10, 25, 12);
    stored = null;
    failWrite = false;
    sensor = StreamController<int>();
    controller = StepController(
      now: () => now,
      read: () async => stored,
      write: (value) async {
        if (failWrite) return false;
        stored = value;
        return true;
      },
      connect: () async => sensor.stream,
    );
    await controller.load();
    await controller.start();
  });

  tearDown(() async {
    controller.dispose();
    await sensor.close();
  });

  test(
    'counts deltas, ignores duplicates, and rebases on sensor reset',
    () async {
      await emit(1000);
      expect(controller.steps, 0);
      await emit(1012);
      expect(controller.steps, 12);
      await emit(1012);
      await emit(-1);
      expect(controller.steps, 12);
      await emit(2);
      expect(controller.steps, 12);
      await emit(5);
      expect(controller.steps, 15);
      expect(jsonDecode(stored!)['last'], 5);
    },
  );

  test('restores saved baseline without double counting on restart', () async {
    await emit(1000);
    await emit(1020);
    final restoredSensor = StreamController<int>();
    final restored = StepController(
      now: () => now,
      read: () async => stored,
      write: (_) async => true,
      connect: () async => restoredSensor.stream,
    );
    await restored.load();
    expect(restored.steps, 20);
    expect(restored.tracking, isFalse);
    await restored.start();
    restoredSensor.add(1025);
    await Future<void>.delayed(Duration.zero);
    expect(restored.steps, 25);
    restored.dispose();
    await restoredSensor.close();
  });

  test('day rollover discards an interval spanning midnight', () async {
    await emit(100);
    await emit(120);
    now = DateTime(2026, 10, 26);
    controller.refreshDay();
    expect(controller.steps, 0);
    await emit(150);
    expect(controller.steps, 0);
    await emit(157);
    expect(controller.steps, 7);
    expect(jsonDecode(stored!)['date'], '2026-10-26');
  });

  test(
    'failed writes retain baseline and next event retries all steps',
    () async {
      await emit(100);
      failWrite = true;
      await emit(110);
      expect(controller.steps, 0);
      expect(controller.error, isNotNull);
      failWrite = false;
      await emit(115);
      expect(controller.steps, 15);
      expect(controller.error, isNull);
    },
  );

  test('sensor errors and completion allow retry', () async {
    sensor.addError(StateError('Sensor unavailable'));
    await Future<void>.delayed(Duration.zero);
    expect(controller.tracking, isFalse);
    expect(controller.error, isNotNull);
    final retrySensor = StreamController<int>();
    final retry = StepController(
      read: () async => null,
      connect: () async => retrySensor.stream,
    );
    await retry.load();
    await retry.start();
    expect(retry.tracking, isTrue);
    await retrySensor.close();
    expect(retry.tracking, isFalse);
    retry.dispose();
  });

  test(
    'permission denial and unsupported platforms preserve saved counts',
    () async {
      for (final error in [StateError('Denied'), UnsupportedError('Desktop')]) {
        final denied = StepController(
          now: () => now,
          read: () async =>
              jsonEncode({'date': '2026-10-25', 'steps': 42, 'last': 100}),
          connect: () async => throw error,
        );
        await denied.load();
        await denied.start();
        expect(denied.steps, 42);
        expect(denied.tracking, isFalse);
        expect(denied.busy, isFalse);
        expect(denied.error, isNotNull);
        denied.dispose();
      }
    },
  );

  test(
    'read failures and corrupt records stay untouched and can retry',
    () async {
      for (final raw in [
        '{broken',
        '{"date":"2026-02-30","steps":0,"last":0}',
        '{"date":"2026-10-25","steps":-1,"last":0}',
      ]) {
        var failRead = true;
        var writes = 0;
        final reader = StepController(
          read: () async => failRead ? raw : null,
          write: (_) async {
            writes++;
            return true;
          },
        );
        await reader.load();
        await reader.start();
        expect(reader.ready, isFalse);
        expect(writes, 0);
        failRead = false;
        await reader.load();
        expect(reader.ready, isTrue);
        reader.dispose();
      }
    },
  );

  test(
    'serializes writes and does not resurrect yesterday after midnight',
    () async {
      final pending = Completer<bool>();
      var writes = 0;
      final events = StreamController<int>();
      final writer = StepController(
        now: () => now,
        read: () async => null,
        write: (_) {
          writes++;
          return writes == 1 ? pending.future : Future.value(true);
        },
        connect: () async => events.stream,
      );
      await writer.load();
      await writer.start();
      events.add(100);
      events.add(110);
      await Future<void>.delayed(Duration.zero);
      expect(writes, 1);
      now = DateTime(2026, 10, 26);
      writer.refreshDay();
      pending.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(writer.steps, 0);
      events.add(120);
      events.add(125);
      await Future<void>.delayed(Duration.zero);
      expect(writer.steps, 5);
      writer.dispose();
      await events.close();
    },
  );

  test('actual preferences round trip preserves steps', () async {
    SharedPreferences.setMockInitialValues({});
    final events = StreamController<int>();
    final first = StepController(connect: () async => events.stream);
    final second = StepController();
    await first.load();
    await first.start();
    events.add(200);
    events.add(208);
    await Future<void>.delayed(Duration.zero);
    await second.load();
    expect(second.steps, 8);
    first.dispose();
    second.dispose();
    await events.close();
  });

  test('pending connection after disposal does not subscribe', () async {
    final connection = Completer<Stream<int>>();
    final events = StreamController<int>.broadcast();
    final pending = StepController(
      read: () async => null,
      connect: () => connection.future,
    );
    await pending.load();
    final starting = pending.start();
    pending.dispose();
    connection.complete(events.stream);
    await starting;
    expect(events.hasListener, isFalse);
    await events.close();
  });
}
