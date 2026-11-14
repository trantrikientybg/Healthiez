import 'dart:convert';

/// "Ngày ngủ" bắt đầu lúc 12h trưa: 12h trưa hôm nay -> 12h trưa hôm sau.
/// Nhờ vậy đêm ngủ vắt qua 0h vẫn thuộc về MỘT ngày, và đồng hồ tự "reset" lúc 12h trưa.
class SleepDay {
  SleepDay._();

  static const int resetHour = 12;

  static DateTime of(DateTime t) {
    final day = DateTime(t.year, t.month, t.day);
    return t.hour >= resetHour ? day : DateTime(day.year, day.month, day.day - 1);
  }

  static String key(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

enum SleepPhase {
  armed,    // đã bấm bắt đầu, chờ tắt màn hình
  sleeping, // màn hình đang tắt, đồng hồ đang đếm
  awake,    // đã mở máy, đồng hồ tạm dừng
}

/// Phiên ngủ đang diễn ra.
class SleepSession {
  final DateTime startedAt;
  final Duration accumulated;     // tổng thời gian màn hình đã tắt
  final DateTime? runningSince;   // lúc màn hình tắt gần nhất (null = đang tạm dừng)
  final DateTime lastEventAt;     // lần tắt/bật màn hình gần nhất

  const SleepSession({
    required this.startedAt,
    required this.accumulated,
    required this.lastEventAt,
    this.runningSince,
  });

  SleepPhase get phase => runningSince != null
      ? SleepPhase.sleeping
      : (accumulated > Duration.zero ? SleepPhase.awake : SleepPhase.armed);

  SleepSession copyWith({
    Duration? accumulated,
    DateTime? runningSince,
    bool clearRunningSince = false,
    DateTime? lastEventAt,
  }) =>
      SleepSession(
        startedAt: startedAt,
        accumulated: accumulated ?? this.accumulated,
        runningSince: clearRunningSince ? null : (runningSince ?? this.runningSince),
        lastEventAt: lastEventAt ?? this.lastEventAt,
      );

  Map<String, dynamic> toJson() => {
        'startedAt': startedAt.millisecondsSinceEpoch,
        'accumulatedMs': accumulated.inMilliseconds,
        'runningSince': runningSince?.millisecondsSinceEpoch,
        'lastEventAt': lastEventAt.millisecondsSinceEpoch,
      };

  factory SleepSession.fromJson(Map<String, dynamic> j) => SleepSession(
        startedAt: DateTime.fromMillisecondsSinceEpoch((j['startedAt'] as num).toInt()),
        accumulated: Duration(milliseconds: (j['accumulatedMs'] as num).toInt()),
        runningSince: j['runningSince'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch((j['runningSince'] as num).toInt()),
        lastEventAt: DateTime.fromMillisecondsSinceEpoch((j['lastEventAt'] as num).toInt()),
      );
}

/// Kết quả một đêm ngủ đã hoàn tất.
class SleepEntry {
  final DateTime bedTime;
  final DateTime wakeTime;
  final Duration asleep;

  const SleepEntry({
    required this.bedTime,
    required this.wakeTime,
    required this.asleep,
  });

  @override
  bool operator ==(Object other) =>
      other is SleepEntry &&
      other.bedTime == bedTime &&
      other.wakeTime == wakeTime &&
      other.asleep == asleep;

  @override
  int get hashCode => Object.hash(bedTime, wakeTime, asleep);

  /// Gộp hai phiên cùng một ngày ngủ (ví dụ ngủ trưa).
  SleepEntry merge(SleepEntry other) => SleepEntry(
        bedTime: bedTime.isBefore(other.bedTime) ? bedTime : other.bedTime,
        wakeTime: wakeTime.isAfter(other.wakeTime) ? wakeTime : other.wakeTime,
        asleep: asleep + other.asleep,
      );

  Map<String, dynamic> toJson() => {
        'bed': bedTime.millisecondsSinceEpoch,
        'wake': wakeTime.millisecondsSinceEpoch,
        'asleepMs': asleep.inMilliseconds,
      };

  factory SleepEntry.fromJson(Map<String, dynamic> j) => SleepEntry(
        bedTime: DateTime.fromMillisecondsSinceEpoch((j['bed'] as num).toInt()),
        wakeTime: DateTime.fromMillisecondsSinceEpoch((j['wake'] as num).toInt()),
        asleep: Duration(milliseconds: (j['asleepMs'] as num).toInt()),
      );
}

/// Toàn bộ dữ liệu giấc ngủ lưu trên máy.
class SleepData {
  static const int keepDays = 14;

  final SleepSession? active;
  final Map<String, SleepEntry> history; // khóa: SleepDay.key

  /// Các ngày ngủ đã lưu trên máy nhưng CHƯA đẩy lên Supabase (sẽ thử lại sau).
  final Set<String> pending;

  const SleepData({
    this.active,
    this.history = const {},
    this.pending = const {},
  });

  SleepData copyWith({
    SleepSession? active,
    bool clearActive = false,
    Map<String, SleepEntry>? history,
    Set<String>? pending,
  }) =>
      SleepData(
        active: clearActive ? null : (active ?? this.active),
        history: history ?? this.history,
        pending: pending ?? this.pending,
      );

  String encode() => jsonEncode({
        'active': active?.toJson(),
        'history': {for (final e in history.entries) e.key: e.value.toJson()},
        'pending': pending.toList(),
      });

  /// Đọc từ chuỗi JSON; dữ liệu hỏng hoặc rỗng thì trả về dữ liệu trống.
  static SleepData decode(String? raw) {
    if (raw == null || raw.isEmpty) return const SleepData();
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final hist = <String, SleepEntry>{};
      final h = j['history'];
      if (h is Map<String, dynamic>) {
        for (final e in h.entries) {
          hist[e.key] = SleepEntry.fromJson(e.value as Map<String, dynamic>);
        }
      }
      final a = j['active'];
      final p = j['pending'];
      return SleepData(
        active: a == null ? null : SleepSession.fromJson(a as Map<String, dynamic>),
        history: hist,
        // Dữ liệu cũ (chưa có trường pending) thì coi như rỗng
        pending: p is List ? p.map((e) => e.toString()).toSet() : <String>{},
      );
    } catch (_) {
      return const SleepData();
    }
  }
}
