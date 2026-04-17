// test/features/todo/todo_provider_test.dart
// Design Ref: §4 테스트 설계 — TodoCategoryFilter + filteredTodosProvider 단위 테스트

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:family_hub/models/todo.dart';
import 'package:family_hub/providers/todo_provider.dart';

// 테스트용 TodoNotifier — Supabase 의존성 없이 고정 데이터 반환
class _FakeTodoNotifier extends TodoNotifier {
  _FakeTodoNotifier(this._todos);
  final List<Todo> _todos;

  @override
  Future<List<Todo>> build() async => _todos;
}

final _testTodos = [
  Todo(
    id: '1',
    familyId: 'f1',
    createdBy: 'u1',
    text: '장보기 1',
    category: '장보기',
    isDone: false,
    createdAt: DateTime(2024),
  ),
  Todo(
    id: '2',
    familyId: 'f1',
    createdBy: 'u1',
    text: '집안일 1',
    category: '집안일',
    isDone: true,
    createdAt: DateTime(2024),
  ),
  Todo(
    id: '3',
    familyId: 'f1',
    createdBy: 'u1',
    text: '미분류',
    category: null,
    isDone: false,
    createdAt: DateTime(2024),
  ),
];

void main() {
  group('TodoCategoryFilter', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('초기 상태는 null (전체)', () {
      final state = container.read(todoCategoryFilterProvider);
      expect(state, isNull);
    });

    test('setCategory → 카테고리 변경', () {
      container.read(todoCategoryFilterProvider.notifier).setCategory('장보기');
      expect(container.read(todoCategoryFilterProvider), '장보기');
    });

    test('setCategory(null) → 전체로 초기화', () {
      container.read(todoCategoryFilterProvider.notifier).setCategory('장보기');
      container.read(todoCategoryFilterProvider.notifier).setCategory(null);
      expect(container.read(todoCategoryFilterProvider), isNull);
    });
  });

  group('filteredTodosProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          todoNotifierProvider.overrideWith(
            () => _FakeTodoNotifier(_testTodos),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('null 필터 → 전체 반환', () async {
      // todoNotifier 로드 대기
      await container.read(todoNotifierProvider.future);

      final result = container.read(filteredTodosProvider);
      expect(result.length, 3);
    });

    test('카테고리 필터 → 해당 카테고리만 반환', () async {
      await container.read(todoNotifierProvider.future);

      container
          .read(todoCategoryFilterProvider.notifier)
          .setCategory('장보기');
      final result = container.read(filteredTodosProvider);

      expect(result.length, 1);
      expect(result.first.text, '장보기 1');
    });

    test('일치하는 카테고리 없음 → 빈 목록', () async {
      await container.read(todoNotifierProvider.future);

      container
          .read(todoCategoryFilterProvider.notifier)
          .setCategory('기타');
      final result = container.read(filteredTodosProvider);

      expect(result, isEmpty);
    });
  });
}
