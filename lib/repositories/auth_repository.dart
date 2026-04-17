// lib/repositories/auth_repository.dart
// Design Ref: §5.1 AuthRepository — Supabase 쿼리 캡슐화

import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase/supabase_client.dart';

class AuthRepository {
  /// 인증 상태 변경 스트림 (로그인/로그아웃 감지)
  Stream<AuthState> get authStateChanges => auth.onAuthStateChange;

  /// 현재 로그인된 유저 (없으면 null)
  User? get currentUser => auth.currentUser;

  /// 현재 세션 (GoRouter 가드에서 사용)
  Session? get currentSession => auth.currentSession;

  /// 이메일 회원가입
  /// handle_new_user 트리거가 profiles 자동 생성
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    await auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  /// 이메일 로그인
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// 로그아웃
  Future<void> signOut() async => auth.signOut();
}
