import 'sleep_models.dart';
import 'sleep_remote.dart';
import 'sleep_store.dart';

/// Đồng bộ giấc ngủ giữa máy và Supabase.
///  - Đẩy lên các ngày ngủ chưa lên được (pending) và các ngày chỉ có trên máy.
///  - Kéo về các ngày từ DB (đổi máy, cài lại app, đăng nhập lại).
/// Không bao giờ ném lỗi: mất mạng thì giữ nguyên dữ liệu trên máy và thử lại lần sau.
class SleepSyncService {
  SleepSyncService({
    required this.store,
    required this.remote,
    required this.userId,
    DateTime Function()? now,
    this.timeout = const Duration(seconds: 8),
  }) : _now = now ?? DateTime.now;

  final SleepStore store;
  final SleepRemote remote;
  final String userId;
  final Duration timeout;
  final DateTime Function() _now;

  /// Null nếu chưa đăng nhập (khi đó chỉ lưu trên máy).
  static SleepSyncService? forCurrentUser(SleepStore store, {DateTime Function()? now}) {
    final id = SleepStore.currentUserId();
    if (id == null) return null;
    return SleepSyncService(
      store: store,
      remote: SupabaseSleepRemote(),
      userId: id,
      now: now,
    );
  }

  Future<void> sync() async {
    try {
      await _sync();
    } catch (_) {
      // dữ liệu trên máy vẫn nguyên vẹn
    }
  }

  Future<void> _sync() async {
    final snapshot = await store.load();
    final today = SleepDay.of(_now());
    final from = DateTime(today.year, today.month, today.day - SleepData.keepDays);

    // 1) Kéo về
    Map<String, SleepEntry>? remoteEntries;
    try {
      remoteEntries = await remote.fetchSince(userId, from).timeout(timeout);
    } catch (_) {
      remoteEntries = null; // mất mạng
    }

    // 2) Những ngày cần đẩy lên: đang chờ, hoặc chỉ có trên máy (dữ liệu từ trước khi có đồng bộ)
    final toUpload = <String, SleepEntry>{};
    for (final k in snapshot.pending) {
      final e = snapshot.history[k];
      if (e != null) toUpload[k] = e;
    }
    if (remoteEntries != null) {
      for (final e in snapshot.history.entries) {
        if (!remoteEntries.containsKey(e.key)) toUpload[e.key] = e.value;
      }
    }

    // 3) Đẩy lên (lỗi đầu tiên thì dừng, tránh chờ hết thời gian chờ nhiều lần)
    final uploaded = <String, SleepEntry>{};
    for (final e in toUpload.entries) {
      try {
        await remote.upsert(userId, e.key, e.value).timeout(timeout);
        uploaded[e.key] = e.value;
      } catch (_) {
        break;
      }
    }

    // 4) Ghi kết quả vào dữ liệu MỚI NHẤT trên máy (phòng khi trong lúc chờ mạng có thay đổi)
    await store.mutate(
      (latest) => applyResult(
        latest,
        remoteEntries: remoteEntries,
        toUpload: toUpload,
        uploaded: uploaded,
      ),
    );
  }

  /// Hợp nhất kết quả đồng bộ vào dữ liệu trên máy (hàm thuần).
  static SleepData applyResult(
    SleepData latest, {
    required Map<String, SleepEntry>? remoteEntries,
    required Map<String, SleepEntry> toUpload,
    required Map<String, SleepEntry> uploaded,
  }) {
    final history = Map<String, SleepEntry>.from(latest.history);
    final pending = Set<String>.from(latest.pending);

    // Bản trên DB thắng bản trên máy, trừ ngày đang chờ đẩy lên (bản máy mới hơn)
    remoteEntries?.forEach((k, e) {
      if (!pending.contains(k) && !toUpload.containsKey(k)) history[k] = e;
    });

    // Đã đẩy xong thì bỏ khỏi danh sách chờ (nếu bản trên máy chưa bị đổi)
    for (final e in uploaded.entries) {
      if (latest.history[e.key] == e.value) pending.remove(e.key);
    }

    // Chưa đẩy được thì chờ lần sau
    for (final k in toUpload.keys) {
      if (!uploaded.containsKey(k) && history.containsKey(k)) pending.add(k);
    }

    // Chỉ giữ vài ngày gần nhất
    final keys = history.keys.toList()..sort((a, b) => b.compareTo(a));
    for (final old in keys.skip(SleepData.keepDays)) {
      history.remove(old);
    }
    pending.removeWhere((k) => !history.containsKey(k));

    return latest.copyWith(history: history, pending: pending);
  }
}
