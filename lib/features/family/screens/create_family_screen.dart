// lib/features/family/screens/create_family_screen.dart
// Design Ref: §5.2 FamilyRepository.createFamily — RPC 원자적 생성
// Plan SC-1: 그룹 생성 전체 플로우

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../core/utils/constants.dart';
import '../../../providers/family_provider.dart';

class CreateFamilyScreen extends ConsumerStatefulWidget {
  const CreateFamilyScreen({super.key});

  @override
  ConsumerState<CreateFamilyScreen> createState() => _CreateFamilyScreenState();
}

class _CreateFamilyScreenState extends ConsumerState<CreateFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedEmoji = '👨‍👩‍👧‍👦';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    try {
      await ref.read(familyNotifierProvider.notifier).createFamily(
            _nameController.text.trim(),
            _selectedEmoji,
          );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('이미 같은 이름')
          ? '이미 같은 이름의 그룹이 있습니다.\n다른 이름을 사용해주세요.'
          : '그룹 생성 중 오류가 발생했습니다.\n$e';
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('그룹 생성 실패'),
          description: Text(msg),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(familyNotifierProvider).isLoading;
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('새 가족 그룹 만들기'),
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 이모지 선택 카드
                  ShadCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '그룹 이모지',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.familyEmojis.map((emoji) {
                            final isSelected = emoji == _selectedEmoji;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedEmoji = emoji),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.muted,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.border,
                                    width: isSelected ? 2.5 : 1.0,
                                  ),
                                ),
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 그룹 이름 입력
                  ShadInputFormField(
                    id: 'name',
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    label: const Text('그룹 이름'),
                    placeholder: const Text('예: 우리 가족, 시댁, 친정'),
                    leading: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.group_outlined, size: 16),
                    ),
                    onSubmitted: (_) => isLoading ? null : _submit(),
                    validator: (v) {
                      if (v.trim().isEmpty) return '그룹 이름을 입력해주세요';
                      if (v.trim().length < 2) return '그룹 이름은 2자 이상이어야 합니다';
                      return null;
                    },
                  ),

                  const Spacer(),

                  // 생성 버튼
                  ShadButton(
                    width: double.infinity,
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('그룹 만들기'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
