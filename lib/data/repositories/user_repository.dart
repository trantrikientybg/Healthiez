import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_client.dart';
import '../../core/utils/date_utils.dart';
import '../models/streak.dart';
import '../models/user_profile.dart';

class UserRepository {
  final SupabaseClient _db = Supabase.instance.client;

  Future<UserProfile> getProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      return UserProfile(id: 'guest', username: 'guest', fullName: 'Bạn');
    }

    final meta = user.userMetadata;
    String? username = (meta?['username'] as String?)?.trim();
    String? fullName = ((meta?['full_name'] ?? meta?['name']) as String?)?.trim();
    String? avatar = ((meta?['avatar_url'] ?? meta?['picture']) as String?)?.trim();

    try {
      final row = await _db
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
      if (row != null) {
        return UserProfile.fromJson(row);
      }
    } catch (_) {}

    return UserProfile(
      id: user.id,
      username: username ?? '',
      fullName: fullName,
      avatarUrl: avatar,
      email: user.email ?? '',
    );
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        return UserProfile.fromJson(data);
      }
    } catch (_) {}

    return UserProfile(
      id: user.id,
      username: (user.userMetadata?['username'] as String?) ?? 'User',
      email: user.email ?? '',
    );
  }

  static Future<void> syncUserProfile({
    required String userId,
    required String username,
    required String email,
  }) async {
    try {
      await supabase.from('profiles').upsert({
        'id': userId,
        'username': username,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<void> updateFullUserProfile(UserProfile profile) async {
    final Map<String, dynamic> data = profile.toJson();
    data['updated_at'] = DateTime.now().toIso8601String();

    await supabase.from('profiles').upsert(data);
  }

  // Tải file ảnh đại diện từ máy người dùng lên Supabase Storage bucket 'avatars'
  static Future<String?> uploadAvatarImage({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.path.split('.').last.toLowerCase();
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = 'public/$fileName';

      await supabase.storage.from('avatars').uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      final String publicUrl = supabase.storage.from('avatars').getPublicUrl(filePath);
      return publicUrl;
    } catch (_) {
      return null;
    }
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
      return Streak(currentDays: 0, lastOpenDate: today);
    }
  }
}
