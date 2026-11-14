import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/data/models/screen_time_record.dart';
import 'package:healthiez/features/home/logic/suggestion.dart';
import 'package:healthiez/features/home/logic/suggestion_engine.dart';

void main() {
  final day = DateTime(2026, 11, 5);

  test('không đọc được thời gian dùng máy: không cảnh báo', () {
    final out = SuggestionEngine.build(
      SuggestionInput(
        now: DateTime(2026, 11, 5, 15),
        screenTime: ScreenTimeRecord.unavailable(date: day, limitMinutes: 240),
      ),
    );
    expect(out.map((s) => s.kind), isNot(contains(SuggestionKind.screenTimeWarning)));
  });

  test('đọc được và vượt 4 tiếng: vẫn cảnh báo', () {
    final out = SuggestionEngine.build(
      SuggestionInput(
        now: DateTime(2026, 11, 5, 15),
        screenTime: ScreenTimeRecord(date: day, minutes: 300, limitMinutes: 240),
      ),
    );
    expect(out.first.kind, SuggestionKind.screenTimeWarning);
  });

  test('bản ghi không đọc được có available = false', () {
    expect(ScreenTimeRecord.unavailable(date: day, limitMinutes: 240).available, isFalse);
    expect(ScreenTimeRecord(date: day, minutes: 0, limitMinutes: 240).available, isTrue);
  });
}
