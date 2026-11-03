/// Bài nhạc gợi ý của Home.
/// (Màn Tinh thần có class Song riêng trong mental_screen.dart; khi cần
/// dùng chung thì import với prefix `as`.)
class Song {
  final String title;
  final String artist;
  final String coverUrl; // link ảnh bìa
  final String musicUrl; // link bài nhạc, mở bằng browser khi nhấn vào ảnh

  const Song({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.musicUrl,
  });
}

