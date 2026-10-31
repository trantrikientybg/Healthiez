import '../models/streak.dart';
import '../models/user_profile.dart';

class UserRepository {
  Future<UserProfile> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 300)); // giả lập mạng
    return const UserProfile(id: 'demo-user', username: 'Kiên');
  }

  Future<Streak> getStreak() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Streak(currentDays: 4, lastOpenDate: DateTime.now());
  }
}
