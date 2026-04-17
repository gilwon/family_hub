// lib/core/push/fcm_service.dart
// Design Ref: §7.1 FCM 서비스 — 토큰 등록 + 갱신
// CLAUDE.md §5: service_role_key 절대 클라이언트 포함 금지
// FCM 토큰은 profiles.fcm_token 에 저장 (로그인 시 + 토큰 갱신 시)

import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import '../supabase/supabase_client.dart';

class FcmService {
  FcmService._();
  static final _instance = FcmService._();
  static FcmService get instance => _instance;

  StreamSubscription<String>? _tokenRefreshSub;

  /// 로그인/회원가입 후 호출 — FCM 토큰을 profiles 테이블에 저장
  /// Firebase 미설정(google-services.json 없음) 시 예외를 무시하고 정상 진행
  Future<void> registerToken() async {
    final userId = auth.currentUser?.id;
    if (userId == null) return;

    // 기존 리스너 정리 (재로그인 시 누적 방지)
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await _saveToken(userId, token);

      // 토큰 갱신 시 자동 업데이트
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _saveToken(userId, newToken);
      });
    } catch (_) {
      // Firebase 미설정 환경에서는 FCM 없이 DB 알림만 동작
    }
  }

  /// 로그아웃 시 토큰 삭제 (다른 기기 알림 방지)
  Future<void> clearToken() async {
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;

    final userId = auth.currentUser?.id;
    if (userId == null) return;

    // DB 업데이트와 Firebase 삭제를 각각 독립적으로 처리
    try {
      await db.from('profiles').update({'fcm_token': null}).eq('id', userId);
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  Future<void> _saveToken(String userId, String token) async {
    await db
        .from('profiles')
        .update({'fcm_token': token})
        .eq('id', userId);
  }
}
