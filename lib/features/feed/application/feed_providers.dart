import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import '../../../core/providers.dart';
import '../domain/feed_models.dart';

part 'feed_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;

/// Slow enough to stay under the rate limit.
const postPollEvery = Duration(seconds: 15);

@riverpod
Future<FeedStatus> feedStatus(Ref ref) =>
    ref.watch(feedRepositoryProvider).status();

@Riverpod(retry: _noRetry)
Future<List<FeedPost>> feedFollowing(Ref ref) =>
    ref.watch(feedRepositoryProvider).following();

@Riverpod(retry: _noRetry)
Future<List<FeedPost>> feedDiscover(Ref ref) =>
    ref.watch(feedRepositoryProvider).discover();

/// Asks again while a post is being checked, and stops when the screen closes.
@Riverpod(retry: _noRetry)
Future<List<FeedPost>> myPosts(Ref ref) async {
  void again() {
    if (!ref.mounted) return;
    final timer = Timer(postPollEvery, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }

  final List<FeedPost> posts;
  try {
    posts = await ref.watch(feedRepositoryProvider).mine();
  } on Exception {
    // A dropped call doesn't end the wait.
    again();
    rethrow;
  }
  if (posts.any((p) => p.working)) again();
  return posts;
}

/// Short-lived links, so they're fetched for the list on show. [ids] is
/// comma-separated, so a family key compares by value.
@Riverpod(retry: _noRetry)
Future<Map<String, String>> feedPosters(Ref ref, String ids) =>
    ref.watch(feedRepositoryProvider).posters(ids.split(','));

/// Posts on their way up from this phone.
@Riverpod(keepAlive: true)
class PostUploads extends _$PostUploads {
  @override
  Set<String> build() => const {};

  void start(String id) => state = {...state, id};

  void finish(String id) => state = {...state}..remove(id);
}

/// The one video playing. Starting another pauses it.
@riverpod
class ActivePost extends _$ActivePost {
  @override
  String? build() => null;

  void play(String id) => state = id;
}

/// Makes a player. A provider so tests can see when one is made: nothing plays,
/// and nothing loads, until someone taps.
typedef PostPlayerMaker = VideoPlayerController Function(Uri url);

@riverpod
PostPlayerMaker postPlayerMaker(Ref ref) => VideoPlayerController.networkUrl;
