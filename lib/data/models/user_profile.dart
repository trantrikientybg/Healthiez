class UserProfile {
  final String id;
  final String username; // tên đăng nhập, dùng khi cần "@username"
  final String name;     // tên hiển thị ở lời chào
  final String? avatarUrl; // null -> dùng avatar mặc định

  const UserProfile({
    required this.id,
    required this.username,
    required this.name,
    this.avatarUrl,
  });
}