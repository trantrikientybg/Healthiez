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
  //final String coverUrl; // hình ảnh bài hát;
  final Mood mood2;
  final String id;
  //final String url;
  const Song(this.title, this.content, this.mood, this.mood2, this.id);
  String get url => 'https://open.spotify.com/playlist/$id';
}

const songs = [
  Song('Cozy Coffee Shop', 'Nhạc Jazz cho 1 ngày phấn khởi', Mood.happy, Mood.neutral, '5vVSfOsF8YRueAI1dOI0Lh'),
  Song('Classical Piano', 'Giúp thư giãn trí óc', Mood.tired, Mood.angry, '37i9dQZF1DWUqIzZNMSCv3'),
  Song('Ambient Relaxation', 'Âm thanh của bình yên', Mood.angry, Mood.neutral, '37i9dQZF1DX3Ogo9pFvBkY'),
  Song('Ocean Ambient', 'Giấc ngủ hòa cùng tiếng đại dương', Mood.neutral, Mood.tired, '3bOWrzil9JfMtd2nqiEUx2'),
  Song('Japanese Zen Garden', 'Nhạc chữa lành phong cách Nhật', Mood.cry, Mood.happy, '0XvBIoFUDrKfoPmnhz1fS4'),
  Song('Sleep', 'Nhạc đi ngủ zzzz', Mood.tired, Mood.neutral, '37i9dQZF1DWZd79rJ6a7lp'),
  Song('Bossa Nova Music', 'Nhạc Bossa Nova vui tươi nhẹ nhàng', Mood.happy, Mood.neutral, '37i9dQZF1DWWgccrbg3zbJ'),
  Song('Deep Sleep', 'Nhạc đi ngủ nhưng sâuuu', Mood.tired, Mood.cry, '37i9dQZF1DWYcDQ1hSjOpY'),
  Song('Todays Top Híts' , 'Khởi đầu ngày mới năng lượng tích cực', Mood.happy, Mood.angry, '37i9dQZF1DXcBWIGoYBM5M'),
  Song('Peaceful Piano', 'Không gian piano bay bổng', Mood.cry, Mood.neutral, '37i9dQZF1DX4sWSpwq3LiO'),
  Song('Amazing Dance Music', 'Nhạc quẩy sôi động ^-^ ', Mood.happy, Mood.happy, '1fve3LRzJzIbtKgIYoDrqA'),

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

