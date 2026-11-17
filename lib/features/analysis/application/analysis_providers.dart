import 'dart:async';

import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/analysis_models.dart';

part 'analysis_providers.g.dart';

Duration? _noRetry(int count, Object error) => null;

const clipPollEvery = Duration(seconds: 3);

/// After [clipPollSlowAfter], so a long queue stays under the rate limit.
const clipPollSlow = Duration(seconds: 15);
const clipPollSlowAfter = Duration(minutes: 5);

@riverpod
Future<AnalysisStatus> analysisStatus(Ref ref) =>
    ref.watch(analysisRepositoryProvider).status();

@Riverpod(retry: _noRetry)
Future<List<AnalysisClip>> myClips(Ref ref) =>
    ref.watch(analysisRepositoryProvider).clips();

@Riverpod(retry: _noRetry)
Future<List<AnalysisClip>> childClips(Ref ref, String childId) =>
    ref.watch(analysisRepositoryProvider).childClips(childId);

/// Asks again while the server works, and stops when the screen closes.
@Riverpod(retry: _noRetry)
Future<AnalysisClip> analysisClip(Ref ref, String id) async {
  final clip = await ref.watch(analysisRepositoryProvider).clip(id);
  if (clip.working && ref.mounted) {
    final age = DateTime.now().difference(clip.createdAt);
    final timer = Timer(
      age < clipPollSlowAfter ? clipPollEvery : clipPollSlow,
      ref.invalidateSelf,
    );
    ref.onDispose(timer.cancel);
  }
  return clip;
}

/// Clips on their way up from this phone. Outlives the screen, so leaving
/// during an upload doesn't read as an upload that failed.
@Riverpod(keepAlive: true)
class ClipUploads extends _$ClipUploads {
  @override
  Set<String> build() => const {};

  void start(String id) => state = {...state, id};

  void finish(String id) => state = {...state}..remove(id);
}

@Riverpod(retry: _noRetry)
Future<ClipFrame> clipFrame(Ref ref, String path) =>
    ref.watch(analysisRepositoryProvider).frame(path);

/// Picks a video. A provider so tests can hand over a file.
typedef ClipPicker = Future<PickedClip?> Function({
  required bool camera,
  required int maxSeconds,
});

@riverpod
ClipPicker clipPicker(Ref ref) =>
    ({required bool camera, required int maxSeconds}) async {
      final file = await ImagePicker().pickVideo(
        source: camera ? ImageSource.camera : ImageSource.gallery,
        maxDuration: Duration(seconds: maxSeconds),
      );
      if (file == null) return null;
      final name = file.path.toLowerCase();
      return PickedClip(
        path: file.path,
        ext: name.substring(name.lastIndexOf('.') + 1),
        bytes: await file.length(),
      );
    };
