import 'package:flutter/foundation.dart';
import '../../screens/mental/mental_data.dart' show Mood;

/// Đồng bộ tâm trạng hôm nay giữa tab Trang chủ và Tinh thần.
/// Tab nào lưu xong thì gọi update(...), tab còn lại tự cập nhật.
class MoodSync extends ChangeNotifier {
  MoodSync._();
  static final MoodSync instance = MoodSync._();

  Mood? _mood;
  Object? _source; // ai vừa phát tín hiệu (để người phát không tự nghe lại mình)

  Mood? get mood => _mood;
  Object? get source => _source;

  void update(Mood mood, Object source) {
    _mood = mood;
    _source = source;
    notifyListeners();
  }
}
