//import 'dart:math' as math;
//import 'mental_screen.dart';
import 'package:flutter/services.dart';

enum Overview { positive, neutral, negative }
enum Mood {
  happy(
    label: 'Hạnh phúc',
    asset: 'assets/images/Mood/mood_happy.png',
    color: Color(0xFF4C8DFF),
  ),
  neutral(
    label: 'Trung lập',
    asset: 'assets/images/Mood/mood_neutral.png',
    color: Color(0xFFFFC94A),
  ),
  angry(
    label: 'Tức giận',
    asset: 'assets/images/Mood/mood_angry.png',
    color: Color(0xFFFF7A5C),
  ),
  tired(
    label: 'Mệt mỏi',
    asset: 'assets/images/Mood/mood_tired.png',
    color: Color(0xFF7B6CF6),
  ),
  cry(
    label: 'Buồn',
    asset: 'assets/images/Mood/mood_cry.png',
    color: Color(0xFF5CC8B5),
  );

  final String label;
  final String asset;
  final Color color;

  const Mood({
    required this.label,
    required this.asset,
    required this.color,
  });
}

extension OverviewX on Overview {
  String get label => const {
    Overview.positive : 'Tích cực',
    Overview.neutral : 'Trung lập',
    Overview.negative : 'Tiêu cực',
  }[this]!;

  String get asset => const {
    Overview.positive: 'assets/images/Overview/overview_neutral.png',
    Overview.neutral: 'assets/images/Overview/overview_positive.png',
    Overview.negative: 'assets/images/Overview/overview_negative.png',
  }[this]!;

}

class Song {
  final String title, content;
  final Mood mood; // bài này hợp với tâm trạng nào
  // final Image cover; // hình ảnh bài hát;
  final Mood mood2;
  final String url;
  const Song(this.title, this.content, this.mood, this.mood2, this.url);
}

const songs = [
  // Cozy Coffee Shop - Nhạc Jazz cho 1 ngày phấn khởi - https://open.spotify.com/playlist/5vVSfOsF8YRueAI1dOI0Lh
  // Joe Hisaishi in Vienna - Âm hưởng kích thích cảm xúc  - https://open.spotify.com/album/2GUUSp5HD5OhINznTpd4TM
  // Classical Piano - Giúp thư giãn trí óc - https://open.spotify.com/album/4vw6B9Myvro7uWjCOmOsBF
  // Relaxing Ambient Sound - Âm thanh của bình yên - https://open.spotify.com/album/0TChik1N7gF9qxTjCSj7TF

  Song('Vũ Trụ Có Anh', 'Sáng tác bởi Phương Mỹ Chi', Mood.happy, Mood.neutral, 'Url Link'),
  Song('Vũ Trụ Có Anh', 'Sáng tác bởi Phương Mỹ Chi', Mood.happy, Mood.neutral, 'Url Link'),
  Song('Vũ Trụ Có Anh', 'Sáng tác bởi Phương Mỹ Chi', Mood.happy, Mood.neutral, 'Url Link'),
  Song('Vũ Trụ Có Anh', 'Sáng tác bởi Phương Mỹ Chi', Mood.happy, Mood.neutral, 'Url Link'),
  Song('Vũ Trụ Có Anh', 'Sáng tác bởi Phương Mỹ Chi', Mood.happy, Mood.neutral, 'Url Link'),

];

class MoodOverview {
  final String status; // ví dụ: 'Tích cực'
  final String message; // đoạn mô tả
  final Color color; // màu chữ của status

  const MoodOverview({
    required this.status,
    required this.message,
    required this.color,
  });
}

const positiveOverview = MoodOverview(
  status: 'Tích cực',
  message:
  'Tâm trạng của bạn có vẻ đang tốt lên mỗi ngày, hãy giữ làm động lực cho một cuộc sống khỏe mạnh hơn',
  color: Color(0xFF2E9E8F),
);

const neutralOverview = MoodOverview(
  status: 'Trung lập',
  message:
  'Tâm trạng của bạn có vẻ đang tốt lên mỗi ngày, hãy giữ làm động lực cho một cuộc sống khỏe mạnh hơn',
  color: Color(0xFF2FC25D),
);