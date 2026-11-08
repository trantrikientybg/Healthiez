import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/day_period.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/screen_time_record.dart';
import '../../data/models/sleep_record.dart';
import '../../data/models/song.dart';
import '../../data/models/step_record.dart';
import '../../data/models/streak.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/mood_repository.dart';
import '../../data/repositories/mood_sync.dart';
import '../../data/repositories/music_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../screens/mental/mental_data.dart' show Mood;
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/section_chip.dart';
import '../../shared/widgets/theme_debug_switcher.dart';
import 'logic/suggestion.dart';
import 'logic/suggestion_dismiss_store.dart';
import 'logic/suggestion_engine.dart';
import 'widgets/daily_greeting_chip.dart';
import 'widgets/greeting_header.dart';
import 'widgets/mood_survey_card.dart';
import 'widgets/overview_section.dart';
import 'widgets/suggestion_section.dart';

class HomeScreen extends StatefulWidget {
  /// Chuyển sang tab Tinh thần (link "Xem lại cảm xúc..." trên thẻ tâm trạng).
  final VoidCallback? onOpenMental;

  /// Chuyển sang tab Thể chất (thẻ gợi ý đi bộ/chạy bộ).
  final VoidCallback? onOpenPhysical;

  const HomeScreen({super.key, this.onOpenMental, this.onOpenPhysical});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final UserRepository _userRepo = UserRepository();
  final ActivityRepository _activityRepo = ActivityRepository();
  final MoodRepository _moodRepo = MoodRepository();
  final MusicRepository _musicRepo = MusicRepository();
  final SuggestionDismissStore _dismissStore = SuggestionDismissStore();

  UserProfile? _profile;
  Streak? _streak;
  StepRecord? _steps;
  SleepRecord? _sleep;
  ScreenTimeRecord? _screenTime;
  Mood? _mood; // tâm trạng hôm nay
  Map<DateTime, Mood> _moodHistory = {};
  Song? _song;
  Set<String> _dismissed = {};

  /// Để thử các luật theo giờ, tạm đổi thành ví dụ DateTime(2026, 11, 5, 23).
  DateTime _now() => DateTime.now();

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
    final historyF = _moodRepo.getRecent(days: AppConstants.moodTrendDays);
    final songF = _musicRepo.getSongOfTheDay();
    final dismissedF = _dismissStore.load(_now());

    final profile = await profileF;
    final streak = await streakF;
    final steps = await stepsF;
    final sleep = await sleepF;
    final screen = await screenF;
    final mood = await moodF;
    final history = await historyF;
    final song = await songF;
    final dismissed = await dismissedF;

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _streak = streak;
      _steps = steps;
      _sleep = sleep;
      _screenTime = screen;
      _mood = mood;
      _moodHistory = history;
      _song = song;
      _dismissed = dismissed;
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
    _toast('Chưa lưu được tâm trạng. Kiểm tra kết nối và thử lại.');
  }

  // ---------------- Gợi ý hằng ngày ----------------

  /// Tâm trạng các ngày gần đây (cũ -> mới), hôm nay lấy theo lựa chọn mới nhất.
  List<Mood> _recentMoods(DateTime now) {
    final today = AppDateUtils.dateOnly(now);
    final map = Map<DateTime, Mood>.from(_moodHistory);
    if (_mood != null) map[today] = _mood!;
    final from = today.subtract(Duration(days: AppConstants.moodTrendDays - 1));
    final days = map.keys.where((d) => !d.isBefore(from)).toList()..sort();
    return [for (final d in days) map[d]!];
  }

  List<Suggestion> _suggestions() {
    final now = _now();
    return SuggestionEngine.build(
      SuggestionInput(
        now: now,
        steps: _steps,
        sleep: _sleep,
        screenTime: _screenTime,
        recentMoods: _recentMoods(now),
        songOfTheDay: _song,
        playlistUrls: MusicRepository.playlistUrls,
      ),
      dismissed: _dismissed,
    );
  }

  Future<void> _onSuggestionTap(Suggestion s) async {
    switch (s.action) {
      case SuggestionAction.openPhysicalTab:
        widget.onOpenPhysical?.call();
      case SuggestionAction.openUrl:
        await _openUrl(s.url);
      case SuggestionAction.showMessage:
        _toast(s.message ?? s.title);
      case SuggestionAction.openSleep:
      case SuggestionAction.openMeditation:
        _toast('Tính năng này đang được phát triển, sắp ra mắt nhé!');
    }
  }

  Future<void> _openUrl(String? url) async {
    var ok = false;
    if (url != null) {
      try {
        final uri = Uri.parse(url);
        ok = uri.hasScheme &&
            await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
    }
    if (!ok) _toast('Không mở được liên kết. Kiểm tra lại link nhạc nhé.');
  }

  void _onSuggestionDismiss(Suggestion s) {
    setState(() => _dismissed = {..._dismissed, s.id});
    _dismissStore.dismiss(s.id, _now());
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
            SuggestionSection(
              suggestions: _suggestions(),
              onTap: _onSuggestionTap,
              onDismiss: _onSuggestionDismiss,
            ),
            const SizedBox(height: 12),
            const ThemeDebugSwitcher(), // TẠM: xóa khi có Settings
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
