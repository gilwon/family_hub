// lib/features/todo/screens/todo_form_screen.dart
// Design Ref: §F-04 할 일 생성/수정 폼
// Design Ref: §3.3 — 담당자 칩 UI (_selectedAssignee + familyMembersProvider)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/error_message.dart';
import '../../../models/todo.dart';
import '../../../providers/family_provider.dart';
import '../../../providers/todo_provider.dart';
import '../widgets/todo_toggle_chip.dart';

class TodoFormScreen extends ConsumerStatefulWidget {
  const TodoFormScreen({super.key, this.todo});
  final Todo? todo;

  @override
  ConsumerState<TodoFormScreen> createState() => _TodoFormScreenState();
}

class _TodoFormScreenState extends ConsumerState<TodoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;
  String? _selectedCategory;
  String? _selectedAssignee; // userId 또는 null
  bool _isLoading = false;

  bool get isEditing => widget.todo != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.todo?.text ?? '');
    _selectedCategory = widget.todo?.category;
    _selectedAssignee = widget.todo?.assignedTo; // Design Ref: §3.3 initState
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        await ref.read(todoNotifierProvider.notifier).updateTodo(
              widget.todo!.id,
              text: _textController.text.trim(),
              category: _selectedCategory,
              assignedTo: _selectedAssignee, // Design Ref: §3.3
            );
      } else {
        await ref.read(todoNotifierProvider.notifier).createTodo(
              text: _textController.text.trim(),
              category: _selectedCategory,
              assignedTo: _selectedAssignee, // Design Ref: §3.3
            );
      }
      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('저장 실패'),
          description: Text(friendlyError(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // Design Ref: §3.3 — 담당자 칩 목록 (loading 시 빈 배열로 안전 처리)
    final members = ref.watch(familyMembersProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? '할 일 수정' : '새 할 일'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ShadButton(
              size: ShadButtonSize.sm,
              onPressed: _isLoading ? null : _submit,
              child: _isLoading
                  ? const SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('저장'),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 할 일 입력
                  ShadInputFormField(
                    id: 'text',
                    controller: _textController,
                    textInputAction: TextInputAction.done,
                    label: const Text('할 일'),
                    placeholder: const Text('무엇을 해야 하나요?'),
                    leading: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.check_box_outline_blank, size: 16),
                    ),
                    autofocus: !isEditing,
                    maxLines: 2,
                    onSubmitted: (_) => _isLoading ? null : _submit(),
                    validator: (v) {
                      if (v.trim().isEmpty) return '할 일을 입력해주세요';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // 카테고리 선택
                  Text(
                    '카테고리',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: theme.colorScheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TodoToggleChip(
                        label: '없음',
                        selected: _selectedCategory == null,
                        onTap: () => setState(() => _selectedCategory = null),
                      ),
                      ...AppConstants.todoCategories.map(
                        (cat) => TodoToggleChip(
                          label: cat,
                          selected: _selectedCategory == cat,
                          onTap: () => setState(() => _selectedCategory = cat),
                        ),
                      ),
                    ],
                  ),

                  // 담당자 선택 (Design Ref: §3.3)
                  if (members.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      '담당자',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TodoToggleChip(
                          label: '없음',
                          selected: _selectedAssignee == null,
                          onTap: () =>
                              setState(() => _selectedAssignee = null),
                        ),
                        ...members.map(
                          (m) => TodoToggleChip(
                            label: '${m.emoji ?? '👤'} ${m.displayName}',
                            selected: _selectedAssignee == m.userId,
                            onTap: () =>
                                setState(() => _selectedAssignee = m.userId),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ShadButton(
            width: double.infinity,
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(isEditing ? '할 일 수정' : '할 일 저장'),
          ),
        ),
      ),
    );
  }
}

