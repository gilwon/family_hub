// lib/repositories/todo_repository.dart
// Design Ref: §5 Repository 설계 — Supabase 쿼리 캡슐화

import '../core/supabase/supabase_client.dart';
import '../models/todo.dart';

class TodoRepository {
  /// 활성 그룹의 할 일 목록 (미완료 우선, 생성 역순)
  Future<List<Todo>> getTodos(String familyId) async {
    final res = await db
        .from('todos')
        .select()
        .eq('family_id', familyId)
        .order('is_done')
        .order('created_at', ascending: false);

    return (res as List).map((r) => Todo.fromJson(r)).toList();
  }

  /// 할 일 생성
  Future<Todo> createTodo({
    required String familyId,
    required String text,
    String? category,
    String? assignedTo,
  }) async {
    final userId = auth.currentUser!.id;
    final res = await db.from('todos').insert({
      'family_id': familyId,
      'created_by': userId,
      'text': text,
      'category': category,
      'assigned_to': assignedTo,
      'is_done': false,
    }).select().maybeSingle();

    if (res == null) throw Exception('할 일 생성에 실패했습니다');
    return Todo.fromJson(res);
  }

  /// 완료 토글
  Future<void> toggleDone(String todoId, bool isDone) async {
    await db.from('todos').update({
      'is_done': isDone,
      'completed_at': isDone ? DateTime.now().toIso8601String() : null,
    }).eq('id', todoId);
  }

  /// 내용 수정
  // null 전달 시 DB 필드 클리어 (기존 값 유지 아님) — category, assignedTo 모두 동일
  Future<void> updateTodo(
    String todoId, {
    String? text,
    String? category,
    String? assignedTo,
  }) async {
    final updates = <String, dynamic>{};
    if (text != null) updates['text'] = text;
    updates['category'] = category;
    updates['assigned_to'] = assignedTo;  // null이면 DB 클리어 (category와 동일하게)

    await db.from('todos').update(updates).eq('id', todoId);
  }

  /// 삭제
  Future<void> deleteTodo(String todoId) async {
    await db.from('todos').delete().eq('id', todoId);
  }
}
