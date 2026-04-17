// lib/providers/todo_provider.dart
// Design Ref: §3 상태 관리 — TodoNotifier (activeFamily 기반)
// Design Ref: §2.2 — Option C Realtime 구독 (캘린더와 동일 패턴)

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide Family;
import '../models/todo.dart';
import '../repositories/todo_repository.dart';
import 'family_provider.dart';

part 'todo_provider.g.dart';

@riverpod
TodoRepository todoRepository(Ref ref) => TodoRepository();

/// 선택된 카테고리 필터 (null = 전체)
@riverpod
class TodoCategoryFilter extends _$TodoCategoryFilter {
  @override
  String? build() => null;

  void setCategory(String? category) => state = category;
}

/// 활성 그룹의 할 일 목록
@riverpod
class TodoNotifier extends _$TodoNotifier {
  @override
  Future<List<Todo>> build() async {
    final familyId = ref.watch(activeFamilyProvider)?.id;
    if (familyId == null) return [];

    // Design Ref: §2.2 — Option C Realtime 구독 (캘린더와 동일 패턴)
    // Plan SC: TODO-SC-1 — A 기기 변경 → B 기기 1초 내 자동 반영
    final svc = ref.watch(realtimeServiceProvider);
    StreamSubscription<void>? sub;
    sub = svc.todosChanged.listen((_) {
      Future.microtask(ref.invalidateSelf);
    });
    ref.onDispose(() => sub?.cancel());

    return ref.read(todoRepositoryProvider).getTodos(familyId);
  }

  Future<void> createTodo({
    required String text,
    String? category,
    String? assignedTo,
  }) async {
    final familyId = ref.read(activeFamilyProvider)?.id;
    if (familyId == null) throw Exception('활성 가족 그룹이 없습니다. 그룹을 선택해주세요.');

    await ref.read(todoRepositoryProvider).createTodo(
          familyId: familyId,
          text: text,
          category: category,
          assignedTo: assignedTo,
        );
    ref.invalidateSelf();
  }

  Future<void> toggleDone(String todoId, bool isDone) async {
    // Optimistic update — 즉시 UI 반영
    state = AsyncData(
      (state.value ?? []).map((t) {
        if (t.id != todoId) return t;
        return t.copyWith(
          isDone: isDone,
          completedAt: isDone ? DateTime.now() : null,
        );
      }).toList(),
    );

    try {
      await ref.read(todoRepositoryProvider).toggleDone(todoId, isDone);
    } catch (_) {
      // 실패 시 롤백
      ref.invalidateSelf();
    }
  }

  Future<void> deleteTodo(String todoId) async {
    await ref.read(todoRepositoryProvider).deleteTodo(todoId);
    ref.invalidateSelf();
  }

  Future<void> updateTodo(
    String todoId, {
    String? text,
    String? category,
    String? assignedTo,  // Design Ref: §3.2 — 담당자 파라미터 추가
  }) async {
    await ref.read(todoRepositoryProvider).updateTodo(
          todoId,
          text: text,
          category: category,
          assignedTo: assignedTo,
        );
    ref.invalidateSelf();
  }
}

/// 카테고리 필터 적용된 할 일 목록
@riverpod
List<Todo> filteredTodos(Ref ref) {
  final todos = ref.watch(todoNotifierProvider).valueOrNull ?? [];
  final filter = ref.watch(todoCategoryFilterProvider);
  if (filter == null) return todos;
  return todos.where((t) => t.category == filter).toList();
}
