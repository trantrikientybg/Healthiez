import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/features/physical/physical_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late String? stored;
  late bool failWrite;
  late PhysicalController controller;

  setUp(() async {
    now = DateTime(2026, 10, 24, 23, 59);
    stored = null;
    failWrite = false;
    controller = PhysicalController(
      now: () => now,
      read: () async => stored,
      write: (value) async {
        if (failWrite) return false;
        stored = value;
        return true;
      },
    );
    await controller.load();
  });
  tearDown(() => controller.dispose());

  test('parses decimals and rejects invalid measurements', () {
    expect(PhysicalController.parseMeasurement(' 65,5 '), 65.5);
    expect(PhysicalController.parseMeasurement('170.5'), 170.5);
    for (final invalid in ['', 'abc', '0', '-1', 'NaN', 'Infinity', '1,2.3']) {
      expect(PhysicalController.parseMeasurement(invalid), isNull);
    }
  });

  test('calculates BMI; invalid input preserves saved values', () async {
    expect(controller.bmi, isNull);
    expect(await controller.saveMeasurements(170, 65.5), isTrue);
    expect(controller.bmi, closeTo(22.664, .001));
    final original = stored;
    for (final invalid in [0.0, -1.0, double.nan, double.infinity, 1e-300]) {
      expect(await controller.saveMeasurements(invalid, 65), isFalse);
      expect(stored, original);
      expect(controller.heightCm, 170);
    }
    expect(await controller.saveMeasurements(170, -1), isFalse);
    expect(controller.weightKg, 65.5);
  });

  test('water exceeds reference; Undo reverses only latest addition', () async {
    expect(await controller.undoWater(), isFalse);
    for (var i = 0; i < 9; i++) {
      await controller.addWater();
    }
    expect(controller.waterMl, 2250);
    expect(await controller.undoWater(), isTrue);
    expect(controller.waterMl, 2000);
    expect(await controller.undoWater(), isFalse);
  });

  test('restores measurements and water, but not session Undo', () async {
    await controller.saveMeasurements(180, 81);
    await controller.addWater();
    final restored = PhysicalController(
      now: () => now,
      read: () async => stored,
    );
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.ready, isTrue);
    expect(restored.bmi, 25);
    expect(restored.waterMl, 250);
    expect(restored.canUndo, isFalse);
  });

  test('actual preferences round trip preserves all fields', () async {
    SharedPreferences.setMockInitialValues({});
    final first = PhysicalController();
    final second = PhysicalController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await first.load();
    await first.saveMeasurements(160, 64);
    await first.addWater();
    await second.load();
    expect(second.heightCm, 160);
    expect(second.weightKg, 64);
    expect(second.bmi, closeTo(25, 0.000001));
    expect(second.waterMl, 250);
  });

  test(
    'date rollover clears water and Undo, preserving measurements',
    () async {
      await controller.saveMeasurements(180, 81);
      await controller.addWater();
      now = DateTime(2026, 10, 25);
      controller.refreshDay();
      expect(controller.waterMl, 0);
      expect(controller.canUndo, isFalse);
      expect(controller.bmi, 25);
      await controller.addWater();
      expect(controller.waterMl, 250);
      expect(jsonDecode(stored!)['waterDate'], '2026-10-25');
    },
  );

  test('loading old water and adding after rollover start at zero', () async {
    await controller.addWater();
    now = DateTime(2026, 11, 1);
    final restored = PhysicalController(
      now: () => now,
      read: () async => stored,
    );
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.waterMl, 0);
    expect(await controller.undoWater(), isFalse);
    await controller.addWater();
    expect(controller.waterMl, 250);
  });

  test('failed saves preserve data and can be retried', () async {
    await controller.saveMeasurements(170, 65);
    await controller.addWater();
    final original = stored;
    failWrite = true;
    expect(await controller.saveMeasurements(180, 80), isFalse);
    expect(controller.heightCm, 170);
    expect(await controller.addWater(), isFalse);
    expect(controller.waterMl, 250);
    expect(await controller.undoWater(), isFalse);
    expect(controller.waterMl, 250);
    expect(controller.canUndo, isTrue);
    expect(stored, original);
    expect(controller.error, isNotNull);
    expect(controller.busy, isFalse);
    failWrite = false;
    expect(await controller.addWater(), isTrue);
    expect(controller.waterMl, 500);
    expect(controller.error, isNull);
  });

  test('read failure retries; corrupt records are not overwritten', () async {
    var failRead = true;
    final reader = PhysicalController(
      read: () async {
        if (failRead) throw StateError('Read failed');
        return stored;
      },
      write: (value) async {
        stored = value;
        return true;
      },
    );
    addTearDown(reader.dispose);
    await reader.load();
    expect(reader.ready, isFalse);
    expect(reader.error, isNotNull);
    failRead = false;
    stored = '{broken json';
    await reader.load();
    expect(reader.ready, isFalse);
    expect(await reader.addWater(), isFalse);
    expect(stored, '{broken json');
    stored = null;
    await reader.load();
    expect(reader.ready, isTrue);
    expect(reader.error, isNull);
  });

  test('malformed stored values cannot become active data', () async {
    final valid = {
      'heightCm': 170,
      'weightKg': 65,
      'waterMl': 250,
      'waterDate': '2026-10-24',
    };
    for (final override in [
      {'heightCm': -1},
      {'weightKg': null},
      {'waterMl': -250},
      {'waterMl': '250'},
      {'waterDate': '2026-02-30'},
    ]) {
      final reader = PhysicalController(
        read: () async => jsonEncode({...valid, ...override}),
      );
      await reader.load();
      expect(reader.ready, isFalse);
      expect(reader.error, isNotNull);
      reader.dispose();
    }
  });

  test('pending save blocks duplicates and handles midnight', () async {
    final pending = Completer<bool>();
    final writer = PhysicalController(
      now: () => now,
      read: () async => null,
      write: (_) => pending.future,
    );
    addTearDown(writer.dispose);
    await writer.load();
    final saving = writer.addWater();
    expect(writer.busy, isTrue);
    expect(await writer.addWater(), isFalse);
    expect(await writer.saveMeasurements(170, 65), isFalse);
    now = DateTime(2026, 10, 25);
    writer.refreshDay();
    pending.complete(true);
    expect(await saving, isTrue);
    expect(writer.waterMl, 0);
    expect(writer.canUndo, isFalse);
  });

  test('load completing after disposal does not notify listeners', () async {
    final pending = Completer<String?>();
    final reader = PhysicalController(read: () => pending.future);
    final loading = reader.load();
    reader.dispose();
    pending.complete(null);
    await loading;
  });
}
