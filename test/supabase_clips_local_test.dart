// Clips through the real API, Storage and Edge Functions. pgTAP can't see
// Storage policies, so this is what proves them. Skipped unless LOCAL_MONEY_TESTS
// is set, because it needs `supabase functions serve` and switches flags for the
// whole stack: run it alone. Never the hosted project.
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:olympus_go/features/analysis/data/analysis_repository.dart';
import 'package:olympus_go/features/analysis/domain/analysis_models.dart';

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
  const bucket = 'analysis-clips';
  const flags = ['video.analysis', 'video.analysis_minors'];
  final video = Uint8List.fromList(List.filled(1024, 7));
  final jpeg = [0xff, 0xd8, 0xff, 0xe0, 0, 16, 74, 70, 73, 70];

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

  Future<Map<String, dynamic>> start(
    SupabaseClient c, {
    String? subject,
    String? clip,
  }) async {
    final r = await c.rpc(
      'clip_create',
      params: {
        'p_clip': clip ?? uuid(),
        'p_subject': subject,
        'p_ext': 'mp4',
        'p_seconds': 30,
        'p_bytes': video.length,
        'p_everyone_agreed': true,
        'p_consent_version': subject == null ? null : 'v1',
      },
    );
    return (r as Map).cast<String, dynamic>();
  }

  Future<void> upload(SupabaseClient c, String path) => c.storage
      .from(bucket)
      .uploadBinary(
        path,
        video,
        fileOptions: const FileOptions(contentType: 'video/mp4'),
      );

  Future<http.Response> worker(Map<String, dynamic> body, {String? secret}) =>
      http.post(
        Uri.parse('$url/functions/v1/analysis-worker'),
        headers: {
          'content-type': 'application/json',
          'x-worker-secret': secret ?? 'local-analysis-secret',
        },
        body: jsonEncode(body),
      );

  Future<void> standIn([Map<String, dynamic>? body]) async {
    final res = await http.post(
      Uri.parse('$url/functions/v1/analysis-local'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
    expect(res.statusCode, 200, reason: res.body);
  }

  Future<void> sweep() async {
    final res = await http.post(
      Uri.parse('$url/functions/v1/money-worker'),
      headers: {
        'content-type': 'application/json',
        'x-worker-secret': 'local-worker-secret',
      },
      body: jsonEncode({'task': 'clips'}),
    );
    expect(res.statusCode, 200, reason: res.body);
  }

  Future<List<String>> filesOf(String owner) async {
    final r = await admin.storage.from(bucket).list(path: owner);
    return [for (final f in r) f.name];
  }

  setUpAll(() async {
    if (skip != null) return;
    admin = SupabaseClient(
      url!,
      service!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await admin
        .from('feature_flags')
        .update({'enabled': true})
        .inFilter('key', flags);
  });

  tearDownAll(() async {
    if (skip != null) return;
    await admin
        .from('feature_flags')
        .update({'enabled': false})
        .inFilter('key', flags);
  });

  test('a player uploads only to the clip they started', () async {
    final a = await player('clipa', '1990-01-01');
    final b = await player('clipb', '1990-01-01');
    final clip = await start(a);
    final path = clip['path'] as String;

    await expectLater(upload(b, path), throwsA(isA<StorageException>()));
    final other = '${b.auth.currentUser!.id}/${uuid()}.mp4';
    await expectLater(upload(b, other), throwsA(isA<StorageException>()));
    await expectLater(
      upload(a, '${a.auth.currentUser!.id}/${uuid()}.mp4'),
      throwsA(isA<StorageException>()),
    );
    await upload(a, path);
    await a.rpc('clip_uploaded', params: {'p_clip': clip['id']});
    await expectLater(upload(a, path), throwsA(isA<StorageException>()));
  }, skip: skip);

  test('there is no way round the upload rules', () async {
    final a = await player('clipi', '1990-01-01');
    final me = a.auth.currentUser!.id;
    final clip = await start(a);
    final path = clip['path'] as String;
    final files = a.storage.from(bucket);

    // A frame's name, a picture, or a file of the wrong type.
    await expectLater(
      upload(a, '$me/${clip['id']}.frame.jpg'),
      throwsA(isA<StorageException>()),
    );
    await expectLater(
      files.uploadBinary(
        path,
        video,
        fileOptions: const FileOptions(contentType: 'text/html'),
      ),
      throwsA(isA<StorageException>()),
    );
    await upload(a, path);
    // Replacing it, even before it's handed over.
    await expectLater(
      files.uploadBinary(
        path,
        video,
        fileOptions: const FileOptions(contentType: 'video/mp4', upsert: true),
      ),
      throwsA(isA<StorageException>()),
    );
    // Listing, and signing a link to it.
    expect(await files.list(path: me), isEmpty);
    await expectLater(
      files.createSignedUrl(path, 60),
      throwsA(isA<StorageException>()),
    );
    await expectLater(
      a.from('objects').select().limit(1),
      throwsA(isA<PostgrestException>()),
    );
  }, skip: skip);

  test('signed out can\'t touch the bucket', () async {
    final a = await player('clipc', '1990-01-01');
    final clip = await start(a);
    final anon = SupabaseClient(
      url!,
      key!,
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    await expectLater(
      upload(anon, clip['path'] as String),
      throwsA(isA<StorageException>()),
    );
  }, skip: skip);

  test('nobody can read a video, and only the owner the frame', () async {
    final a = await player('clipd', '1990-01-01');
    final b = await player('clipe', '1990-01-01');
    final clip = await start(a);
    await upload(a, clip['path'] as String);
    await a.rpc('clip_uploaded', params: {'p_clip': clip['id']});
    await standIn();

    final got = await a.rpc('clip_get', params: {'p_clip': clip['id']}) as Map;
    expect(got['status'], 'court_ready');
    final frame = got['frame'] as String;

    await expectLater(
      a.storage.from(bucket).download(clip['path'] as String),
      throwsA(isA<StorageException>()),
    );
    expect(
      (await a.storage.from(bucket).download(frame)).length,
      greaterThan(100),
    );
    await expectLater(
      b.storage.from(bucket).download(frame),
      throwsA(isA<StorageException>()),
    );
    await expectLater(
      b.storage.from(bucket).download(clip['path'] as String),
      throwsA(isA<StorageException>()),
    );
    await expectLater(
      a.storage.from(bucket).remove([clip['path'] as String]).then((r) {
        if (r.isNotEmpty) throw StateError('removed');
      }),
      completes,
    );
    expect(
      await filesOf(a.auth.currentUser!.id),
      contains('${clip['id']}.mp4'),
    );
  }, skip: skip);

  test('a stranger can\'t read a child\'s clip row, file or frame', () async {
    final child = await player('kid', '2011-01-01');
    final parent = await player('par', '1980-01-01');
    final stranger = await player('stranger', '1990-01-01');
    final childId = child.auth.currentUser!.id;
    await admin.from('guardian_links').insert({
      'child_id': childId,
      'parent_id': parent.auth.currentUser!.id,
      'status': 'approved',
    });

    final clip = await start(parent, subject: childId);
    await upload(parent, clip['path'] as String);
    await parent.rpc('clip_uploaded', params: {'p_clip': clip['id']});
    await standIn();
    final got =
        await parent.rpc('clip_get', params: {'p_clip': clip['id']}) as Map;
    final frame = got['frame'] as String;

    await expectLater(
      stranger.rpc('clip_get', params: {'p_clip': clip['id']}),
      throwsA(isA<PostgrestException>()),
    );
    await expectLater(
      stranger.rpc('child_clip_list', params: {'p_child': childId}),
      throwsA(isA<PostgrestException>()),
    );
    await expectLater(
      stranger.from('video_clips').select(),
      throwsA(isA<PostgrestException>()),
    );
    for (final path in [clip['path'] as String, frame]) {
      await expectLater(
        stranger.storage.from(bucket).download(path),
        throwsA(isA<StorageException>()),
      );
    }
    for (final path in [clip['path'] as String, frame]) {
      await expectLater(
        child.storage.from(bucket).download(path),
        throwsA(isA<StorageException>()),
      );
    }
    expect(
      (await parent.storage.from(bucket).download(frame)).length,
      greaterThan(100),
    );

    final list = await parent.rpc(
      'child_clip_list',
      params: {'p_child': childId},
    );
    expect(list as List, hasLength(1));
    await parent.rpc('consent_withdraw', params: {'p_clip': clip['id']});
    await sweep();
    expect(await filesOf(parent.auth.currentUser!.id), isEmpty);
  }, skip: skip);

  test('the worker API: secret, tokens, a replay, a bad report', () async {
    final wrong = await worker({'action': 'claim'}, secret: 'wrong');
    expect(wrong.statusCode, 404);

    final a = await player('clipf', '1990-01-01');
    final clip = await start(a);
    await upload(a, clip['path'] as String);
    await a.rpc('clip_uploaded', params: {'p_clip': clip['id']});

    final claimed = await worker({'action': 'claim'});
    expect(claimed.statusCode, 200, reason: claimed.body);
    final job = (jsonDecode(claimed.body) as Map)['job'] as Map;
    expect(claimed.body.contains(service!), isFalse);
    expect(job['kind'], 'court');

    // The function sees the stack from inside. A real worker sets
    // ANALYSIS_PUBLIC_URL instead.
    final video2 = await http.get(
      Uri.parse(
        (job['clip_url'] as String).replaceFirst(
          RegExp('^https?://[^/]+'),
          url!,
        ),
      ),
    );
    expect(video2.statusCode, 200);
    expect(video2.bodyBytes.length, video.length);

    Map<String, dynamic> result(String token) => {
      'action': 'result',
      'job_id': job['job_id'],
      'kind': 'court',
      'token': token,
      'ok': true,
      'result': {'seconds': 30, 'corners': null},
      'frame': base64Encode(jpeg),
      // Ignored: the database says where a job's frame goes.
      'frame_path': clip['path'],
      'worker_seconds': 2,
    };

    expect(
      (jsonDecode(
        (await worker({
          'action': 'continue',
          'job_id': job['job_id'],
          'token': job['token'],
        })).body,
      ) as Map)['continue'],
      isTrue,
    );
    expect((await worker(result('wrong'))).statusCode, 403);
    expect(
      await filesOf(a.auth.currentUser!.id),
      isNot(contains('${clip['id']}.frame.jpg')),
    );
    final notJpeg = await worker({
      ...result(job['token'] as String),
      'frame': base64Encode([1, 2, 3, 4, 5, 6, 7, 8]),
    });
    expect(notJpeg.statusCode, 400);
    final good = await worker(result(job['token'] as String));
    expect(good.statusCode, 200, reason: good.body);
    expect((jsonDecode(good.body) as Map)['status'], 'done');
    expect(
      await filesOf(a.auth.currentUser!.id),
      contains('${clip['id']}.frame.jpg'),
    );
    final replay = await worker(result(job['token'] as String));
    expect(replay.statusCode, 403);

    // The video is untouched by that path in the request.
    final kept = await admin.storage
        .from(bucket)
        .download(clip['path'] as String);
    expect(kept.length, video.length);

    final bad = await worker({
      'action': 'result',
      'job_id': job['job_id'],
      'kind': 'analyse',
      'token': job['token'],
      'ok': true,
      'result': {'distance_m': 'lots'},
    });
    expect(bad.statusCode, 400);
  }, skip: skip);

  test('a clip goes all the way, and its file really goes', () async {
    final a = await player('clipg', '1990-01-01');
    final me = a.auth.currentUser!.id;
    final clip = await start(a);
    await upload(a, clip['path'] as String);
    await a.rpc('clip_uploaded', params: {'p_clip': clip['id']});
    await standIn();
    await a.rpc(
      'clip_confirm_court',
      params: {
        'p_clip': clip['id'],
        'p_corners': [
          [0.1, 0.1],
          [0.9, 0.1],
          [0.9, 0.9],
          [0.1, 0.9],
        ],
        'p_side': 'near',
      },
    );
    await standIn();
    final done = await a.rpc('clip_get', params: {'p_clip': clip['id']}) as Map;
    expect(done['status'], 'done');
    expect((done['report'] as Map)['distance_m'], 412.5);
    expect(await filesOf(me), hasLength(2));

    await admin
        .from('video_clips')
        .update({'purge_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', clip['id'] as String);
    await sweep();
    expect(await filesOf(me), isEmpty);
    final after =
        await a.rpc('clip_get', params: {'p_clip': clip['id']}) as Map;
    expect(after['file_gone'], isTrue);
    expect((after['report'] as Map)['distance_m'], 412.5);
  }, skip: skip);

  test('deleting an account leaves no file behind', () async {
    final a = await player('cliph', '1990-01-01');
    final me = a.auth.currentUser!.id;
    final clip = await start(a);
    await upload(a, clip['path'] as String);
    expect(await filesOf(me), hasLength(1));
    await admin.auth.admin.deleteUser(me);
    await sweep();
    expect(await filesOf(me), isEmpty);
  }, skip: skip);

  test('the app\'s repository: a retry reaches the same clip', () async {
    final owner = await player('repo', '1990-01-01');
    final repo = SupabaseAnalysisRepository(owner);
    final file = File('${Directory.systemTemp.path}/og-clip-${uuid()}.mp4')
      ..writeAsBytesSync(video);
    addTearDown(file.deleteSync);
    final picked = PickedClip(path: file.path, ext: 'mp4', bytes: video.length);

    final id = uuid();
    await repo.addClip(id: id, file: picked, seconds: 30);
    expect((await repo.clip(id)).status, ClipStatus.uploaded);
    // The status has moved on, so nothing is sent twice.
    await repo.addClip(id: id, file: picked, seconds: 30);
    expect((await repo.clip(id)).status, ClipStatus.uploaded);
    expect((await repo.clip(id)).addedByMe, isTrue);

    // The file landed and the next step didn't. Storage calls that a conflict.
    final late = uuid();
    final row = await start(owner, clip: late);
    await upload(owner, row['path'] as String);
    await repo.addClip(id: late, file: picked, seconds: 30);
    expect((await repo.clip(late)).status, ClipStatus.uploaded);

    await repo.delete(id);
    await repo.delete(late);
  }, skip: skip);
}
