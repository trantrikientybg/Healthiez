/// Thứ tự khớp với 5 icon trong thiết kế (trái -> phải).
/// Khi nối Supabase, đối chiếu tên với enum `emotion_type`.
enum MoodType {
  happy('Vui vẻ'),
  surprised('Bất ngờ'),
  angry('Tức giận'),
  neutral('Bình thường'),
  sad('Buồn');

  final String label;
  const MoodType(this.label);
}

class MoodEntry {
  final DateTime date; // chỉ có ngày
  final MoodType mood;

  const MoodEntry({required this.date, required this.mood});
}