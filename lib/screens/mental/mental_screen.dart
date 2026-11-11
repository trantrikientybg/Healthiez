import 'dart:math' as math;
import 'package:healthiez/shared/widgets/gradient_text.dart';
import 'mental_data.dart';
import 'overview_popup.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:healthiez/core/theme/day_period.dart';
import 'package:healthiez/core/theme/app_text_styles.dart';
import 'spotify_cover.dart';

// ============ 1. MODEL ============
class DailyRecord {
  final DateTime date;
  final double? sleepHours;
  final int? waterMl;
  final Mood? emotion;
  final String? aiJournal;

  DailyRecord({
    required this.date,
    this.sleepHours,
    this.waterMl,
    this.emotion,
    this.aiJournal,
  });
}

class Profiles {
  final String name;
  final String username;

  Profiles({
    required this.name,
    required this.username,
  });
}

class DailyRecordService {
  final _db = Supabase.instance.client;

  String _fmt(DateTime d) => d.toIso8601String().substring(0, 10);

  Future<List<DailyRecord>> getRecords() async {
    final row = await _db
        .from('mental_health_records')
        .select('dates, emotions')
        .maybeSingle();

    if (row == null) return [];

    final dates = List<String>.from(row['dates'] ?? []);
    final emotions = List<dynamic>.from(row['emotions'] ?? []);

    final list = <DailyRecord>[];
    for (var i = 0; i < dates.length; i++) {
      final name = i < emotions.length ? emotions[i] : null;
      final mood = name == null ? null : Mood.values.asNameMap()[name];
      if (mood == null) continue;
      list.add(DailyRecord(date: DateTime.parse(dates[i]), emotion: mood));
    }
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> saveRecord({
    required Mood emotion,
    DateTime? date,
  }) async {
    await _db.rpc('upsert_mental_health_record', params: {
      'p_date': _fmt(date ?? DateTime.now()),
      'p_emotion': emotion.name,
    });
  }
}

Future<void> _openUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  var ok = false;
  if (uri != null && uri.hasScheme) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }
  if (ok) return;
}

DateTime dateOnly(DateTime x) => DateTime(x.year, x.month, x.day);

Map<Mood, double> moodScores(Map<DateTime, Mood> logs, DateTime today) {
  const freqWeight = 1.0;
  const streakWeight = 1.5;
  const todayBonusValue = 5.0;

  final t = dateOnly(today);
  final byDay = {for (final e in logs.entries) dateOnly(e.key): e.value};
  final scores = {for (final m in Mood.values) m: 0.0};

  for (final m in Mood.values) {
    var freq = 0, streak = 0, best = 0;
    for (var i = 28 - 1; i >= 0; i--) {
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

Mood? topMood(Map<Mood, double> scores, Mood? todayMood) {
  final maxScore = scores.values.fold(0.0, math.max);
  if (maxScore == 0) return null;
  final tops = [
    for (final e in scores.entries)
      if (e.value == maxScore) e.key
  ];
  return (todayMood != null && tops.contains(todayMood))
      ? todayMood
      : tops.first;
}

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
  Mood? today;
  bool loading = true;
  String name = 'UnnamedUser';
  String username = 'unnamed';
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _loadUser() async {
    final db = Supabase.instance.client;
    final user = db.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata;

    String? u = (meta?['username'] as String?)?.trim();
    String? n = ((meta?['full_name'] ?? meta?['name']) as String?)?.trim();
    String? avatar = ((meta?['avatar_url'] ?? meta?['picture']) as String?)?.trim();

    try {
      final row = await db
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        final dbUsername = (row['username'] as String?)?.trim();
        final dbName = (row['full_name'] as String?)?.trim();
        final dbAvatar = (row['avatar_url'] as String?)?.trim();

        if (dbUsername != null && dbUsername.isNotEmpty) u = dbUsername;
        if (dbName != null && dbName.isNotEmpty) n = dbName;
        if (dbAvatar != null && dbAvatar.isNotEmpty) avatar = dbAvatar;
      }
    } catch (_) {}

    if (u != null && u.isNotEmpty) username = u;
    if (n != null && n.isNotEmpty) {
      name = n;
    } else if (u != null && u.isNotEmpty) {
      name = u;
    }
    if (avatar != null && avatar.isNotEmpty) avatarUrl = avatar;
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

    setState(() {
      today = m;
      logs[key] = m;
    });

    try {
      await DailyRecordService().saveRecord(emotion: m);
    } catch (e) {
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
    final suggested = topMood(scores, today);
    final sorted = [...songs]..sort((a, b) {
      final scoreA = scores[a.mood] ?? 0.0;
      final scoreB = scores[a.mood] ?? 0.0;

      final scoreComparison = scoreB.compareTo(scoreA);
      if (scoreComparison != 0) {
        return scoreComparison;
      } else {
        final scoreA = scores[a.mood2] ?? 0.0;
        final scoreB = scores[a.mood2] ?? 0.0;
        final scoreComparison2 = scoreB.compareTo(scoreA);
        if (scoreComparison2 != 0) {
          return scoreComparison2;
        }
      }
      return a.title.compareTo(b.title);
    });

    return Scaffold(
      backgroundColor: context.palette.background,
      extendBody: true,
      body: loading
          ? const Center(child: CircularProgressIndicator())
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
                style: AppTextStyles.mentalSubtitle.copyWith(
                  color: context.palette.textPrimary,
                  decorationColor: context.palette.textPrimary,
                ),
              ),

              ]
            ),
          ),
          _card(
            title: 'Biểu đồ tâm trạng',
            subtitle: 'Dữ liệu 28 ngày gần nhất',
            child: _chart(),
          ),
          _card(
            title: 'Góc thư giãn - Âm nhạc cho tâm trạng',
            subtitle: suggested == null
                ? 'Chọn tâm trạng để nhận gợi ý nhạc'
                : 'Gợi ý Playlist nhạc theo tâm trạng ',
            child: Column(children: sorted.map(_songTile).toList()),
          ),
          const SizedBox(height: 45),

        ]),
      ),
    );
  }

  Widget _header() => Stack(
    children: [
      Image.asset(
        'assets/images/AppBar.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
      ),
      Positioned.fill(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.of(context).padding.top + 8,
            16,
            16,
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 27,
                backgroundColor: Colors.white,
                child: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? ClipOval(
                        child: Image.network(
                          avatarUrl!,
                          width: 54,
                          height: 54,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.person_outline, size: 32),
                        ),
                      )
                    : const Icon(Icons.person_outline, size: 32),
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
                    Text('@$username', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => showMoodOverview(context, overviewOf(logs, DateTime.now()).overviewData),
                child: overviewImage(logs),
              ),
              const SizedBox(width: 7),
              GestureDetector(
                onTap: () {/* TODO: mở màn hình AI Chat */},
                child: Image.asset('assets/images/calmy_button.png', width: 40),
              ),
              const SizedBox(width: 7),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 26),
                tooltip: 'Cài đặt',
                onPressed: () async {
                  await Navigator.pushNamed(context, '/settings');
                  _load();
                },
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
          color: context.palette.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
            crossAxisAlignment: centerAligned ? CrossAxisAlignment.center : CrossAxisAlignment.start,
          children: [
          GradientText(title,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),),
          if (subtitle != null)
            Text(subtitle,
                style : AppTextStyles.mentalSubtitle.copyWith(
                  color: context.palette.textPrimary,
                  decorationColor: context.palette.textPrimary,
                ),
            ),
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
    for (int i = 0; i < 28; i++) {
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
                  style: AppTextStyles.mentalSubtitle.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color : context.palette.textPrimary)),
              Text(top?.label ?? '', style: AppTextStyles.happiness.copyWith(
                color : context.palette.textAccent,
              )
              ),
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
                    style: AppTextStyles.index.copyWith(
                      color : context.palette.textPrimary,
                      fontSize: 12.5,
                    )),
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
      SongCover(
        spotifyUrl: s.url,
        size: 52,
        radius: 8,
        placeholderColor: s.mood.color.withValues(alpha: 0.3),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(s.content, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: s.mood.color,
        icon: const Icon(
          Icons.play_circle_fill,
          size: 32,
        ),
        onPressed: () => _openUrl(context, s.url),
        ),]
    )
  );
}

class _DonutPainter extends CustomPainter {
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
