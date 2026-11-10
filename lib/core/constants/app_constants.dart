class AppConstants {
  AppConstants._();

  // Mục tiêu
  static const int stepGoal = 10000;             // bước/ngày
  static const double sleepGoalHours = 8;        // giờ ngủ mục tiêu
  static const int screenTimeLimitMinutes = 240; // 4 giờ/ngày (dùng cho vòng tròn %)

  // ---- Ngưỡng cho Gợi ý hằng ngày (sau này màn Settings có thể cho chỉnh) ----
  static const int maxSuggestions = 4;             // tối đa số thẻ gợi ý
  static const int screenTimeWarningMinutes = 240; // vượt mức này thì cảnh báo

  static const double sleepEnoughHours = 7;   // ngủ dưới mức này là "chưa đủ giấc"
  static const int sleepSuggestFromHour = 22; // chỉ nhắc đi ngủ từ 22h...
  static const int sleepSuggestUntilHour = 3; // ...đến trước 3h sáng

  static const int stepsSuggestFromHour = 10; // trước giờ này không nhắc đi bộ
  static const int stepsDayStartHour = 6;     // mốc "tiến độ mong đợi" = 0% lúc 6h
  static const int stepsDayEndHour = 21;      // ...và = 100% lúc 21h

  static const int moodTrendDays = 2;       // xét tâm trạng trong N ngày gần nhất
  static const int moodTrendMinEntries = 1; // cần ít nhất N ngày đã ghi nhận
}
