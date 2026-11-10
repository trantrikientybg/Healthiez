import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/screen_time_record.dart';
import '../models/step_record.dart';

/// Bước chân và thời gian dùng máy (hiện vẫn là dữ liệu giả).
/// Giấc ngủ đã chuyển sang SleepRepository.
class ActivityRepository {
  Future<StepRecord> getTodaySteps() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return StepRecord(
      date: AppDateUtils.dateOnly(DateTime.now()),
      steps: 7500,
      goal: AppConstants.stepGoal,
      weeklyTotal: 27500,
    );
  }

  Future<ScreenTimeRecord> getTodayScreenTime() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return ScreenTimeRecord(
      date: AppDateUtils.dateOnly(DateTime.now()),
      minutes: 200, // 3h 20m
      limitMinutes: AppConstants.screenTimeLimitMinutes,
    );
  }
}
