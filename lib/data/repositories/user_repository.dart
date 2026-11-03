import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/date_utils.dart';
import '../models/streak.dart';
import '../models/user_profile.dart';

/// Tên/avatar: cùng quy tắc với màn Tinh thần (metadata trước, profiles sau).
/// Streak: gọi hàm touch_streak() trong DB.
class UserRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<UserProfile> getProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      // Chưa đăng nhập (ví dụ đang bypass để xem giao diện)
      return const UserProfile(id: 'guest', username: 'guest', name: 'Bạn');
    }

    final meta = user.userMetadata;
    String? username = (meta?['username'] as String?)?.trim();
    String? fullName =
    ((meta?['full_name'] ?? meta?['name']) as String?)?.trim();
    String? avatar =
    ((meta?['avatar_url'] ?? meta?['picture']) as String?)?.trim();

    try {
      final row = await _db
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        if (username == null || username.isEmpty) {
          username = (row['username'] as String?)?.trim();
        }
        if (fullName == null || fullName.isEmpty) {
          fullName = (row['full_name'] as String?)?.trim();
        }
        final dbAvatar = (row['avatar_url'] as String?)?.trim();
        if (dbAvatar != null && dbAvatar.isNotEmpty) avatar = dbAvatar;
      }
    } catch (_) {
      // Lỗi mạng/RLS: dùng thông tin trong metadata
    }

    final name = (fullName != null && fullName.isNotEmpty)
        ? fullName
        : (username != null && username.isNotEmpty ? username : 'Bạn');

    return UserProfile(
      id: user.id,
      username: username ?? '',
      name: name,
      avatarUrl: (avatar != null && avatar.isNotEmpty) ? avatar : null,
    );
  }

  Future<Streak> getStreak() async {
    final today = AppDateUtils.dateOnly(DateTime.now());
    if (_db.auth.currentUser == null) {
      return Streak(currentDays: 0, lastOpenDate: today);
    }
    try {
      final result = await _db.rpc('touch_streak');
      return Streak(currentDays: (result as num).toInt(), lastOpenDate: today);
    } catch (_) {
      // Hàm chưa được tạo hoặc mất mạng: hiện 0 thay vì số giả
      return Streak(currentDays: 0, lastOpenDate: today);
    }
  }
}