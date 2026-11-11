import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthiez/app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://tzdbowjwsewwzmxvcfqk.supabase.co',
      publishableKey: 'sb_publishable_RgNJjOg7dyXBpHJxA5yDoA_9LTzNSB2',
    );
  });

  testWidgets('HealthiezApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthiezApp(isLoggedIn: false));
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
