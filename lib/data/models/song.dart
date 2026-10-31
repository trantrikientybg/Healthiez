class Song {
  final String title;
  final String artist;
  final String coverUrl; // link ảnh bìa (mạng)
  final String musicUrl;

  const Song({
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.musicUrl,
  });
}