// lib/providers/chat_provider.dart
// Design Ref: §5.3 ChatProvider — 페이지네이션 + 읽음 처리 + Realtime
// Plan SC-3: A→B 1초 내 메시지 수신 (Realtime invalidate 방식)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide Family;
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import 'auth_provider.dart';
import 'family_provider.dart';

part 'chat_provider.g.dart';

// Repository provider
@riverpod
ChatRepository chatRepository(Ref ref) => ChatRepository();

/// 채팅 메시지 상태 관리
@riverpod
class ChatNotifier extends _$ChatNotifier {
  static const _pageSize = 30;

  @override
  Future<List<ChatMessage>> build() async {
    final familyId = ref.watch(activeFamilyProvider)?.id;
    if (familyId == null) return [];

    final messages = await ref
        .read(chatRepositoryProvider)
        .getMessages(familyId, limit: _pageSize);

    // 화면 진입 시 읽음 처리
    _markVisible(messages);

    return messages;
  }

  bool _isLoadingMore = false;

  /// 이전 메시지 더 불러오기 (페이지네이션)
  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    final familyId = ref.read(activeFamilyProvider)?.id;
    final current = state.valueOrNull;
    if (familyId == null || current == null || current.isEmpty) return;

    _isLoadingMore = true;
    try {
      final oldest = current.last.createdAt;
      final older = await ref
          .read(chatRepositoryProvider)
          .getMessages(familyId, limit: _pageSize, before: oldest);
      if (older.isEmpty) return;
      state = AsyncData([...current, ...older]);
    } finally {
      _isLoadingMore = false;
    }
  }

  /// 텍스트 메시지 전송
  Future<void> sendText(String text) async {
    final familyId = ref.read(activeFamilyProvider)?.id;
    if (familyId == null || text.trim().isEmpty) return;

    await ref.read(chatRepositoryProvider).sendMessage(familyId, text.trim());
    ref.invalidateSelf();
  }

  /// 이미지 메시지 전송
  Future<void> sendImage(String familyId, dynamic imageFile) async {
    await ref
        .read(chatRepositoryProvider)
        .sendImageMessage(familyId, imageFile);
    ref.invalidateSelf();
  }

  /// Realtime 새 메시지 수신 시 호출 (family_provider에서 콜백)
  void onNewMessage() {
    ref.invalidateSelf();
  }

  /// 화면에 보이는 메시지 읽음 처리
  void _markVisible(List<ChatMessage> messages) {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    final unread = messages
        .where((m) => !m.isReadBy(userId))
        .map((m) => m.id)
        .toList();

    if (unread.isNotEmpty) {
      unawaited(ref.read(chatRepositoryProvider).markRead(unread));
      // 채팅 탭 배지 초기화
      ref.read(unreadChatCountNotifierProvider.notifier).reset();
    }
  }

  /// 수동 읽음 처리 (화면 포커스 복귀 시)
  Future<void> markCurrentRead() async {
    final messages = state.valueOrNull;
    if (messages == null) return;
    _markVisible(messages);
  }
}

/// 채팅 안 읽은 메시지 수 (바텀 탭 배지용)
/// build() 시 DB 초기값 조회 + RealtimeService.messagesChanged Stream으로 실시간 증가
/// 채팅 탭 진입 시 reset() 호출로 0 복귀
/// Design Ref: §3.2 — G-1 fix: 직접 채널 제거, RealtimeService Stream 구독으로 교체
class UnreadChatCountNotifier extends AutoDisposeAsyncNotifier<int> {
  @override
  Future<int> build() async {
    final familyId = ref.watch(activeFamilyProvider)?.id;
    final userId = ref.read(currentUserProvider)?.id;
    if (familyId == null || userId == null) return 0;

    // Design Ref: §3.2 — RealtimeService.messagesChanged Stream 구독
    // Plan SC: CHAT-SC-1 — 그룹 전환 시 sub.cancel()로 즉시 정리 (직접 채널 대비 타이밍 안전)
    final svc = ref.watch(realtimeServiceProvider);
    final sub = svc.messagesChanged.listen((payload) {
      final senderId = payload['sender_id'] as String?;
      if (senderId != null && senderId != userId) {
        final current = state.valueOrNull ?? 0;
        state = AsyncData(current + 1);
      }
    });
    ref.onDispose(sub.cancel);

    return ref.read(chatRepositoryProvider).getUnreadCount(familyId);
  }

  /// 채팅 탭 진입 시 배지 초기화
  void reset() => state = const AsyncData(0);
}

final unreadChatCountNotifierProvider =
    AutoDisposeAsyncNotifierProvider<UnreadChatCountNotifier, int>(
  UnreadChatCountNotifier.new,
);

/// 배지 숫자 편의 provider
final unreadChatCountProvider = Provider.autoDispose<int>((ref) =>
    ref.watch(unreadChatCountNotifierProvider).valueOrNull ?? 0);
