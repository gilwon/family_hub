// lib/core/push/local_notification.dart
// Design Ref: §7.2 로컬 알림 — 포그라운드 FCM 메시지 표시

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'push_handler.dart';

class LocalNotificationService {
  LocalNotificationService._();
  static final _instance = LocalNotificationService._();
  static LocalNotificationService get instance => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'family_hub_default';
  static const _channelName = '가족 알림';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // FCM이 권한 요청 담당
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      // 포그라운드 로컬 알림 탭 시 payload(route)로 화면 이동
      onDidReceiveNotificationResponse: (details) {
        PushHandler.instance.navigate(details.payload);
      },
    );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();

    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }
}
