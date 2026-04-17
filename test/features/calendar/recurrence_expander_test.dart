// test/features/calendar/recurrence_expander_test.dart
// Design Ref: §8.1 단위 테스트 — RecurrenceExpander EC-1~EC-9

import 'package:flutter_test/flutter_test.dart';
import 'package:family_hub/features/calendar/logic/recurrence_expander.dart';
import 'package:family_hub/models/calendar_event.dart';

CalendarEvent _event({
  required DateTime date,
  RecurrenceRule? recurrence,
}) =>
    CalendarEvent(
      id: 'test-id',
      familyId: 'family-1',
      createdBy: 'user-1',
      title: '테스트 일정',
      date: date,
      createdAt: date,
      recurrence: recurrence,
    );

void main() {
  group('RecurrenceExpander', () {
    final viewFrom = DateTime(2024, 3, 1);
    final viewTo = DateTime(2024, 3, 31);

    // EC-1: 반복 없는 일정 — 뷰 범위 안에 있으면 포함
    test('EC-1: 비반복 일정은 뷰 범위 내에서만 반환', () {
      final inRange = _event(date: DateTime(2024, 3, 15));
      final outRange = _event(date: DateTime(2024, 2, 15));
      final result = RecurrenceExpander.expand(
        [inRange, outRange],
        from: viewFrom,
        to: viewTo,
      );
      expect(result.length, 1);
      expect(result.first.date, DateTime(2024, 3, 15));
    });

    // EC-2: daily 반복 — 뷰 범위 내 인스턴스 수 확인
    test('EC-2: daily 반복 일정은 매일 인스턴스 생성', () {
      final event = _event(
        date: DateTime(2024, 2, 28), // 뷰 범위 이전 시작
        recurrence: RecurrenceRule(type: 'daily', interval: 1),
      );
      final result = RecurrenceExpander.expand(
        [event],
        from: viewFrom,
        to: viewTo,
      );
      expect(result.length, 31); // 3/1~3/31 = 31일
    });

    // EC-3: weekly 반복 — 매주 인스턴스 수
    test('EC-3: weekly 반복 일정은 매주 인스턴스 생성', () {
      final event = _event(
        date: DateTime(2024, 3, 1), // 금요일
        recurrence: RecurrenceRule(type: 'weekly', interval: 1),
      );
      final result = RecurrenceExpander.expand(
        [event],
        from: viewFrom,
        to: viewTo,
      );
      // 3/1, 3/8, 3/15, 3/22, 3/29 = 5번
      expect(result.length, 5);
    });

    // EC-4: monthly 반복 — 같은 날 인스턴스
    test('EC-4: monthly 반복은 같은 날(15일)에 인스턴스 생성', () {
      final event = _event(
        date: DateTime(2024, 1, 15),
        recurrence: RecurrenceRule(type: 'monthly', interval: 1),
      );
      final march = RecurrenceExpander.expand(
        [event],
        from: DateTime(2024, 3, 1),
        to: DateTime(2024, 3, 31),
      );
      expect(march.length, 1);
      expect(march.first.date, DateTime(2024, 3, 15));
    });

    // EC-5: monthly 31일 → 2월 말일 clamping (RFC 5545)
    test('EC-5: monthly 31일 반복은 2월에 마지막 날(28/29)로 clamping', () {
      final event = _event(
        date: DateTime(2024, 1, 31),
        recurrence: RecurrenceRule(type: 'monthly', interval: 1),
      );
      // 2024년은 윤년 (2/29)
      final feb = RecurrenceExpander.expand(
        [event],
        from: DateTime(2024, 2, 1),
        to: DateTime(2024, 2, 29),
      );
      expect(feb.length, 1);
      expect(feb.first.date, DateTime(2024, 2, 29));
    });

    // EC-6: monthly 31일 → 2월 (비윤년)
    test('EC-6: monthly 31일 반복은 비윤년 2월에 28일로 clamping', () {
      final event = _event(
        date: DateTime(2023, 1, 31),
        recurrence: RecurrenceRule(type: 'monthly', interval: 1),
      );
      final feb = RecurrenceExpander.expand(
        [event],
        from: DateTime(2023, 2, 1),
        to: DateTime(2023, 2, 28),
      );
      expect(feb.length, 1);
      expect(feb.first.date, DateTime(2023, 2, 28));
    });

    // EC-7: endDate 이후 인스턴스 제외
    test('EC-7: endDate 이후 인스턴스는 생성되지 않음', () {
      final event = _event(
        date: DateTime(2024, 3, 1),
        recurrence: RecurrenceRule(
          type: 'daily',
          interval: 1,
          endDate: DateTime(2024, 3, 10),
        ),
      );
      final result = RecurrenceExpander.expand(
        [event],
        from: viewFrom,
        to: viewTo,
      );
      expect(result.length, 10); // 3/1~3/10
      expect(result.last.date, DateTime(2024, 3, 10));
    });

    // EC-8: 500개 하드 캡 — 일평 daily 무한 반복은 최대 500개
    test('EC-8: 500개 하드 캡 적용', () {
      final event = _event(
        date: DateTime(2020, 1, 1),
        recurrence: RecurrenceRule(type: 'daily', interval: 1),
      );
      final result = RecurrenceExpander.expand(
        [event],
        from: DateTime(2020, 1, 1),
        to: DateTime(2030, 12, 31), // 10년
      );
      expect(result.length, lessThanOrEqualTo(500));
    });

    // EC-9: 빈 목록 입력
    test('EC-9: 빈 이벤트 목록은 빈 결과 반환', () {
      final result = RecurrenceExpander.expand(
        [],
        from: viewFrom,
        to: viewTo,
      );
      expect(result, isEmpty);
    });

    // 추가: interval=2 weekly
    test('interval=2 주 2회 반복', () {
      final event = _event(
        date: DateTime(2024, 3, 1),
        recurrence: RecurrenceRule(type: 'weekly', interval: 2),
      );
      final result = RecurrenceExpander.expand(
        [event],
        from: viewFrom,
        to: viewTo,
      );
      // 3/1, 3/15, 3/29 = 3번
      expect(result.length, 3);
    });

    // 추가: 연도 롤오버 (12월 → 1월)
    test('monthly 12월에서 1월로 연도 롤오버', () {
      final event = _event(
        date: DateTime(2023, 12, 31),
        recurrence: RecurrenceRule(type: 'monthly', interval: 1),
      );
      final jan = RecurrenceExpander.expand(
        [event],
        from: DateTime(2024, 1, 1),
        to: DateTime(2024, 1, 31),
      );
      expect(jan.length, 1);
      expect(jan.first.date, DateTime(2024, 1, 31));
    });
  });
}
