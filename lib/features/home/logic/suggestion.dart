import '../../../data/models/music_playlist.dart';

enum SuggestionKind {
  screenTimeWarning,
  sleep,
  meditation,
  run,
  music, // luôn có, luôn đứng cuối
}

/// Việc xảy ra khi người dùng bấm vào thẻ.
enum SuggestionAction {
  showMessage,     // chỉ hiện lời nhắn
  openSleep,       // màn Chế độ ngủ (làm ở bước sau)
  openMeditation,  // màn Thiền (làm ở bước sau)
  openPhysicalTab, // chuyển sang tab Thể chất
  openUrl,         // mở link bằng app ngoài (Spotify)
}

class Suggestion {
  final SuggestionKind kind;
  final String title;
  final String subtitle;
  final String cta; // chữ trên nửa vé xanh đen
  final SuggestionAction action;
  final String? url;
  final String? message;
  final MusicPlaylist? playlist; // chỉ có ở thẻ nhạc

  const Suggestion({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.action,
    this.url,
    this.message,
    this.playlist,
  });

  /// Mỗi loại thẻ chỉ xuất hiện một lần trong ngày -> dùng làm id để "ẩn hôm nay".
  String get id => kind.name;

  bool get isWarning => kind == SuggestionKind.screenTimeWarning;
  bool get isMusic => kind == SuggestionKind.music;
}
