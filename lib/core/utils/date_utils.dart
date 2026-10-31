class AppDateUtils {
  AppDateUtils._();

  /// Bỏ phần giờ, chỉ giữ ngày.
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Thứ Hai của tuần chứa ngày d.
  static DateTime startOfWeek(DateTime d) =>
      dateOnly(d).subtract(Duration(days: d.weekday - 1));

  /// Số thứ tự ngày trong năm (1-366), dùng để xoay vòng playlist.
  static int dayOfYear(DateTime d) =>
      dateOnly(d).difference(DateTime(d.year, 1, 1)).inDays + 1;
}