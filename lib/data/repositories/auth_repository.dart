import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_client.dart';

class AuthRepository {
  static Future<SharedPreferences> _getPrefs() async => SharedPreferences.getInstance();

  static Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    final bool loggedInInPrefs = prefs.getBool('is_logged_in') ?? false;
    final session = supabase.auth.currentSession;
    return loggedInInPrefs || session != null;
  }

  // Đảm bảo khởi tạo username đúng quy tắc cho OAuth (Google & Facebook)
  static Future<void> ensureOAuthUsernameCreated(User user) async {
    final String provider = (user.appMetadata['provider']?.toString() ?? '').toLowerCase();

    if (provider == 'google' || provider == 'facebook') {
      final String metaUsername = (user.userMetadata?['username'] as String?)?.trim() ?? '';

      Map<String, dynamic>? profileData;
      try {
        profileData = await supabase
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();
      } catch (_) {}

      final String currentProfileUsername = (profileData?['username'] as String?)?.trim() ?? '';

      // Kiểm tra nếu chưa có username trong user_metadata hoặc profiles
      final bool needsUsername = metaUsername.isEmpty ||
          metaUsername == 'User' ||
          currentProfileUsername.isEmpty ||
          currentProfileUsername == 'User' ||
          currentProfileUsername.startsWith('User_');

      if (needsUsername) {
        String newUsername = '';

        if (provider == 'google') {
          final emailStr = user.email ?? '';
          final prefix = emailStr.contains('@')
              ? emailStr.split('@')[0]
              : user.id.substring(0, user.id.length >= 8 ? 8 : user.id.length);
          newUsername = 'gg_$prefix';
        } else if (provider == 'facebook') {
          String? fbId;

          // 1. Lấy provider_id hoặc sub từ userMetadata
          if (user.userMetadata != null) {
            fbId = user.userMetadata!['provider_id']?.toString() ??
                user.userMetadata!['sub']?.toString();
          }

          // 2. Lấy từ danh sách identities nếu có
          if ((fbId == null || fbId.isEmpty) && user.identities != null) {
            for (final identity in user.identities!) {
              if (identity.provider == 'facebook') {
                fbId = identity.identityData?['sub']?.toString() ??
                    identity.identityData?['provider_id']?.toString() ??
                    identity.id;
                break;
              }
            }
          }

          // 3. Fallback nếu không tìm thấy fbId
          fbId ??= user.id.length >= 8 ? user.id.substring(0, 8) : user.id;

          newUsername = 'fb_$fbId';
        }

        if (newUsername.isNotEmpty) {
          // a. Cập nhật thuộc tính "username" vào raw_user_meta_data của Supabase Auth
          try {
            await supabase.auth.updateUser(
              UserAttributes(data: {'username': newUsername}),
            );
          } catch (_) {}

          // b. Cập nhật thuộc tính "username" vào bảng public.profiles
          try {
            await supabase.from('profiles').upsert({
              'id': user.id,
              'username': newUsername,
              'email': user.email ?? '',
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        }
      }
    }
  }

  static Future<void> saveCurrentSessionState() async {
    final prefs = await _getPrefs();
    final session = supabase.auth.currentSession;
    if (session != null) {
      final String email = session.user.email ?? session.user.id;
      final String provider = session.user.appMetadata['provider']?.toString() ?? 'email';
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', email);
      await prefs.setString('auth_provider', provider);

      // Tự động khởi tạo username chuẩn quy tắc khi đăng nhập OAuth
      await ensureOAuthUsernameCreated(session.user);
    }
  }

  static Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  static String getErrorMessage(dynamic e) {
    if (e is AuthException) {
      final message = e.message.toLowerCase();
      final statusCode = e.statusCode;

      if (message.contains('token has expired') ||
          message.contains('otp_expired') ||
          message.contains('invalid token') ||
          message.contains('token is invalid')) {
        return 'Mã xác minh không hợp lệ hoặc đã hết hạn. Vui lòng thử gửi lại mã!';
      }
      if (message.contains('email not confirmed') || message.contains('email link is invalid')) {
        return 'Tài khoản chưa được xác nhận email. Vui lòng kiểm tra hộp thư email của bạn để xác nhận trước khi đăng nhập!';
      }
      if (message.contains('invalid login credentials') || message.contains('invalid_credentials')) {
        return 'Tài khoản/Email hoặc mật khẩu không chính xác!';
      }
      if (message.contains('user already registered') || message.contains('already exists')) {
        return 'Email này đã được sử dụng. Vui lòng thử đăng nhập hoặc dùng email khác!';
      }
      if (message.contains('password should be at least')) {
        return 'Mật khẩu quá ngắn. Mật khẩu phải có ít nhất 6 ký tự!';
      }
      if (message.contains('rate limit') || statusCode == '429') {
        return 'Đã gửi quá nhiều yêu cầu. Vui lòng đợi một phút rồi thử lại!';
      }
      return e.message;
    } else if (e is PostgrestException) {
      return 'Lỗi cơ sở dữ liệu: ${e.message}';
    } else if (e is Exception) {
      final msg = e.toString().replaceAll('Exception:', '').trim();
      if (msg.isNotEmpty) return msg;
    }
    return 'Đã xảy ra lỗi không xác định. Vui lòng thử lại sau!';
  }

  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    if (response.session != null) {
      await saveCurrentSessionState();
    }
    return response;
  }

  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      await saveCurrentSessionState();
    }
    return response;
  }

  static Future<AuthResponse> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    Map<String, dynamic>? userData;
    try {
      userData = await supabase
          .from('profiles')
          .select('email')
          .ilike('username', cleanUsername)
          .maybeSingle();
    } catch (_) {}

    if (userData == null || userData['email'] == null || (userData['email'] as String).isEmpty) {
      throw const AuthException(
        'Không tìm thấy tài khoản với tên người dùng này. Vui lòng thử đăng nhập bằng Email!',
      );
    }

    final String actualEmail = userData['email'] as String;
    final response = await supabase.auth.signInWithPassword(
      email: actualEmail,
      password: password,
    );
    if (response.session != null) {
      await saveCurrentSessionState();
    }
    return response;
  }

  static Future<String?> getEmailByUsername(String username) async {
    try {
      final userData = await supabase
          .from('profiles')
          .select('email')
          .ilike('username', username.trim())
          .maybeSingle();
      if (userData != null && userData['email'] != null) {
        return userData['email'] as String;
      }
    } catch (_) {}
    return null;
  }

  static Future<void> sendPasswordResetCode(String email) async {
    await supabase.auth.resetPasswordForEmail(
      email.trim(),
    );
  }

  static Future<AuthResponse> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await supabase.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
    return response;
  }

  static Future<UserResponse> updatePassword(String newPassword) async {
    final response = await supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    await signOut();
    return response;
  }

  static Future<bool> signInWithGoogle() async {
    return await supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.healthiez://login-callback',
    );
  }

  static Future<bool> signInWithFacebook() async {
    return await supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.healthiez://login-callback',
      scopes: 'public_profile',
    );
  }
}
