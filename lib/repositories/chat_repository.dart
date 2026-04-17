// lib/repositories/chat_repository.dart
// Design Ref: §5.3 ChatRepository — 페이지네이션 + 읽음 처리(N+1 방지)
// Plan SC-3: A→B 1초 내 메시지 수신 (Realtime)

import 'dart:io';
import '../core/supabase/storage_service.dart';
import '../core/supabase/supabase_client.dart';
import '../core/utils/constants.dart';
import '../models/chat_message.dart';

class ChatRepository {
  final _storage = StorageService();

  /// 메시지 목록 (역순 — 최신이 앞)
  Future<List<ChatMessage>> getMessages(
    String familyId, {
    int limit = AppConstants.chatPageSize,
    DateTime? before,
  }) async {
    var query = db
        .from('messages')
        .select('*, profiles!sender_id(name, avatar_url)')
        .eq('family_id', familyId);

    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }

    final result = await query
        .order('created_at', ascending: false)
        .limit(limit);

    return (result as List)
        .map((r) => ChatMessage.fromJson(r))
        .toList();
  }

  /// 텍스트 메시지 전송
  Future<void> sendMessage(
    String familyId,
    String text, {
    String? imageUrl,
  }) async {
    final userId = auth.currentUser!.id;
    await db.from('messages').insert({
      'family_id': familyId,
      'sender_id': userId,
      'text': text,
      'image_url': imageUrl,
      'read_by': [userId],
    });
  }

  /// 이미지 전송 — 업로드 실패 시 보상 처리
  Future<void> sendImageMessage(String familyId, File imageFile) async {
    String? imageUrl;
    try {
      imageUrl = await _storage.uploadChatImage(familyId, imageFile);
      await sendMessage(familyId, '', imageUrl: imageUrl);
    } catch (e) {
      // messages insert 실패 시 고아 이미지 삭제
      if (imageUrl != null) {
        await _storage.deleteChatImage(imageUrl);
      }
      rethrow;
    }
  }

  /// 읽지 않은 메시지 수 (바텀 탭 배지용)
  Future<int> getUnreadCount(String familyId) async {
    final userId = auth.currentUser!.id;
    final result = await db
        .from('messages')
        .select('id')
        .eq('family_id', familyId)
        .neq('sender_id', userId)
        .not('read_by', 'cs', '{$userId}')
        .limit(99);
    return (result as List).length;
  }

  /// 읽음 처리 — 단일 RPC (N+1 방지)
  Future<void> markRead(List<String> messageIds) async {
    if (messageIds.isEmpty) return;
    final userId = auth.currentUser!.id;
    await db.rpc('mark_messages_read', params: {
      'p_message_ids': messageIds,
      'p_user_id': userId,
    });
  }
}
