import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhysicalController extends ChangeNotifier {
  PhysicalController({
    DateTime Function()? now,
    Future<String?> Function()? read,
    Future<bool> Function(String)? write,
    Future<bool> Function(String)? writeMeasurements,
  }) : _now = now ?? DateTime.now,
       _read = read ?? _readPreferences,
       _write = write ?? _writePreferences,
       _writeMeasurements = writeMeasurements ?? write ?? _writePreferences;

  // Default to device storage; signed-in screens inject Supabase persistence.
  static const storageKey = 'healthiez.physical.v1';
  static const waterReference = 2000;
  final DateTime Function() _now;
  final Future<String?> Function() _read;
  final Future<bool> Function(String) _write;
  final Future<bool> Function(String) _writeMeasurements;
  bool _disposed = false;
  bool ready = false;
  bool busy = false;
  String? error;
  double? heightCm;
  double? weightKg;
  int waterMl = 0;
  String? _waterDate;
  bool canUndo = false;

  double? get bmi => heightCm == null || weightKg == null
      ? null
      : calculateBmi(heightCm!, weightKg!);

  static double? parseMeasurement(String value) {
    final number = double.tryParse(value.trim().replaceAll(',', '.'));
    return number != null && number.isFinite && number > 0 ? number : null;
  }

  static double calculateBmi(double heightCm, double weightKg) =>
      weightKg / ((heightCm / 100) * (heightCm / 100));

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  static Future<String?> _readPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.reload();
    return preferences.getString(storageKey);
  }

  static Future<bool> _writePreferences(String value) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(storageKey, value);
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy || ready) return;
    busy = true;
    error = null;
    _changed();
    try {
      final raw = await _read();
      double? height;
      double? weight;
      var water = 0;
      var date = _date(_now());
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        height = (data['heightCm'] as num?)?.toDouble();
        weight = (data['weightKg'] as num?)?.toDouble();
        water = data['waterMl'] as int;
        date = data['waterDate'] as String;
        final parsedDate = DateTime.tryParse(date);
        final hasMeasurements = height != null && weight != null;
        if ((height == null) != (weight == null) ||
            (hasMeasurements &&
                (!height.isFinite ||
                    height <= 0 ||
                    !weight.isFinite ||
                    weight <= 0 ||
                    !calculateBmi(height, weight).isFinite ||
                    calculateBmi(height, weight) <= 0)) ||
            water < 0 ||
            parsedDate == null ||
            _date(parsedDate) != date) {
          throw const FormatException('Invalid physical health record');
        }
      }
      heightCm = height;
      weightKg = weight;
      waterMl = water;
      _waterDate = date;
      ready = true;
      refreshDay();
    } catch (_) {
      error = 'Không thể đọc dữ liệu. Vui lòng thử lại.';
    } finally {
      busy = false;
      _changed();
    }
  }

  void refreshDay() {
    if (!ready) return;
    final today = _date(_now());
    if (_waterDate == today) return;
    _waterDate = today;
    waterMl = 0;
    canUndo = false;
    _changed();
  }

  Future<bool> saveMeasurements(double height, double weight) async {
    final result = calculateBmi(height, weight);
    if (!height.isFinite ||
        height <= 0 ||
        !weight.isFinite ||
        weight <= 0 ||
        !result.isFinite ||
        result <= 0) {
      error = 'Chiều cao hoặc cân nặng không hợp lệ.';
      _changed();
      return false;
    }
    return _save(height: height, weight: weight);
  }

  Future<bool> addWater() => _save(waterChange: 250);

  Future<bool> undoWater() async {
    refreshDay();
    if (!canUndo) return false;
    return _save(waterChange: -250);
  }

  Future<bool> _save({
    double? height,
    double? weight,
    int waterChange = 0,
  }) async {
    if (!ready || busy) return false;
    refreshDay();
    busy = true;
    error = null;
    final date = _waterDate!;
    final nextWater = waterMl + waterChange;
    final nextHeight = height ?? heightCm;
    final nextWeight = weight ?? weightKg;
    _changed();
    try {
      final write = height == null ? _write : _writeMeasurements;
      final saved = await write(
        jsonEncode({
          'heightCm': nextHeight,
          'weightKg': nextWeight,
          'waterMl': nextWater,
          'waterDate': date,
        }),
      );
      if (!saved) throw StateError('Preferences write failed');
      heightCm = nextHeight;
      weightKg = nextWeight;
      waterMl = nextWater;
      _waterDate = date;
      if (waterChange != 0) canUndo = waterChange > 0;
      refreshDay();
      return true;
    } catch (_) {
      error = 'Không thể lưu dữ liệu. Vui lòng thử lại thao tác.';
      return false;
    } finally {
      busy = false;
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
