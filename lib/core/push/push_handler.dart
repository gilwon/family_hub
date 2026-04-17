// lib/core/push/push_handler.dart
// Design Ref: §7.3 푸시 핸들러 — 포그라운드/백그라운드/종료 상태 메시지 라우팅
// CLAUDE.md §7: FCM 딥링크 타이밍 이슈 — GoRouter 마운트 후 처리

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'local_notification.dart';

class PushHandler {
  PushHandler._();
  static final _instance = PushHandler._();
  static PushHandler get instance => _instance;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // 1) 권한 요청 (iOS)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2) 포그라운드 메시지 → 로컬 알림으로 표시
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      if (notification != null) {
        LocalNotificationService.instance.show(
          id: message.hashCode,
          title: notification.title ?? '',
          body: notification.body ?? '',
          payload: message.data['route'] as String?,
        );
      }
    });

    // 3) 백그라운드에서 탭해서 앱 진입 (GoRouter 마운트 후 처리)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleRoute(message.data['route'] as String?);
    });

    // 4) 앱 종료 상태에서 탭하여 진입 — GoRouter 마운트 완료 후 처리
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      // 마운트 완료를 기다린 후 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleRoute(initial.data['route'] as String?);
      });
    }
  }

  /// 외부(LocalNotificationService 등)에서 라우팅 트리거
  void navigate(String? route) => _handleRoute(route);

  void _handleRoute(String? route) {
    if (route == null || route.isEmpty) return;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    try {
      GoRouter.of(context).go(route);
    } catch (_) {
      // 라우트가 없거나 처리 불가한 경우 무시
    }
  }
}
