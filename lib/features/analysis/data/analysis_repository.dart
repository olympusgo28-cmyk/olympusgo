import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/analysis_models.dart';

abstract class AnalysisRepository {
  Future<AnalysisStatus> status();
  Future<List<AnalysisClip>> clips();
  Future<List<AnalysisClip>> childClips(String childId);
  Future<AnalysisClip> clip(String id);

  /// Sends the file and queues the job. [id] stays the same on a retry, so a
  /// dropped signal reaches the same clip. [consentVersion] is the parent's
  /// agreement, for a clip of [childId].
  Future<void> addClip({
    required String id,
    required PickedClip file,
    required int seconds,
    String? childId,
    String? consentVersion,
  });

  Future<ClipFrame> frame(String path);
  Future<void> confirmCourt(
    String id, {
    required List<ui.Offset> corners,
    required String side,
  });
  Future<void> delete(String id);
  Future<void> extend(String id);
  Future<void> withdrawConsent(String id);
}

class SupabaseAnalysisRepository implements AnalysisRepository {
  SupabaseAnalysisRepository(this._client);

  final SupabaseClient _client;
  static const _bucket = 'analysis-clips';

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (e) {
      debugPrint('Analysis error: ${e.code}');
      if (e.code == 'P0001') throw AuthFailure(e.message);
      throw const AuthFailure('Something went wrong. Try again.');
    } on StorageException catch (e) {
      debugPrint('Analysis file error: ${e.statusCode}');
      throw const AuthFailure('The upload didn’t finish. Try again.');
    } on AuthFailure {
      rethrow;
    } on Exception {
      throw const AuthFailure('Check your connection and try again.');
    }
  }

  List<AnalysisClip> _list(Object? rows) => [
    for (final r in rows as List? ?? const [])
      AnalysisClip.fromRow((r as Map).cast<String, dynamic>()),
  ];

  /// Without the container, a local stack has nothing to run the job.
  Future<void> _standIn() async {
    if (!Env.localStandIn) return;
    try {
      await _client.functions.invoke('analysis-local', body: const {});
    } on Exception catch (e) {
      debugPrint('Analysis stand-in: ${e.runtimeType}');
    }
  }

  @override
  Future<AnalysisStatus> status() => _guard(() async {
    final r = await _client.rpc('analysis_status');
    return AnalysisStatus.fromRow((r as Map).cast<String, dynamic>());
  });

  @override
  Future<List<AnalysisClip>> clips() =>
      _guard(() async => _list(await _client.rpc('clip_list')));

  @override
  Future<List<AnalysisClip>> childClips(String childId) => _guard(
    () async => _list(
      await _client.rpc('child_clip_list', params: {'p_child': childId}),
    ),
  );

  @override
  Future<AnalysisClip> clip(String id) => _guard(() async {
    final r = await _client.rpc('clip_get', params: {'p_clip': id});
    return AnalysisClip.fromRow((r as Map).cast<String, dynamic>());
  });

  @override
  Future<void> addClip({
    required String id,
    required PickedClip file,
    required int seconds,
    String? childId,
    String? consentVersion,
  }) => _guard(() async {
    final row = await _client.rpc(
      'clip_create',
      params: {
        'p_clip': id,
        'p_subject': childId,
        'p_ext': file.ext,
        'p_seconds': seconds,
        'p_bytes': file.bytes,
        'p_everyone_agreed': true,
        'p_consent_version': consentVersion,
      },
    ) as Map;
    if (row['status'] == 'waiting') {
      try {
        await _client.storage
            .from(_bucket)
            .upload(
              row['path'] as String,
              File(file.path),
              fileOptions: FileOptions(
                contentType: file.ext == 'mov'
                    ? 'video/quicktime'
                    : 'video/mp4',
              ),
            );
      } on StorageException catch (e) {
        // A retry after the file landed and the next step didn't.
        if (e.statusCode != '409') rethrow;
      }
      await _client.rpc('clip_uploaded', params: {'p_clip': id});
    }
    await _standIn();
  });

  @override
  Future<ClipFrame> frame(String path) => _guard(() async {
    final bytes = await _client.storage.from(_bucket).download(path);
    final codec = await ui.instantiateImageCodec(bytes);
    final image = (await codec.getNextFrame()).image;
    final frame = ClipFrame(
      bytes: bytes,
      width: image.width,
      height: image.height,
    );
    image.dispose();
    codec.dispose();
    return frame;
  });

  @override
  Future<void> confirmCourt(
    String id, {
    required List<ui.Offset> corners,
    required String side,
  }) => _guard(() async {
    await _client.rpc(
      'clip_confirm_court',
      params: {
        'p_clip': id,
        'p_corners': [
          for (final p in corners) [p.dx, p.dy],
        ],
        'p_side': side,
      },
    );
    await _standIn();
  });

  @override
  Future<void> delete(String id) =>
      _guard(() => _client.rpc('clip_delete', params: {'p_clip': id}));

  @override
  Future<void> extend(String id) =>
      _guard(() => _client.rpc('clip_extend', params: {'p_clip': id}));

  @override
  Future<void> withdrawConsent(String id) =>
      _guard(() => _client.rpc('consent_withdraw', params: {'p_clip': id}));
}

/// Stores clips in memory and finishes each job the next time it's read.
class DemoAnalysisRepository implements AnalysisRepository {
  final _clips = <String, AnalysisClip>{};

  static final _frame = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA'
    '60e6kgAAAABJRU5ErkJggg==',
  );

  static const _report = ClipReport(
    distanceM: 412,
    avgSpeedMs: 1.4,
    topSpeedMs: 4.2,
    movingSeconds: 96,
    heatmap: [
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0, 0],
      [0, 2, 4, 4, 2, 0],
      [1, 4, 8, 8, 4, 1],
      [1, 4, 10, 10, 4, 1],
      [1, 3, 6, 6, 3, 1],
      [0, 1, 2, 2, 1, 0],
      [0, 0, 1, 1, 0, 0],
    ],
  );

  @override
  Future<AnalysisStatus> status() async => const AnalysisStatus(
    open: true,
    childrenOpen: true,
    maxSeconds: 180,
    maxMb: 200,
  );

  List<AnalysisClip> _newest(Iterable<AnalysisClip> list) =>
      list.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  @override
  Future<List<AnalysisClip>> clips() async => _newest(_clips.values);

  @override
  Future<List<AnalysisClip>> childClips(String childId) async =>
      _newest(_clips.values.where((c) => c.forChild));

  @override
  Future<AnalysisClip> clip(String id) async {
    final clip = _clips[id];
    if (clip == null) throw const AuthFailure('Clip not found.');
    return _clips[id] = switch (clip.status) {
      ClipStatus.uploaded => clip.copy(
        status: ClipStatus.courtReady,
        framePath: 'demo',
        corners: defaultCorners,
      ),
      ClipStatus.queued => clip.copy(status: ClipStatus.done, report: _report),
      _ => clip,
    };
  }

  @override
  Future<void> addClip({
    required String id,
    required PickedClip file,
    required int seconds,
    String? childId,
    String? consentVersion,
  }) async {
    final now = DateTime.now();
    _clips[id] = AnalysisClip(
      id: id,
      status: ClipStatus.uploaded,
      createdAt: now,
      purgeAt: now.add(const Duration(days: 90)),
      seconds: seconds,
      canExtend: true,
      forChild: childId != null,
      child: childId == null ? null : 'Your child',
    );
  }

  @override
  Future<ClipFrame> frame(String path) async =>
      ClipFrame(bytes: Uint8List.fromList(_frame), width: 16, height: 9);

  @override
  Future<void> confirmCourt(
    String id, {
    required List<ui.Offset> corners,
    required String side,
  }) async {
    _clips[id] = _clips[id]!.copy(
      status: ClipStatus.queued,
      corners: corners,
      side: side,
    );
  }

  @override
  Future<void> delete(String id) async => _clips.remove(id);

  @override
  Future<void> extend(String id) async {
    final clip = _clips[id]!;
    _clips[id] = clip.copy(
      canExtend: false,
      purgeAt: clip.purgeAt.add(const Duration(days: 90)),
    );
  }

  @override
  Future<void> withdrawConsent(String id) async {
    _clips[id] = _clips[id]!.copy(
      status: ClipStatus.withdrawn,
      canExtend: false,
      purgeAt: DateTime.now(),
    );
  }
}
