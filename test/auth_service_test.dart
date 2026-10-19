import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:healthiez/services/auth_service.dart';

void main() {
  group('AuthService getErrorMessage unit tests', () {
    test('translates Email Not Confirmed AuthException correctly', () {
      const exception = AuthException('Email not confirmed');
      final msg = AuthService.getErrorMessage(exception);
      expect(msg, contains('chưa được xác nhận email'));
    });

    test('translates Invalid Login Credentials AuthException correctly', () {
      const exception = AuthException('Invalid login credentials');
      final msg = AuthService.getErrorMessage(exception);
      expect(msg, contains('không chính xác'));
    });

    test('translates User Already Registered AuthException correctly', () {
      const exception = AuthException('User already registered');
      final msg = AuthService.getErrorMessage(exception);
      expect(msg, contains('đã được sử dụng'));
    });

    test('translates Short Password AuthException correctly', () {
      const exception = AuthException('Password should be at least 6 characters');
      final msg = AuthService.getErrorMessage(exception);
      expect(msg, contains('Mật khẩu quá ngắn'));
    });

    test('translates Rate Limit AuthException correctly', () {
      const exception = AuthException('Over email rate limit', statusCode: '429');
      final msg = AuthService.getErrorMessage(exception);
      expect(msg, contains('Đã gửi quá nhiều yêu cầu'));
    });

    test('translates generic Exception correctly', () {
      final exception = Exception('Custom system error');
      final msg = AuthService.getErrorMessage(exception);
      expect(msg, equals('Custom system error'));
    });
  });
}
