// lib/features/auth/screens/login_screen.dart
// Design Ref: §3.2 Auth Provider, §10.3 에러 처리 패턴
// Plan SC-1: 이메일 로그인 플로우

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('로그인 실패'),
          description: Text(_friendlyError(authState.error)),
        ),
      );
    }
  }

  String _friendlyError(Object? error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('invalid') || msg.contains('credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return '네트워크 연결을 확인해주세요.';
    }
    return '로그인 중 오류가 발생했습니다. 다시 시도해주세요.';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authNotifierProvider).isLoading;

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Family Hub',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '가족과 함께하는 일정 허브',
                        style: TextStyle(
                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // 이메일
                      ShadInputFormField(
                        id: 'email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        label: const Text('이메일'),
                        placeholder: const Text('name@example.com'),
                        leading: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.email_outlined, size: 16),
                        ),
                        onSubmitted: (_) => _passwordFocus.requestFocus(),
                        validator: (v) {
                          if (v.trim().isEmpty) return '이메일을 입력해주세요';
                          if (!v.contains('@')) return '올바른 이메일 형식이 아닙니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호
                      ShadInputFormField(
                        id: 'password',
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        label: const Text('비밀번호'),
                        placeholder: const Text('••••••••'),
                        leading: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.lock_outlined, size: 16),
                        ),
                        onSubmitted: (_) => isLoading ? null : _submit(),
                        validator: (v) {
                          if (v.isEmpty) return '비밀번호를 입력해주세요';
                          if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 로그인 버튼
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
                            : const Text('로그인'),
                      ),
                      const SizedBox(height: 12),

                      // 회원가입 링크
                      ShadButton.ghost(
                        width: double.infinity,
                        onPressed: isLoading ? null : () => context.go('/signup'),
                        child: const Text('계정이 없으신가요? 회원가입'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
