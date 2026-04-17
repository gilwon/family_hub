// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationRepositoryHash() =>
    r'71219757436a2e8f634f48d840b62059d3d54f21';

/// See also [notificationRepository].
@ProviderFor(notificationRepository)
final notificationRepositoryProvider =
    AutoDisposeProvider<NotificationRepository>.internal(
      notificationRepository,
      name: r'notificationRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationRepositoryRef =
    AutoDisposeProviderRef<NotificationRepository>;
String _$unreadCountHash() => r'ace7460b0e5c69160110beea41371ef5fd5171b6';

/// 읽지 않은 알림 수 (뱃지용)
///
/// Copied from [unreadCount].
@ProviderFor(unreadCount)
final unreadCountProvider = AutoDisposeProvider<int>.internal(
  unreadCount,
  name: r'unreadCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadCountRef = AutoDisposeProviderRef<int>;
String _$notificationNotifierHash() =>
    r'954a954ea1112eb30c1087898bef1bf25d70164f';

/// 알림 목록
///
/// Copied from [NotificationNotifier].
@ProviderFor(NotificationNotifier)
final notificationNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      NotificationNotifier,
      List<NotificationItem>
    >.internal(
      NotificationNotifier.new,
      name: r'notificationNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationNotifier =
    AutoDisposeAsyncNotifier<List<NotificationItem>>;
String _$notificationSettingsNotifierHash() =>
    r'b5e26a9fe4b18dd0640c61e45c9c3579514f0957';

/// 알림 설정
///
/// Copied from [NotificationSettingsNotifier].
@ProviderFor(NotificationSettingsNotifier)
final notificationSettingsNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      NotificationSettingsNotifier,
      NotificationSettings
    >.internal(
      NotificationSettingsNotifier.new,
      name: r'notificationSettingsNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationSettingsNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationSettingsNotifier =
    AutoDisposeAsyncNotifier<NotificationSettings>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
