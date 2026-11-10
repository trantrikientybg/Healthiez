import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/data/repositories/sleep_repository.dart';
import 'package:healthiez/data/sleep/sleep_logic.dart';
import 'package:healthiez/data/sleep/sleep_models.dart';
import 'package:healthiez/data/sleep/sleep_store.dart';

void main() {
  DateTime t(int day, int h, [int m = 0]) => DateTime(2026, 11, day, h, m);

  group('ngày ngủ (reset 12h trưa)', () {
    test('23h và 1h sáng cùng thuộc một ngày ngủ', () {
      expect(SleepDay.of(t(5, 23)), DateTime(2026, 11, 5));
      expect(SleepDay.of(t(6, 1)), DateTime(2026, 11, 5));
      expect(SleepDay.of(t(6, 11, 59)), DateTime(2026, 11, 5));
    });

    test('đúng 12h trưa là sang ngày ngủ mới', () {
      expect(SleepDay.of(t(6, 12)), DateTime(2026, 11, 6));
    });

    test('khóa dạng YYYY-MM-DD', () {
      expect(SleepDay.key(DateTime(2026, 3, 7)), '2026-03-07');
    });
  });

  group('đếm giờ ngủ', () {
    test('một đêm trọn vẹn: tắt màn hình 23h10, mở lúc 6h40', () {
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23, 10));
      expect(d.active!.phase, SleepPhase.sleeping);
      d = SleepLogic.screenOn(d, t(6, 6, 40));
      expect(d.active!.phase, SleepPhase.awake);
      expect(d.active!.accumulated, const Duration(hours: 7, minutes: 30));

      final (after, entry) = SleepLogic.finish(d, t(6, 6, 45));
      expect(after.active, isNull);
      expect(entry!.asleep, const Duration(hours: 7, minutes: 30));
      expect(entry.bedTime, t(5, 23));
      expect(entry.wakeTime, t(6, 6, 40)); // lần mở máy cuối = lúc thức dậy
      expect(after.history.keys, ['2026-11-05']);
    });

    test('mở máy giữa đêm thì tạm dừng, tắt lại thì đếm tiếp', () {
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23, 10));
      d = SleepLogic.screenOn(d, t(6, 3, 10)); // 4 giờ
      d = SleepLogic.screenOff(d, t(6, 3, 20)); // 10 phút xem điện thoại không tính
      d = SleepLogic.screenOn(d, t(6, 7, 20)); // 4 giờ nữa
      expect(d.active!.accumulated, const Duration(hours: 8));
    });

    test('tắt màn hình hai lần liên tiếp không làm mất mốc đầu', () {
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23, 10));
      final again = SleepLogic.screenOff(d, t(5, 23, 50));
      expect(identical(again, d), isTrue);
    });

    test('mở máy khi chưa tắt màn hình thì không có gì thay đổi', () {
      final d = SleepLogic.begin(const SleepData(), t(5, 23));
      expect(identical(SleepLogic.screenOn(d, t(5, 23, 5)), d), isTrue);
    });

    test('kết thúc khi chưa ngủ phút nào: không lưu gì', () {
      final d = SleepLogic.begin(const SleepData(), t(5, 23));
      final (after, entry) = SleepLogic.finish(d, t(5, 23, 5));
      expect(entry, isNull);
      expect(after.active, isNull);
      expect(after.history, isEmpty);
    });

    test('bắt đầu sau nửa đêm vẫn thuộc ngày ngủ hôm trước', () {
      var d = SleepLogic.begin(const SleepData(), t(6, 1));
      d = SleepLogic.screenOff(d, t(6, 1, 5));
      d = SleepLogic.screenOn(d, t(6, 7));
      final (after, _) = SleepLogic.finish(d, t(6, 7));
      expect(after.history.keys, ['2026-11-05']);
    });

    test('hai phiên cùng ngày ngủ được cộng dồn', () {
      var d = const SleepData();
      for (final (start, end) in [(t(5, 23), t(6, 3)), (t(6, 5), t(6, 7))]) {
        d = SleepLogic.begin(d, start);
        d = SleepLogic.screenOff(d, start);
        d = SleepLogic.screenOn(d, end);
        d = SleepLogic.finish(d, end).$1;
      }
      expect(d.history['2026-11-05']!.asleep, const Duration(hours: 6));
    });
  });

  group('phiên bị bỏ dở (app bị tắt giữa đêm)', () {
    test('mở lại app thì coi như thức dậy lúc đó', () {
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23, 10));
      final settled = SleepLogic.settle(d, t(6, 7));
      expect(settled.active!.phase, SleepPhase.awake);
      expect(settled.active!.accumulated, const Duration(hours: 7, minutes: 50));
    });

    test('một đoạn tắt màn hình không tính quá 14 giờ và phiên quá 20 giờ tự kết thúc', () {
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23));
      final settled = SleepLogic.settle(d, t(6, 23)); // 24 giờ sau
      expect(settled.active, isNull);
      expect(settled.history['2026-11-05']!.asleep, const Duration(hours: 14));
    });
  });

  group('lưu trữ', () {
    test('mã hóa rồi đọc lại giữ nguyên dữ liệu', () {
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23, 10));
      final back = SleepData.decode(d.encode());
      expect(back.active!.runningSince, t(5, 23, 10));
      expect(back.active!.startedAt, t(5, 23));
    });

    test('dữ liệu hỏng thì trả về dữ liệu trống', () {
      expect(SleepData.decode('khong phai json').active, isNull);
      expect(SleepData.decode(null).history, isEmpty);
    });
  });

  group('SleepRepository (đọc cho Home)', () {
    Future<SleepRepository> repoWith(DateTime now) async {
      final storage = MemorySleepStorage();
      var d = SleepLogic.begin(const SleepData(), t(5, 23));
      d = SleepLogic.screenOff(d, t(5, 23, 10));
      d = SleepLogic.screenOn(d, t(6, 6, 40)); // ngủ 7 giờ 30 phút
      d = SleepLogic.finish(d, t(6, 6, 40)).$1;
      storage.value = d.encode();
      return SleepRepository(store: SleepStore(storage: storage), now: () => now);
    }

    test('7h sáng: thấy đêm vừa rồi', () async {
      final r = await (await repoWith(t(6, 7))).getLastNightSleep();
      expect(r, isNotNull);
      expect(r!.hours, 7.5);
      expect(r.rangeLabel, '23h - 6h40');
    });

    test('3h chiều và 11h đêm vẫn thấy đêm trước (chờ đêm mới)', () async {
      expect(await (await repoWith(t(6, 15))).getLastNightSleep(), isNotNull);
      expect(await (await repoWith(t(6, 23))).getLastNightSleep(), isNotNull);
    });

    test('hai ngày sau không còn dữ liệu', () async {
      expect(await (await repoWith(t(7, 15))).getLastNightSleep(), isNull);
    });

    test('chưa từng dùng thì trả về null', () async {
      final repo = SleepRepository(
        store: SleepStore(storage: MemorySleepStorage()),
        now: () => t(6, 23),
      );
      expect(await repo.getLastNightSleep(), isNull);
    });
  });
}
