// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_filter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventFilterHash() => r'c5e8d381953b279b4e4c69cffe1e960fe33a3a1f';

/// 현재 보여줄 구성원 userId Set.
/// 비어 있으면 "전체 표시" (필터 없음).
///
/// Copied from [EventFilter].
@ProviderFor(EventFilter)
final eventFilterProvider =
    AutoDisposeNotifierProvider<EventFilter, Set<String>>.internal(
      EventFilter.new,
      name: r'eventFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$eventFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EventFilter = AutoDisposeNotifier<Set<String>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
