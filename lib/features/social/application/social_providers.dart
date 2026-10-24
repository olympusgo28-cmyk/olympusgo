import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/social_models.dart';

part 'social_providers.g.dart';

@riverpod
Future<PlayerDetail> playerDetail(Ref ref, String id) {
  ref.watch(myFollowingProvider);
  return ref.watch(socialRepositoryProvider).player(id);
}

@riverpod
Future<List<PlayerSummary>> followersOf(Ref ref, String id) =>
    ref.watch(socialRepositoryProvider).followers(id);

@riverpod
Future<List<PlayerSummary>> followingOf(Ref ref, String id) {
  ref.watch(myFollowingProvider);
  return ref.watch(socialRepositoryProvider).following(id);
}

/// Follower and following counts for the signed-in player.
@riverpod
Future<PlayerSocial> mySocial(Ref ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) return const PlayerSocial();
  ref.watch(myFollowingProvider);
  return ref.watch(socialRepositoryProvider).social(me);
}

/// Who the signed-in player follows. Toggling updates instantly and rolls
/// back if the server refuses.
@Riverpod(keepAlive: true)
class MyFollowing extends _$MyFollowing {
  @override
  Future<Set<String>> build() async {
    final me = await ref.watch(currentUserIdProvider.future);
    if (me == null) return const {};
    return ref.watch(socialRepositoryProvider).myFollowingIds();
  }

  bool isFollowing(String id) => state.value?.contains(id) ?? false;

  Future<void> toggle(String id) async {
    final before = state.value ?? const <String>{};
    final follow = !before.contains(id);
    HapticFeedback.selectionClick();
    state = AsyncData(follow ? {...before, id} : ({...before}..remove(id)));
    try {
      final repo = ref.read(socialRepositoryProvider);
      follow ? await repo.follow(id) : await repo.unfollow(id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

@riverpod
class BlockedPlayers extends _$BlockedPlayers {
  @override
  Future<List<PlayerSummary>> build() =>
      ref.watch(socialRepositoryProvider).blocked();

  Future<void> block(String id) async {
    await ref.read(socialRepositoryProvider).block(id);
    ref.invalidateSelf();
    ref.invalidate(myFollowingProvider);
  }

  Future<void> unblock(String id) async {
    final before = state.value ?? const [];
    state = AsyncData(before.where((p) => p.id != id).toList());
    try {
      await ref.read(socialRepositoryProvider).unblock(id);
    } catch (_) {
      state = AsyncData(before);
      rethrow;
    }
  }
}

@riverpod
class SavedPlayers extends _$SavedPlayers {
  @override
  Future<List<PlayerSummary>> build() =>
      ref.watch(socialRepositoryProvider).savedPlayers();

  Future<void> unsave(String id) async {
    final before = state.value ?? const [];
    state = AsyncData(before.where((p) => p.id != id).toList());
    await ref
        .read(socialRepositoryProvider)
        .setSaved(SavedKind.player, id, false);
  }
}

@riverpod
Stream<List<Conversation>> conversations(Ref ref) async* {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) {
    yield const [];
    return;
  }
  yield* ref.watch(chatRepositoryProvider).conversations();
}

@riverpod
Future<List<SuggestedPlayer>> suggestedPlayers(Ref ref) =>
    ref.watch(socialRepositoryProvider).suggested();

@riverpod
Stream<List<ChatMessage>> chatMessages(Ref ref, String conversationId) =>
    ref.watch(chatRepositoryProvider).messages(conversationId);

@riverpod
Future<PlayerSummary> chatPartner(Ref ref, String conversationId) =>
    ref.watch(chatRepositoryProvider).otherIn(conversationId);

/// Ids I've saved of one kind, with optimistic toggling.
@riverpod
class SavedIds extends _$SavedIds {
  @override
  Future<Set<String>> build(SavedKind kind) async {
    final me = await ref.watch(currentUserIdProvider.future);
    if (me == null) return const {};
    return ref.watch(socialRepositoryProvider).savedIds(kind);
  }

  /// Saves or unsaves [id]; returns whether it is saved now.
  Future<bool> toggle(String id) async {
    final current = state.value ?? const <String>{};
    final saved = !current.contains(id);
    state = AsyncData(saved ? {...current, id} : ({...current}..remove(id)));
    try {
      await ref.read(socialRepositoryProvider).setSaved(kind, id, saved);
    } catch (_) {
      state = AsyncData(current);
      rethrow;
    }
    return saved;
  }
}
