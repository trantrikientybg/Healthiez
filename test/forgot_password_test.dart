import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/screens/auth/code_confirmation_screen.dart';
import 'package:healthiez/screens/auth/forgot_password_screen.dart';
import 'package:healthiez/screens/auth/reset_password_screen.dart';

void main() {
  group('Forgot Password Screens Smoke Tests', () {
    testWidgets('ForgotPasswordScreen renders UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );

      expect(find.text('Quên mật khẩu!'), findsOneWidget);
      expect(find.text('Tên tài khoản / e-mail'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('CodeConfirmationScreen renders UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CodeConfirmationScreen(),
        ),
      );

      expect(find.text('Mã xác minh!'), findsOneWidget);
      expect(find.text('Nhập mã xác minh được gửi qua e-mail'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen renders UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResetPasswordScreen(),
        ),
      );

      expect(find.text('Mật khẩu mới'), findsAtLeastNWidgets(1));
      expect(find.text('Tiếp tục'), findsOneWidget);
    });
  });
}
