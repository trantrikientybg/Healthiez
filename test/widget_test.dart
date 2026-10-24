import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/features/physical/physical_screen.dart';
import 'package:healthiez/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Home opens; physical values survive tab changes', (
    tester,
  ) async {
    await tester.pumpWidget(const HealthiezApp());
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(PhysicalScreen), findsNothing);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.text('Sức khỏe thể chất'), findsOneWidget);
    await tester.ensureVisible(find.text('Thêm 250 ml'));
    await tester.tap(find.text('Thêm 250 ml'));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.psychology_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(MentalScreen), findsOneWidget);
    expect(find.text('Sức khỏe thể chất'), findsNothing);
    await tester.tap(find.byIcon(Icons.favorite_border));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('validates measurements, displays BMI, and undoes water', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PhysicalScreen())),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Nhập và lưu chiều cao, cân nặng để xem BMI.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Lưu chỉ số'));
    await tester.pumpAndSettle();
    expect(find.text('Nhập số lớn hơn 0.'), findsNWidgets(2));
    await tester.enterText(find.byType(TextFormField).at(0), '170');
    await tester.enterText(find.byType(TextFormField).at(1), '65,5');
    await tester.ensureVisible(find.text('Lưu chỉ số'));
    await tester.tap(find.text('Lưu chỉ số'));
    await tester.pumpAndSettle();
    expect(find.text('BMI: 22.7'), findsOneWidget);
    await tester.ensureVisible(find.text('Thêm 250 ml'));
    await tester.tap(find.text('Thêm 250 ml'));
    await tester.pumpAndSettle();
    expect(find.text('250 ml'), findsOneWidget);
    await tester.tap(find.text('Hoàn tác'));
    await tester.pumpAndSettle();
    expect(find.text('0 ml'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, 'Hoàn tác'))
          .onPressed,
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: PhysicalScreen())),
    );
    await tester.pumpAndSettle();
    expect(find.text('BMI: 22.7'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      '170.0',
    );
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('narrow screen with keyboard and large text stays scrollable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.5),
            viewInsets: const EdgeInsets.only(bottom: 260),
          ),
          child: child!,
        ),
        home: const Scaffold(body: PhysicalScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(TextFormField).first);
    await tester.tap(find.byType(TextFormField).first);
    await tester.enterText(find.byType(TextFormField).first, '170');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Thêm 250 ml'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm 250 ml').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
