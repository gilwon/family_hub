// lib/core/utils/constants.dart

class AppConstants {
  AppConstants._();

  // 앱 기본 설정
  static const appName = 'Family Hub';
  static const appVersion = '1.0.0';

  // 채팅
  static const chatPageSize = 30;

  // 초대 코드
  static const inviteCodeLength = 6;

  // 투두 카테고리
  static const todoCategories = ['장보기', '집안일', '기타'];

  // 알림 리마인더 옵션 (분)
  static const reminderOptions = [15, 30, 60];

  // Storage 버킷
  static const chatImagesBucket = 'chat-images';

  // 딥링크 스킴 (dart-define 우선, 없으면 기본값)
  static const inviteBaseUrl = String.fromEnvironment(
    'INVITE_BASE_URL',
    defaultValue: 'https://familyhub.app',
  );

  /// @deprecated inviteBaseUrl 사용 권장
  static const inviteLinkBase = '$inviteBaseUrl/invite/';

  // 가족 그룹 이모지 선택지
  static const familyEmojis = [
    '👨‍👩‍👧‍👦', // 가족
    '🏡', // 집
    '❤️', // 하트
    '🌈', // 무지개
    '⭐', // 별
    '🎉', // 파티
    '🌸', // 벚꽃
    '🌻', // 해바라기
    '🍀', // 네잎클로버
    '🦋', // 나비
    '🎵', // 음악
    '🌙', // 달
  ];

  // 기본 멤버 색상 팔레트
  static const memberColors = [
    '#818cf8', // indigo
    '#34d399', // emerald
    '#f87171', // red
    '#fb923c', // orange
    '#a78bfa', // violet
    '#38bdf8', // sky
    '#facc15', // yellow
    '#4ade80', // green
  ];
}
