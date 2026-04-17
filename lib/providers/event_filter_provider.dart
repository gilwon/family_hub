// lib/providers/event_filter_provider.dart
// Design Ref: §3.6 EventFilterProvider — 구성원 필터 상태

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'event_filter_provider.g.dart';

/// 현재 보여줄 구성원 userId Set.
/// 비어 있으면 "전체 표시" (필터 없음).
@riverpod
class EventFilter extends _$EventFilter {
  @override
  Set<String> build() => {};

  /// 구성원 토글: 이미 있으면 제거, 없으면 추가
  void toggle(String userId) {
    final next = Set<String>.from(state);
    if (next.contains(userId)) {
      next.remove(userId);
    } else {
      next.add(userId);
    }
    state = next;
  }

  /// 전체 선택/전체 해제
  void setAll(List<String> userIds) {
    state = Set<String>.from(userIds);
  }

  void clearAll() {
    state = {};
  }
}
