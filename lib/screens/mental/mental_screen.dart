import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// FILE NÀY GỒM 3 PHẦN:
//  1. MODEL      : dữ liệu (Mood, Song, DailyRecord) + DailyRecordService nói chuyện với Supabase
//  2. THUẬT TOÁN : chấm điểm từng tâm trạng để gợi ý nhạc
//  3. MÀN HÌNH   : giao diện Tab Tinh thần (chọn tâm trạng, biểu đồ, nhạc)

// ============ 1. MODEL ============
enum Mood { happy, neutral, angry, tired, cry }
enum Overview { positive, neutral, negative }
extension MoodX on Mood {
  String get label => const {
    Mood.happy: 'Hạnh phúc',
    Mood.neutral: 'Trung lập',
    Mood.angry: 'Tức giận',
    Mood.tired: 'Mệt mỏi',
    Mood.cry: 'Buồn',
  }[this]!;

  String get asset => const {
    Mood.happy: 'assets/images/Mood/mood_happy.png',
    Mood.neutral: 'assets/images/Mood/mood_neutral.png',
    Mood.angry: 'assets/images/Mood/mood_angry.png',
    Mood.tired: 'assets/images/Mood/mood_tired.png',
    Mood.cry: 'assets/images/Mood/mood_cry.png',
  }[this]!;

  Color get color => const {
    Mood.happy: Color(0xFF4C8DFF),
    Mood.neutral: Color(0xFFFFC94A),
    Mood.angry: Color(0xFFFF7A5C),
    Mood.tired: Color(0xFF7B6CF6),
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

];

class DailyRecord {
  final DateTime date;
  final double? sleepHours; final int? waterMl; // Cho physical
  final Mood? emotion;
  final String? aiJournal;

  DailyRecord({
    required this.date,
    this.sleepHours, this.waterMl, // Cho physical
    this.emotion,
    this.aiJournal,
  });
}

class Profiles {
  final String name;
  final String username;

  Profiles ({
    required this.name,
    required this.username,
  });
}

class DailyRecordService {
  final _db = Supabase.instance.client;

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<List<DailyRecord>> getRecords() async {
    final row = await _db
        .from('daily_records')
        .select('dates, emotions')
        .maybeSingle(); // Chưa có thì trả null

    if (row == null) return []; // Chưa có thì trả về rỗng

    final dates = List<String>.from(row['dates'] ?? []);
    final emotions = List<dynamic>.from(row['emotions'] ?? []);

    final list = <DailyRecord>[];
    for (var i = 0; i < dates.length; i++) {
      final name = i < emotions.length ? emotions[i] : null;
      final mood = name == null ? null : Mood.values.asNameMap()[name];
      if (mood == null) continue; // Bỏ qua ngày chưa có cảm xúc (hoặc giá trị lạ)
      list.add(DailyRecord(date: DateTime.parse(dates[i]), emotion: mood));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Ghi: thêm cảm xúc cho hôm nay, chọn lại thì ghi đè
  Future<void> saveRecord({
    required Mood emotion,
    DateTime? date,
  }) async {
    await _db.rpc('upsert_daily_record', params: {
      'p_date': _fmt(date ?? DateTime.now()),
      'p_emotion': emotion.name,
    });
  }
}
// ============ 2. THUẬT TOÁN ĐIỂM ============
// Điểm = Tần suất 3-4 tuần gần đây x 1 + Streak lớn nhất x 1.5 + 5 (nếu hôm nay là tâm trạng đó)
DateTime dateOnly(DateTime x) => DateTime(x.year, x.month, x.day);

Map<Mood, double> moodScores(Map<DateTime, Mood> logs, DateTime today) {
  // VD Map : Mood.happy: 12.5,
  // DateTime(2026, 10, 22): Mood.happy,
  const freqWeight = 1.0;      // mỗi lần xuất hiện: +1 điểm
  const streakWeight = 1.5;    // mỗi ngày trong chuỗi liên tiếp dài nhất: +1.5 điểm
  const todayBonusValue = 5.0; // hôm nay chọn đúng tâm trạng này: +5 điểm

  final t = dateOnly(today);
  final byDay = {for (final e in logs.entries) dateOnly(e.key): e.value};
  final scores = {for (final m in Mood.values) m: 0.0};

  // Xét 4 tuần gần nhất
  for (final m in Mood.values) {
    var freq = 0, streak = 0, best = 0;
    for (var i = 28 - 1; i >= 0; i--) { // duyệt từ ngày cũ -> mới
      final day = DateTime(t.year, t.month, t.day - i);
      if (byDay[day] == m) {
        freq++;
        streak++;
        best = math.max(best, streak);
      } else {
        streak = 0;
      }
    }
    final todayBonus = byDay[t] == m ? todayBonusValue : 0.0;
    scores[m] = freq * freqWeight + best * streakWeight + todayBonus;
  }
  return scores;
}

// Chọn mood có điểm cao nhất; hòa thì ưu tiên mood hôm nay
Mood? topMood(Map<Mood, double> scores, Mood? todayMood) {
  final maxScore = scores.values.fold(0.0, math.max); // Điểm >= 0
  if (maxScore == 0) return null; // chưa có dữ liệu thì không gợi ý
  final tops = [
    for (final e in scores.entries)
      if (e.value == maxScore) e.key
  ];
  return (todayMood != null && tops.contains(todayMood))
      ? todayMood
      : tops.first;
}

// Điểm tổng quan : Overview Score = Hạnh phúc * 3 + Trung lập * 1 - Buồn * 2 - Tức giận * 3
// Điểm trung bình : Average Score = Điểm tổng quan / số ngày
// Avg >= 0.4 : Positive | Avg <= -0.2 : Negative | Còn lại : Neutral
const moodPlus = {
  Mood.happy: 3,
  Mood.neutral: 1,
  Mood.cry: -2,
  Mood.tired: 0,
  Mood.angry: -3,
};

Overview overviewOf(Map<DateTime, Mood> logs, DateTime today) {
  final t = DateTime(today.year, today.month, today.day);
  int score = 0, days = 0;

  for (int i = 0; i < 28; i++) {
    final m = logs[t.subtract(Duration(days: i))];
    if (m == null) continue;
    score += moodPlus[m]!;
    days++;
  }

  if (days == 0) return Overview.neutral;
  final avg = score / days;
  if (avg >= 0.4) return Overview.positive;
  if (avg <= -0.2) return Overview.negative;
  return Overview.neutral;
}

Widget overviewImage(Map<DateTime, Mood> logs, {double size = 40}) {
  final overview = overviewOf(logs, DateTime.now());
  return Image.asset(
    overview.asset,
    width: size,
    errorBuilder: (_, _, _) => Icon(Icons.sentiment_neutral, size: size, color: Colors.white),
  );
}

// ============ 3. MÀN HÌNH ============
class MentalScreen extends StatefulWidget {
  const MentalScreen({super.key});
  @override
  State<MentalScreen> createState() => _MentalScreenState();
}

class _MentalScreenState extends State<MentalScreen> {
  final Map<DateTime, Mood> logs = {};
  Mood? today; bool loading = true;
  String name = 'UnnamedUser'; String username = 'unnamed';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadUser() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null) return; // chưa đăng nhập thì giữ tên mặc định

    final meta = user.userMetadata;

    // username: lấy từ metadata (lưu lúc đăng ký), không có thì hỏi bảng profiles
    String? u = (meta?['username'] as String?)?.trim();
    if (u == null || u.isEmpty) {
      try {
        final row = await db
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();
        u = (row?['username'] as String?)?.trim();
      } catch (_) {}
    }

    // name: tên thật (Google/Facebook), không có thì dùng username
    String? n = ((meta?['full_name'] ?? meta?['name']) as String?)?.trim();
    if (n == null || n.isEmpty) n = u;

    if (u != null && u.isNotEmpty) username = u;
    if (n != null && n.isNotEmpty) name = n;
  }

  Future<void> _load() async {
    await _loadUser();
    try {
      final records = await DailyRecordService().getRecords();
      logs.clear();
      for (final r in records) {
        if (r.emotion != null) logs[dateOnly(r.date)] = r.emotion!;
      }
    } catch (e) {
      debugPrint('Lỗi tải cảm xúc: $e');
    }
    if (!mounted) return;
    setState(() {
      today = logs[dateOnly(DateTime.now())];
      loading = false;
    });
  }

  Future<void> _pick(Mood m) async {
    final key = dateOnly(DateTime.now());
    final old = logs[key];

    // Cập nhật giao diện ngay cho mượt
    setState(() {
      today = m;
      logs[key] = m;
    });

    try {
      await DailyRecordService().saveRecord(emotion: m);
    } catch (e) {
      // Lưu thất bại thì trả về như cũ
      if (!mounted) return;
      setState(() {
        today = old;
        if (old == null) {
          logs.remove(key);
        } else {
          logs[key] = old;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không lưu được, thử lại nhé')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scores = moodScores(logs, DateTime.now());
    final suggested = topMood(scores, today); // tâm trạng nổi bật nhất
    // Sắp xếp bài hát theo điểm tâm trạng cao -> thấp (với mood2 phụ)
    final sorted = [...songs]..sort((a, b) {
      // So sánh mood 1 của mỗi bài hát
      final scoreA = scores[a.mood] ?? 0.0;
      final scoreB = scores[a.mood] ?? 0.0;

      final scoreComparison = scoreB.compareTo(scoreA);
      if (scoreComparison != 0) {
        return scoreComparison;
      } else {
        // So sánh mood2 nếu chung mood1
        final scoreA = scores[a.mood2] ?? 0.0;
        final scoreB = scores[a.mood2] ?? 0.0;
        final scoreComparison2 = scoreB.compareTo(scoreA);
        if (scoreComparison2 != 0) {
          return scoreComparison2;
        }
      }
      // Nếu điểm bằng nhau, sắp xếp theo tên bài hát (tăng dần A-Z)
      return a.title.compareTo(b.title);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      body: loading
          ? const Center(child: CircularProgressIndicator()) // đang tải từ Supabase
          : SingleChildScrollView(
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
            subtitle: 'Dữ liệu 7 ngày gần nhất',
            child: _chart(),
          ),
          _card(
            title: 'Góc thư giãn - Âm nhạc cho tâm trạng',
            subtitle: suggested == null
                ? 'Chọn tâm trạng để nhận gợi ý nhạc'
                : 'Gợi ý theo tâm trạng nổi bật: ${suggested.label}',
            child: Column(children: sorted.map(_songTile).toList()),
          ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  Widget _header() => Stack(
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text('@$username', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {/* TODO: đánh giá tổng quan */},
                child: overviewImage(logs),

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
      final day = DateTime(n.year, n.month, n.day - i);
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
    margin: const EdgeInsets.only(bottom: 8),
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
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(s.content, style: const TextStyle(fontSize: 10, color: Colors.grey)),
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
