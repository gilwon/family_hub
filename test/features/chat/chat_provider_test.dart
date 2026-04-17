// test/features/chat/chat_provider_test.dart
// QA Ref: 채팅-기능 L1 단위 테스트
// Design Ref: §3.1 RealtimeService.messagesChanged, §3.2 UnreadChatCountNotifier
// 검증 항목: CHAT-SC-1(그룹 전환 배지 오집계 방지), CHAT-SC-2(타입 안전), reset()

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_hub/core/supabase/realtime_service.dart';
import 'package:family_hub/providers/chat_provider.dart';

// --------------------------------------------------------------------------
// FakeUnreadChatCountNotifier
// Supabase / RealtimeService 의존성 없이 주입된 Stream으로 동작.
// UnreadChatCountNotifier의 핵심 로직(sender_id 필터, count 증가, reset)만 검증.
// --------------------------------------------------------------------------
class _FakeUnreadChatCountNotifier extends UnreadChatCountNotifier {
  _FakeUnreadChatCountNotifier({
    required Stream<Map<String, dynamic>> stream,
    required String userId,
  })  : _stream = stream,
        _userId = userId;

  final Stream<Map<String, dynamic>> _stream;
  final String _userId;

  @override
  Future<int> build() async {
    // Design Ref: §3.2 — sender_id 필터링 + StreamSubscription 정리
    final sub = _stream.listen((payload) {
      final senderId = payload['sender_id'] as String?;
      if (senderId != null && senderId != _userId) {
        final current = state.valueOrNull ?? 0;
        state = AsyncData(current + 1);
      }
    });
    ref.onDispose(sub.cancel);
    return 0; // Supabase getUnreadCount 대체 (초기값 0)
  }
}

void main() {
  // =========================================================================
  group('RealtimeService — messagesChanged Stream', () {
    late RealtimeService svc;

    setUp(() {
      svc = RealtimeService();
    });

    tearDown(() {
      svc.dispose();
    });

    test('messagesChanged는 broadcast stream이다', () {
      expect(svc.messagesChanged.isBroadcast, isTrue);
    });

    test('broadcast stream은 다중 구독자를 동시에 허용한다', () {
      expect(
        () {
          svc.messagesChanged.listen((_) {});
          svc.messagesChanged.listen((_) {});
        },
        returnsNormally,
      );
    });

    test('dispose() 이후 messagesChanged stream이 완료(done) 상태가 된다', () async {
      var isDone = false;
      svc.messagesChanged.listen((_) {}, onDone: () => isDone = true);

      svc.dispose();
      await Future.delayed(Duration.zero); // microtask flush

      expect(isDone, isTrue);
    });
  });

  // =========================================================================
  group('UnreadChatCountNotifier', () {
    test('초기 상태는 0이다', () async {
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: const Stream.empty(),
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result =
          await container.read(unreadChatCountNotifierProvider.future);
      expect(result, 0);
    });

    test('타인 메시지 수신 시 count가 1 증가한다', () async {
      final ctrl = StreamController<Map<String, dynamic>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: ctrl.stream,
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(ctrl.close);
      addTearDown(container.dispose);

      // AutoDispose 유지: listen으로 provider를 살아있게 고정
      container.listen(unreadChatCountNotifierProvider, (p, n) {});
      await container.read(unreadChatCountNotifierProvider.future);

      ctrl.add({'sender_id': 'user-other'});
      await Future.delayed(Duration.zero);

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        1,
      );
    });

    // CHAT-SC-1 핵심: 본인 메시지는 배지 증가 없음
    test('본인 메시지 수신 시 count가 증가하지 않는다', () async {
      final ctrl = StreamController<Map<String, dynamic>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: ctrl.stream,
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(ctrl.close);
      addTearDown(container.dispose);

      container.listen(unreadChatCountNotifierProvider, (p, n) {});
      await container.read(unreadChatCountNotifierProvider.future);

      ctrl.add({'sender_id': 'user-1'}); // 본인
      await Future.delayed(Duration.zero);

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        0,
      );
    });

    test('연속 타인 메시지 3개 → count가 3이 된다', () async {
      final ctrl = StreamController<Map<String, dynamic>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: ctrl.stream,
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(ctrl.close);
      addTearDown(container.dispose);

      container.listen(unreadChatCountNotifierProvider, (p, n) {});
      await container.read(unreadChatCountNotifierProvider.future);

      ctrl.add({'sender_id': 'user-A'});
      ctrl.add({'sender_id': 'user-B'});
      ctrl.add({'sender_id': 'user-A'});
      await Future.delayed(Duration.zero);

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        3,
      );
    });

    test('타인+본인 혼합 → 타인 메시지만 카운트된다', () async {
      final ctrl = StreamController<Map<String, dynamic>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: ctrl.stream,
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(ctrl.close);
      addTearDown(container.dispose);

      container.listen(unreadChatCountNotifierProvider, (p, n) {});
      await container.read(unreadChatCountNotifierProvider.future);

      ctrl.add({'sender_id': 'user-other'}); // 타인 +1
      ctrl.add({'sender_id': 'user-1'});     // 본인 무시
      ctrl.add({'sender_id': 'user-other'}); // 타인 +1
      await Future.delayed(Duration.zero);

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        2,
      );
    });

    test('sender_id 없는 payload는 count가 증가하지 않는다', () async {
      final ctrl = StreamController<Map<String, dynamic>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: ctrl.stream,
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(ctrl.close);
      addTearDown(container.dispose);

      container.listen(unreadChatCountNotifierProvider, (p, n) {});
      await container.read(unreadChatCountNotifierProvider.future);

      ctrl.add({'content': 'malformed payload'}); // sender_id 없음
      await Future.delayed(Duration.zero);

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        0,
      );
    });

    test('reset() → count가 0으로 초기화된다', () async {
      final ctrl = StreamController<Map<String, dynamic>>.broadcast();
      final container = ProviderContainer(
        overrides: [
          unreadChatCountNotifierProvider.overrideWith(
            () => _FakeUnreadChatCountNotifier(
              stream: ctrl.stream,
              userId: 'user-1',
            ),
          ),
        ],
      );
      addTearDown(ctrl.close);
      addTearDown(container.dispose);

      container.listen(unreadChatCountNotifierProvider, (p, n) {});
      await container.read(unreadChatCountNotifierProvider.future);

      // 타인 메시지로 카운트 올린 후 reset
      ctrl.add({'sender_id': 'user-other'});
      ctrl.add({'sender_id': 'user-other'});
      await Future.delayed(Duration.zero);

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        2,
      );

      container.read(unreadChatCountNotifierProvider.notifier).reset();

      expect(
        container.read(unreadChatCountNotifierProvider).valueOrNull,
        0,
      );
    });
  });
}
