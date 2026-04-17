// lib/core/utils/error_message.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 내부 오류를 사용자 친화적 메시지로 변환
/// 상세 오류는 로거로만 출력 (UI 노출 금지 — CLAUDE.md §5)
String friendlyError(Object? error) {
  if (error == null) return '알 수 없는 오류가 발생했습니다.';
  if (error is PostgrestException) return '데이터 처리 중 오류가 발생했습니다.';
  if (error is AuthException) return '인증 오류가 발생했습니다. 다시 로그인해주세요.';
  final msg = error.toString().toLowerCase();
  if (msg.contains('network') || msg.contains('connection') || msg.contains('socket')) {
    return '네트워크 연결을 확인해주세요.';
  }
  return '오류가 발생했습니다. 다시 시도해주세요.';
}
