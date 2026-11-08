import '../../core/utils/date_utils.dart';
import '../../screens/mental/mental_data.dart' show Mood;
import '../models/song.dart';

class MusicRepository {
  /// Playlist theo tâm trạng. TẠM dùng link tìm kiếm của Spotify (mở được ngay);
  /// thay bằng link playlist thật (dạng https://open.spotify.com/playlist/...).
  static const Map<Mood, String> playlistUrls = {
    Mood.happy: 'https://open.spotify.com/search/happy%20vibes',
    Mood.cry: 'https://open.spotify.com/search/sad%20songs',
  };

  // Tạm thời cả 3 bài dùng chung một ảnh và một link nhạc.
  // Thay 'aaaa' / 'bbbb' bằng link thật (bắt đầu bằng https://).
  static const List<Song> _playlist = [
    Song(title: 'Vu Tru Co Bay', artist: 'Phuong My Chi', coverUrl: 'aaaa', musicUrl: 'bbbb'),
    Song(title: 'Bai hat 2', artist: 'Nghe si 2', coverUrl: 'aaaa', musicUrl: 'bbbb'),
    Song(title: 'Bai hat 3', artist: 'Nghe si 3', coverUrl: 'aaaa', musicUrl: 'bbbb'),
  ];

  /// Mỗi ngày một bài, xoay vòng theo playlist.
  Future<Song> getSongOfTheDay() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = AppDateUtils.dayOfYear(DateTime.now()) % _playlist.length;
    return _playlist[index];
  }

  Future<List<Song>> getPlaylist() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _playlist;
  }
}
