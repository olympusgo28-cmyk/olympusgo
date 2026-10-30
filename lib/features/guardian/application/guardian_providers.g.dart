// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guardian_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// What the signed-in player may do. Null when signed out.

@ProviderFor(restrictions)
final restrictionsProvider = RestrictionsProvider._();

/// What the signed-in player may do. Null when signed out.

final class RestrictionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Restrictions?>,
          Restrictions?,
          FutureOr<Restrictions?>
        >
    with $FutureModifier<Restrictions?>, $FutureProvider<Restrictions?> {
  /// What the signed-in player may do. Null when signed out.
  RestrictionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'restrictionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$restrictionsHash();

  @$internal
  @override
  $FutureProviderElement<Restrictions?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Restrictions?> create(Ref ref) {
    return restrictions(ref);
  }
}

String _$restrictionsHash() => r'cd42f79c4350238e9dd61d81b5763ec83cbb9161';

@ProviderFor(myChildren)
final myChildrenProvider = MyChildrenProvider._();

final class MyChildrenProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GuardianLink>>,
          List<GuardianLink>,
          FutureOr<List<GuardianLink>>
        >
    with
        $FutureModifier<List<GuardianLink>>,
        $FutureProvider<List<GuardianLink>> {
  MyChildrenProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myChildrenProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myChildrenHash();

  @$internal
  @override
  $FutureProviderElement<List<GuardianLink>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GuardianLink>> create(Ref ref) {
    return myChildren(ref);
  }
}

String _$myChildrenHash() => r'cd112a63c6b7a255b0b47ef6d00618adc4240e0f';

@ProviderFor(myParents)
final myParentsProvider = MyParentsProvider._();

final class MyParentsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GuardianLink>>,
          List<GuardianLink>,
          FutureOr<List<GuardianLink>>
        >
    with
        $FutureModifier<List<GuardianLink>>,
        $FutureProvider<List<GuardianLink>> {
  MyParentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myParentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myParentsHash();

  @$internal
  @override
  $FutureProviderElement<List<GuardianLink>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GuardianLink>> create(Ref ref) {
    return myParents(ref);
  }
}

String _$myParentsHash() => r'8cb3e08a3307c49b76b7e2f9af1c2e3a233c3889';

@ProviderFor(childPosts)
final childPostsProvider = ChildPostsFamily._();

final class ChildPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChildPost>>,
          List<ChildPost>,
          FutureOr<List<ChildPost>>
        >
    with $FutureModifier<List<ChildPost>>, $FutureProvider<List<ChildPost>> {
  ChildPostsProvider._({
    required ChildPostsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'childPostsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$childPostsHash();

  @override
  String toString() {
    return r'childPostsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ChildPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChildPost>> create(Ref ref) {
    final argument = this.argument as String;
    return childPosts(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChildPostsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$childPostsHash() => r'7a66b40b5ee4d064c1271f3b6d90dc49d9963565';

final class ChildPostsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ChildPost>>, String> {
  ChildPostsFamily._()
    : super(
        retry: null,
        name: r'childPostsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChildPostsProvider call(String childId) =>
      ChildPostsProvider._(argument: childId, from: this);

  @override
  String toString() => r'childPostsProvider';
}

@ProviderFor(childGroupRequests)
final childGroupRequestsProvider = ChildGroupRequestsFamily._();

final class ChildGroupRequestsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupRequest>>,
          List<GroupRequest>,
          FutureOr<List<GroupRequest>>
        >
    with
        $FutureModifier<List<GroupRequest>>,
        $FutureProvider<List<GroupRequest>> {
  ChildGroupRequestsProvider._({
    required ChildGroupRequestsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'childGroupRequestsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$childGroupRequestsHash();

  @override
  String toString() {
    return r'childGroupRequestsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GroupRequest>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupRequest>> create(Ref ref) {
    final argument = this.argument as String;
    return childGroupRequests(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChildGroupRequestsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$childGroupRequestsHash() =>
    r'2fa6f3da17838bec7a1a130199d6d31eec12cdda';

final class ChildGroupRequestsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<GroupRequest>>, String> {
  ChildGroupRequestsFamily._()
    : super(
        retry: null,
        name: r'childGroupRequestsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChildGroupRequestsProvider call(String childId) =>
      ChildGroupRequestsProvider._(argument: childId, from: this);

  @override
  String toString() => r'childGroupRequestsProvider';
}
