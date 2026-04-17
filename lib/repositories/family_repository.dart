// lib/repositories/family_repository.dart
// Design Ref: §5.2 FamilyRepository — Supabase 쿼리 캡슐화
// Plan SC-2: 초대 코드로 합류 → validate-invite Edge Function 경유

import '../core/supabase/supabase_client.dart';
import '../core/utils/constants.dart';
import '../models/family.dart';

class FamilyRepository {
  /// 내가 속한 모든 가족 그룹 조회
  Future<List<Family>> getMyFamilies() async {
    final userId = auth.currentUser!.id;

    // 1단계: 내가 속한 family_id 목록 조회
    final memberRows = await db
        .from('family_members')
        .select('family_id')
        .eq('user_id', userId);

    final familyIds = (memberRows as List)
        .map((r) => r['family_id'] as String)
        .toList();

    if (familyIds.isEmpty) return [];

    // 2단계: family_id 목록으로 그룹 정보 조회 (생성순 정렬 — 활성 그룹 일관성)
    final familyRows = await db
        .from('families')
        .select()
        .inFilter('id', familyIds)
        .order('created_at');

    return (familyRows as List)
        .map((r) => Family.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// 원자적 그룹 생성 (RPC — 트랜잭션 보장)
  Future<Family> createFamily(String name, String emoji) async {
    final userId = auth.currentUser!.id;
    final res = await db.rpc('create_family_with_admin', params: {
      'p_name': name,
      'p_emoji': emoji,
      'p_user_id': userId,
    });
    return Family.fromJson(res as Map<String, dynamic>);
  }

  /// 초대 코드로 합류 — validate-invite Edge Function으로 서버 검증
  Future<void> joinByCode(String code, String displayName) async {
    final userId = auth.currentUser!.id;

    // 1) Edge Function으로 서버 측 시간 검증 (클라이언트 시간 조작 방지)
    final res = await db.functions.invoke('validate-invite', body: {
      'code': code.toUpperCase(),
    });

    if (res.status != 200) {
      final errorMsg = (res.data as Map?)?['error'] ?? '유효하지 않은 초대 코드입니다';
      throw Exception(errorMsg);
    }

    final familyId = (res.data as Map)['family_id'] as String;

    // 2) 중복 합류 확인 (.maybeSingle() — .single() 크래시 방지)
    final existing = await db
        .from('family_members')
        .select('id')
        .eq('user_id', userId)
        .eq('family_id', familyId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('이미 해당 그룹의 구성원입니다');
    }

    // 3) 구성원 등록
    await db.from('family_members').insert({
      'user_id': userId,
      'family_id': familyId,
      'display_name': displayName,
    });
  }

  /// 그룹 구성원 목록 조회
  Future<List<FamilyMember>> getMembers(String familyId) async {
    final res = await db
        .from('family_members')
        .select('*, profiles!user_id(name, avatar_url)')
        .eq('family_id', familyId)
        .order('joined_at');

    return (res as List).map((r) => FamilyMember.fromJson(r)).toList();
  }

  /// 내 프로필(닉네임·이모지·색상) 수정
  Future<void> updateMyProfile(
    String familyId, {
    String? displayName,
    String? emoji,
    String? color,
  }) async {
    final userId = auth.currentUser!.id;
    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (emoji != null) updates['emoji'] = emoji;
    if (color != null) updates['color'] = color;
    if (updates.isEmpty) return;

    await db
        .from('family_members')
        .update(updates)
        .eq('user_id', userId)
        .eq('family_id', familyId);
  }

  /// 초대 링크 토큰 조회
  Future<String> getInviteLink(String familyId) async {
    final res = await db
        .from('families')
        .select('invite_link_token')
        .eq('id', familyId)
        .maybeSingle();

    if (res == null) throw Exception('그룹을 찾을 수 없습니다');
    return '${AppConstants.inviteBaseUrl}/invite/${res['invite_link_token']}';
  }

  /// 초대 코드 재생성 (admin 전용 — 함수 내부에서 권한 검증)
  Future<void> regenerateInvite(String familyId) async {
    await db.rpc('regenerate_invite', params: {'p_family_id': familyId});
  }

  /// 구성원 내보내기 (admin 전용 — RLS delete 정책)
  Future<void> removeMember(String familyId, String targetUserId) async {
    await db
        .from('family_members')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', targetUserId);
  }
}
