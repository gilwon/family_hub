// lib/models/notification_item.dart
// Design Ref: §2.1 Model — notifications 테이블 매핑

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.familyId,
    required this.targetUser,
    required this.triggeredBy,
    required this.type,
    required this.title,
    required this.body,
    this.referenceId,
    required this.isRead,
    required this.createdAt,
    this.triggeredByName,
  });

  final String id;
  final String familyId;
  final String targetUser;
  final String triggeredBy;
  final String type; // event_create, todo_create, chat, member_join ...
  final String title;
  final String body;
  final String? referenceId;
  final bool isRead;
  final DateTime createdAt;
  final String? triggeredByName; // join 결과

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return NotificationItem(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      targetUser: json['target_user'] as String,
      triggeredBy: json['triggered_by'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      referenceId: json['reference_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      triggeredByName: profile?['name'] as String?,
    );
  }

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        familyId: familyId,
        targetUser: targetUser,
        triggeredBy: triggeredBy,
        type: type,
        title: title,
        body: body,
        referenceId: referenceId,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        triggeredByName: triggeredByName,
      );
}
