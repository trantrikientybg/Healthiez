import 'package:shared_preferences/shared_preferences.dart';

/// Lưu các gợi ý người dùng đã "ẩn hôm nay". Sang ngày mới tự hiện lại.
class SuggestionDismissStore {
  static const _prefix = 'home.suggestions.dismissed.';

  static String _key(DateTime d) =>
      '$_prefix${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<Set<String>> load(DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getStringList(_key(now)) ?? const <String>[]).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  Future<void> dismiss(String id, DateTime now) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _key(now);
      final list = (prefs.getStringList(key) ?? <String>[]).toList();
      if (!list.contains(id)) list.add(id);
      await prefs.setStringList(key, list);
      // Dọn khóa của các ngày cũ
      for (final k in prefs.getKeys().toList()) {
        if (k.startsWith(_prefix) && k != key) await prefs.remove(k);
      }
    } catch (_) {
      // Không lưu được thì thẻ chỉ ẩn trong phiên này
    }
  }
}
