// lib/repositories/notification_repository.dart
// Design Ref: §5.5 NotificationRepository — 알림 목록 + 읽음 처리 + 설정 저장

import '../core/supabase/supabase_client.dart';
import '../models/notification_item.dart';
import '../models/notification_settings.dart';

class NotificationRepository {
  /// 알림 목록 (전체 가족 그룹 통합, 최신순 50개)
  Future<List<NotificationItem>> getNotifications() async {
    final userId = auth.currentUser!.id;
    final result = await db
        .from('notifications')
        .select('*, profiles!triggered_by(name)')
        .eq('target_user', userId)
        .order('created_at', ascending: false)
        .limit(50);

    return (result as List).map((r) => NotificationItem.fromJson(r)).toList();
  }

  /// 읽음 처리 (단일)
  Future<void> markRead(String notificationId) async {
    await db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  /// 전체 읽음 처리 (전체 가족 통합)
  Future<void> markAllRead() async {
    final userId = auth.currentUser!.id;
    await db
        .from('notifications')
        .update({'is_read': true})
        .eq('target_user', userId)
        .eq('is_read', false);
  }

  /// 알림 단건 삭제
  Future<void> deleteNotification(String notificationId) async {
    await db.from('notifications').delete().eq('id', notificationId);
  }

  /// 알림 다건 삭제 (선택 삭제용)
  Future<void> deleteNotifications(List<String> ids) async {
    if (ids.isEmpty) return;
    await db.from('notifications').delete().inFilter('id', ids);
  }

  /// 전체 알림 삭제 (전체 가족 통합)
  Future<void> deleteAll() async {
    final userId = auth.currentUser!.id;
    await db
        .from('notifications')
        .delete()
        .eq('target_user', userId);
  }

  /// 알림 설정 조회
  Future<NotificationSettings> getSettings(String familyId) async {
    final userId = auth.currentUser!.id;
    final result = await db
        .from('family_members')
        .select('notification_settings')
        .eq('family_id', familyId)
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) return NotificationSettings.defaultSettings;
    final json = result['notification_settings'] as Map<String, dynamic>?;
    if (json == null) return NotificationSettings.defaultSettings;
    return NotificationSettings.fromJson(json);
  }

  /// 알림 설정 저장
  Future<void> saveSettings(
      String familyId, NotificationSettings settings) async {
    final userId = auth.currentUser!.id;
    await db
        .from('family_members')
        .update({'notification_settings': settings.toJson()})
        .eq('family_id', familyId)
        .eq('user_id', userId);
  }
}
