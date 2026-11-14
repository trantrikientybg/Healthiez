import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/day_period.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/screen_time_record.dart';
import '../../data/models/sleep_record.dart';
import '../../data/models/step_record.dart';
import '../../data/models/streak.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/activity_repository.dart';
import '../../data/repositories/mood_repository.dart';
import '../../data/repositories/mood_sync.dart';
import '../../data/repositories/sleep_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../screens/mental/mental_data.dart' show Mood;
import '../../shared/widgets/app_header.dart';
import '../../shared/widgets/section_chip.dart';
import '../meditation/meditation_screen.dart';
import '../sleep/sleep_screen.dart';
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

  /// Tab Trang chủ có đang được mở không (để làm mới số liệu khi quay lại).
  final bool active;

  const HomeScreen({
    super.key,
    this.onOpenMental,
    this.onOpenPhysical,
    this.active = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final UserRepository _userRepo = UserRepository();
  final ActivityRepository _activityRepo = ActivityRepository();
  final MoodRepository _moodRepo = MoodRepository();
  final SleepRepository _sleepRepo = SleepRepository();
  final SuggestionDismissStore _dismissStore = SuggestionDismissStore();

  UserProfile? _profile;
  Streak? _streak;
  StepRecord? _steps;
  SleepRecord? _sleep;
  bool _sleepLoaded = false;
  ScreenTimeRecord? _screenTime;
  Mood? _mood; // tâm trạng hôm nay
  Map<DateTime, Mood> _moodHistory = {};
  Set<String> _dismissed = {};

  // Làm mới số liệu trực tiếp (bước chân, thời gian dùng máy)
  static const Duration _liveRefreshEvery = Duration(seconds: 30);
  StreamSubscription<StepRecord>? _stepsSub;
  bool _stepsStreamBroken = false;
  Timer? _liveTimer;

  DateTime _now() => DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    MoodSync.instance.addListener(_onMoodSync);
    _listenSteps();
    _liveTimer = Timer.periodic(_liveRefreshEvery, (_) {
      if (mounted && widget.active) _refreshLive();
    });
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveTimer?.cancel();
    _stepsSub?.cancel();
    MoodSync.instance.removeListener(_onMoodSync);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Vừa chuyển sang tab Trang chủ: lấy số liệu mới
    if (!oldWidget.active && widget.active) _refreshLive();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mở lại app (hoặc mở khóa máy): lấy số liệu mới
    if (state == AppLifecycleState.resumed && widget.active) _refreshLive();
  }

  /// Nghe bước chân theo thời gian thực: tab Thể chất ghi bước mới là thẻ Tổng quan đổi ngay.
  void _listenSteps() {
    _stepsSub?.cancel();
    _stepsStreamBroken = false;
    _stepsSub = _activityRepo.watchTodaySteps().listen(
      (record) {
        if (mounted) setState(() => _steps = record);
      },
      onError: (Object _) {
        // Kênh Realtime bị ngắt: bộ hẹn giờ vẫn làm mới, và sẽ nghe lại ở lần sau
        _stepsStreamBroken = true;
      },
    );
  }

  /// Đọc lại bước chân và thời gian dùng máy (hẹn giờ, mở lại app, quay lại tab).
  Future<void> _refreshLive() async {
    if (_stepsStreamBroken) _listenSteps();
    final stepsF = _activityRepo.getTodaySteps();
    final screenF = _activityRepo.getTodayScreenTime();
    final steps = await stepsF;
    final screen = await screenF;
    if (!mounted) return;
    setState(() {
      if (steps != null) _steps = steps; // không đọc được thì giữ số cũ
      _screenTime = screen;
    });
  }

  void _onMoodSync() {
    final s = MoodSync.instance;
    if (identical(s.source, this) || s.mood == null) return;
    setState(() => _mood = s.mood);
  }

  Future<void> _loadData() async {
    final profileF = _userRepo.getProfile();
    final streakF = _userRepo.getStreak();
    final stepsF = _activityRepo.getTodaySteps();
    final sleepF = _sleepRepo.getLastNightSleep(); // đọc nhanh trên máy
    final screenF = _activityRepo.getTodayScreenTime();
    final moodF = _moodRepo.getToday();
    final historyF = _moodRepo.getRecent(days: AppConstants.moodTrendDays);
    final dismissedF = _dismissStore.load(_now());

    final profile = await profileF;
    final streak = await streakF;
    final steps = await stepsF;
    final sleep = await sleepF;
    final screen = await screenF;
    final mood = await moodF;
    final history = await historyF;
    final dismissed = await dismissedF;

    if (!mounted) return;
    setState(() {
      _profile = profile;
      _streak = streak;
      _steps = steps ?? _steps ?? _activityRepo.emptyStepRecord();
      _sleep = sleep;
      _sleepLoaded = true;
      _screenTime = screen;
      _mood = mood;
      _moodHistory = history;
      _dismissed = dismissed;
    });
    unawaited(_syncSleep()); // đồng bộ giấc ngủ với DB ở nền
  }

  Future<void> _onMoodSelected(Mood mood) async {
    setState(() => _mood = mood);
    final ok = await _moodRepo.saveToday(mood);
    if (!mounted) return;
    if (ok) {
      MoodSync.instance.update(mood, this);
      return;
    }
    _toast('Chưa lưu được tâm trạng. Kiểm tra kết nối và thử lại.');
  }

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
        sleepLoaded: _sleepLoaded,
        screenTime: _screenTime,
        recentMoods: _recentMoods(now),
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
      case SuggestionAction.openMeditation:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const MeditationScreen()),
        );
      case SuggestionAction.openSleep:
        await _openSleep();
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

  Future<void> _openSleep() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SleepScreen()),
    );
    await _reloadSleep();
  }

  Future<void> _reloadSleep() async {
    final sleep = await _sleepRepo.getLastNightSleep();
    if (!mounted) return;
    setState(() {
      _sleep = sleep;
      _sleepLoaded = true;
    });
    unawaited(_syncSleep());
  }

  /// Đẩy giấc ngủ chưa lên DB và kéo về giấc ngủ từ DB (đổi máy, cài lại app).
  Future<void> _syncSleep() async {
    final sleep = await _sleepRepo.syncAndGetLastNightSleep();
    if (!mounted) return;
    setState(() {
      _sleep = sleep;
      _sleepLoaded = true;
    });
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
    return ColoredBox(
      color: context.palette.background,
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppHeader(
              onSettingsPressed: () async {
                await Navigator.pushNamed(context, '/settings');
                _loadData();
              },
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
              sleepEmpty: _sleepLoaded && _sleep == null,
              onSleepTap: _openSleep,
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
              onMoreMusic: widget.onOpenMental,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
