import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/data/models/music_playlist.dart';
import 'package:healthiez/data/models/screen_time_record.dart';
import 'package:healthiez/data/models/sleep_record.dart';
import 'package:healthiez/data/models/step_record.dart';
import 'package:healthiez/features/home/logic/suggestion.dart';
import 'package:healthiez/features/home/logic/suggestion_engine.dart';
import 'package:healthiez/screens/mental/mental_data.dart' show Mood;

void main() {
  final day = DateTime(2026, 11, 5);

  StepRecord steps(int n) =>
      StepRecord(date: day, steps: n, goal: 10000, weeklyTotal: n);

  SleepRecord sleep(int hours) => SleepRecord(
        date: DateTime(2026, 11, 4), // ngày ngủ trước ngày ngủ của now (5/11)
        bedTime: DateTime(2026, 11, 5, 0),
        wakeTime: DateTime(2026, 11, 5, hours),
        goalHours: 8,
      );

  ScreenTimeRecord screen(int minutes) =>
      ScreenTimeRecord(date: day, minutes: minutes, limitMinutes: 240);

  List<Suggestion> run(SuggestionInput i, {Set<String> dismissed = const {}}) =>
      SuggestionEngine.build(i, dismissed: dismissed);

  List<SuggestionKind> kinds(SuggestionInput i, {Set<String> dismissed = const {}}) =>
      run(i, dismissed: dismissed).map((s) => s.kind).toList();

  Suggestion music(SuggestionInput i) =>
      run(i).firstWhere((s) => s.kind == SuggestionKind.music);

  test('không có luật nào: chỉ còn thẻ nhạc', () {
    expect(kinds(SuggestionInput(now: DateTime(2026, 11, 5, 12))),
        [SuggestionKind.music]);
  });

  test('dùng máy trên 4 tiếng: cảnh báo đứng đầu, nhạc đứng cuối', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 15),
      screenTime: screen(260),
    ));
    expect(out.first, SuggestionKind.screenTimeWarning);
    expect(out.last, SuggestionKind.music);
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

  test('ngủ đủ giấc đêm trước: đến khuya vẫn hiện thẻ để người dùng đo giấc ngủ', () {
    final list = run(SuggestionInput(now: DateTime(2026, 11, 5, 23), sleep: sleep(8)));
    final s = list.firstWhere((e) => e.kind == SuggestionKind.sleep);
    expect(s.title, 'Sắp đến giờ đi ngủ rồi');
    expect(s.action, SuggestionAction.openSleep);
  });

  test('tối nay đã ngủ rồi (1h30 sáng, đã lưu giấc ngủ): không hiện nữa', () {
    final slept = SleepRecord(
      date: DateTime(2026, 11, 5), // cùng ngày ngủ với 1h30 sáng 6/11
      bedTime: DateTime(2026, 11, 5, 23),
      wakeTime: DateTime(2026, 11, 6, 1, 30),
      goalHours: 8,
      asleep: const Duration(hours: 2, minutes: 30),
    );
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 6, 1, 30), sleep: slept));
    expect(out, isNot(contains(SuggestionKind.sleep)));
  });

  test('chưa có dữ liệu giấc ngủ nhưng đã khuya: vẫn gợi ý đi ngủ (để bắt đầu dùng)', () {
    final list = run(SuggestionInput(now: DateTime(2026, 11, 5, 23), sleepLoaded: true));
    final s = list.firstWhere((e) => e.kind == SuggestionKind.sleep);
    expect(s.subtitle, contains('Chưa có dữ liệu'));
  });

  test('đang tải dữ liệu giấc ngủ: chưa gợi ý, tránh nhấp nháy', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 23), sleepLoaded: false));
    expect(out, isNot(contains(SuggestionKind.sleep)));
  });

  test('chưa có dữ liệu nhưng ban ngày: không gợi ý đi ngủ', () {
    final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 14)));
    expect(out, isNot(contains(SuggestionKind.sleep)));
  });

  test('tức giận liên tiếp: gợi ý thiền', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.angry, Mood.angry],
    ));
    expect(out, contains(SuggestionKind.meditation));
  });

  test('tâm trạng lẫn lộn hoặc không tức giận: không gợi ý thiền', () {
    for (final moods in [
      const [Mood.happy, Mood.angry],
      const [Mood.cry, Mood.cry],
      const [Mood.neutral],
    ]) {
      final out = kinds(SuggestionInput(now: DateTime(2026, 11, 5, 12), recentMoods: moods));
      expect(out, isNot(contains(SuggestionKind.meditation)));
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

  test('nhóm nhạc theo tâm trạng mới nhất', () {
    MusicGroup groupOf(List<Mood> moods) => music(
          SuggestionInput(now: DateTime(2026, 11, 5, 12), recentMoods: moods),
        ).playlist!.group;

    expect(groupOf(const [Mood.happy]), MusicGroup.energetic);
    expect(groupOf(const [Mood.neutral]), MusicGroup.trending);
    expect(groupOf(const []), MusicGroup.trending); // chưa chọn tâm trạng
    expect(groupOf(const [Mood.angry]), MusicGroup.gentle);
    expect(groupOf(const [Mood.cry]), MusicGroup.gentle);
    expect(groupOf(const [Mood.tired]), MusicGroup.gentle);
    // Hôm qua vui, hôm nay buồn -> theo hôm nay
    expect(groupOf(const [Mood.happy, Mood.cry]), MusicGroup.gentle);
  });

  test('thẻ nhạc kèm link playlist của nhóm', () {
    final s = music(SuggestionInput(
      now: DateTime(2026, 11, 5, 12),
      recentMoods: const [Mood.happy],
    ));
    expect(s.action, SuggestionAction.openUrl);
    expect(s.url, s.playlist!.musicUrl);
  });

  test('tối đa 4 thẻ: 3 thẻ luật + thẻ nhạc luôn ở cuối', () {
    final out = kinds(SuggestionInput(
      now: DateTime(2026, 11, 5, 23),
      screenTime: screen(300),
      sleep: sleep(5),
      steps: steps(1000),
      recentMoods: const [Mood.angry],
    ));
    // 4 luật cùng thỏa nhưng chỉ lấy 3 luật ưu tiên cao nhất
    expect(out, [
      SuggestionKind.screenTimeWarning,
      SuggestionKind.sleep,
      SuggestionKind.meditation,
      SuggestionKind.music,
    ]);
  });

  test('thẻ đã ẩn bị bỏ và thẻ ưu tiên thấp hơn lấp chỗ', () {
    final out = kinds(
      SuggestionInput(
        now: DateTime(2026, 11, 5, 23),
        screenTime: screen(300),
        sleep: sleep(5),
        steps: steps(1000),
        recentMoods: const [Mood.angry],
      ),
      dismissed: {'screenTimeWarning'},
    );
    expect(out, [
      SuggestionKind.sleep,
      SuggestionKind.meditation,
      SuggestionKind.run,
      SuggestionKind.music,
    ]);
  });

  test('thẻ nhạc không thể bị ẩn', () {
    final out = kinds(
      SuggestionInput(now: DateTime(2026, 11, 5, 12)),
      dismissed: {'music'},
    );
    expect(out, [SuggestionKind.music]);
  });
}
