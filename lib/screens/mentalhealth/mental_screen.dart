import 'dart:math' as math;
import 'package:flutter/material.dart';

// ============ 1. MODEL ============
enum Mood { veryHappy, neutral, angry, sad, cry }
enum Overview { positive, neutral, negative }
extension MoodX on Mood {
  String get label => const {
    Mood.veryHappy: 'Hạnh phúc',
    Mood.neutral: 'Trung lập',
    Mood.angry: 'Tức giận',
    Mood.sad: 'Mệt mỏi',
    Mood.cry: 'Buồn',
  }[this]!;

  String get asset => const {
    Mood.veryHappy: 'assets/images/Mood/mood_very_happy.png',
    Mood.neutral: 'assets/images/Mood/mood_neutral.png',
    Mood.angry: 'assets/images/Mood/mood_angry.png',
    Mood.sad: 'assets/images/Mood/mood_sad.png',
    Mood.cry: 'assets/images/Mood/mood_cry.png',
  }[this]!;

  Color get color => const {
    Mood.veryHappy: Color(0xFF4C8DFF),
    Mood.neutral: Color(0xFFFFC94A),
    Mood.angry: Color(0xFFFF7A5C),
    Mood.sad: Color(0xFF7B6CF6),
    Mood.cry: Color(0xFF5CC8B5),
  }[this]!;
}

extension OverviewX on Overview {
  String get label => const {
    Overview.positive : 'Tích cực',
    Overview.neutral : 'Trung lập',
    Overview.negative : 'Tiêu cực',
  }[this]!;

  String get asset => const {
    Overview.positive: 'assets/images/Overview/overview_positive.png',
    Overview.neutral: 'assets/images/Overview/overview_neutral.png',
    Overview.negative: 'assets/images/Overview/overview_negative.png',
  }[this]!;

}

class Song {
  final String title, artist;
  final Mood mood; // bài này hợp với tâm trạng nào
  // final Image cover; // hình ảnh bài hát;
  const Song(this.title, this.artist, this.mood);
}

const songs = [
  Song('Vũ Trụ Có Anh', 'Phương Mỹ Chi', Mood.veryHappy),
  Song('Nhạc không lời - Tiếng mưa rơi', 'Relax', Mood.sad),
  Song('Piano thư giãn', 'Relax', Mood.cry),
  Song('Thiền hít thở', 'Relax', Mood.angry),
  Song('Lofi nhẹ nhàng', 'Relax', Mood.neutral),
];

// ============ 2. THUẬT TOÁN ĐIỂM ============
// Điểm = Tần suất 3-4 tuần gần đây x 1 + Streak lớn nhất x 1.5 + 5 (nếu hôm nay là tâm trạng đó)
Map<Mood, double> moodScores(Map<DateTime, Mood> logs, DateTime today) {
  DateTime d(DateTime x) => DateTime(x.year, x.month, x.day);
  final t = d(today);
  final scores = {for (final m in Mood.values) m: 0.0};

  for (final m in Mood.values) {
    int freq = 0, streak = 0, best = 0;
    for (int i = 27; i >= 0; i--) {
      // 28 ngày, từ cũ -> mới
      final day = t.subtract(Duration(days: i));
      if (logs[day] == m) {
        freq++;
        streak++;
        best = math.max(best, streak);
      } else {
        streak = 0;
      }
    }
    final todayBonus = logs[t] == m ? 5 : 0;
    scores[m] = freq * 1 + best * 1.5 + todayBonus;
  }
  return scores;
}
// Điểm tổng quan : Overview Score = Hạnh phúc * 3 + Trung lập * 1 - Buồn * 2 - Mệt mỏi * 1 - Tức giận * 3


// ============ 3. MÀN HÌNH ============
class MentalScreen extends StatefulWidget {
  const MentalScreen({super.key});
  @override
  State<MentalScreen> createState() => _MentalScreenState();
}

class _MentalScreenState extends State<MentalScreen> {
  // Dữ liệu mẫu 7 ngày (sau này lấy từ Supabase)
  final Map<DateTime, Mood> logs = {};
  Mood? today;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final base = DateTime(now.year, now.month, now.day);
    const sample = [
      Mood.veryHappy, Mood.veryHappy, Mood.neutral, Mood.sad,
      Mood.veryHappy, Mood.neutral, Mood.veryHappy,
    ];
    for (int i = 0; i < sample.length; i++) {
      logs[base.subtract(Duration(days: sample.length - 1 - i))] = sample[i];
    }
  }

  void _pick(Mood m) {
    final n = DateTime.now();
    setState(() {
      today = m;
      logs[DateTime(n.year, n.month, n.day)] = m;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scores = moodScores(logs, DateTime.now());
    // Sắp xếp bài hát theo điểm tâm trạng cao -> thấp
    final sorted = [...songs]
      ..sort((a, b) => scores[b.mood]!.compareTo(scores[a.mood]!));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: SingleChildScrollView(
        child: Column(children: [
          _header(),
          _card(
            title: 'Hôm nay bạn cảm thấy thế nào ?',
            centerAligned: true,
            child: Column( children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: Mood.values.map(_moodButton).toList(),
              ),
              const SizedBox(height: 15),
              Text(
                today == null ? 'Hãy chọn tâm trạng của bạn': 'Tâm trạng hôm nay: ${today!.label}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),

              ]
            ),
          ),
          _card(
            title: 'Biểu đồ tâm trạng',
            subtitle: 'Dữ liệu 1 tháng gần nhất',
            child: _chart(),
          ),
          _card(
            title: 'Góc thư giãn - Âm nhạc cho tâm trạng',
            subtitle: 'Nghe nhạc phù hợp với tâm trạng hiện tại',
            child: SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.vertical,
                itemCount: sorted.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _songTile(sorted[i]),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _header() => Stack(
    /* width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 56, 16, 28),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF4C8DFF), Color(0xFF7B6CF6)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
    ), */
    children: [
      // Ảnh nền, rộng hết màn hình, cao theo tỉ lệ ảnh để không bị cắt phần sóng
      Image.asset(
        'assets/images/AppBar.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
      // Nội dung đè lên ảnh
      Positioned.fill(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 8,
            16,
            16, // chừa chỗ cho phần sóng ở đáy
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
                child: Icon(Icons.person_outline, size: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AppUser1234',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('@username1234', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {/* TODO: đánh gái tổng quan */},
                child: Image.asset('assets/images/Overview/overview_positive.png', width: 40),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: () {/* TODO: mở màn hình AI Chat */},
                child: Image.asset('assets/images/calmy_button.png', width: 40),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _card({required String title, String? subtitle, required Widget child, bool centerAligned = false,}) =>

      Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
            crossAxisAlignment: centerAligned ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
          Text(title,
              textAlign: centerAligned ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                  color: Color(0xFF4C5BD4), fontWeight: FontWeight.bold, fontSize: 18)),
          if (subtitle != null)
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _moodButton(Mood m) {
    final selected = today == m;
    return GestureDetector(
      onTap: () => _pick(m),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: selected ? m.color.withValues(alpha: 0.2) : const Color(0xFFF3F6FB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? m.color : Colors.transparent, width: 2),
        ),
        child: Center(child: Image.asset(m.asset, width: 28)),
      ),
    );
  }

  Widget _chart() {
    final counts = {for (final m in Mood.values) m: 0};
    final n = DateTime.now();
    for (int i = 0; i < 7; i++) {
      final day = DateTime(n.year, n.month, n.day).subtract(Duration(days: i));
      final m = logs[day];
      if (m != null) counts[m] = counts[m]! + 1;
    }
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final shown = Mood.values.where((m) => counts[m]! > 0).toList();
    final top = shown.isEmpty
        ? null
        : (shown..sort((a, b) => counts[b]!.compareTo(counts[a]!))).first;

    return Row(children: [
      const SizedBox(width: 40),
      SizedBox(
        width: 120, height: 120,
        child: CustomPaint(
          painter: _DonutPainter(counts, total),
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(top == null ? '--' : '${(counts[top]! * 100 / total).round()}%',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(top?.label ?? '', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: Mood.values.where((m) => counts[m]! > 0).map((m) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                CircleAvatar(radius: 4, backgroundColor: m.color),
                const SizedBox(width: 6),
                Text('${m.label} • ${(counts[m]! * 100 / total).round()}%',
                    style: const TextStyle(fontSize: 12)),
              ]),
            );
          }).toList(),
        ),
      ),
    ]);
  }

  Widget _songTile(Song s) => Container(
    width: 210,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: const Color(0xFFF3F6FB),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: s.mood.color.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.music_note),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text(s.artist, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
      const Icon(Icons.play_circle_fill, color: Color(0xFFFF8A5C), size: 32),
    ]),
  );
}

class _DonutPainter extends CustomPainter { // Tạo chart tròn
  final Map<Mood, int> counts;
  final int total;
  _DonutPainter(this.counts, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.butt;
    if (total == 0) {
      paint.color = Colors.grey.shade300;
      canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, paint);
      return;
    }
    double start = -math.pi / 2;
    for (final m in Mood.values) {
      final c = counts[m]!;
      if (c == 0) continue;
      final sweep = 2 * math.pi * c / total;
      paint.color = m.color;
      canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}