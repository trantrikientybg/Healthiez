import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/features/meditation/meditation_controller.dart';

void main() {
  late DateTime clock;
  late MeditationController c;

  setUp(() {
    clock = DateTime(2026, 11, 5, 20);
    c = MeditationController(now: () => clock, minutes: 5);
  });

  tearDown(() => c.dispose());

  void advance(Duration d) {
    clock = clock.add(d);
    c.tick();
  }

  test('ban đầu: chờ, đủ thời lượng', () {
    expect(c.status, MeditationStatus.idle);
    expect(c.remaining, const Duration(minutes: 5));
    expect(c.remainingSeconds, 300);
  });

  test('chạy 60 giây thì còn 4 phút', () {
    c.start();
    advance(const Duration(seconds: 60));
    expect(c.status, MeditationStatus.running);
    expect(c.remaining, const Duration(minutes: 4));
    expect(c.elapsedFraction, closeTo(0.2, 0.001));
  });

  test('tạm dừng thì thời gian đứng yên, tiếp tục thì chạy lại', () {
    c.start();
    advance(const Duration(seconds: 60));
    c.pause();
    expect(c.status, MeditationStatus.paused);

    clock = clock.add(const Duration(minutes: 3)); // thời gian trôi trong lúc dừng
    c.tick();
    expect(c.remaining, const Duration(minutes: 4));

    c.resume();
    advance(const Duration(seconds: 30));
    expect(c.status, MeditationStatus.running);
    expect(c.remaining, const Duration(minutes: 3, seconds: 30));
  });

  test('hết giờ thì chuyển sang hoàn thành', () {
    c.start();
    advance(const Duration(minutes: 5, seconds: 1));
    expect(c.status, MeditationStatus.finished);
    expect(c.remaining, Duration.zero);
    expect(c.elapsedFraction, 1.0);
  });

  test('app bị tắt màn hình lâu rồi quay lại: tick() vẫn tính đúng', () {
    c.start();
    advance(const Duration(minutes: 2, seconds: 10)); // giống lúc mở lại máy
    expect(c.remaining, const Duration(minutes: 2, seconds: 50));
  });

  test('đang chạy thì không đổi được thời lượng, chờ thì đổi được', () {
    c.setMinutes(10);
    expect(c.remaining, const Duration(minutes: 10));
    c.start();
    c.setMinutes(20);
    expect(c.minutes, 10);
  });

  test('đặt lại về trạng thái chờ', () {
    c.start();
    advance(const Duration(minutes: 1));
    c.reset();
    expect(c.status, MeditationStatus.idle);
    expect(c.remaining, const Duration(minutes: 5));
  });

  test('thiền lại sau khi xong bắt đầu từ đầu', () {
    c.start();
    advance(const Duration(minutes: 6));
    expect(c.status, MeditationStatus.finished);
    c.start();
    expect(c.status, MeditationStatus.running);
    expect(c.remaining, const Duration(minutes: 5));
  });
}
