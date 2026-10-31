import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/screen_time_record.dart';
import '../models/sleep_record.dart';
import '../models/step_record.dart';

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

  Future<SleepRecord> getLastNightSleep() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final today = AppDateUtils.dateOnly(DateTime.now());
    return SleepRecord(
      date: today,
      bedTime: today.subtract(const Duration(hours: 1)),          // 23:00 hôm qua
      wakeTime: today.add(const Duration(hours: 7, minutes: 30)), // 7:30 hôm nay
      goalHours: AppConstants.sleepGoalHours,
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