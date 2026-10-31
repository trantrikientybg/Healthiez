import 'package:flutter/material.dart';
import '../../core/theme/day_period.dart';
import '../../data/models/screen_time_record.dart';
import '../../data/models/sleep_record.dart';
import '../../data/models/step_record.dart';
import '../../data/models/streak.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/section_chip.dart';
import '../../shared/widgets/theme_debug_switcher.dart';
import 'widgets/daily_greeting_chip.dart';
import 'widgets/greeting_header.dart';
import 'widgets/overview_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserRepository _userRepo = UserRepository();
  final ActivityRepository _activityRepo = ActivityRepository();

  UserProfile? _profile;
  Streak? _streak;
  StepRecord? _steps;
  SleepRecord? _sleep;
  ScreenTimeRecord? _screenTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Gọi tất cả cùng lúc (chưa await) để các lần chờ chạy song song
    final profileF = _userRepo.getProfile();
    final streakF = _userRepo.getStreak();
    final stepsF = _activityRepo.getTodaySteps();
    final sleepF = _activityRepo.getLastNightSleep();
    final screenF = _activityRepo.getTodayScreenTime();

    final profile = await profileF;
    final streak = await streakF;
    final steps = await stepsF;
    final sleep = await sleepF;
    final screen = await screenF;

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _streak = streak;
      _steps = steps;
      _sleep = sleep;
      _screenTime = screen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nền theo buổi chỉ áp dụng cho Home (Login và Tinh thần không đổi)
    return ColoredBox(
      color: context.palette.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppHeader(
              child: GreetingHeader(profile: _profile, streak: _streak),
            ),
            const SizedBox(height: 16),
            const DailyGreetingChip(),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 20),
                child: SectionChip('Tổng quan'),
              ),
            ),
            const SizedBox(height: 12),
            OverviewSection(
              steps: _steps,
              sleep: _sleep,
              screenTime: _screenTime,
            ),
            // Các phần tiếp theo (tâm trạng, gợi ý) sẽ thêm ở dưới

            const SizedBox(height: 24),
            const ThemeDebugSwitcher(), // TẠM: xóa khi có Settings
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
