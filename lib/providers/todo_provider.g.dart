// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todoRepositoryHash() => r'c1010635ce61bed1c092c70b2c77f5146bbd2077';

/// See also [todoRepository].
@ProviderFor(todoRepository)
final todoRepositoryProvider = AutoDisposeProvider<TodoRepository>.internal(
  todoRepository,
  name: r'todoRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$todoRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TodoRepositoryRef = AutoDisposeProviderRef<TodoRepository>;
String _$filteredTodosHash() => r'a51fba0359c29c576f714ba5a8c0c0aa9be89b2e';

/// 카테고리 필터 적용된 할 일 목록
///
/// Copied from [filteredTodos].
@ProviderFor(filteredTodos)
final filteredTodosProvider = AutoDisposeProvider<List<Todo>>.internal(
  filteredTodos,
  name: r'filteredTodosProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$filteredTodosHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FilteredTodosRef = AutoDisposeProviderRef<List<Todo>>;
String _$todoCategoryFilterHash() =>
    r'55f75a9e7cc5b2ee50a0807f4d88d91818994e25';

/// 선택된 카테고리 필터 (null = 전체)
///
/// Copied from [TodoCategoryFilter].
@ProviderFor(TodoCategoryFilter)
final todoCategoryFilterProvider =
    AutoDisposeNotifierProvider<TodoCategoryFilter, String?>.internal(
      TodoCategoryFilter.new,
      name: r'todoCategoryFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$todoCategoryFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TodoCategoryFilter = AutoDisposeNotifier<String?>;
String _$todoNotifierHash() => r'ca0f75514585c7c3259ca95c484a3d52baebec66';

/// 활성 그룹의 할 일 목록
///
/// Copied from [TodoNotifier].
@ProviderFor(TodoNotifier)
final todoNotifierProvider =
    AutoDisposeAsyncNotifierProvider<TodoNotifier, List<Todo>>.internal(
      TodoNotifier.new,
      name: r'todoNotifierProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$todoNotifierHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TodoNotifier = AutoDisposeAsyncNotifier<List<Todo>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
