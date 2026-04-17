// lib/providers/family_provider.dart
// Design Ref: §3.3 Family Provider — 다중 그룹 + 활성 그룹 + Realtime 구독
// Plan SC-4: switchFamily 시 이전 구독 해제 후 새 구독 성립

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Family;
import 'package:riverpod_annotation/riverpod_annotation.dart' hide Family;
import '../core/supabase/realtime_service.dart';
import '../models/family.dart';
import '../repositories/family_repository.dart';
import 'auth_provider.dart';
import 'chat_provider.dart';
import 'event_provider.dart';
import 'todo_provider.dart';

part 'family_provider.g.dart';

// Repository provider
@riverpod
FamilyRepository familyRepository(Ref ref) => FamilyRepository();

// RealtimeService provider (싱글턴)
@riverpod
RealtimeService realtimeService(Ref ref) {
  final service = RealtimeService();
  // Provider 해제 시 구독 + StreamController 정리
  ref.onDispose(() async {
    await service.unsubscribeAll();
    service.dispose();
  });
  return service;
}

/// 활성 가족 구성원 userId → Color 맵 (Design Ref: §5.5 familyMemberColorMapProvider)
@riverpod
Map<String, Color> familyMemberColorMap(Ref ref) {
  final members = ref.watch(familyMembersProvider).valueOrNull ?? [];
  return {
    for (final m in members)
      m.userId: m.color != null
          ? Color(int.parse(m.color!.replaceFirst('#', '0xFF')))
          : _hashColor(m.userId),
  };
}

/// userId 해시 기반 결정론적 HSL 색상 (황금각 분포)
Color _hashColor(String userId) {
  final hash = userId.codeUnits.fold(0, (a, b) => a + b);
  final hue = (hash * 137.508) % 360;
  return HSLColor.fromAHSL(1.0, hue, 0.55, 0.50).toColor();
}

/// 다중 가족 그룹 상태 관리
@riverpod
class FamilyNotifier extends _$FamilyNotifier {
  @override
  Future<FamilyState> build() async {
    final userId = ref.watch(currentUserProvider)?.id;
    if (userId == null) return FamilyState.empty();

    final families = await ref.read(familyRepositoryProvider).getMyFamilies();
    final defaultId = families.isNotEmpty ? families.first.id : null;

    if (defaultId != null) {
      await _subscribeRealtime(defaultId);
    }

    return FamilyState(families: families, activeFamilyId: defaultId);
  }

  /// 그룹 전환 — Plan SC-4: unsubscribeAll await 후 새 구독
  Future<void> switchFamily(String familyId) async {
    final current = state.value;
    if (current == null) return;

    // 기존 구독 해제 (await 보장 — 경쟁 조건 방지)
    await ref.read(realtimeServiceProvider).unsubscribeAll();

    state = AsyncData(current.copyWith(activeFamilyId: familyId));

    // 하위 Provider 무효화 (활성 그룹 변경)
    ref.invalidate(familyMembersProvider);

    // 새 구독 시작
    await _subscribeRealtime(familyId);
  }

  Future<void> _subscribeRealtime(String familyId) async {
    ref.read(realtimeServiceProvider).subscribeToFamily(
      familyId,
      onNewMessage: (_) => ref.invalidate(chatNotifierProvider),
      onEventChange: (_) => ref.invalidate(eventNotifierProvider), // M4 Realtime
      onTodoChange: (_) => ref.invalidate(todoNotifierProvider), // M5 Realtime
    );
  }

  /// 그룹 생성 (RPC — 트랜잭션 보장)
  Future<void> createFamily(String name, String emoji) async {
    await ref.read(familyRepositoryProvider).createFamily(name, emoji);
    ref.invalidateSelf();
  }

  /// 초대 코드로 합류
  Future<void> joinByCode(String code, String displayName) async {
    await ref.read(familyRepositoryProvider).joinByCode(code, displayName);
    ref.invalidateSelf();
  }
}

/// 활성 가족 그룹 편의 provider
@riverpod
Family? activeFamily(Ref ref) {
  final state = ref.watch(familyNotifierProvider).valueOrNull;
  if (state == null) return null;
  return state.families
      .where((f) => f.id == state.activeFamilyId)
      .firstOrNull;
}

/// 활성 그룹 구성원 목록
@riverpod
Future<List<FamilyMember>> familyMembers(Ref ref) async {
  final familyId = ref.watch(activeFamilyProvider)?.id;
  if (familyId == null) return [];
  return ref.read(familyRepositoryProvider).getMembers(familyId);
}
