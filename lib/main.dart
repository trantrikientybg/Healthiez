import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_colors.dart';
import 'data/repositories/auth_repository.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding đã được khởi tạo trước khi gọi native code
  WidgetsFlutterBinding.ensureInitialized();

  // Load bảng màu động từ tệp JSON
  await AppColors.loadFromPath();

  // Khởi tạo Supabase Client
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    publishableKey: AppConstants.supabaseAnonKey,
  );

  // Kiểm tra trạng thái đăng nhập từ trước
  final bool isLoggedIn = await AuthRepository.isLoggedIn();

  runApp(HealthiezApp(isLoggedIn: isLoggedIn));
}
