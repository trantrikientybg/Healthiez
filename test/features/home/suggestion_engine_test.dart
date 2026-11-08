import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/data/models/screen_time_record.dart';
import 'package:healthiez/data/models/sleep_record.dart';
import 'package:healthiez/data/models/song.dart';
import 'package:healthiez/data/models/step_record.dart';
import 'package:healthiez/features/home/logic/suggestion.dart';
import 'package:healthiez/features/home/logic/suggestion_engine.dart';
import 'package:healthiez/screens/mental/mental_data.dart' show Mood;

void main() {
  final day = DateTime(2026, 11, 5);

  StepRecord steps(int n) =>
      StepRecord(date: day, steps: n, goal: 10000, weeklyTotal: n);

  SleepRecord sleep(int hours) => SleepRecord(
        date: day,
        bedTime: DateTime(2026, 11, 5, 0),
        wakeTime: DateTime(2026, 11, 5, hours),
        goalHours: 8,
      );

  ScreenTimeRecord screen(int minutes) =>
      ScreenTimeRecord(date: day, minutes: minutes, limitMinutes: 240);

  const song = Song(title: 'A', artist: 'B', coverUrl: '', musicUrl: 'https://x.y');
  const urls = {Mood.happy: 'https://happy', Mood.cry: 'https://sad'};

  List<SuggestionKind> kinds(SuggestionInput i, {Set<String> dismissed = const {}}) =>
      SuggestionEngine.build(i, dismissed: dismissed).map((s) => s.kind).toList();

  test('dùng máy trên 4 tiếng: cảnh báo luôn đứng đầu', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 15),
      screenTime: screen(260),
      recentMoods: const [Mood.happy, Mood.happy],
      playlistUrls: urls,
    ));
    expect(out.first, SuggestionKind.screenTimeWarning);
  });

  test('dùng máy đúng 4 tiếng: chưa cảnh báo', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 15), screenTime: screen(240)));
    expect(out, isNot(contains(SuggestionKind.screenTimeWarning)));
  });

  test('ngủ thiếu và sau 22h: gợi ý đi ngủ', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 23), sleep: sleep(6)));
    expect(out, contains(SuggestionKind.sleep));
  });

  test('ngủ thiếu nhưng còn ban ngày: không gợi ý đi ngủ', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 15), sleep: sleep(6)));
    expect(out, isNot(contains(SuggestionKind.sleep)));
  });

  test('ngủ đủ giấc sau 22h: không gợi ý đi ngủ', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 23), sleep: sleep(8)));
    expect(out, isNot(contains(SuggestionKind.sleep)));
  });

  test('tức giận liên tiếp: gợi ý thiền', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.angry, Mood.angry],
    ));
    expect(out, contains(SuggestionKind.meditation));
  });

  test('vui liên tiếp: playlist vui kèm link', () {
    final list = SuggestionEngine.build(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.happy, Mood.happy],
      playlistUrls: urls,
    ));
    final s = list.firstWhere((e) => e.kind == SuggestionKind.happyMusic);
    expect(s.url, 'https://happy');
  });

  test('buồn liên tiếp: playlist nhẹ nhàng', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.cry],
      playlistUrls: urls,
    ));
    expect(out, contains(SuggestionKind.sadMusic));
  });

  test('tâm trạng lẫn lộn hoặc bình thường: không gợi ý theo tâm trạng', () {
    final mixed = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.happy, Mood.angry],
    ));
    final neutral = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.neutral, Mood.neutral],
    ));
    for (final out in [mixed, neutral]) {
      expect(out, isNot(contains(SuggestionKind.meditation)));
      expect(out, isNot(contains(SuggestionKind.happyMusic)));
      expect(out, isNot(contains(SuggestionKind.sadMusic)));
    }
  });

  test('chưa đủ bước và đã muộn: gợi ý đi bộ', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 19), steps: steps(2000)));
    expect(out, contains(SuggestionKind.run));
  });

  test('buổi sáng sớm thì chưa nhắc đi bộ', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 8), steps: steps(0)));
    expect(out, isNot(contains(SuggestionKind.run)));
  });

  test('đạt mục tiêu bước: không nhắc', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 20), steps: steps(10000)));
    expect(out, isNot(contains(SuggestionKind.run)));
  });

  test('tối đa 4 thẻ và bài hát chỉ lấp chỗ trống', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 23),
      screenTime: screen(300),
      sleep: sleep(5),
      steps: steps(1000),
      recentMoods: const [Mood.angry],
      songOfTheDay: song,
    ));
    expect(out.length, 4);
    expect(out, isNot(contains(SuggestionKind.songOfTheDay)));
  });

  test('không có luật nào: chỉ hiện bài hát trong ngày', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 12), songOfTheDay: song));
    expect(out, [SuggestionKind.songOfTheDay]);
  });

  test('thẻ đã ẩn bị bỏ và thẻ khác lấp chỗ', () {
    final out = kinds(
      SuggestionInput(
        now: DateTime(2026, 11, 5, 15),
        screenTime: screen(300),
        songOfTheDay: song,
      ),
      dismissed: {'screenTimeWarning'},
    );
    expect(out, [SuggestionKind.songOfTheDay]);
  });
}
