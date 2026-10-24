// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inbox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(inboxUpdates)
final inboxUpdatesProvider = InboxUpdatesProvider._();

final class InboxUpdatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InboxUpdate>>,
          List<InboxUpdate>,
          FutureOr<List<InboxUpdate>>
        >
    with
        $FutureModifier<List<InboxUpdate>>,
        $FutureProvider<List<InboxUpdate>> {
  InboxUpdatesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxUpdatesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxUpdatesHash();

  @$internal
  @override
  $FutureProviderElement<List<InboxUpdate>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<InboxUpdate>> create(Ref ref) {
    return inboxUpdates(ref);
  }
}

String _$inboxUpdatesHash() => r'8c4e20ebf1722a1e5b887a7ef23ffc9d0276c83e';

/// Club, team and direct chats, newest first.

@ProviderFor(inboxChats)
final inboxChatsProvider = InboxChatsProvider._();

/// Club, team and direct chats, newest first.

final class InboxChatsProvider
    extends
        $FunctionalProvider<List<InboxChat>, List<InboxChat>, List<InboxChat>>
    with $Provider<List<InboxChat>> {
  /// Club, team and direct chats, newest first.
  InboxChatsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxChatsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxChatsHash();

  @$internal
  @override
  $ProviderElement<List<InboxChat>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<InboxChat> create(Ref ref) {
    return inboxChats(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<InboxChat> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<InboxChat>>(value),
    );
  }
}

String _$inboxChatsHash() => r'26bc43acd4fea7c5fb86b556f52c93a20bc97a92';

/// The Inbox tab badge: chats with something new plus unread updates.

@ProviderFor(inboxUnread)
final inboxUnreadProvider = InboxUnreadProvider._();

/// The Inbox tab badge: chats with something new plus unread updates.

final class InboxUnreadProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
  /// The Inbox tab badge: chats with something new plus unread updates.
  InboxUnreadProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inboxUnreadProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inboxUnreadHash();

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    return inboxUnread(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$inboxUnreadHash() => r'2984b6b1a97a33dc851fdc68e184a1442ca4ef3f';
