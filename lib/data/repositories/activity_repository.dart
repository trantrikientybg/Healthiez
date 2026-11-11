import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/screen_time_record.dart';
import '../models/step_record.dart';

class ActivityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _tableName = 'physical_health_records';
  static const String _stepKind = 'steps';

  /// Lắng nghe dữ liệu bước chân hôm nay theo THỜI GIAN THỰC (Realtime) từ Supabase.
  Stream<StepRecord> watchTodaySteps() {
    final userId = _supabase.auth.currentUser?.id;
    final today = AppDateUtils.dateOnly(DateTime.now());

    if (userId == null) {
      return Stream.value(_emptyStepRecord(today));
    }

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['user_id', 'kind', 'device_id'])
        .eq('user_id', userId)
        .map((rows) {
          final currentToday = AppDateUtils.dateOnly(DateTime.now());
          final todayStr = _formatDate(currentToday);
          final startOfWeek = _getStartOfWeek(currentToday);

          int todaySteps = 0;
          int weeklyTotal = 0;

          for (final row in rows) {
            if (row['kind'] != _stepKind) continue;

            final payload = row['payload'];
            if (payload is! Map<String, dynamic>) continue;

            final dateStr = payload['date'] as String?;
            final steps = (payload['steps'] as num?)?.toInt() ?? 0;
            // Trường 'last' cũng có sẵn ở đây nếu bạn cần dùng để khôi phục trạng thái cảm biến:
            // final last = (payload['last'] as num?)?.toInt() ?? 0;

            if (dateStr == null) continue;
            final recordDate = DateTime.tryParse(dateStr);
            if (recordDate == null) continue;

            final normalizedDate = AppDateUtils.dateOnly(recordDate);
            if (!normalizedDate.isBefore(startOfWeek) &&
                !normalizedDate.isAfter(currentToday)) {
              weeklyTotal += steps;
            }

            if (dateStr == todayStr) {
              todaySteps += steps;
            }

            // Past days of this week, kept by StepController in payload 'history'.
            final history = payload['history'];
            if (history is Map<String, dynamic>) {
              for (final entry in history.entries) {
                final day = DateTime.tryParse(entry.key);
                if (day != null &&
                    !day.isBefore(startOfWeek) &&
                    day.isBefore(currentToday)) {
                  weeklyTotal += (entry.value as num?)?.toInt() ?? 0;
                }
              }
            }
          }

          return StepRecord(
            date: currentToday,
            steps: todaySteps,
            goal: AppConstants.stepGoal,
            weeklyTotal: weeklyTotal,
          );
        });
  }

  /// Lấy dữ liệu bước chân hôm nay 1 lần.
  Future<StepRecord> getTodaySteps() async {
    try {
      return await watchTodaySteps().first;
    } catch (_) {
      return _emptyStepRecord(AppDateUtils.dateOnly(DateTime.now()));
    }
  }

  /// Lấy raw payload (date, steps, last) từ DB để khôi phục cho StepController khi đổi máy hoặc cài lại app.
  Future<Map<String, dynamic>?> getTodayRawPayload({
    String deviceId = 'default_phone',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from(_tableName)
          .select('payload')
          .eq('user_id', userId)
          .eq('kind', _stepKind)
          .eq('device_id', deviceId)
          .maybeSingle();

      if (response == null) return null;
      return response['payload'] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  /// Lưu hoặc cập nhật payload chuẩn {date, steps, last} lên Supabase.
  Future<bool> syncTodaySteps({
    required String date,
    required int steps,
    required int last,
    String deviceId = 'default_phone',
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabase.from(_tableName).upsert({
        'user_id': userId,
        'kind': _stepKind,
        'device_id': deviceId,
        'payload': {'date': date, 'steps': steps, 'last': last},
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  static const _screenTimeChannel = MethodChannel('healthiez/screen_time');

  Future<ScreenTimeRecord> getTodayScreenTime() async {
    final now = DateTime.now();
    final today = AppDateUtils.dateOnly(now);
    int totalMinutes = 0;

    if (Platform.isAndroid) {
      try {
        final int? mins = await _screenTimeChannel.invokeMethod<int>(
          'getTodayScreenOnMinutes',
        );
        totalMinutes = mins ?? 0;
      } catch (_) {
        totalMinutes = 0;
      }
    }

    return ScreenTimeRecord(
      date: today,
      minutes: totalMinutes,
      limitMinutes: AppConstants.screenTimeLimitMinutes,
    );
  }




  StepRecord _emptyStepRecord(DateTime date) => StepRecord(
    date: date,
    steps: 0,
    goal: AppConstants.stepGoal,
    weeklyTotal: 0,
  );

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _getStartOfWeek(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));
}
