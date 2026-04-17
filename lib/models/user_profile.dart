// lib/models/user_profile.dart
// Design Ref: §2.1 Model 클래스 설계

class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.defaultFamilyId,
    this.fcmToken,
    this.platform,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? defaultFamilyId;
  final String? fcmToken;
  final String? platform;
  final DateTime createdAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        avatarUrl: json['avatar_url'] as String?,
        defaultFamilyId: json['default_family_id'] as String?,
        fcmToken: json['fcm_token'] as String?,
        platform: json['platform'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar_url': avatarUrl,
        'default_family_id': defaultFamilyId,
        'fcm_token': fcmToken,
        'platform': platform,
        'created_at': createdAt.toIso8601String(),
      };
}
