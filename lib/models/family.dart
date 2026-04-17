// lib/models/family.dart
// Design Ref: §2.1 Model 클래스 설계

class Family {
  const Family({
    required this.id,
    required this.name,
    required this.emoji,
    required this.createdBy,
    required this.inviteCode,
    required this.inviteExpiresAt,
    this.inviteLinkToken,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String emoji;

  String get displayLabel => '$emoji $name';
  final String createdBy;
  final String inviteCode;
  final DateTime inviteExpiresAt;
  final String? inviteLinkToken;
  final DateTime createdAt;

  factory Family.fromJson(Map<String, dynamic> json) => Family(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        createdBy: json['created_by'] as String,
        inviteCode: json['invite_code'] as String,
        inviteExpiresAt:
            DateTime.parse(json['invite_expires_at'] as String),
        inviteLinkToken: json['invite_link_token'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'created_by': createdBy,
        'invite_code': inviteCode,
        'invite_expires_at': inviteExpiresAt.toIso8601String(),
        'invite_link_token': inviteLinkToken,
        'created_at': createdAt.toIso8601String(),
      };
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.displayName,
    required this.role,
    this.emoji,
    this.color,
    this.avatarUrl,
    required this.joinedAt,
  });

  final String id;
  final String userId;
  final String familyId;
  final String displayName;
  final String role; // 'admin' | 'member'
  final String? emoji;
  final String? color;
  final String? avatarUrl;
  final DateTime joinedAt;

  bool get isAdmin => role == 'admin';

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return FamilyMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      familyId: json['family_id'] as String,
      displayName: json['display_name'] as String,
      role: json['role'] as String? ?? 'member',
      emoji: json['emoji'] as String?,
      color: json['color'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

/// FamilyNotifier가 관리하는 상태
class FamilyState {
  const FamilyState({
    required this.families,
    this.activeFamilyId,
  });

  final List<Family> families;
  final String? activeFamilyId;

  static FamilyState empty() =>
      const FamilyState(families: [], activeFamilyId: null);

  FamilyState copyWith({
    List<Family>? families,
    String? activeFamilyId,
  }) =>
      FamilyState(
        families: families ?? this.families,
        activeFamilyId: activeFamilyId ?? this.activeFamilyId,
      );
}
