import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
Future<void> main() async {
  // Đảm bảo Flutter đã khởi tạo trước khi gọi code native
  WidgetsFlutterBinding.ensureInitialized();

  // Kết nối Supabase
  await Supabase.initialize(
    url: 'https://tzdbowjwsewwzmxvcfqk.supabase.co', // không có /rest/v1/
    anonKey: 'sb_publishable_RgNJjOg7dyXBpHJxA5yDoA_9LTzNSB2',
  );

  runApp(const HealthiezApp());
}