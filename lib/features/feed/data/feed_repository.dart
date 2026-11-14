import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/feed_models.dart';

abstract class FeedRepository {
  Future<FeedStatus> status();
  Future<List<FeedPost>> following();
  Future<List<FeedPost>> discover();
  Future<List<FeedPost>> mine();

  /// Sends the file and queues its checks. [id] stays the same on a retry, so
  /// a dropped signal reaches the same post.
  Future<void> addPost({
    required String id,
    required PickedClip file,
    required int seconds,
    required String caption,
    required String sport,
    required PostAudience audience,
    required bool noMinors,
  });

  Future<void> retry(String id);
  Future<void> delete(String id);
  Future<void> like(String id);
  Future<void> unlike(String id);

  /// A short link to one video, asked for when someone taps play.
  Future<String> playUrl(String id);

  /// Short links to posters, by post id.
  Future<Map<String, String>> posters(List<String> ids);
}

class SupabaseFeedRepository implements FeedRepository {
  SupabaseFeedRepository(this._client);

  final SupabaseClient _client;
  static const _bucket = 'feed-videos';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Feed error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on StorageException catch (e) {
      debugPrint('Feed file error: ${e.statusCode}');
      throw const AuthFailure('The upload didn’t finish. Try again.');
    } on FunctionException catch (e) {
      debugPrint('Feed link error: ${e.status}');
      final details = e.details;
      throw AuthFailure(
        details is Map && details['error'] is String
            ? details['error'] as String
            : 'Something went wrong. Try again.',
      );
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure('Check your connection and try again.');
    }
  }

  List<FeedPost> _list(Object? rows) => [
    for (final r in rows as List? ?? const [])
      FeedPost.fromRow((r as Map).cast<String, dynamic>()),
  ];

  Future<Map<String, dynamic>> _media(Map<String, Object?> body) async {
    final r = await _client.functions.invoke('feed-media', body: body);
    return (r.data as Map).cast<String, dynamic>();
  }

  /// Without the container, a local stack has nothing to run the checks.
  Future<void> _standIn() async {
    if (!Env.localStandIn) return;
    try {
      await _client.functions.invoke('feed-local', body: const {});
    } on Exception catch (e) {
      debugPrint('Feed stand-in: ${e.runtimeType}');
    }
  }

  @override
  Future<FeedStatus> status() => _guard(() async {
    final r = await _client.rpc('feed_status');
    return FeedStatus.fromRow((r as Map).cast<String, dynamic>());
  });

  @override
  Future<List<FeedPost>> following() =>
      _guard(() async => _list(await _client.rpc('feed_following')));

  @override
  Future<List<FeedPost>> discover() =>
      _guard(() async => _list(await _client.rpc('feed_discover')));

  @override
  Future<List<FeedPost>> mine() =>
      _guard(() async => _list(await _client.rpc('post_mine')));

  @override
  Future<void> addPost({
    required String id,
    required PickedClip file,
    required int seconds,
    required String caption,
    required String sport,
    required PostAudience audience,
    required bool noMinors,
  }) => _guard(() async {
    final row = await _client.rpc(
      'post_create',
      params: {
        'p_post': id,
        'p_ext': file.ext,
        'p_seconds': seconds,
        'p_bytes': file.bytes,
        'p_caption': caption,
        'p_sport': sport,
        'p_audience': audience.id,
        'p_no_minors': noMinors,
      },
    ) as Map;
    if (row['status'] == 'waiting') {
      final target = await _media({'action': 'upload', 'post': id});
      // Already there on a retry, if the file landed and the next step didn't.
      if (target['exists'] != true) {
        await _client.storage
            .from(_bucket)
            .uploadToSignedUrl(
              target['path'] as String,
              target['token'] as String,
              File(file.path),
              FileOptions(
                contentType: file.ext == 'mov'
                    ? 'video/quicktime'
                    : 'video/mp4',
              ),
            );
      }
      await _client.rpc('post_uploaded', params: {'p_post': id});
    }
    await _standIn();
  });

  @override
  Future<void> retry(String id) => _guard(() async {
    await _client.rpc('post_retry', params: {'p_post': id});
    await _standIn();
  });

  @override
  Future<void> delete(String id) =>
      _guard(() => _client.rpc('post_delete', params: {'p_post': id}));

  @override
  Future<void> like(String id) =>
      _guard(() => _client.rpc('post_like', params: {'p_post': id}));

  @override
  Future<void> unlike(String id) =>
      _guard(() => _client.rpc('post_unlike', params: {'p_post': id}));

  @override
  Future<String> playUrl(String id) => _guard(() async {
    final r = await _media({'action': 'play', 'post': id});
    return r['url'] as String;
  });

  @override
  Future<Map<String, String>> posters(List<String> ids) => _guard(() async {
    if (ids.isEmpty) return const {};
    final r = await _media({'action': 'posters', 'posts': ids});
    return (r['urls'] as Map).cast<String, String>();
  });
}

/// Keeps posts in memory, so the screens work with no backend.
class DemoFeedRepository implements FeedRepository {
  final _mine = <String, FeedPost>{};
  final _liked = <String>{};

  static const _sample = FeedPost(
    id: 'demo-1',
    authorId: 'demo-author',
    author: 'Mei Tan',
    caption: 'Working on my backhand clear',
    sport: 'badminton',
    seconds: 24,
    hasPoster: false,
    likes: 3,
    liked: false,
    mine: false,
    audience: PostAudience.public,
  );

  FeedPost _withLike(FeedPost p) =>
      _liked.contains(p.id) ? p.copy(liked: true, likes: p.likes + 1) : p;

  @override
  Future<FeedStatus> status() async => const FeedStatus(
    open: true,
    canPost: true,
    canDiscover: true,
    maxSeconds: 60,
    maxMb: 100,
  );

  @override
  Future<List<FeedPost>> following() async => [_withLike(_sample)];

  @override
  Future<List<FeedPost>> discover() async => [_withLike(_sample)];

  @override
  Future<List<FeedPost>> mine() async => _mine.values.toList();

  @override
  Future<void> addPost({
    required String id,
    required PickedClip file,
    required int seconds,
    required String caption,
    required String sport,
    required PostAudience audience,
    required bool noMinors,
  }) async {
    _mine[id] = FeedPost(
      id: id,
      authorId: 'me',
      author: 'You',
      caption: caption,
      sport: sport,
      seconds: seconds,
      hasPoster: false,
      likes: 0,
      liked: false,
      mine: true,
      audience: audience,
      status: PostStatus.review,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> retry(String id) async {}

  @override
  Future<void> delete(String id) async => _mine.remove(id);

  @override
  Future<void> like(String id) async => _liked.add(id);

  @override
  Future<void> unlike(String id) async => _liked.remove(id);

  @override
  Future<String> playUrl(String id) async =>
      throw const AuthFailure('Videos don’t play in the demo.');

  @override
  Future<Map<String, String>> posters(List<String> ids) async => const {};
}
