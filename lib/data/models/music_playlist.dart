/// 3 nhóm nhạc của Home.
enum MusicGroup {
  energetic, // nhạc vui, sôi động
  trending,  // nhạc thịnh hành
  gentle,    // nhạc nhẹ nhàng
}

class MusicPlaylist {
  final MusicGroup group;
  final String name;
  final String musicUrl; // link playlist Spotify
  final String imageUrl; // link ảnh bìa

  const MusicPlaylist({
    required this.group,
    required this.name,
    required this.musicUrl,
    required this.imageUrl,
  });
}
