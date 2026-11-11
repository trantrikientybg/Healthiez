class UserProfile {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? dateOfBirth;
  final String? gender;
  final double? weight;
  final double? height;
  final DateTime? updatedAt;

  UserProfile({
    required this.id,
    required this.username,
    this.email = '',
    this.fullName,
    this.avatarUrl,
    this.dateOfBirth,
    this.gender,
    this.weight,
    this.height,
    this.updatedAt,
  });

  String get name => (fullName != null && fullName!.isNotEmpty) ? fullName! : (username.isNotEmpty ? username : 'User');

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      height: json['height'] != null ? (json['height'] as num).toDouble() : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'weight': weight?.round(),
      'height': height?.round(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
