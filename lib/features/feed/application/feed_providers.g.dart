// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(feedStatus)
final feedStatusProvider = FeedStatusProvider._();

final class FeedStatusProvider
    extends
        $FunctionalProvider<
          AsyncValue<FeedStatus>,
          FeedStatus,
          FutureOr<FeedStatus>
        >
    with $FutureModifier<FeedStatus>, $FutureProvider<FeedStatus> {
  FeedStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'feedStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedStatusHash();

  @$internal
  @override
  $FutureProviderElement<FeedStatus> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<FeedStatus> create(Ref ref) {
    return feedStatus(ref);
  }
}

String _$feedStatusHash() => r'f435544d75bc3f264ed90b04937cdcfc6af0e6ca';

@ProviderFor(feedFollowing)
final feedFollowingProvider = FeedFollowingProvider._();

final class FeedFollowingProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedPost>>,
          List<FeedPost>,
          FutureOr<List<FeedPost>>
        >
    with $FutureModifier<List<FeedPost>>, $FutureProvider<List<FeedPost>> {
  FeedFollowingProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'feedFollowingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedFollowingHash();

  @$internal
  @override
  $FutureProviderElement<List<FeedPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedPost>> create(Ref ref) {
    return feedFollowing(ref);
  }
}

String _$feedFollowingHash() => r'65b62837c9aead2be726de4466da10fab2c2b5af';

@ProviderFor(feedDiscover)
final feedDiscoverProvider = FeedDiscoverProvider._();

final class FeedDiscoverProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedPost>>,
          List<FeedPost>,
          FutureOr<List<FeedPost>>
        >
    with $FutureModifier<List<FeedPost>>, $FutureProvider<List<FeedPost>> {
  FeedDiscoverProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'feedDiscoverProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$feedDiscoverHash();

  @$internal
  @override
  $FutureProviderElement<List<FeedPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedPost>> create(Ref ref) {
    return feedDiscover(ref);
  }
}

String _$feedDiscoverHash() => r'cf44edb2a93722d344a614e978e27050a7bd8d7f';

/// Asks again while a post is being checked, and stops when the screen closes.

@ProviderFor(myPosts)
final myPostsProvider = MyPostsProvider._();

/// Asks again while a post is being checked, and stops when the screen closes.

final class MyPostsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<FeedPost>>,
          List<FeedPost>,
          FutureOr<List<FeedPost>>
        >
    with $FutureModifier<List<FeedPost>>, $FutureProvider<List<FeedPost>> {
  /// Asks again while a post is being checked, and stops when the screen closes.
  MyPostsProvider._()
    : super(
        from: null,
        argument: null,
        retry: _noRetry,
        name: r'myPostsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myPostsHash();

  @$internal
  @override
  $FutureProviderElement<List<FeedPost>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<FeedPost>> create(Ref ref) {
    return myPosts(ref);
  }
}

String _$myPostsHash() => r'708c09a771983f5b0e14176146f6b94d58282af4';

/// Short-lived links, so they're fetched for the list on show. [ids] is
/// comma-separated, so a family key compares by value.

@ProviderFor(feedPosters)
final feedPostersProvider = FeedPostersFamily._();

/// Short-lived links, so they're fetched for the list on show. [ids] is
/// comma-separated, so a family key compares by value.

final class FeedPostersProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, String>>,
          Map<String, String>,
          FutureOr<Map<String, String>>
        >
    with
        $FutureModifier<Map<String, String>>,
        $FutureProvider<Map<String, String>> {
  /// Short-lived links, so they're fetched for the list on show. [ids] is
  /// comma-separated, so a family key compares by value.
  FeedPostersProvider._({
    required FeedPostersFamily super.from,
    required String super.argument,
  }) : super(
         retry: _noRetry,
         name: r'feedPostersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedPostersHash();

  @override
  String toString() {
    return r'feedPostersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, String>> create(Ref ref) {
    final argument = this.argument as String;
    return feedPosters(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FeedPostersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedPostersHash() => r'29a9eb7324d48f764d33f78e8d1efd7f6b4872b6';

/// Short-lived links, so they're fetched for the list on show. [ids] is
/// comma-separated, so a family key compares by value.

final class FeedPostersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Map<String, String>>, String> {
  FeedPostersFamily._()
    : super(
        retry: _noRetry,
        name: r'feedPostersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Short-lived links, so they're fetched for the list on show. [ids] is
  /// comma-separated, so a family key compares by value.

  FeedPostersProvider call(String ids) =>
      FeedPostersProvider._(argument: ids, from: this);

  @override
  String toString() => r'feedPostersProvider';
}

/// Posts on their way up from this phone.

@ProviderFor(PostUploads)
final postUploadsProvider = PostUploadsProvider._();

/// Posts on their way up from this phone.
final class PostUploadsProvider
    extends $NotifierProvider<PostUploads, Set<String>> {
  /// Posts on their way up from this phone.
  PostUploadsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postUploadsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postUploadsHash();

  @$internal
  @override
  PostUploads create() => PostUploads();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$postUploadsHash() => r'239172542eabe3cef8e0af6b361a61996305bace';

/// Posts on their way up from this phone.

abstract class _$PostUploads extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(postPlayerMaker)
final postPlayerMakerProvider = PostPlayerMakerProvider._();

final class PostPlayerMakerProvider
    extends
        $FunctionalProvider<PostPlayerMaker, PostPlayerMaker, PostPlayerMaker>
    with $Provider<PostPlayerMaker> {
  PostPlayerMakerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postPlayerMakerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postPlayerMakerHash();

  @$internal
  @override
  $ProviderElement<PostPlayerMaker> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  PostPlayerMaker create(Ref ref) {
    return postPlayerMaker(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostPlayerMaker value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostPlayerMaker>(value),
    );
  }
}

String _$postPlayerMakerHash() => r'207cfc1953983413a805c3bef04a0b079b86c2c8';
