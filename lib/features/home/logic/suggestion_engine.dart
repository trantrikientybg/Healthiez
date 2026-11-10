import '../../../core/constants/app_constants.dart';
import '../../../data/models/music_playlist.dart';
import '../../../data/models/screen_time_record.dart';
import '../../../data/models/sleep_record.dart';
import '../../../data/models/step_record.dart';
import '../../../data/sleep/sleep_models.dart' show SleepDay;
import '../../../data/repositories/music_repository.dart';
import '../../../screens/mental/mental_data.dart' show Mood;
import 'suggestion.dart';

/// Dữ liệu đầu vào của bộ luật. Các trường null nghĩa là chưa có dữ liệu.
class SuggestionInput {
  final DateTime now;
  final StepRecord? steps;
  final SleepRecord? sleep;

  /// Đã đọc xong dữ liệu giấc ngủ chưa. Đọc xong mà sleep == null nghĩa là
  /// chưa có dữ liệu (chưa từng dùng chế độ ngủ).
  final bool sleepLoaded;
  final ScreenTimeRecord? screenTime;

  /// Tâm trạng đã ghi nhận trong những ngày gần nhất (cũ -> mới).
  /// Phần tử cuối là tâm trạng mới nhất, dùng để chọn nhóm nhạc.
  final List<Mood> recentMoods;

  const SuggestionInput({
    required this.now,
    this.steps,
    this.sleep,
    this.sleepLoaded = true,
    this.screenTime,
    this.recentMoods = const [],
  });
}

/// Bộ luật gợi ý: hàm thuần túy (không đọc DB, không dùng giờ hệ thống),
/// nên dễ kiểm thử và chỉnh ngưỡng trong AppConstants.
///
/// Các thẻ luật (tối đa maxSuggestions - 1), theo thứ tự ưu tiên:
///   cảnh báo dùng máy > đi ngủ > thiền (tức giận) > đi bộ.
/// Thẻ nhạc luôn có và luôn đứng cuối.
class SuggestionEngine {
  SuggestionEngine._();

  static List<Suggestion> build(
    SuggestionInput input, {
    Set<String> dismissed = const {},
  }) {
    final rules = <Suggestion?>[
      _screenTime(input),
      _sleep(input),
      _meditation(input),
      _steps(input),
    ];

    // Bỏ thẻ đã ẩn trước khi cắt số lượng, để thẻ khác lấp chỗ.
    final cards = <Suggestion>[
      for (final s in rules)
        if (s != null && !dismissed.contains(s.id)) s,
    ].take(AppConstants.maxSuggestions - 1).toList();

    cards.add(_music(input));
    return cards;
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

  /// Thẻ đi ngủ: LUÔN hiện trong khung giờ đi ngủ (để người dùng luôn có lối vào
  /// chế độ ngủ và đo được giấc ngủ), chỉ đổi lời nhắn theo giấc ngủ đêm trước.
  /// Không hiện nếu tối nay đã ngủ rồi.
  static Suggestion? _sleep(SuggestionInput i) {
    if (!i.sleepLoaded) return null; // đang tải thì chưa gợi ý
    final h = i.now.hour;
    final inWindow = h >= AppConstants.sleepSuggestFromHour ||
        h < AppConstants.sleepSuggestUntilHour;
    if (!inWindow) return null;

    final s = i.sleep;
    // Giấc ngủ gần nhất thuộc chính "ngày ngủ" hiện tại = tối nay đã ngủ rồi
    if (s != null && SleepDay.of(s.date) == SleepDay.of(i.now)) return null;

    if (s != null && s.hours >= AppConstants.sleepEnoughHours) {
      return Suggestion(
        kind: SuggestionKind.sleep,
        title: 'Sắp đến giờ đi ngủ rồi',
        subtitle: 'Đêm qua bạn ngủ ${s.hours.toStringAsFixed(1)} giờ, rất tốt. '
            'Bắt đầu đo giấc ngủ nhé',
        cta: 'Bắt đầu đi ngủ',
        action: SuggestionAction.openSleep,
      );
    }
    return Suggestion(
      kind: SuggestionKind.sleep,
      title: 'Tối nay đi ngủ sớm nhé',
      subtitle: s == null
          ? 'Chưa có dữ liệu giấc ngủ đêm qua'
          : 'Đêm qua bạn mới ngủ ${s.hours.toStringAsFixed(1)} giờ',
      cta: 'Bắt đầu đi ngủ',
      action: SuggestionAction.openSleep,
    );
  }

  /// Tâm trạng xu hướng: tất cả ngày đã ghi nhận gần đây giống nhau.
  static Mood? moodTrend(List<Mood> recent) {
    if (recent.isEmpty || recent.length < AppConstants.moodTrendMinEntries) {
      return null;
    }
    final first = recent.first;
    return recent.every((m) => m == first) ? first : null;
  }

  static Suggestion? _meditation(SuggestionInput i) {
    if (moodTrend(i.recentMoods) != Mood.angry) return null;
    return const Suggestion(
      kind: SuggestionKind.meditation,
      title: 'Thiền vài phút nhé',
      subtitle: 'Mấy hôm nay bạn có vẻ hơi bực bội. Thử hít thở sâu xem sao',
      cta: 'Mở đồng hồ thiền',
      action: SuggestionAction.openMeditation,
    );
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

  /// Thẻ nhạc: nhóm nhạc theo tâm trạng mới nhất (không có thì nhạc thịnh hành).
  static Suggestion _music(SuggestionInput i) {
    final mood = i.recentMoods.isEmpty ? null : i.recentMoods.last;
    final playlist = MusicRepository.playlistForMood(mood);
    final reason = switch (playlist.group) {
      MusicGroup.energetic => 'Hợp với tâm trạng vui của bạn',
      MusicGroup.gentle => 'Nhạc nhẹ nhàng để lòng dịu lại',
      MusicGroup.trending => 'Playlist thịnh hành, tự cập nhật mỗi ngày',
    };
    return Suggestion(
      kind: SuggestionKind.music,
      title: playlist.name,
      subtitle: reason,
      cta: 'Nghe ngay',
      action: SuggestionAction.openUrl,
      url: playlist.musicUrl,
      playlist: playlist,
    );
  }
}
