// lib/features/family/screens/join_family_screen.dart
// Design Ref: §5.2 FamilyRepository.joinByCode — validate-invite Edge Function
// Plan SC-2: 초대 코드로 합류

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../providers/family_provider.dart';

class JoinFamilyScreen extends ConsumerStatefulWidget {
  const JoinFamilyScreen({super.key});

  @override
  ConsumerState<JoinFamilyScreen> createState() => _JoinFamilyScreenState();
}

class _JoinFamilyScreenState extends ConsumerState<JoinFamilyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _nicknameFocus = FocusNode();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    _nicknameFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref
          .read(familyNotifierProvider.notifier)
          .joinByCode(
            _codeController.text.trim(),
            _nicknameController.text.trim(),
          );

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('합류 실패'),
          description: Text(_friendlyError(e)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _friendlyError(Object? error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('이미 해당 그룹')) return '이미 해당 그룹의 구성원입니다.';
    if (msg.contains('유효하지 않은') || msg.contains('만료')) {
      return '초대 코드가 유효하지 않거나 만료되었습니다.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return '네트워크 연결을 확인해주세요.';
    }
    return '합류 중 오류가 발생했습니다. 코드를 확인하고 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('초대 코드로 합류'), elevation: 0),
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
                  Text(
                    '가족에게 초대 코드를 받아 입력하세요',
                    style: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 초대 코드
                  ShadInputFormField(
                    id: 'code',
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.next,
                    label: const Text('초대 코드'),
                    placeholder: const Text('ABC123'),
                    description: const Text('6자리 영문+숫자 코드'),
                    leading: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.vpn_key_outlined, size: 16),
                    ),
                    onSubmitted: (_) => _nicknameFocus.requestFocus(),
                    validator: (v) {
                      if (v.trim().isEmpty) return '초대 코드를 입력해주세요';
                      if (v.trim().length != 6) return '초대 코드는 6자리입니다';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 닉네임
                  ShadInputFormField(
                    id: 'nickname',
                    controller: _nicknameController,
                    focusNode: _nicknameFocus,
                    textInputAction: TextInputAction.done,
                    label: const Text('이 그룹에서 사용할 닉네임'),
                    placeholder: const Text('예: 엄마, 아빠, 아들, 딸'),
                    leading: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.person_outline, size: 16),
                    ),
                    onSubmitted: (_) => _isLoading ? null : _submit(),
                    validator: (v) {
                      if (v.trim().isEmpty) return '닉네임을 입력해주세요';
                      return null;
                    },
                  ),

                  const Spacer(),

                  // 합류 버튼
                  ShadButton(
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
                        : const Text('합류하기'),
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
