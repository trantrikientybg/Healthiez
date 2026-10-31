class UserProfile {
  final String id;
  final String username;
  final String? avatarUrl; // null -> dùng avatar mặc định

  const UserProfile({
    required this.id,
    required this.username,
    this.avatarUrl,
  });
}