import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/data/sleep/sleep_logic.dart';
import 'package:healthiez/data/sleep/sleep_models.dart';
import 'package:healthiez/data/sleep/sleep_remote.dart';
import 'package:healthiez/data/sleep/sleep_store.dart';
import 'package:healthiez/data/sleep/sleep_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeRemote implements SleepRemote {
  final Map<String, SleepEntry> rows = {};
  bool failFetch = false;
  bool failUpsert = false;
  final List<String> upserts = [];

  @override
  Future<Map<String, SleepEntry>> fetchSince(String userId, DateTime fromDay) async {
    if (failFetch) throw Exception('mất mạng');
    return Map.of(rows);
  }

  @override
  Future<void> upsert(String userId, String dayKey, SleepEntry entry) async {
    if (failUpsert) throw Exception('mất mạng');
    rows[dayKey] = entry;
    upserts.add(dayKey);
  }
}

void main() {
  DateTime t(int day, int h, [int m = 0]) => DateTime(2026, 11, day, h, m);

  SleepEntry entry(int day, int bedH, int wakeDay, int wakeH, Duration asleep) => SleepEntry(
        bedTime: t(day, bedH),
        wakeTime: t(wakeDay, wakeH),
        asleep: asleep,
      );

  late MemorySleepStorage storage;
  late SleepStore store;
  late FakeRemote remote;
  late SleepSyncService sync;

  setUp(() {
    storage = MemorySleepStorage();
    store = SleepStore(storage: storage);
    remote = FakeRemote();
    sync = SleepSyncService(
      store: store,
      remote: remote,
      userId: 'u1',
      now: () => t(6, 8),
    );
  });

  Future<void> seed(SleepData d) => store.save(d);

  test('kết thúc giấc ngủ thì ngày đó nằm trong danh sách chờ đẩy', () {
    var d = SleepLogic.begin(const SleepData(), t(5, 23));
    d = SleepLogic.screenOff(d, t(5, 23, 10));
    d = SleepLogic.screenOn(d, t(6, 6, 40));
    final (after, _) = SleepLogic.finish(d, t(6, 6, 40));
    expect(after.pending, {'2026-11-05'});
  });

  test('đẩy ngày đang chờ lên DB rồi bỏ khỏi danh sách chờ', () async {
    final e = entry(5, 23, 6, 7, const Duration(hours: 7));
    await seed(SleepData(history: {'2026-11-05': e}, pending: {'2026-11-05'}));

    await sync.sync();

    expect(remote.rows['2026-11-05'], e);
    final after = await store.load();
    expect(after.pending, isEmpty);
    expect(after.history['2026-11-05'], e);
  });

  test('đổi máy: máy trống thì kéo giấc ngủ từ DB về', () async {
    final e = entry(5, 23, 6, 7, const Duration(hours: 7));
    remote.rows['2026-11-05'] = e;

    await sync.sync();

    final after = await store.load();
    expect(after.history['2026-11-05'], e);
    expect(after.pending, isEmpty);
    expect(remote.upserts, isEmpty); // không đẩy lại thứ vừa kéo về
  });

  test('dữ liệu cũ chỉ có trên máy (trước khi có đồng bộ) cũng được đẩy lên', () async {
    final e = entry(5, 23, 6, 7, const Duration(hours: 6));
    await seed(SleepData(history: {'2026-11-05': e})); // không nằm trong pending

    await sync.sync();

    expect(remote.rows['2026-11-05'], e);
    expect((await store.load()).pending, isEmpty);
  });

  test('mất mạng: không báo lỗi, giữ nguyên dữ liệu và danh sách chờ', () async {
    final e = entry(5, 23, 6, 7, const Duration(hours: 7));
    await seed(SleepData(history: {'2026-11-05': e}, pending: {'2026-11-05'}));
    remote.failFetch = true;
    remote.failUpsert = true;

    await sync.sync(); // không ném lỗi

    final after = await store.load();
    expect(after.history['2026-11-05'], e);
    expect(after.pending, {'2026-11-05'});
  });

  test('chỉ kéo về được, đẩy lên lỗi: vẫn nhận dữ liệu từ DB và giữ ngày chờ', () async {
    final local = entry(5, 23, 6, 7, const Duration(hours: 7));
    final other = entry(4, 23, 5, 7, const Duration(hours: 8));
    remote.rows['2026-11-04'] = other;
    remote.failUpsert = true;
    await seed(SleepData(history: {'2026-11-05': local}, pending: {'2026-11-05'}));

    await sync.sync();

    final after = await store.load();
    expect(after.history['2026-11-04'], other);
    expect(after.pending, {'2026-11-05'});
  });

  test('bản trên máy đang chờ đẩy thắng bản trên DB', () async {
    final local = entry(5, 23, 6, 7, const Duration(hours: 7));
    final old = entry(5, 23, 6, 5, const Duration(hours: 5));
    remote.rows['2026-11-05'] = old;
    await seed(SleepData(history: {'2026-11-05': local}, pending: {'2026-11-05'}));

    await sync.sync();

    expect(remote.rows['2026-11-05'], local);
    expect((await store.load()).history['2026-11-05'], local);
  });

  test('bản trên DB thắng bản trên máy không còn chờ', () async {
    final local = entry(5, 23, 6, 5, const Duration(hours: 5));
    final server = entry(5, 23, 6, 7, const Duration(hours: 7));
    remote.rows['2026-11-05'] = server;
    await seed(SleepData(history: {'2026-11-05': local}));

    await sync.sync();

    expect((await store.load()).history['2026-11-05'], server);
    expect(remote.upserts, isEmpty);
  });

  test('applyResult: bản trên máy bị đổi trong lúc đồng bộ thì giữ trạng thái chờ', () {
    final uploadedVersion = entry(5, 23, 6, 5, const Duration(hours: 5));
    final newerLocal = entry(5, 23, 6, 7, const Duration(hours: 7));
    final latest = SleepData(history: {'2026-11-05': newerLocal}, pending: {'2026-11-05'});

    final out = SleepSyncService.applyResult(
      latest,
      remoteEntries: const {},
      toUpload: {'2026-11-05': uploadedVersion},
      uploaded: {'2026-11-05': uploadedVersion},
    );

    expect(out.pending, {'2026-11-05'}); // phải đẩy lại bản mới hơn
    expect(out.history['2026-11-05'], newerLocal);
  });

  test('applyResult: không giữ quá 14 ngày gần nhất', () {
    final hist = {
      for (var d = 1; d <= 20; d++)
        '2026-10-${d.toString().padLeft(2, '0')}': entry(d, 23, d + 1, 7, const Duration(hours: 7)),
    };
    final out = SleepSyncService.applyResult(
      SleepData(history: hist),
      remoteEntries: const {},
      toUpload: const {},
      uploaded: const {},
    );
    expect(out.history.length, SleepData.keepDays);
    expect(out.history.containsKey('2026-10-20'), isTrue);
    expect(out.history.containsKey('2026-10-01'), isFalse);
  });

  group('mã hóa dòng của bảng sleep_records', () {
    test('đổi qua lại không mất dữ liệu', () {
      final e = entry(5, 23, 6, 7, const Duration(hours: 7, minutes: 15));
      final row = SleepRemoteCodec.toRow('u1', '2026-11-05', e);
      expect(row['asleep_minutes'], 435);
      final back = SleepRemoteCodec.fromRow(row);
      expect(back!.$1, '2026-11-05');
      expect(back.$2, e);
    });

    test('dòng hỏng thì bỏ qua', () {
      expect(SleepRemoteCodec.fromRow({'sleep_day': 5}), isNull);
    });

    test('thời gian ngủ không vượt 24 giờ (khớp ràng buộc của bảng)', () {
      final e = SleepEntry(
        bedTime: t(5, 1),
        wakeTime: t(6, 1),
        asleep: const Duration(hours: 30),
      );
      expect(SleepRemoteCodec.toRow('u', '2026-11-05', e)['asleep_minutes'], 1440);
    });
  });

  group('lưu trên máy theo từng tài khoản', () {
    test('hai tài khoản không thấy dữ liệu của nhau', () async {
      SharedPreferences.setMockInitialValues({});
      final a = SleepStore(storage: PrefsSleepStorage(userId: 'a'));
      final b = SleepStore(storage: PrefsSleepStorage(userId: 'b'));
      await a.save(SleepData(
        history: {'2026-11-05': entry(5, 23, 6, 7, const Duration(hours: 7))},
      ));
      expect((await a.load()).history, isNotEmpty);
      expect((await b.load()).history, isEmpty);
    });

    test('dữ liệu của bản cũ được chuyển cho tài khoản đầu tiên, không bị chia hai lần', () async {
      final legacy = SleepData(
        history: {'2026-11-05': entry(5, 23, 6, 7, const Duration(hours: 7))},
      ).encode();
      SharedPreferences.setMockInitialValues({'sleep.v1': legacy});

      final a = SleepStore(storage: PrefsSleepStorage(userId: 'a'));
      final b = SleepStore(storage: PrefsSleepStorage(userId: 'b'));
      expect((await a.load()).history.keys, ['2026-11-05']);
      expect((await b.load()).history, isEmpty);
    });
  });

  test('dữ liệu cũ chưa có trường pending vẫn đọc được', () {
    const old = '{"active":null,"history":{}}';
    expect(SleepData.decode(old).pending, isEmpty);
  });
}
