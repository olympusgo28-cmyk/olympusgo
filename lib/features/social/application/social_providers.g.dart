// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(playerDetail)
final playerDetailProvider = PlayerDetailFamily._();

final class PlayerDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerDetail>,
          PlayerDetail,
          FutureOr<PlayerDetail>
        >
    with $FutureModifier<PlayerDetail>, $FutureProvider<PlayerDetail> {
  PlayerDetailProvider._({
    required PlayerDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'playerDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$playerDetailHash();

  @override
  String toString() {
    return r'playerDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerDetail> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerDetail> create(Ref ref) {
    final argument = this.argument as String;
    return playerDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlayerDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$playerDetailHash() => r'a3f9c537cb44646e5787e8dbd8859444bff48959';

final class PlayerDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerDetail>, String> {
  PlayerDetailFamily._()
    : super(
        retry: null,
        name: r'playerDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  PlayerDetailProvider call(String id) =>
      PlayerDetailProvider._(argument: id, from: this);

  @override
  String toString() => r'playerDetailProvider';
}

@ProviderFor(followersOf)
final followersOfProvider = FollowersOfFamily._();

final class FollowersOfProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerSummary>>,
          List<PlayerSummary>,
          FutureOr<List<PlayerSummary>>
        >
    with
        $FutureModifier<List<PlayerSummary>>,
        $FutureProvider<List<PlayerSummary>> {
  FollowersOfProvider._({
    required FollowersOfFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'followersOfProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followersOfHash();

  @override
  String toString() {
    return r'followersOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return followersOf(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowersOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followersOfHash() => r'b8224e968c2414feb8fabaa69da07639d492565a';

final class FollowersOfFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerSummary>>, String> {
  FollowersOfFamily._()
    : super(
        retry: null,
        name: r'followersOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FollowersOfProvider call(String id) =>
      FollowersOfProvider._(argument: id, from: this);

  @override
  String toString() => r'followersOfProvider';
}

@ProviderFor(followingOf)
final followingOfProvider = FollowingOfFamily._();

final class FollowingOfProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlayerSummary>>,
          List<PlayerSummary>,
          FutureOr<List<PlayerSummary>>
        >
    with
        $FutureModifier<List<PlayerSummary>>,
        $FutureProvider<List<PlayerSummary>> {
  FollowingOfProvider._({
    required FollowingOfFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'followingOfProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$followingOfHash();

  @override
  String toString() {
    return r'followingOfProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlayerSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlayerSummary>> create(Ref ref) {
    final argument = this.argument as String;
    return followingOf(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FollowingOfProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$followingOfHash() => r'300e6625654067eb5f93b1a989d0dc0b62d93d3a';

final class FollowingOfFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlayerSummary>>, String> {
  FollowingOfFamily._()
    : super(
        retry: null,
        name: r'followingOfProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  FollowingOfProvider call(String id) =>
      FollowingOfProvider._(argument: id, from: this);

  @override
  String toString() => r'followingOfProvider';
}

/// Follower and following counts for the signed-in player.

@ProviderFor(mySocial)
final mySocialProvider = MySocialProvider._();

/// Follower and following counts for the signed-in player.

final class MySocialProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerSocial>,
          PlayerSocial,
          FutureOr<PlayerSocial>
        >
    with $FutureModifier<PlayerSocial>, $FutureProvider<PlayerSocial> {
  /// Follower and following counts for the signed-in player.
  MySocialProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mySocialProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mySocialHash();

  @$internal
  @override
  $FutureProviderElement<PlayerSocial> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerSocial> create(Ref ref) {
    return mySocial(ref);
  }
}

String _$mySocialHash() => r'23e87ac8540aee15a945664fc13ca4db429e2952';

/// Who the signed-in player follows. Toggling updates instantly and rolls
/// back if the server refuses.

@ProviderFor(MyFollowing)
final myFollowingProvider = MyFollowingProvider._();

/// Who the signed-in player follows. Toggling updates instantly and rolls
/// back if the server refuses.
final class MyFollowingProvider
    extends $AsyncNotifierProvider<MyFollowing, Set<String>> {
  /// Who the signed-in player follows. Toggling updates instantly and rolls
  /// back if the server refuses.
  MyFollowingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'myFollowingProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$myFollowingHash();

  @$internal
  @override
  MyFollowing create() => MyFollowing();
}

String _$myFollowingHash() => r'28ea67311359d5eedc2280e653bfedb178cae022';

/// Who the signed-in player follows. Toggling updates instantly and rolls
/// back if the server refuses.

abstract class _$MyFollowing extends $AsyncNotifier<Set<String>> {
  FutureOr<Set<String>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(BlockedPlayers)
final blockedPlayersProvider = BlockedPlayersProvider._();

final class BlockedPlayersProvider
    extends $AsyncNotifierProvider<BlockedPlayers, List<PlayerSummary>> {
  BlockedPlayersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blockedPlayersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blockedPlayersHash();

  @$internal
  @override
  BlockedPlayers create() => BlockedPlayers();
}

String _$blockedPlayersHash() => r'f23c79d431f655f6a987d4e3ef6375fa4b8f614d';

abstract class _$BlockedPlayers extends $AsyncNotifier<List<PlayerSummary>> {
  FutureOr<List<PlayerSummary>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlayerSummary>>, List<PlayerSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PlayerSummary>>, List<PlayerSummary>>,
              AsyncValue<List<PlayerSummary>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(SavedPlayers)
final savedPlayersProvider = SavedPlayersProvider._();

final class SavedPlayersProvider
    extends $AsyncNotifierProvider<SavedPlayers, List<PlayerSummary>> {
  SavedPlayersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'savedPlayersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$savedPlayersHash();

  @$internal
  @override
  SavedPlayers create() => SavedPlayers();
}

String _$savedPlayersHash() => r'f80f34f63bd1e677994fe64f46bceeaf9649b95e';

abstract class _$SavedPlayers extends $AsyncNotifier<List<PlayerSummary>> {
  FutureOr<List<PlayerSummary>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PlayerSummary>>, List<PlayerSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<PlayerSummary>>, List<PlayerSummary>>,
              AsyncValue<List<PlayerSummary>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(conversations)
final conversationsProvider = ConversationsProvider._();

final class ConversationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Conversation>>,
          List<Conversation>,
          Stream<List<Conversation>>
        >
    with
        $FutureModifier<List<Conversation>>,
        $StreamProvider<List<Conversation>> {
  ConversationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationsHash();

  @$internal
  @override
  $StreamProviderElement<List<Conversation>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Conversation>> create(Ref ref) {
    return conversations(ref);
  }
}

String _$conversationsHash() => r'9ce728769ff501f8a2ce2b242f50916d1330a233';

@ProviderFor(suggestedPlayers)
final suggestedPlayersProvider = SuggestedPlayersProvider._();

final class SuggestedPlayersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<SuggestedPlayer>>,
          List<SuggestedPlayer>,
          FutureOr<List<SuggestedPlayer>>
        >
    with
        $FutureModifier<List<SuggestedPlayer>>,
        $FutureProvider<List<SuggestedPlayer>> {
  SuggestedPlayersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'suggestedPlayersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$suggestedPlayersHash();

  @$internal
  @override
  $FutureProviderElement<List<SuggestedPlayer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<SuggestedPlayer>> create(Ref ref) {
    return suggestedPlayers(ref);
  }
}

String _$suggestedPlayersHash() => r'f33ab1f88e8b7bb7a457d14bbd2c56501fc59633';

@ProviderFor(chatMessages)
final chatMessagesProvider = ChatMessagesFamily._();

final class ChatMessagesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChatMessage>>,
          List<ChatMessage>,
          Stream<List<ChatMessage>>
        >
    with
        $FutureModifier<List<ChatMessage>>,
        $StreamProvider<List<ChatMessage>> {
  ChatMessagesProvider._({
    required ChatMessagesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatMessagesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatMessagesHash();

  @override
  String toString() {
    return r'chatMessagesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<ChatMessage>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChatMessage>> create(Ref ref) {
    final argument = this.argument as String;
    return chatMessages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatMessagesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatMessagesHash() => r'adb278657c060e9239f1f9589907d2693ce7f734';

final class ChatMessagesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<ChatMessage>>, String> {
  ChatMessagesFamily._()
    : super(
        retry: null,
        name: r'chatMessagesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatMessagesProvider call(String conversationId) =>
      ChatMessagesProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'chatMessagesProvider';
}

@ProviderFor(chatPartner)
final chatPartnerProvider = ChatPartnerFamily._();

final class ChatPartnerProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlayerSummary>,
          PlayerSummary,
          FutureOr<PlayerSummary>
        >
    with $FutureModifier<PlayerSummary>, $FutureProvider<PlayerSummary> {
  ChatPartnerProvider._({
    required ChatPartnerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'chatPartnerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatPartnerHash();

  @override
  String toString() {
    return r'chatPartnerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlayerSummary> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlayerSummary> create(Ref ref) {
    final argument = this.argument as String;
    return chatPartner(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ChatPartnerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatPartnerHash() => r'2229521b2a2d0e33fecb22d0828d2c9924930b85';

final class ChatPartnerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlayerSummary>, String> {
  ChatPartnerFamily._()
    : super(
        retry: null,
        name: r'chatPartnerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatPartnerProvider call(String conversationId) =>
      ChatPartnerProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'chatPartnerProvider';
}

/// Ids I've saved of one kind, with optimistic toggling.

@ProviderFor(SavedIds)
final savedIdsProvider = SavedIdsFamily._();

/// Ids I've saved of one kind, with optimistic toggling.
final class SavedIdsProvider
    extends $AsyncNotifierProvider<SavedIds, Set<String>> {
  /// Ids I've saved of one kind, with optimistic toggling.
  SavedIdsProvider._({
    required SavedIdsFamily super.from,
    required SavedKind super.argument,
  }) : super(
         retry: null,
         name: r'savedIdsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedIdsHash();

  @override
  String toString() {
    return r'savedIdsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  SavedIds create() => SavedIds();

  @override
  bool operator ==(Object other) {
    return other is SavedIdsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedIdsHash() => r'821980a8bb2356961404b295bb76d59bae3d7857';

/// Ids I've saved of one kind, with optimistic toggling.

final class SavedIdsFamily extends $Family
    with
        $ClassFamilyOverride<
          SavedIds,
          AsyncValue<Set<String>>,
          Set<String>,
          FutureOr<Set<String>>,
          SavedKind
        > {
  SavedIdsFamily._()
    : super(
        retry: null,
        name: r'savedIdsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ids I've saved of one kind, with optimistic toggling.

  SavedIdsProvider call(SavedKind kind) =>
      SavedIdsProvider._(argument: kind, from: this);

  @override
  String toString() => r'savedIdsProvider';
}

/// Ids I've saved of one kind, with optimistic toggling.

abstract class _$SavedIds extends $AsyncNotifier<Set<String>> {
  late final _$args = ref.$arg as SavedKind;
  SavedKind get kind => _$args;

  FutureOr<Set<String>> build(SavedKind kind);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<String>>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<String>>, Set<String>>,
              AsyncValue<Set<String>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
