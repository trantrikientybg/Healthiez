import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/theme/app_colors.dart';
import 'data/repositories/auth_repository.dart';

Future<Map<String, String>> _getSupabaseConfig() async {
  // 1. Lấy từ biến môi trường --dart-define nếu có truyền
  const envUrl = String.fromEnvironment('SUPABASE_URL');
  const envKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  if (envUrl.startsWith('https://') && envKey.isNotEmpty) {
    return {'url': envUrl, 'key': envKey};
  }

  // 2. Tự động đọc từ file supabase.local.json nếu có
  try {
    final file = File('supabase.local.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      final url = data['SUPABASE_URL']?.toString() ?? '';
      final key = (data['SUPABASE_PUBLISHABLE_KEY'] ?? data['SUPABASE_ANON_KEY'])?.toString() ?? '';
      if (url.startsWith('https://') && key.isNotEmpty) {
        return {'url': url, 'key': key};
      }
    }
  } catch (_) {}

  // 3. Giá trị mặc định dự phòng của ứng dụng
  return {
    'url': 'https://tzdbowjwsewwzmxvcfqk.supabase.co',
    'key': 'sb_publishable_RgNJjOg7dyXBpHJxA5yDoA_9LTzNSB2',
  };
}

Future<void> main() async {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Tự động nạp cấu hình URL và Key Supabase từ supabase.local.json hoặc mặc định
  final config = await _getSupabaseConfig();

  // Load bảng màu động từ tệp JSON
  await AppColors.loadFromPath();

  // Khởi tạo Supabase Client
  await Supabase.initialize(
    url: config['url']!,
    publishableKey: config['key']!,
  );

  // Kiểm tra trạng thái đăng nhập từ trước
  final bool isLoggedIn = await AuthRepository.isLoggedIn();

  runApp(HealthiezApp(isLoggedIn: isLoggedIn));
}
