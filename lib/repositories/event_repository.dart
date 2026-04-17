// lib/repositories/event_repository.dart
// Design Ref: §5.4 EventRepository — Supabase 쿼리 캡슐화

import '../core/supabase/supabase_client.dart';
import '../models/calendar_event.dart';

class EventRepository {
  /// 기간 내 일정 조회 (월 단위)
  ///
  /// [excludeRecurring] = true 이면 recurrence가 NULL인 이벤트만 반환
  Future<List<CalendarEvent>> getEvents(
    String familyId, {
    required DateTime from,
    required DateTime to,
    bool excludeRecurring = false,
  }) async {
    var query = db
        .from('events')
        .select()
        .eq('family_id', familyId)
        .gte('date', from.toIso8601String().substring(0, 10))
        .lte('date', to.toIso8601String().substring(0, 10));

    if (excludeRecurring) {
      query = query.isFilter('recurrence', null);
    }

    final res = await query
        .order('date')
        .order('time', ascending: true, nullsFirst: true);

    return (res as List).map((r) => CalendarEvent.fromJson(r)).toList();
  }

  /// 반복 일정만 조회 (recurrence IS NOT NULL, [to] 이전에 시작한 것)
  /// A-7 수정: 비반복 이벤트는 포함하지 않아 과조회 방지
  Future<List<CalendarEvent>> getRecurringEvents(
    String familyId, {
    required DateTime to,
  }) async {
    final res = await db
        .from('events')
        .select()
        .eq('family_id', familyId)
        .not('recurrence', 'is', null)
        .lte('date', to.toIso8601String().substring(0, 10))
        .order('date')
        .order('time', ascending: true, nullsFirst: true);

    return (res as List).map((r) => CalendarEvent.fromJson(r)).toList();
  }

  /// 일정 생성
  Future<CalendarEvent> createEvent({
    required String familyId,
    required String title,
    required DateTime date,
    String? time,
    String? memo,
    RecurrenceRule? recurrence,
  }) async {
    final userId = auth.currentUser!.id;
    final res = await db.from('events').insert({
      'family_id': familyId,
      'created_by': userId,
      'title': title,
      'date': date.toIso8601String().substring(0, 10),
      'time': time,
      'memo': memo,
      'recurrence': recurrence?.toJson(),
    }).select().maybeSingle();

    if (res == null) throw Exception('일정 생성에 실패했습니다');
    return CalendarEvent.fromJson(res);
  }

  /// 일정 수정 — time·memo·recurrence 는 null 전달 시 DB에서 클리어
  Future<void> updateEvent(
    String eventId, {
    String? title,
    DateTime? date,
    String? time,
    String? memo,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (date != null) updates['date'] = date.toIso8601String().substring(0, 10);
    // null 이면 DB 필드를 명시적으로 비움 (기존 값 유지가 아님)
    updates['time'] = time;
    updates['memo'] = memo;
    updates['recurrence'] = clearRecurrence ? null : recurrence?.toJson();

    await db.from('events').update(updates).eq('id', eventId);
  }

  /// 일정 삭제
  Future<void> deleteEvent(String eventId) async {
    await db.from('events').delete().eq('id', eventId);
  }
}
