// The feed through the real API, Storage and Edge Functions. pgTAP can't see
// Storage, PostgREST's read-only rule or the request gate, so this is what
// proves them. Skipped unless LOCAL_MONEY_TESTS is set, because it needs
// `supabase functions serve` and switches flags for the whole stack: run it
// alone. Never the hosted project.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:olympus_go/features/analysis/domain/analysis_models.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/feed/data/feed_repository.dart';
import 'package:olympus_go/features/feed/domain/feed_models.dart';

import 'support/local_accounts.dart';

void main() {
  final url = Platform.environment['LOCAL_SUPABASE_URL'];
  final key = Platform.environment['LOCAL_SUPABASE_KEY'];
  final service = Platform.environment['LOCAL_SUPABASE_SERVICE_KEY'];
  final skip =
      url == null ||
          key == null ||
          service == null ||
          !url.contains('127.0.0.1') ||
          Platform.environment['LOCAL_MONEY_TESTS'] == null
      ? 'Needs a local stack, its functions and LOCAL_MONEY_TESTS'
      : null;

  late SupabaseClient admin;
  late SupabaseClient author;
  late SupabaseClient follower;
  late SupabaseClient stranger;
  late SupabaseClient teen;
  late SupabaseClient restricted;
  late File file;
  const bucket = 'feed-videos';
  const flags = ['video.feed', 'feed.fake_checks'];
  final video = Uint8List.fromList(List.filled(1024, 7));

  Future<SupabaseClient> player(String name, String birthday) async {
    final c = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(
        autoRefreshToken: false,
        authFlowType: AuthFlowType.implicit,
      ),
    );
    final stamp = DateTime.now().microsecondsSinceEpoch;
    await signUpLocal(
      c,
      email: '$name.$stamp@test.local',
      password: 'test-password-123',
    );
    await c.rpc(
      'set_birthday',
      params: {'p_birthday': birthday, 'p_country': 'SG'},
    );
    await c
        .from('profiles')
        .update({
          'username': '${name}_${stamp % 10000000}',
          'full_name': '$name Test',
          'onboarding_completed': true,
        })
        .eq('id', c.auth.currentUser!.id);
    return c;
  }

  String uuid() {
    final r = Random.secure();
    final b = List<int>.generate(16, (_) => r.nextInt(256));
    b[6] = (b[6] & 0x0f) | 0x40;
    b[8] = (b[8] & 0x3f) | 0x80;
    final h = b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-'
        '${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<http.Response> post(
    String function,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) => http.post(
    Uri.parse('$url/functions/v1/$function'),
    headers: {'content-type': 'application/json', ...headers},
    body: jsonEncode(body),
  );

  Future<void> standIn([Map<String, dynamic>? body]) async {
    final res = await post('feed-local', body ?? {});
    expect(res.statusCode, 200, reason: res.body);
  }

  Future<void> sweep() async {
    final res = await post(
      'money-worker',
      {'task': 'clips'},
      headers: {'x-worker-secret': 'local-worker-secret'},
    );
    expect(res.statusCode, 200, reason: res.body);
  }

  Future<String> status(String id) async =>
      (await admin
              .from('video_posts')
              .select('status')
              .eq('id', id)
              .single())['status']
          as String;

  /// Posts through the app's own repository, as far as the checks.
  Future<String> add(
    SupabaseClient c, {
    PostAudience audience = PostAudience.public,
  }) async {
    final id = uuid();
    await SupabaseFeedRepository(c).addPost(
      id: id,
      file: PickedClip(path: file.path, ext: 'mp4', bytes: video.length),
      seconds: 20,
      caption: 'Smash practice',
      sport: 'badminton',
      audience: audience,
      noMinors: true,
    );
    return id;
  }

  /// As if staff had said yes.
  Future<void> approve(String id) => admin
      .from('video_posts')
      .update({
        'status': 'live',
        'live_at': DateTime.now().toUtc().toIso8601String(),
        'approved_at': DateTime.now().toUtc().toIso8601String(),
      })
      .eq('id', id);

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(url!, service!);
    await admin
        .from('feature_flags')
        .update({'enabled': true})
        .inFilter('key', flags);
    await admin
        .from('app_settings')
        .update({'value': 100})
        .eq('key', 'feed.daily_posts');
    author = await player('feedauthor', '1990-01-01');
    follower = await player('feedfan', '1991-01-01');
    stranger = await player('feedstranger', '1992-01-01');
    teen = await player('feedteen', '2011-01-01');
    restricted = await player('feedchild', '2012-01-01');
    final parent = await player('feedparent', '1980-01-01');
    await admin.from('guardian_links').insert({
      'parent_id': parent.auth.currentUser!.id,
      'child_id': teen.auth.currentUser!.id,
      'status': 'approved',
    });
    final me = author.auth.currentUser!.id;
    await admin.from('follows').insert([
      {'follower_id': follower.auth.currentUser!.id, 'followee_id': me},
      {'follower_id': teen.auth.currentUser!.id, 'followee_id': me},
      {'follower_id': restricted.auth.currentUser!.id, 'followee_id': me},
    ]);
    final dir = await Directory.systemTemp.createTemp('feed');
    file = File('${dir.path}/post.mp4')..writeAsBytesSync(video);
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin
        .from('feature_flags')
        .update({'enabled': false})
        .inFilter('key', flags);
    await admin
        .from('app_settings')
        .update({'value': 5})
        .eq('key', 'feed.daily_posts');
  });

  test('reads work through the API, not only in a transaction', () async {
    final repo = SupabaseFeedRepository(author);
    expect((await repo.status()).open, isTrue);
    expect(await repo.following(), isEmpty);
    expect(await repo.mine(), isA<List<FeedPost>>());
    await repo.discover();
    await repo.posters([uuid()]);
  }, skip: skip);

  test('a post goes from the phone to a person, then to a viewer', () async {
    final id = await add(author);
    expect(await status(id), 'checking');
    await standIn();
    expect(await status(id), 'review');
    await expectLater(
      SupabaseFeedRepository(follower).playUrl(id),
      throwsA(isA<AuthFailure>()),
    );
    await approve(id);

    final fan = SupabaseFeedRepository(follower);
    final seen = await fan.following();
    expect(seen.map((p) => p.id), contains(id));
    final link = await fan.playUrl(id);
    expect(await http.readBytes(Uri.parse(link)), video);
    final posters = await fan.posters([id]);
    expect(posters.keys, [id]);
    expect((await http.get(Uri.parse(posters[id]!))).statusCode, 200);
    await fan.like(id);
    expect((await fan.following()).firstWhere((p) => p.id == id).likes, 1);
  }, skip: skip);

  test('a client never reaches a file on its own', () async {
    final id = await add(author);
    final path = '${author.auth.currentUser!.id}/$id.mp4';
    for (final c in [author, follower, stranger]) {
      await expectLater(
        c.storage.from(bucket).download(path),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        c.storage.from(bucket).createSignedUrl(path, 60),
        throwsA(isA<StorageException>()),
      );
      await expectLater(
        c.storage
            .from(bucket)
            .uploadBinary('${c.auth.currentUser!.id}/mine.mp4', video),
        throwsA(isA<StorageException>()),
      );
    }
  }, skip: skip);

  test('a passed file can\'t be swapped', () async {
    final id = uuid();
    final me = author.auth.currentUser!.id;
    await author.rpc(
      'post_create',
      params: {
        'p_post': id,
        'p_ext': 'mp4',
        'p_seconds': 20,
        'p_bytes': video.length,
        'p_caption': '',
        'p_sport': 'badminton',
        'p_audience': 'public',
        'p_no_minors': true,
      },
    );
    final target =
        (await author.functions.invoke(
              'feed-media',
              body: {'action': 'upload', 'post': id},
            )).data
            as Map;
    final files = author.storage.from(bucket);
    await files.uploadBinaryToSignedUrl(
      target['path'] as String,
      target['token'] as String,
      video,
    );
    await author.rpc('post_uploaded', params: {'p_post': id});
    await standIn();
    await approve(id);
    expect(target['path'], '$me/$id.mp4');
    await expectLater(
      files.uploadBinaryToSignedUrl(
        target['path'] as String,
        target['token'] as String,
        Uint8List.fromList(List.filled(1024, 9)),
      ),
      throwsA(isA<StorageException>()),
    );
    final link = await SupabaseFeedRepository(follower).playUrl(id);
    expect(await http.readBytes(Uri.parse(link)), video);
  }, skip: skip);

  test('Someone with no feed is refused by the real gate', () async {
    final id = await add(author);
    await standIn();
    await approve(id);
    final child = SupabaseFeedRepository(restricted);
    expect((await child.status()).open, isFalse);
    for (final call in <Future<Object?> Function()>[
      child.following,
      child.discover,
      () => child.playUrl(id),
      () => child.posters([id]),
      () => child.like(id),
    ]) {
      await expectLater(call(), throwsA(isA<AuthFailure>()));
    }
    expect(await child.mine(), isEmpty);
  }, skip: skip);

  test('a teen follows, and never discovers or posts', () async {
    final id = await add(author);
    await standIn();
    await approve(id);
    final other = await add(stranger);
    await standIn();
    await approve(other);

    final repo = SupabaseFeedRepository(teen);
    final s = await repo.status();
    expect(s.open, isTrue);
    expect(s.canDiscover, isFalse);
    expect(s.canPost, isFalse);
    expect((await repo.following()).map((p) => p.id), contains(id));
    await expectLater(repo.discover(), throwsA(isA<AuthFailure>()));
    await expectLater(repo.playUrl(other), throwsA(isA<AuthFailure>()));
    await expectLater(add(teen), throwsA(isA<AuthFailure>()));
  }, skip: skip);

  test('deleting takes the file out of Storage', () async {
    final id = await add(author);
    await standIn();
    final me = author.auth.currentUser!.id;
    await SupabaseFeedRepository(author).delete(id);
    await sweep();
    final left = await admin.storage.from(bucket).list(path: me);
    expect(left.where((f) => f.name.contains(id)), isEmpty);
    expect(await admin.from('video_posts').select('id').eq('id', id), isEmpty);
  }, skip: skip);

  test('a match blocks the post and keeps its file', () async {
    final clean = await add(stranger);
    await standIn({'hash': 'match'});
    expect(await status(clean), 'blocked');
    final mine = await SupabaseFeedRepository(stranger).mine();
    expect(mine.firstWhere((p) => p.id == clean).status, PostStatus.rejected);
    final left = await admin.storage
        .from(bucket)
        .list(path: stranger.auth.currentUser!.id);
    expect(left.where((f) => f.name.contains(clean)).length, 1);
  }, skip: skip);

  test('the worker\'s door is shut without its secret or a good job', () async {
    final none = await post('feed-worker', {'action': 'claim'});
    expect(none.statusCode, 404);
    final wrong = await post(
      'feed-worker',
      {'action': 'claim'},
      headers: {'x-worker-secret': 'nope'},
    );
    expect(wrong.statusCode, 404);

    final id = await add(author);
    final claim = await post(
      'feed-worker',
      {'action': 'claim'},
      headers: {'x-worker-secret': 'local-analysis-secret'},
    );
    expect(claim.statusCode, 200, reason: claim.body);
    final job = (jsonDecode(claim.body) as Map)['job'] as Map;
    expect(job.containsKey('author_id'), isFalse);
    final notAnImage = await post(
      'feed-worker',
      {
        'action': 'check',
        'ok': true,
        'job_id': job['job_id'],
        'token': job['token'],
        'frames': ['bm90IGFuIGltYWdl'],
      },
      headers: {'x-worker-secret': 'local-analysis-secret'},
    );
    expect(notAnImage.statusCode, 400);
    final badToken = await post(
      'feed-worker',
      {
        'action': 'check',
        'ok': false,
        'job_id': job['job_id'],
        'token': 'wrong',
        'code': 'internal',
      },
      headers: {'x-worker-secret': 'local-analysis-secret'},
    );
    expect(badToken.statusCode, 403);
    expect(await status(id), 'checking');
    final gaveUp = await post(
      'feed-worker',
      {
        'action': 'check',
        'ok': false,
        'job_id': job['job_id'],
        'token': job['token'],
        'code': 'too_long',
      },
      headers: {'x-worker-secret': 'local-analysis-secret'},
    );
    expect(gaveUp.statusCode, 200, reason: gaveUp.body);
    expect(await status(id), 'checking');
  }, skip: skip);
}
