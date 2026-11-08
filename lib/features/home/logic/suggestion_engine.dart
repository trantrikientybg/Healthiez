import '../../../core/constants/app_constants.dart';
import '../../../data/models/screen_time_record.dart';
import '../../../data/models/sleep_record.dart';
import '../../../data/models/song.dart';
import '../../../data/models/step_record.dart';
import '../../../screens/mental/mental_data.dart' show Mood;
import 'suggestion.dart';

/// Dữ liệu đầu vào của bộ luật. Các trường null nghĩa là chưa có dữ liệu.
class SuggestionInput {
  final DateTime now;
  final StepRecord? steps;
  final SleepRecord? sleep;
  final ScreenTimeRecord? screenTime;

  /// Tâm trạng đã ghi nhận trong những ngày gần nhất (cũ -> mới).
  final List<Mood> recentMoods;
  final Song? songOfTheDay;
  final Map<Mood, String> playlistUrls;

  const SuggestionInput({
    required this.now,
    this.steps,
    this.sleep,
    this.screenTime,
    this.recentMoods = const [],
    this.songOfTheDay,
    this.playlistUrls = const {},
  });
}

/// Bộ luật gợi ý: hàm thuần túy (không đọc DB, không dùng giờ hệ thống),
/// nên dễ kiểm thử và chỉnh ngưỡng trong AppConstants.
///
/// Thứ tự ưu tiên: cảnh báo dùng máy > đi ngủ > tâm trạng > đi bộ > bài hát trong ngày.
class SuggestionEngine {
  SuggestionEngine._();

  static List<Suggestion> build(
    SuggestionInput input, {
    Set<String> dismissed = const {},
  }) {
    final rules = <Suggestion?>[
      _screenTime(input),
      _sleep(input),
      _mood(input),
      _steps(input),
    ];

    // Bỏ thẻ đã ẩn trước khi cắt số lượng, để thẻ khác lấp chỗ.
    final cards = <Suggestion>[
      for (final s in rules)
        if (s != null && !dismissed.contains(s.id)) s,
    ];

    // Bài hát trong ngày chỉ lấp chỗ trống còn lại.
    final song = input.songOfTheDay;
    if (cards.length < AppConstants.maxSuggestions && song != null) {
      final card = Suggestion(
        kind: SuggestionKind.songOfTheDay,
        title: song.title,
        subtitle: song.artist,
        cta: 'Nghe bài hát',
        action: SuggestionAction.openUrl,
        url: song.musicUrl,
        song: song,
      );
      if (!dismissed.contains(card.id)) cards.add(card);
    }

    return cards.take(AppConstants.maxSuggestions).toList();
  }

  // ---------------- Từng luật ----------------

  static Suggestion? _screenTime(SuggestionInput i) {
    final s = i.screenTime;
    if (s == null || s.minutes <= AppConstants.screenTimeWarningMinutes) {
      return null;
    }
    return Suggestion(
      kind: SuggestionKind.screenTimeWarning,
      title: 'Bạn đã dùng điện thoại ${s.totalLabel} hôm nay',
      subtitle: 'Nghỉ mắt một chút nhé',
      cta: 'Nghỉ mắt 20 giây',
      action: SuggestionAction.showMessage,
      message: 'Nhìn ra xa khoảng 20 giây và chớp mắt vài lần nhé.',
    );
  }

  static Suggestion? _sleep(SuggestionInput i) {
    final s = i.sleep;
    if (s == null || s.hours >= AppConstants.sleepEnoughHours) return null;
    final h = i.now.hour;
    final inWindow = h >= AppConstants.sleepSuggestFromHour ||
        h < AppConstants.sleepSuggestUntilHour;
    if (!inWindow) return null;
    return Suggestion(
      kind: SuggestionKind.sleep,
      title: 'Tối nay đi ngủ sớm nhé',
      subtitle: 'Đêm qua bạn mới ngủ ${s.hours.toStringAsFixed(1)} giờ',
      cta: 'Bắt đầu đi ngủ',
      action: SuggestionAction.openSleep,
    );
  }

  /// Tâm trạng xu hướng: tất cả ngày đã ghi nhận gần đây giống nhau.
  static Mood? moodTrend(List<Mood> recent) {
    if (recent.length < AppConstants.moodTrendMinEntries || recent.isEmpty) {
      return null;
    }
    final first = recent.first;
    return recent.every((m) => m == first) ? first : null;
  }

  static Suggestion? _mood(SuggestionInput i) {
    final trend = moodTrend(i.recentMoods);
    switch (trend) {
      case Mood.angry:
        return const Suggestion(
          kind: SuggestionKind.meditation,
          title: 'Thiền vài phút nhé',
          subtitle: 'Mấy hôm nay bạn có vẻ hơi bực bội. Thử hít thở sâu xem sao',
          cta: 'Mở đồng hồ thiền',
          action: SuggestionAction.openMeditation,
        );
      case Mood.happy:
        return Suggestion(
          kind: SuggestionKind.happyMusic,
          title: 'Nghe nhạc vui cho thêm năng lượng',
          subtitle: 'Mấy hôm nay bạn đang rất vui',
          cta: 'Mở playlist',
          action: SuggestionAction.openUrl,
          url: i.playlistUrls[Mood.happy],
        );
      case Mood.cry:
        return Suggestion(
          kind: SuggestionKind.sadMusic,
          title: 'Một chút nhạc cho dịu lòng',
          subtitle: 'Mấy hôm nay bạn có vẻ hơi buồn',
          cta: 'Mở playlist',
          action: SuggestionAction.openUrl,
          url: i.playlistUrls[Mood.cry],
        );
      default:
        return null;
    }
  }

  /// Tiến độ bước chân "nên có" theo giờ trong ngày (0.0 - 1.0).
  static double expectedStepFraction(DateTime now) {
    const start = AppConstants.stepsDayStartHour;
    const end = AppConstants.stepsDayEndHour;
    final hour = now.hour + now.minute / 60;
    return ((hour - start) / (end - start)).clamp(0.0, 1.0);
  }

  static Suggestion? _steps(SuggestionInput i) {
    final s = i.steps;
    if (s == null || s.steps >= s.goal) return null;
    if (i.now.hour < AppConstants.stepsSuggestFromHour) return null;
    // Chỉ nhắc khi đang chậm hơn tiến độ mong đợi của giờ này
    if (s.steps >= s.goal * expectedStepFraction(i.now)) return null;
    return Suggestion(
      kind: SuggestionKind.run,
      title: 'Đi bộ hoặc chạy bộ nào',
      subtitle: 'Bạn còn thiếu ${s.goal - s.steps} bước so với mục tiêu',
      cta: 'Mở tab Thể chất',
      action: SuggestionAction.openPhysicalTab,
    );
  }
}
