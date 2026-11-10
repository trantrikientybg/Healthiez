import '../../screens/mental/mental_data.dart' show Mood;
import '../models/music_playlist.dart';

class MusicRepository {
  MusicRepository._();

  /// Nhóm 1: nhạc vui, sôi động  (tâm trạng: happy)
  static const MusicPlaylist energetic = MusicPlaylist(
    group: MusicGroup.energetic,
    name: 'Nhạc vui, sôi động',
    musicUrl: 'https://open.spotify.com/playlist/1eZFGOIjduu8V83qRs5jK2',
    imageUrl: 'https://image-cdn-ak.spotifycdn.com/image/ab67706c000097ace3af6359044e463e994bb3d8',
  );

  /// Nhóm 2: nhạc thịnh hành  (tâm trạng: neutral, hoặc chưa chọn)
  static const MusicPlaylist trending = MusicPlaylist(
    group: MusicGroup.trending,
    name: 'Nhạc thịnh hành',
    musicUrl: 'https://open.spotify.com/playlist/37i9dQZF1DWVOaOWiVD1Lf',
    imageUrl: 'https://i.scdn.co/image/ab67706f00000002f91483ce78b40207d68e725b',
  );

  /// Nhóm 3: nhạc nhẹ nhàng  (tâm trạng: angry, cry, tired)
  static const MusicPlaylist gentle = MusicPlaylist(
    group: MusicGroup.gentle,
    name: 'Nhạc nhẹ nhàng',
    musicUrl: 'https://open.spotify.com/playlist/37i9dQZF1EVHGWrwldPRtj',
    imageUrl: 'https://is1-ssl.mzstatic.com/image/thumb/AMCArtistImages211/v4/ef/05/78/ef057825-793f-90b2-ed1b-079ee035c600/ami_U003aidentity_U003ac2e957ae924d4e26ec325897fe0e8c4b-2026-10-08T19-47-40.924Z_cropped.png/800x800vb.webp',
  );

  /// Chọn playlist theo tâm trạng. Chưa có tâm trạng (null) -> thịnh hành.
  static MusicPlaylist playlistForMood(Mood? mood) {
    switch (mood) {
      case Mood.happy:
        return energetic;
      case Mood.angry:
      case Mood.cry:
      case Mood.tired:
        return gentle;
      case Mood.neutral:
      case null:
        return trending;
    }
  }
}
