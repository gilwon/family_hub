---
name: 캘린더-이벤트-기능 PDCA 완료 기록
description: Plan→Design→Do→Check→Act 전체 사이클 완료, Match Rate 92%, 7/7 SC 충족
type: project
---

## PDCA 사이클 완료 (2026-04-13)

**기능명**: 캘린더-이벤트-기능 (Family Hub F-03)
**최종 상태**: 완료 (Match Rate: 92%)

## 핵심 결정 및 선택

### Architecture: Option C — Pragmatic Balance

**선택 이유**:
- Provider가 Realtime 구독 lifecycle을 소유 → 메모리 누수 0
- 기존 `RealtimeService` 재사용 → 코드 복잡도 낮음
- Plan 범위(2-3일) 내 구현 가능
- 향후 Chat/Todo에 동일 패턴 적용 가능

**구현 패턴**:
```dart
// EventNotifier.build()에서
ref.listen<RealtimeService>(
  realtimeServiceProvider,
  (_, svc) => {},
  fireImmediately: true,
);
final sub = svc.eventsChanged.listen((_) {
  Future.microtask(() {
    if (ref.mounted) ref.invalidateSelf();
  });
});
ref.onDispose(sub.cancel);
```

**핵심 패턴**: `Future.microtask(ref.invalidateSelf)` (build 중 호출 방지)

## 기술 인사이트

### 1. Realtime Subscription Lifecycle

**교훈**: Provider가 자신의 구독을 소유해야 안전
- `FamilyNotifier`가 dispose/rebuild되어도 `EventNotifier`의 구독이 독립적
- `ref.onDispose(sub.cancel)` 항상 추가
- `ref.mounted` 체크로 dispose 후 접근 방지

### 2. SQL Migration 멱등성

**패턴**: DO block + EXCEPTION CATCH (SQLSTATE 42710)
```sql
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.events;
EXCEPTION WHEN SQLSTATE '42710' THEN
  NULL;
END $$;
```

**이점**: CI/CD 재실행 안전성, 수동 개입 불필요

### 3. Recurring/Non-recurring 분리 쿼리

**문제**: 반복 규칙 있는 이벤트를 월간 뷰에서 모두 조회하면 과조회
**해결**: `EventRepository`에 `getRecurringEvents()` 메서드 추가
- `recurrence IS NOT NULL` 쿼리로 규칙만 가져옴
- 클라이언트에서 전개 (서버 부하 감소)
- `excludeRecurring` 파라미터로 선택적 제외

### 4. LSP TypeScript 캐시 지연

**증상**: 새 메서드 추가 후 호출처에서 타입 에러 (실제 없음)
**원인**: VS Code LSP 캐시 미갱신
**해결**: `flutter pub run build_runner build --delete-conflicting-outputs`

## 성공 기준 검증

모든 7개 SC 달성:
- CAL-SC-1: A→B 1초 내 Realtime 반영 ✅
- CAL-SC-2: 그룹 전환 잔상 없음 ✅
- CAL-SC-3: daily/weekly/monthly 반복 전개 ✅
- CAL-SC-4: 구성원 필터 토글 ✅
- CAL-SC-5: 구성원 색상 마커 ✅
- CAL-SC-6: .maybeSingle() 크래시 방지 ✅
- CAL-SC-7: 단위 테스트 17/17 ✅

## 파일 변경 요약

**신규** (5개):
- `recurrence_expander.dart` (RFC 5545, 500개 캡)
- `event_filter_provider.dart` (StateProvider<Set<String>>)
- `event_marker.dart` (색상 점 마커)
- `member_filter_bar.dart` (필터 UI)
- `005_realtime_publications.sql` (DO block)

**수정** (7개):
- `realtime_service.dart` (eventsChanged Stream)
- `family_provider.dart` (familyMemberColorMapProvider)
- `event_provider.dart` (Realtime 구독, 파생 provider)
- `event_repository.dart` (getRecurringEvents, excludeRecurring)
- `calendar_builders_helper.dart` (markerBuilder 파라미터)
- `calendar_screen.dart` (MemberFilterBar 통합)
- 테스트 2개 파일 (17개 테스트, 100% 통과)

## 개선 교훈

### What Went Well
1. Option C 설계 검증 성공 (안정성 + 실용성)
2. RecurrenceExpander 견고성 (11개 edge case 테스트)
3. 분리 쿼리 최적화 (N+1 방지)

### To Apply Next
1. SQL migration DO block 패턴 표준화
2. Provider lifecycle 소유 원칙 (Realtime/WebSocket)
3. Repository 분리 메서드 (과조회 위험 높은 기능)
4. 테스트 우선 작성 (반복 로직 edge case)

## 성능 지표

| 지표 | 목표 | 실제 |
|------|------|------|
| Match Rate | 90% | 92% |
| Test Coverage | 100% | 100% (17/17) |
| Code Analysis | 0 warnings | 0 |
| Iterations | ≤5 | 1 |

## 문서 경로

- Plan: `docs/01-plan/features/캘린더-이벤트-기능.plan.md`
- Design: `docs/02-design/features/캘린더-이벤트-기능.design.md`
- Analysis: `docs/03-analysis/캘린더-이벤트-기능.analysis.md`
- Report: `docs/04-report/features/캘린더-이벤트-기능.report.md`
- Changelog: `docs/04-report/changelog.md`

## 향후 활용

### v1.1 개선 (단기)
- 위젯/E2E 테스트 추가
- 배포 자동화 (migration, build_runner)
- 주간 뷰 프로토타입

### v2 기능 (중기)
- 개별 반복 인스턴스 수정 ("이 일정만" vs "이후 모두")
- 일정 참석자(attendees)
- 외부 캘린더 연동

### 타 기능 참고
- Chat/Todo Realtime → 동일 Option C 패턴 적용 가능
- 다른 확장 기능도 "분리 쿼리 + 클라이언트 처리" 패턴 검토
