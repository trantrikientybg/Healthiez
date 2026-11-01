import 'package:flutter/material.dart';
import '../../core/theme/day_period.dart';
import '../../data/models/screen_time_record.dart';
import '../../data/models/sleep_record.dart';
import '../../data/models/step_record.dart';
import '../../data/models/streak.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/mood_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../screens/mental/mental_data.dart' show Mood;
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/section_chip.dart';
import '../../shared/widgets/theme_debug_switcher.dart';
import 'widgets/daily_greeting_chip.dart';
import 'widgets/greeting_header.dart';
import 'widgets/mood_survey_card.dart';
import 'widgets/overview_section.dart';
import '../../data/repositories/mood_sync.dart';

class HomeScreen extends StatefulWidget {
  /// Gọi khi bấm "Xem lại cảm xúc của bạn tháng này" (MainShell chuyển sang tab Tinh thần).
  final VoidCallback? onOpenMental;

  const HomeScreen({super.key, this.onOpenMental});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserRepository _userRepo = UserRepository();
  final ActivityRepository _activityRepo = ActivityRepository();
  final MoodRepository _moodRepo = MoodRepository();

  UserProfile? _profile;
  Streak? _streak;
  StepRecord? _steps;
  SleepRecord? _sleep;
  ScreenTimeRecord? _screenTime;
  Mood? _mood;

  @override
  @override
  void initState() {
    super.initState();
    MoodSync.instance.addListener(_onMoodSync);
    _loadData();
  }

  @override
  void dispose() {
    MoodSync.instance.removeListener(_onMoodSync);
    super.dispose();
  }

  // Tab Tinh thần vừa đổi tâm trạng -> Home cập nhật theo
  void _onMoodSync() {
    final s = MoodSync.instance;
    if (identical(s.source, this) || s.mood == null) return;
    setState(() => _mood = s.mood);
  }

  Future<void> _loadData() async {
    // Gọi tất cả cùng lúc (chưa await) để các lần chờ chạy song song
    final profileF = _userRepo.getProfile();
    final streakF = _userRepo.getStreak();
    final stepsF = _activityRepo.getTodaySteps();
    final sleepF = _activityRepo.getLastNightSleep();
    final screenF = _activityRepo.getTodayScreenTime();
    final moodF = _moodRepo.getToday();

    final profile = await profileF;
    final streak = await streakF;
    final steps = await stepsF;
    final sleep = await sleepF;
    final screen = await screenF;
    final mood = await moodF;

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _streak = streak;
      _steps = steps;
      _sleep = sleep;
      _screenTime = screen;
      _mood = mood;
    });
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() => _mood = mood); // hiện ngay, không chờ mạng
    final ok = await _moodRepo.saveToday(mood);
    if (!mounted) return;
    if (ok) {
      MoodSync.instance.update(mood, this); // báo cho tab Tinh thần
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Chưa lưu được tâm trạng. Kiểm tra kết nối và thử lại.'),
      ),
    );
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
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: MoodSurveyCard(
                selected: _mood,
                onSelected: _onMoodSelected,
                onViewMonth: widget.onOpenMental,
              ),
            ),
            const SizedBox(height: 24),
            // Phần tiếp theo: Gợi ý hằng ngày sẽ thêm ở đây

            const SizedBox(height: 24),
            const ThemeDebugSwitcher(), // TẠM: xóa khi có Settings
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}