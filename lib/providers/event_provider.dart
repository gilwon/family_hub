// lib/providers/event_provider.dart
// Design Ref: §3 상태 관리 — EventNotifier (activeFamily 기반)
// Design Ref: §5.2 Option C — eventsChanged Stream listen + invalidateSelf()

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide Family;
import '../features/calendar/logic/recurrence_expander.dart';
import '../models/calendar_event.dart';
import '../repositories/event_repository.dart';
import 'event_filter_provider.dart';
import 'family_provider.dart';

part 'event_provider.g.dart';

@riverpod
EventRepository eventRepository(Ref ref) => EventRepository();

/// 현재 표시 중인 달 (캘린더 탐색용)
@riverpod
class FocusedMonth extends _$FocusedMonth {
  @override
  DateTime build() => DateTime.now();

  void setMonth(DateTime month) {
    state = DateTime(month.year, month.month, 1);
  }
}

/// 활성 그룹의 일정 목록 (focusedMonth 기준 ±1달 로드)
@riverpod
class EventNotifier extends _$EventNotifier {
  @override
  Future<List<CalendarEvent>> build() async {
    final familyId = ref.watch(activeFamilyProvider)?.id;
    if (familyId == null) return [];

    final focused = ref.watch(focusedMonthProvider);
    // 화면에 표시할 범위: 이전 달 ~ 다음 달
    final viewFrom = DateTime(focused.year, focused.month - 1, 1);
    final viewTo = DateTime(focused.year, focused.month + 2, 0);

    // Design Ref: §5.2 Option C — RealtimeService.eventsChanged 스트림 구독
    // Provider가 자기 lifecycle을 소유 → 그룹 전환/재빌드 시 구독이 함께 해제됨
    final svc = ref.watch(realtimeServiceProvider);
    StreamSubscription<void>? sub;
    sub = svc.eventsChanged.listen((_) {
      // microtask: build 콜백 내 동기 invalidateSelf() 방지
      Future.microtask(ref.invalidateSelf);
    });
    ref.onDispose(() => sub?.cancel());

    // A-7 수정: 반복 일정은 2년 lookback, 비반복은 뷰 범위만 조회
    final repo = ref.read(eventRepositoryProvider);
    final recurring = await repo.getRecurringEvents(familyId, to: viewTo);
    final nonRecurring = await repo.getEvents(
      familyId,
      from: viewFrom,
      to: viewTo,
      excludeRecurring: true,
    );
    final raw = [...recurring, ...nonRecurring];

    // 반복 일정 전개 — 뷰 범위 내 인스턴스만 포함
    return RecurrenceExpander.expand(raw, from: viewFrom, to: viewTo);
  }

  Future<void> createEvent({
    required String title,
    required DateTime date,
    String? time,
    String? memo,
    RecurrenceRule? recurrence,
  }) async {
    final familyId = ref.read(activeFamilyProvider)?.id;
    if (familyId == null) throw Exception('활성 가족 그룹이 없습니다. 그룹을 선택해주세요.');

    await ref.read(eventRepositoryProvider).createEvent(
          familyId: familyId,
          title: title,
          date: date,
          time: time,
          memo: memo,
          recurrence: recurrence,
        );
    ref.invalidateSelf();
  }

  Future<void> updateEvent(
    String eventId, {
    String? title,
    DateTime? date,
    String? time,
    String? memo,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
  }) async {
    await ref.read(eventRepositoryProvider).updateEvent(
          eventId,
          title: title,
          date: date,
          time: time,
          memo: memo,
          recurrence: recurrence,
          clearRecurrence: clearRecurrence,
        );
    ref.invalidateSelf();
  }

  Future<void> deleteEvent(String eventId) async {
    await ref.read(eventRepositoryProvider).deleteEvent(eventId);
    ref.invalidateSelf();
  }
}

/// Design Ref: §5.3 filteredEventsProvider — 구성원 필터 적용 이벤트 목록
/// calendar_screen에서 직접 where 처리하지 않고 이 provider를 watch
@riverpod
List<CalendarEvent> filteredEvents(Ref ref) {
  final allEvents = ref.watch(eventNotifierProvider).valueOrNull ?? [];
  final filterIds = ref.watch(eventFilterProvider);
  if (filterIds.isEmpty) return allEvents;
  return allEvents.where((e) => filterIds.contains(e.createdBy)).toList();
}

/// Design Ref: §5.4 monthlyEventMapProvider — O(1) eventLoader 캐시
/// 날짜(년·월·일) → 이벤트 목록 맵. calendar_screen에서 ref.watch 후 eventLoader에 주입
@riverpod
Map<DateTime, List<CalendarEvent>> monthlyEventMap(Ref ref) {
  final events = ref.watch(filteredEventsProvider);
  final map = <DateTime, List<CalendarEvent>>{};
  for (final e in events) {
    final key = DateTime(e.date.year, e.date.month, e.date.day);
    map.putIfAbsent(key, () => []).add(e);
  }
  return map;
}

