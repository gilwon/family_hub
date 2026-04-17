// lib/features/calendar/logic/recurrence_expander.dart
// Design Ref: §5 RecurrenceExpander — 반복 일정 클라이언트 전개
// Plan SC-2: 반복 일정이 월간 뷰에 올바르게 전개

import '../../../models/calendar_event.dart';

/// 반복 일정을 주어진 날짜 범위 내 가상 인스턴스로 전개합니다.
///
/// 규칙:
/// - `monthly` 타입: RFC 5545 준수 — 대상 월에 원본 day가 없으면 해당 월 마지막 날로 clamping
/// - 하드 캡: 규칙당 최대 [_kMaxInstances]개 (무한 루프 방지)
/// - 반복 없는 이벤트는 뷰 범위 안에 있을 때만 포함
class RecurrenceExpander {
  const RecurrenceExpander._();

  static const int _kMaxInstances = 500;

  /// [events]를 [from] ~ [to] 범위로 전개하여 반환합니다.
  ///
  /// 반환 리스트의 반복 인스턴스는 원본 [CalendarEvent]의 [copyWith]로 생성되므로
  /// id, title, memo 등 나머지 필드는 동일합니다.
  static List<CalendarEvent> expand(
    List<CalendarEvent> events, {
    required DateTime from,
    required DateTime to,
  }) {
    final fromDate = _dateOnly(from);
    final toDate = _dateOnly(to);

    final result = <CalendarEvent>[];
    for (final event in events) {
      if (event.recurrence == null) {
        final d = _dateOnly(event.date);
        if (!d.isBefore(fromDate) && !d.isAfter(toDate)) {
          result.add(event);
        }
      } else {
        result.addAll(
          _expandRecurring(event, from: fromDate, to: toDate),
        );
      }
    }
    return result;
  }

  // ── 내부 ──────────────────────────────────────────────────────────────

  static List<CalendarEvent> _expandRecurring(
    CalendarEvent event, {
    required DateTime from,
    required DateTime to,
  }) {
    final rule = event.recurrence!;
    final originalDay = event.date.day; // monthly clamping 기준
    final endDate =
        rule.endDate != null ? _dateOnly(rule.endDate!) : null;

    final instances = <CalendarEvent>[];
    DateTime current = _dateOnly(event.date);
    int count = 0;

    while (!current.isAfter(to) && count < _kMaxInstances) {
      // endDate 초과 시 중단
      if (endDate != null && current.isAfter(endDate)) break;

      if (!current.isBefore(from)) {
        instances.add(event.copyWith(date: current));
      }

      current = _advance(current, rule, originalDay);
      count++;
    }

    return instances;
  }

  /// [current]에서 다음 발생 날짜를 계산합니다.
  static DateTime _advance(
    DateTime current,
    RecurrenceRule rule,
    int originalDay,
  ) {
    return switch (rule.type) {
      'daily' => current.add(Duration(days: rule.interval)),
      'weekly' => current.add(Duration(days: 7 * rule.interval)),
      'monthly' => _nextMonthly(current, rule.interval, originalDay),
      _ => current.add(const Duration(days: 1)),
    };
  }

  /// RFC 5545: monthly 규칙에서 대상 월의 마지막 날로 clamping
  static DateTime _nextMonthly(
    DateTime current,
    int interval,
    int originalDay,
  ) {
    // 월 덧셈 후 연도 롤오버 처리
    final rawMonth = current.month + interval;
    final year = current.year + (rawMonth - 1) ~/ 12;
    final month = ((rawMonth - 1) % 12) + 1;
    // 해당 월의 마지막 날 (DateTime(y, m+1, 0) 트릭)
    final lastDayOfMonth = DateTime(year, month + 1, 0).day;
    final day = originalDay.clamp(1, lastDayOfMonth);
    return DateTime(year, month, day);
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
