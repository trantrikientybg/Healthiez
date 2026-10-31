import 'package:flutter/material.dart';
import '../../data/models/streak.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/app_header.dart';
import 'widgets/greeting_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserRepository _userRepo = UserRepository();

  UserProfile? _profile;
  Streak? _streak;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Chạy song song hai yêu cầu cho nhanh
    final profileFuture = _userRepo.getProfile();
    final streakFuture = _userRepo.getStreak();
    final profile = await profileFuture;
    final streak = await streakFuture;

    if (!mounted) return; // màn hình đã bị hủy thì không setState
    setState(() {
      _profile = profile;
      _streak = streak;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          AppHeader(
            child: GreetingHeader(profile: _profile, streak: _streak),
          ),
          // Các phần tiếp theo sẽ thêm ở dưới
          const Padding(
            padding: EdgeInsets.all(32),
            child: Text('Nội dung đang xây dựng...'),
          ),
        ],
      ),
    );
  }
}