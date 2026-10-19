import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Lấy đối tượng SharedPreferences
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  // Kiểm tra trạng thái đăng nhập khi mở app
  static Future<bool> isLoggedIn() async {
    final prefs = await _getPrefs();
    final bool loggedInInPrefs = prefs.getBool('is_logged_in') ?? false;
    final session = _supabase.auth.currentSession;
    return loggedInInPrefs || session != null;
  }

  // Lưu trạng thái đăng nhập
  static Future<void> saveCurrentSessionState() async {
    final prefs = await _getPrefs();
    final session = _supabase.auth.currentSession;
    if (session != null) {
      final String email = session.user.email ?? session.user.id;
      final String provider = session.user.appMetadata['provider']?.toString() ?? 'email';
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', email);
      await prefs.setString('auth_provider', provider);
    }
  }

  // Đăng xuất
  static Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {}
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  // Đồng bộ thông tin profile vào bảng profiles trong Supabase
  static Future<void> _syncUserProfile({
    required String userId,
    required String username,
    required String email,
  }) async {
    try {
      await _supabase.from('profiles').upsert({
        'id': userId,
        'username': username,
        'email': email,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Bỏ qua lỗi nếu RLS hoặc kết nối DB chưa sẵn sàng
    }
  }

  // Chuyển đổi ngoại lệ Supabase/Hệ thống thành thông báo tiếng Việt dễ hiểu
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

  // Đăng ký tài khoản bằng Email và Mật khẩu
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );

    if (response.session != null) {
      await saveCurrentSessionState();
      if (response.user != null) {
        await _syncUserProfile(
          userId: response.user!.id,
          username: username,
          email: email,
        );
      }
    }
    return response;
  }

  // Đăng nhập bằng Email và Mật khẩu
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.session != null) {
      await saveCurrentSessionState();

      if (response.user != null) {
        final username = response.user?.userMetadata?['username'] as String?;
        if (username != null && username.isNotEmpty) {
          await _syncUserProfile(
            userId: response.user!.id,
            username: username,
            email: response.user!.email ?? email,
          );
        }
      }
    }
    return response;
  }

  // Đăng nhập bằng tài khoản (username) và mật khẩu
  static Future<AuthResponse> signInWithUsername({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();

    // Tìm email tương ứng với username trong bảng profiles
    Map<String, dynamic>? userData;
    try {
      userData = await _supabase
          .from('profiles')
          .select('email')
          .ilike('username', cleanUsername)
          .maybeSingle();
    } catch (_) {
      // Bỏ qua lỗi nếu bảng không truy vấn được
    }

    if (userData == null || userData['email'] == null || (userData['email'] as String).isEmpty) {
      throw const AuthException(
        'Không tìm thấy tài khoản với tên người dùng này. Vui lòng thử đăng nhập bằng Email!',
      );
    }

    final String actualEmail = userData['email'] as String;

    final response = await _supabase.auth.signInWithPassword(
      email: actualEmail,
      password: password,
    );

    if (response.session != null) {
      await saveCurrentSessionState();
      if (response.user != null) {
        await _syncUserProfile(
          userId: response.user!.id,
          username: cleanUsername,
          email: actualEmail,
        );
      }
    }

    return response;
  }

  // Tra cứu email dựa trên tên tài khoản (username) trong bảng profiles
  static Future<String?> getEmailByUsername(String username) async {
    try {
      final userData = await _supabase
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

  // Gửi mã OTP xác minh đặt lại mật khẩu qua Email
  static Future<void> sendPasswordResetCode(String email) async {
    await _supabase.auth.resetPasswordForEmail(
      email.trim(),
    );
  }

  // Xác minh mã OTP khôi phục mật khẩu
  static Future<AuthResponse> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _supabase.auth.verifyOTP(
      email: email.trim(),
      token: code.trim(),
      type: OtpType.recovery,
    );
    return response;
  }

  // Cập nhật mật khẩu mới sau khi xác minh mã OTP
  static Future<UserResponse> updatePassword(String newPassword) async {
    final response = await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    await signOut(); // Đăng xuất phiên đệm khôi phục để người dùng đăng nhập lại
    return response;
  }

  // Đăng nhập bằng Google
  static Future<bool> signInWithGoogle() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.healthiez://login-callback',
    );
  }

  // Đăng nhập bằng Facebook
  static Future<bool> signInWithFacebook() async {
    return await _supabase.auth.signInWithOAuth(
      OAuthProvider.facebook,
      redirectTo: 'io.supabase.healthiez://login-callback',
      scopes: 'public_profile',
    );
  }
}
