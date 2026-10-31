import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/features/physical/physical_controller.dart';
import 'package:healthiez/features/physical/physical_store.dart';
import 'package:healthiez/features/physical/step_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late HttpServer server;
  late SupabaseClient client;
  late PhysicalStore store;
  late Map<String, Map<String, dynamic>> records;
  late List<Uri> reads;
  late bool fail;
  Completer<void>? holdRead;
  Completer<void>? readStarted;

  Future<void> signIn(String id) => client.auth.recoverSession(
    jsonEncode({
      'access_token': 'test-session',
      'token_type': 'bearer',
      'user': {'id': id},
    }),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    records = {};
    reads = [];
    fail = false;
    holdRead = null;
    readStarted = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (fail) {
        request.response.statusCode = 400;
        request.response.write(jsonEncode({'message': 'Storage unavailable'}));
      } else if (request.method == 'POST') {
        final row = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        records['${row['user_id']}/${row['kind']}/${row['device_id']}'] = row;
        request.response.statusCode = 201;
      } else {
        reads.add(request.uri);
        readStarted?.complete();
        await holdRead?.future;
        final query = request.uri.queryParameters;
        final key = [
          'user_id',
          'kind',
          'device_id',
        ].map((field) => query[field]!.substring(3)).join('/');
        final row = records[key];
        request.response.write(
          jsonEncode([
            if (row != null) {'payload': row['payload']},
          ]),
        );
      }
      await request.response.close();
    });
    client = SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'test-publishable-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await signIn('user-a');
    store = PhysicalStore(client, 'user-a');
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  PhysicalController physical() => PhysicalController(
    now: () => DateTime(2026, 10, 25),
    read: () => store.read('physical'),
    write: (value) => store.write('physical', value),
  );

  test('measurements and water restore through Supabase requests', () async {
    final first = physical();
    addTearDown(first.dispose);
    await first.load();
    expect(await first.saveMeasurements(170.5, 65.5), isTrue);
    expect(await first.addWater(), isTrue);
    final restored = physical();
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.heightCm, 170.5);
    expect(restored.weightKg, 65.5);
    expect(restored.waterMl, 250);
    expect(reads.last.queryParameters['user_id'], 'eq.user-a');
    expect(records.keys.single, 'user-a/physical/');
  });

  test('cloud failures retain confirmed values and allow retry', () async {
    final controller = physical();
    addTearDown(controller.dispose);
    fail = true;
    await controller.load();
    expect(controller.ready, isFalse);
    expect(controller.error, isNotNull);
    fail = false;
    await controller.load();
    expect(await controller.addWater(), isTrue);
    fail = true;
    expect(await controller.addWater(), isFalse);
    expect(controller.waterMl, 250);
    fail = false;
    expect(await controller.addWater(), isTrue);
    expect(controller.waterMl, 500);
  });

  test('step baseline survives restart only for the same device', () async {
    final sensor = StreamController<int>();
    final controller = StepController(
      now: () => DateTime(2026, 10, 25),
      read: () => store.read('steps'),
      write: (value) => store.write('steps', value),
      connect: () async => sensor.stream,
    );
    addTearDown(controller.dispose);
    await controller.load();
    await controller.start();
    final baseline = Completer<void>();
    final counted = Completer<void>();
    controller.addListener(() {
      if (records.isNotEmpty && !baseline.isCompleted) baseline.complete();
      if (controller.steps == 12 && !counted.isCompleted) counted.complete();
    });
    sensor.add(1000);
    await baseline.future;
    sensor.add(1012);
    await counted.future;
    await sensor.close();
    final sameDevice = PhysicalStore(client, 'user-a');
    expect(jsonDecode((await sameDevice.read('steps'))!)['steps'], 12);
    expect(jsonDecode((await sameDevice.read('steps'))!)['last'], 1012);
    SharedPreferences.setMockInitialValues({});
    final otherDevice = PhysicalStore(client, 'user-a');
    expect(await otherDevice.read('steps'), isNull);
  });

  test('stale account stores reject reads and writes', () async {
    await signIn('user-b');
    await expectLater(store.read('physical'), throwsStateError);
    await expectLater(store.write('physical', '{}'), throwsStateError);
    expect(records, isEmpty);
    expect(reads, isEmpty);
  });

  test('a response arriving after an account switch is rejected', () async {
    holdRead = Completer<void>();
    readStarted = Completer<void>();
    final reading = store.read('physical');
    final rejected = expectLater(reading, throwsStateError);
    await readStarted!.future;
    await signIn('user-b');
    holdRead!.complete();
    await rejected;
  });
}
