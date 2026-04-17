// lib/features/todo/screens/todo_screen.dart
// Design Ref: §F-04 할 일 — CRUD + 완료 토글 + 카테고리 필터 + Realtime
// Design Ref: §3.4 — 담당자 subtitle 표시 (familyMembersProvider)

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/error_message.dart';
import '../../../models/family.dart';
import '../../../models/todo.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/todo_provider.dart';
import '../widgets/todo_toggle_chip.dart';

class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(todoNotifierProvider);
    final filtered = ref.watch(filteredTodosProvider);
    final activeFilter = ref.watch(todoCategoryFilterProvider);
    final theme = ShadTheme.of(context);
    // Design Ref: §3.4 — 담당자 역매핑용 멤버 목록
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];

    return Scaffold(
      body: Column(
        children: [
          // 카테고리 필터 버튼
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                TodoToggleChip(
                  label: '전체',
                  selected: activeFilter == null,
                  onTap: () => ref
                      .read(todoCategoryFilterProvider.notifier)
                      .setCategory(null),
                ),
                const SizedBox(width: 8),
                ...AppConstants.todoCategories.map((cat) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TodoToggleChip(
                        label: cat,
                        selected: activeFilter == cat,
                        onTap: () => ref
                            .read(todoCategoryFilterProvider.notifier)
                            .setCategory(cat),
                      ),
                    )),
              ],
            ),
          ),
          Divider(height: 1, color: theme.colorScheme.border),

          // 할 일 목록
          Expanded(
            child: todosAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(friendlyError(e))),
              data: (_) {
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_box_outlined,
                          size: 56,
                          color: theme.colorScheme.mutedForeground
                              .withValues(alpha: 0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '할 일이 없습니다',
                          style: TextStyle(
                            color: theme.colorScheme.mutedForeground,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(
                    indent: 16,
                    endIndent: 16,
                    height: 1,
                    color: theme.colorScheme.border,
                  ),
                  itemBuilder: (context, i) {
                    final todo = filtered[i];
                    return Dismissible(
                      key: ValueKey(todo.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.colorScheme.destructive,
                        child: Icon(
                          Icons.delete,
                          color: theme.colorScheme.destructiveForeground,
                        ),
                      ),
                      confirmDismiss: (_) => _confirmDelete(context),
                      onDismissed: (_) => ref
                          .read(todoNotifierProvider.notifier)
                          .deleteTodo(todo.id),
                      child: ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (v) => ref
                              .read(todoNotifierProvider.notifier)
                              .toggleDone(todo.id, v ?? false),
                        ),
                        title: Text(
                          todo.text,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            color: todo.isDone
                                ? theme.colorScheme.mutedForeground
                                : null,
                          ),
                        ),
                        subtitle: _buildSubtitle(todo, members, theme),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: theme.colorScheme.mutedForeground,
                          ),
                          onPressed: () => context.push(
                            '/todo/edit/${todo.id}',
                            extra: todo,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/todo/new'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.primaryForeground,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Design Ref: §3.4 — 카테고리 · 담당자 subtitle 조합
  Widget? _buildSubtitle(
    Todo todo,
    List<FamilyMember> members,
    ShadThemeData theme,
  ) {
    final parts = <String>[];
    if (todo.category != null) parts.add(todo.category!);
    if (todo.assignedTo != null) {
      final member =
          members.firstWhereOrNull((m) => m.userId == todo.assignedTo);
      if (member != null) {
        parts.add('담당: ${member.emoji ?? ''} ${member.displayName}'.trim());
      }
    }
    if (parts.isEmpty) return null;
    return Text(
      parts.join(' · '),
      style: TextStyle(
        fontSize: 12,
        color: theme.colorScheme.mutedForeground,
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('삭제'),
        content: const Text('이 할 일을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: ShadTheme.of(ctx).colorScheme.destructive,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

