import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/date_utils.dart';
import '../models/screen_time_record.dart';
import '../models/step_record.dart';
import 'step_aggregator.dart';

class ActivityRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _tableName = 'physical_health_records';
  static const String _stepKind = 'steps';

  /// Lắng nghe dữ liệu bước chân theo THỜI GIAN THỰC (Realtime) từ Supabase.
  /// Mỗi khi tab Thể chất ghi bước mới lên DB, luồng này phát ra bản ghi mới.
  Stream<StepRecord> watchTodaySteps() {
    final userId = _supabase.auth.currentUser?.id;

    if (userId == null) {
      return Stream.value(emptyStepRecord());
    }

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['user_id', 'kind', 'device_id'])
        .eq('user_id', userId)
        .map(
          (rows) => StepAggregator.fromRows(
            rows,
            DateTime.now(),
            goal: AppConstants.stepGoal,
          ),
        );
  }

  /// Đọc bước chân 1 lần (không mở kênh Realtime). Trả về null nếu không đọc được
  /// (mất mạng...), để nơi gọi giữ lại số cũ thay vì hiện 0.
  Future<StepRecord?> getTodaySteps() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return emptyStepRecord();
    try {
      final rows = await _supabase
          .from(_tableName)
          .select('kind, payload')
          .eq('user_id', userId)
          .eq('kind', _stepKind);
      return StepAggregator.fromRows(
        List<Map<String, dynamic>>.from(rows),
        DateTime.now(),
        goal: AppConstants.stepGoal,
      );
    } catch (_) {
      return null;
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
    final today = AppDateUtils.dateOnly(DateTime.now());
    ScreenTimeRecord unavailable() => ScreenTimeRecord.unavailable(
          date: today,
          limitMinutes: AppConstants.screenTimeLimitMinutes,
        );

    if (!Platform.isAndroid) return unavailable();

    try {
      final int? mins = await _screenTimeChannel.invokeMethod<int>(
        'getTodayScreenOnMinutes',
      );
      // Không có kết quả hợp lệ thì báo "không đọc được", không coi là 0 phút
      if (mins == null || mins < 0) return unavailable();
      return ScreenTimeRecord(
        date: today,
        minutes: mins,
        limitMinutes: AppConstants.screenTimeLimitMinutes,
      );
    } catch (_) {
      return unavailable();
    }
  }

  /// Bản ghi bước chân rỗng (chưa đăng nhập hoặc chưa có dữ liệu).
  StepRecord emptyStepRecord() => _emptyStepRecord(AppDateUtils.dateOnly(DateTime.now()));

  StepRecord _emptyStepRecord(DateTime date) => StepRecord(
    date: date,
    steps: 0,
    goal: AppConstants.stepGoal,
    weeklyTotal: 0,
  );
}
