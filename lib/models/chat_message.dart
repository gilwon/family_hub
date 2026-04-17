// lib/models/chat_message.dart
// Design Ref: §2.1 Model 클래스 설계

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.familyId,
    required this.senderId,
    required this.text,
    this.imageUrl,
    required this.readBy,
    required this.createdAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  final String id;
  final String familyId;
  final String senderId;
  final String text;
  final String? imageUrl;
  final List<String> readBy;
  final DateTime createdAt;

  // 발신자 프로필 (join 결과)
  final String? senderName;
  final String? senderAvatarUrl;

  bool isReadBy(String userId) => readBy.contains(userId);

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return ChatMessage(
      id: json['id'] as String,
      familyId: json['family_id'] as String,
      senderId: json['sender_id'] as String,
      text: json['text'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      readBy: (json['read_by'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      senderName: profile?['name'] as String?,
      senderAvatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
