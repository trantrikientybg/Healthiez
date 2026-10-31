/// Tên giá trị TRÙNG với enum Mood trong screens/mental/mental_screen.dart
/// (happy, neutral, angry, tired, cry) vì DB lưu emotion.name.
/// Thứ tự khớp 5 icon trong thiết kế Home (trái -> phải).
enum MoodType {
  happy('Hạnh phúc'),
  tired('Mệt mỏi'),
  angry('Tức giận'),
  neutral('Trung lập'),
  cry('Buồn');

  final String label;
  const MoodType(this.label);
}

class MoodEntry {
  final DateTime date; // chỉ có ngày
  final MoodType mood;

  const MoodEntry({required this.date, required this.mood});
}
