// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'family_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$familyRepositoryHash() => r'75896f230ed087f11246519b8cc844be0a3c50d2';

/// See also [familyRepository].
@ProviderFor(familyRepository)
final familyRepositoryProvider = AutoDisposeProvider<FamilyRepository>.internal(
  familyRepository,
  name: r'familyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$familyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FamilyRepositoryRef = AutoDisposeProviderRef<FamilyRepository>;
String _$realtimeServiceHash() => r'28207e5afbdc2159f7d2d29dd39b1724a602b287';

/// See also [realtimeService].
@ProviderFor(realtimeService)
final realtimeServiceProvider = AutoDisposeProvider<RealtimeService>.internal(
  realtimeService,
  name: r'realtimeServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$realtimeServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RealtimeServiceRef = AutoDisposeProviderRef<RealtimeService>;
String _$familyMemberColorMapHash() =>
    r'639dc1af78ac194432967ecab64fb886b7cf771e';

/// 활성 가족 구성원 userId → Color 맵 (Design Ref: §5.5 familyMemberColorMapProvider)
///
/// Copied from [familyMemberColorMap].
@ProviderFor(familyMemberColorMap)
final familyMemberColorMapProvider =
    AutoDisposeProvider<Map<String, Color>>.internal(
      familyMemberColorMap,
      name: r'familyMemberColorMapProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$familyMemberColorMapHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FamilyMemberColorMapRef = AutoDisposeProviderRef<Map<String, Color>>;
String _$activeFamilyHash() => r'e2bd8f151feabe5ba23157dd683460cfe8b2bb45';

/// 활성 가족 그룹 편의 provider
///
/// Copied from [activeFamily].
@ProviderFor(activeFamily)
final activeFamilyProvider = AutoDisposeProvider<Family?>.internal(
  activeFamily,
  name: r'activeFamilyProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$activeFamilyHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ActiveFamilyRef = AutoDisposeProviderRef<Family?>;
String _$familyMembersHash() => r'44ef17e9852a39b1f1abddb432c4e0b76291c3f2';

/// 활성 그룹 구성원 목록
///
/// Copied from [familyMembers].
@ProviderFor(familyMembers)
final familyMembersProvider =
    AutoDisposeFutureProvider<List<FamilyMember>>.internal(
      familyMembers,
      name: r'familyMembersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$familyMembersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FamilyMembersRef = AutoDisposeFutureProviderRef<List<FamilyMember>>;
String _$familyNotifierHash() => r'd5df9e5638c99bb6f17bc60e80161a68b39285bb';

/// 다중 가족 그룹 상태 관리
///
/// Copied from [FamilyNotifier].
@ProviderFor(FamilyNotifier)
final familyNotifierProvider =
    AutoDisposeAsyncNotifierProvider<FamilyNotifier, FamilyState>.internal(
      FamilyNotifier.new,
      name: r'familyNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$familyNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FamilyNotifier = AutoDisposeAsyncNotifier<FamilyState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
