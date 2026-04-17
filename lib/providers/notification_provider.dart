// lib/providers/notification_provider.dart
// Design Ref: §3.5 NotificationProvider — 알림 목록 + 설정

import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide Family;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notification_item.dart';
import '../models/notification_settings.dart';
import '../repositories/notification_repository.dart';
import 'family_provider.dart';

part 'notification_provider.g.dart';

@riverpod
NotificationRepository notificationRepository(Ref ref) =>
    NotificationRepository();

/// 알림 목록
@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  @override
  Future<List<NotificationItem>> build() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return [];

    // Realtime 구독 — 나를 대상으로 한 새 알림이 DB에 INSERT될 때 즉시 반영
    final channel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'target_user',
            value: userId,
          ),
          callback: (payload) {
            // Realtime payload에는 profiles join 없음 — triggeredByName은 null (body에 이름 포함)
            final newItem = NotificationItem.fromJson(payload.newRecord);
            final current = state.valueOrNull ?? [];
            state = AsyncData([newItem, ...current]);
          },
        )
        .subscribe();

    // provider dispose 시 채널 해제
    ref.onDispose(() => Supabase.instance.client.removeChannel(channel));

    return ref.read(notificationRepositoryProvider).getNotifications();
  }

  Future<void> markRead(String notificationId) async {
    await ref
        .read(notificationRepositoryProvider)
        .markRead(notificationId);

    // 낙관적 업데이트
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current
        .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
        .toList());
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();

    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.map((n) => n.copyWith(isRead: true)).toList());
  }

  Future<void> deleteNotification(String notificationId) async {
    await ref
        .read(notificationRepositoryProvider)
        .deleteNotification(notificationId);

    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.where((n) => n.id != notificationId).toList());
  }

  Future<void> deleteNotifications(List<String> ids) async {
    await ref
        .read(notificationRepositoryProvider)
        .deleteNotifications(ids);

    final current = state.valueOrNull;
    if (current == null) return;
    final idSet = ids.toSet();
    state = AsyncData(current.where((n) => !idSet.contains(n.id)).toList());
  }

  Future<void> deleteAll() async {
    await ref.read(notificationRepositoryProvider).deleteAll();
    state = const AsyncData([]);
  }
}

/// 읽지 않은 알림 수 (뱃지용)
@riverpod
int unreadCount(Ref ref) {
  final notifications =
      ref.watch(notificationNotifierProvider).valueOrNull ?? [];
  return notifications.where((n) => !n.isRead).length;
}

/// 알림 설정
@riverpod
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  Future<NotificationSettings> build() async {
    final familyId = ref.watch(activeFamilyProvider)?.id;
    if (familyId == null) return NotificationSettings.defaultSettings;
    return ref
        .read(notificationRepositoryProvider)
        .getSettings(familyId);
  }

  Future<void> save(NotificationSettings settings) async {
    final familyId = ref.read(activeFamilyProvider)?.id;
    if (familyId == null) return;

    // 낙관적 업데이트
    state = AsyncData(settings);
    await ref
        .read(notificationRepositoryProvider)
        .saveSettings(familyId, settings);
  }
}
