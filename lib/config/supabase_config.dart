// lib/config/supabase_config.dart
// Design Ref: §7 보안 설계 — dart-define 우선, 로컬 개발 시 local_config.dart 폴백

import 'local_config.dart';

class SupabaseConfig {
  // 1순위: --dart-define (CI/CD, 스토어 배포 시 사용)
  // 2순위: local_config.dart (로컬 개발 편의용, gitignore됨)
  static const _dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
  static const _dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url =>
      _dartDefineUrl.isNotEmpty ? _dartDefineUrl : LocalConfig.supabaseUrl;

  static String get anonKey =>
      _dartDefineKey.isNotEmpty ? _dartDefineKey : LocalConfig.supabaseAnonKey;

  /// 앱 시작 시 환경 변수 검증 (값 자체는 로그 출력 금지)
  static void validate() {
    if (url.isEmpty || url.contains('여기에')) {
      throw StateError(
        'Supabase URL이 설정되지 않았습니다.\n'
        'lib/config/local_config.dart에 실제 URL을 입력하거나\n'
        '--dart-define=SUPABASE_URL=https://xxx.supabase.co 를 사용하세요.',
      );
    }
    if (anonKey.isEmpty || anonKey.contains('여기에')) {
      throw StateError(
        'Supabase Anon Key가 설정되지 않았습니다.\n'
        'lib/config/local_config.dart에 실제 키를 입력하거나\n'
        '--dart-define=SUPABASE_ANON_KEY=eyJ... 를 사용하세요.',
      );
    }
  }
}
