// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$eventRepositoryHash() => r'd14da7c87af660c685e78b2c7e5bc34754d8acf8';

/// See also [eventRepository].
@ProviderFor(eventRepository)
final eventRepositoryProvider = AutoDisposeProvider<EventRepository>.internal(
  eventRepository,
  name: r'eventRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$eventRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef EventRepositoryRef = AutoDisposeProviderRef<EventRepository>;
String _$filteredEventsHash() => r'aebf3195f9c32872e9395a85796c4b2d36f62f9a';

/// Design Ref: §5.3 filteredEventsProvider — 구성원 필터 적용 이벤트 목록
/// calendar_screen에서 직접 where 처리하지 않고 이 provider를 watch
///
/// Copied from [filteredEvents].
@ProviderFor(filteredEvents)
final filteredEventsProvider =
    AutoDisposeProvider<List<CalendarEvent>>.internal(
      filteredEvents,
      name: r'filteredEventsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$filteredEventsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredEventsRef = AutoDisposeProviderRef<List<CalendarEvent>>;
String _$monthlyEventMapHash() => r'7a9fb7737d106de5eefd5b2ab86651a37f781f31';

/// Design Ref: §5.4 monthlyEventMapProvider — O(1) eventLoader 캐시
/// 날짜(년·월·일) → 이벤트 목록 맵. calendar_screen에서 ref.watch 후 eventLoader에 주입
///
/// Copied from [monthlyEventMap].
@ProviderFor(monthlyEventMap)
final monthlyEventMapProvider =
    AutoDisposeProvider<Map<DateTime, List<CalendarEvent>>>.internal(
      monthlyEventMap,
      name: r'monthlyEventMapProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$monthlyEventMapHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MonthlyEventMapRef =
    AutoDisposeProviderRef<Map<DateTime, List<CalendarEvent>>>;
String _$focusedMonthHash() => r'cbd44e6e302064a56f18080936d227f7d0db47dd';

/// 현재 표시 중인 달 (캘린더 탐색용)
///
/// Copied from [FocusedMonth].
@ProviderFor(FocusedMonth)
final focusedMonthProvider =
    AutoDisposeNotifierProvider<FocusedMonth, DateTime>.internal(
      FocusedMonth.new,
      name: r'focusedMonthProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$focusedMonthHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FocusedMonth = AutoDisposeNotifier<DateTime>;
String _$eventNotifierHash() => r'2cbf19764bc91f84ece2d9e98ad03e1b0f4075ca';

/// 활성 그룹의 일정 목록 (focusedMonth 기준 ±1달 로드)
///
/// Copied from [EventNotifier].
@ProviderFor(EventNotifier)
final eventNotifierProvider =
    AutoDisposeAsyncNotifierProvider<
      EventNotifier,
      List<CalendarEvent>
    >.internal(
      EventNotifier.new,
      name: r'eventNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$eventNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EventNotifier = AutoDisposeAsyncNotifier<List<CalendarEvent>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
