// lib/providers/auth_provider.dart
// Design Ref: §3.2 Auth Provider — @riverpod AsyncNotifier 패턴

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/push/fcm_service.dart';
import '../repositories/auth_repository.dart';

part 'auth_provider.g.dart';

// Repository provider
@riverpod
AuthRepository authRepository(Ref ref) => AuthRepository();

/// 인증 상태 스트림 provider
/// User? — 로그인 시 User 객체, 로그아웃 시 null
@riverpod
Stream<User?> authState(Ref ref) {
  return ref
      .read(authRepositoryProvider)
      .authStateChanges
      .map((state) => state.session?.user);
}

/// 현재 유저 편의 provider
@riverpod
User? currentUser(Ref ref) {
  return ref.watch(authStateProvider).valueOrNull;
}

/// 인증 액션 provider (로그인, 회원가입, 로그아웃)
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signUp(
            email: email,
            password: password,
            name: name,
          );
      // 회원가입 성공 후 FCM 토큰 등록
      await FcmService.instance.registerToken();
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      // 로그인 성공 후 FCM 토큰 등록
      await FcmService.instance.registerToken();
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 로그아웃 전 FCM 토큰 삭제 (다른 기기 알림 방지)
      await FcmService.instance.clearToken();
      await ref.read(authRepositoryProvider).signOut();
    });
  }
}
