import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/data/repositories/step_aggregator.dart';

void main() {
  // Thứ Năm 12/11/2026 -> tuần bắt đầu thứ Hai 9/11
  final now = DateTime(2026, 11, 12, 15);

  Map<String, dynamic> row({
    required String date,
    required int steps,
    Map<String, dynamic> history = const {},
    String kind = 'steps',
  }) =>
      {
        'kind': kind,
        'payload': {'date': date, 'steps': steps, 'history': history},
      };

  int today(List<Map<String, dynamic>> rows) =>
      StepAggregator.fromRows(rows, now, goal: 10000).steps;
  int week(List<Map<String, dynamic>> rows) =>
      StepAggregator.fromRows(rows, now, goal: 10000).weeklyTotal;

  test('chưa có dữ liệu: 0 bước', () {
    expect(today([]), 0);
    expect(week([]), 0);
  });

  test('chỉ có hôm nay: tuần = hôm nay', () {
    final rows = [row(date: '2026-11-12', steps: 5000)];
    expect(today(rows), 5000);
    expect(week(rows), 5000);
  });

  test('cộng các ngày trước đó trong tuần (history)', () {
    final rows = [
      row(date: '2026-11-12', steps: 3000, history: {
        '2026-11-09': 4000, // thứ Hai
        '2026-11-10': 6000,
        '2026-11-11': 7000,
      }),
    ];
    expect(today(rows), 3000);
    expect(week(rows), 3000 + 4000 + 6000 + 7000);
  });

  test('bỏ các ngày của tuần trước', () {
    final rows = [
      row(date: '2026-11-12', steps: 1000, history: {
        '2026-11-08': 9999, // Chủ nhật tuần trước
        '2026-11-01': 9999,
      }),
    ];
    expect(week(rows), 1000);
  });

  test('hai điện thoại cùng ngày thì cộng lại', () {
    final rows = [
      row(date: '2026-11-12', steps: 3000),
      row(date: '2026-11-12', steps: 2000),
    ];
    expect(today(rows), 5000);
    expect(week(rows), 5000);
  });

  test('điện thoại lâu chưa mở: bước của ngày cuối vẫn tính vào tuần, không tính vào hôm nay', () {
    final rows = [
      row(date: '2026-11-10', steps: 8000, history: {'2026-11-09': 2000}),
    ];
    expect(today(rows), 0);
    expect(week(rows), 10000);
  });

  test('dòng của tuần trước không tính', () {
    final rows = [row(date: '2026-11-06', steps: 8000)];
    expect(week(rows), 0);
  });

  test('history trùng đúng ngày của dòng thì không cộng hai lần', () {
    final rows = [
      row(date: '2026-11-11', steps: 5000, history: {'2026-11-11': 5000}),
    ];
    expect(week(rows), 5000);
  });

  test('history có hôm nay hoặc ngày tương lai thì bỏ qua', () {
    final rows = [
      row(date: '2026-11-12', steps: 1000, history: {
        '2026-11-12': 9999,
        '2026-11-14': 9999,
      }),
    ];
    expect(week(rows), 1000);
  });

  test('thứ Hai: tuần chỉ gồm hôm nay', () {
    final monday = DateTime(2026, 11, 9, 9);
    final r = StepAggregator.fromRows(
      [row(date: '2026-11-09', steps: 800, history: {'2026-11-08': 5000})],
      monday,
      goal: 10000,
    );
    expect(r.weeklyTotal, 800);
  });

  test('Chủ nhật: tuần gồm cả bảy ngày', () {
    final sunday = DateTime(2026, 11, 15, 20);
    final r = StepAggregator.fromRows(
      [
        row(date: '2026-11-15', steps: 100, history: {
          '2026-11-09': 1,
          '2026-11-10': 10,
          '2026-11-11': 1000,
          '2026-11-12': 10000,
          '2026-11-13': 100000,
          '2026-11-14': 1000000,
        }),
      ],
      sunday,
      goal: 10000,
    );
    expect(r.weeklyTotal, 100 + 1 + 10 + 1000 + 10000 + 100000 + 1000000);
  });

  test('dòng không phải kind steps hoặc payload hỏng thì bỏ qua', () {
    final rows = <Map<String, dynamic>>[
      row(date: '2026-11-12', steps: 5000, kind: 'physical'),
      {'kind': 'steps', 'payload': 'khong phai map'},
      {'kind': 'steps', 'payload': {'date': 'hong', 'steps': 'abc', 'history': 5}},
    ];
    expect(today(rows), 0);
    expect(week(rows), 0);
  });

  test('số bước âm hoặc kiểu chuỗi được xử lý an toàn', () {
    final rows = [
      row(date: '2026-11-12', steps: -50),
      {'kind': 'steps', 'payload': {'date': '2026-11-12', 'steps': '1200'}},
    ];
    expect(today(rows), 1200);
  });
}
