import '../data/repositories/auth_repository.dart';

class AuthService {
  static Future<bool> isLoggedIn() => AuthRepository.isLoggedIn();
  static Future<void> saveCurrentSessionState() => AuthRepository.saveCurrentSessionState();
  static Future<void> ensureOAuthUsernameCreated(dynamic user) =>
      AuthRepository.ensureOAuthUsernameCreated(user);
  static String getErrorMessage(dynamic e) => AuthRepository.getErrorMessage(e);
  static Future<void> signOut() => AuthRepository.signOut();

  static Future<dynamic> signUpWithEmail({
    required String email,
    required String password,
    required String username,
  }) =>
      AuthRepository.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );

  static Future<dynamic> signInWithEmail({
    required String email,
    required String password,
  }) =>
      AuthRepository.signInWithEmail(email: email, password: password);

  static Future<dynamic> signInWithUsername({
    required String username,
    required String password,
  }) =>
      AuthRepository.signInWithUsername(username: username, password: password);

  static Future<String?> getEmailByUsername(String username) =>
      AuthRepository.getEmailByUsername(username);

  static Future<void> sendPasswordResetCode(String email) =>
      AuthRepository.sendPasswordResetCode(email);

  static Future<dynamic> verifyResetCode({
    required String email,
    required String code,
  }) =>
      AuthRepository.verifyResetCode(email: email, code: code);

  static Future<dynamic> updatePassword(String newPassword) =>
      AuthRepository.updatePassword(newPassword);

  static Future<bool> signInWithGoogle() => AuthRepository.signInWithGoogle();
  static Future<bool> signInWithFacebook() => AuthRepository.signInWithFacebook();
}
