import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_client.dart';
import '../models/user_profile.dart';

class UserRepository {
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
}
