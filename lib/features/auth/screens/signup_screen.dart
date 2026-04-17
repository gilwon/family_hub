// lib/features/auth/screens/signup_screen.dart
// Design Ref: §3.2 Auth Provider, §10.3 에러 처리 패턴
// Plan SC-1: 이메일 회원가입 플로우

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmFocus = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authNotifierProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
        );

    if (!mounted) return;

    final authState = ref.read(authNotifierProvider);
    if (authState.hasError) {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          title: const Text('회원가입 실패'),
          description: Text(_friendlyError(authState.error)),
        ),
      );
    }
  }

  String _friendlyError(Object? error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('already registered') || msg.contains('already exists')) {
      return '이미 사용 중인 이메일입니다.';
    }
    if (msg.contains('password') && msg.contains('weak')) {
      return '비밀번호가 너무 단순합니다. 더 복잡한 비밀번호를 사용해주세요.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return '네트워크 연결을 확인해주세요.';
    }
    return '회원가입 중 오류가 발생했습니다. 다시 시도해주세요.';
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
                        '새 계정 만들기',
                        style: TextStyle(
                          color: ShadTheme.of(context).colorScheme.mutedForeground,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // 이름
                      ShadInputFormField(
                        id: 'name',
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        label: const Text('이름'),
                        placeholder: const Text('홍길동'),
                        leading: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.person_outline, size: 16),
                        ),
                        onSubmitted: (_) => _emailFocus.requestFocus(),
                        validator: (v) {
                          if (v.trim().isEmpty) return '이름을 입력해주세요';
                          if (v.trim().length < 2) return '이름은 2자 이상이어야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 이메일
                      ShadInputFormField(
                        id: 'email',
                        controller: _emailController,
                        focusNode: _emailFocus,
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
                        textInputAction: TextInputAction.next,
                        label: const Text('비밀번호'),
                        placeholder: const Text('6자 이상 입력하세요'),
                        leading: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.lock_outlined, size: 16),
                        ),
                        onSubmitted: (_) => _confirmFocus.requestFocus(),
                        validator: (v) {
                          if (v.isEmpty) return '비밀번호를 입력해주세요';
                          if (v.length < 6) return '비밀번호는 6자 이상이어야 합니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 비밀번호 확인
                      ShadInputFormField(
                        id: 'confirm_password',
                        controller: _confirmPasswordController,
                        focusNode: _confirmFocus,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        label: const Text('비밀번호 확인'),
                        placeholder: const Text('비밀번호를 다시 입력하세요'),
                        leading: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.lock_outlined, size: 16),
                        ),
                        onSubmitted: (_) => isLoading ? null : _submit(),
                        validator: (v) {
                          if (v.isEmpty) return '비밀번호를 다시 입력해주세요';
                          if (v != _passwordController.text) return '비밀번호가 일치하지 않습니다';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // 회원가입 버튼
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
                            : const Text('회원가입'),
                      ),
                      const SizedBox(height: 12),

                      // 로그인 링크
                      ShadButton.ghost(
                        width: double.infinity,
                        onPressed: isLoading ? null : () => context.go('/login'),
                        child: const Text('이미 계정이 있으신가요? 로그인'),
                      ),
                      const SizedBox(height: 24),
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
