import 'package:supabase_flutter/supabase_flutter.dart';
import 'sleep_models.dart';

/// Nơi lưu giấc ngủ trên server (bảng sleep_records, xem sql/sleep_records.sql).
abstract class SleepRemote {
  /// Các ngày ngủ từ [fromDay] trở đi của người dùng, theo khóa SleepDay.key.
  Future<Map<String, SleepEntry>> fetchSince(String userId, DateTime fromDay);

  Future<void> upsert(String userId, String dayKey, SleepEntry entry);
}

/// Đổi qua lại giữa SleepEntry và một dòng của bảng.
class SleepRemoteCodec {
  SleepRemoteCodec._();

  static Map<String, dynamic> toRow(
    String userId,
    String dayKey,
    SleepEntry e, {
    DateTime? now,
  }) =>
      {
        'user_id': userId,
        'sleep_day': dayKey,
        'bed_time': e.bedTime.toUtc().toIso8601String(),
        'wake_time': e.wakeTime.toUtc().toIso8601String(),
        'asleep_minutes': e.asleep.inMinutes.clamp(0, 1440).toInt(),
        'updated_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
      };

  /// Trả về null nếu dòng hỏng.
  static (String, SleepEntry)? fromRow(Map<String, dynamic> row) {
    try {
      final key = (row['sleep_day'] as String).substring(0, 10);
      final bed = DateTime.parse(row['bed_time'] as String).toLocal();
      final wake = DateTime.parse(row['wake_time'] as String).toLocal();
      final minutes = (row['asleep_minutes'] as num).toInt();
      return (
        key,
        SleepEntry(
          bedTime: bed,
          wakeTime: wake,
          asleep: Duration(minutes: minutes),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}

class SupabaseSleepRemote implements SleepRemote {
  SupabaseSleepRemote({SupabaseClient? client})
      : _db = client ?? Supabase.instance.client;

  static const String table = 'sleep_records';

  final SupabaseClient _db;

  @override
  Future<Map<String, SleepEntry>> fetchSince(String userId, DateTime fromDay) async {
    final rows = await _db
        .from(table)
        .select('sleep_day, bed_time, wake_time, asleep_minutes')
        .eq('user_id', userId)
        .gte('sleep_day', SleepDay.key(fromDay));

    final out = <String, SleepEntry>{};
    for (final r in rows) {
      final parsed = SleepRemoteCodec.fromRow(Map<String, dynamic>.from(r));
      if (parsed != null) out[parsed.$1] = parsed.$2;
    }
    return out;
  }

  @override
  Future<void> upsert(String userId, String dayKey, SleepEntry entry) async {
    await _db
        .from(table)
        .upsert(SleepRemoteCodec.toRow(userId, dayKey, entry), onConflict: 'user_id,sleep_day');
  }
}
