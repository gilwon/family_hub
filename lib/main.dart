// lib/main.dart
// Design Ref: §7 보안 설계 — dart-define 환경 변수, 로그 미출력
// Plan SC-5: Supabase 키 하드코딩 금지

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'config/supabase_config.dart';
import 'core/push/local_notification.dart';
import 'core/push/push_handler.dart';
import 'firebase_options.dart';

final _log = Logger();

// FCM 백그라운드 메시지 핸들러 (최상위 함수 필수)
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 백그라운드: FCM이 시스템 알림 자동 표시
}

/// Firebase 초기화 — 앱 시작과 별도로 비동기 실행
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await LocalNotificationService.instance.init();
    await PushHandler.instance.init();
    _log.i('Firebase initialized');
  } catch (e) {
    _log.w('Firebase initialization failed: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 한국어 날짜 포맷 초기화 (table_calendar 한국어 표시)
  await initializeDateFormatting('ko_KR');

  // 1) 환경 변수 검증 (값은 로그 출력 금지)
  SupabaseConfig.validate();

  // 2) Supabase 초기화
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );
  _log.i('Supabase initialized');

  // 3) Firebase 초기화 — 앱 시작을 블로킹하지 않도록 unawaited 처리
  // requestPermission 등 FCM 작업이 완료되지 않아도 앱이 정상 실행됨
  _initFirebase();

  // 4) 앱 시작 시 Supabase 연결 헬스체크 (Plan SC-6)
  try {
    await Supabase.instance.client
        .from('profiles')
        .select('id')
        .limit(1);
    _log.i('Supabase health check passed');
  } catch (e) {
    _log.w('Supabase health check failed: $e');
    // 오프라인 모드 처리는 M9에서 추가
  }

  runApp(const ProviderScope(child: FamilyHubApp()));
}
