// test/features/calendar/event_filter_provider_test.dart
// Design Ref: §8.1 단위 테스트 — EventFilter toggle/setAll/clearAll

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_hub/providers/event_filter_provider.dart';

void main() {
  group('EventFilter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 빈 Set (전체 표시)', () {
      final state = container.read(eventFilterProvider);
      expect(state, isEmpty);
    });

    test('toggle: 없는 userId 추가', () {
      container.read(eventFilterProvider.notifier).toggle('user-1');
      expect(container.read(eventFilterProvider), {'user-1'});
    });

    test('toggle: 있는 userId 제거', () {
      container.read(eventFilterProvider.notifier).toggle('user-1');
      container.read(eventFilterProvider.notifier).toggle('user-1');
      expect(container.read(eventFilterProvider), isEmpty);
    });

    test('setAll: 여러 userId 한번에 설정', () {
      container
          .read(eventFilterProvider.notifier)
          .setAll(['user-1', 'user-2', 'user-3']);
      expect(
        container.read(eventFilterProvider),
        {'user-1', 'user-2', 'user-3'},
      );
    });

    test('clearAll: 모든 필터 해제 → 빈 Set', () {
      container
          .read(eventFilterProvider.notifier)
          .setAll(['user-1', 'user-2']);
      container.read(eventFilterProvider.notifier).clearAll();
      expect(container.read(eventFilterProvider), isEmpty);
    });

    test('여러 userId toggle 조합', () {
      final notifier = container.read(eventFilterProvider.notifier);
      notifier.toggle('user-1');
      notifier.toggle('user-2');
      notifier.toggle('user-1'); // 제거
      expect(container.read(eventFilterProvider), {'user-2'});
    });
  });
}
