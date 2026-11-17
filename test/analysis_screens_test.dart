import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/analysis/application/analysis_providers.dart';
import 'package:olympus_go/features/analysis/data/analysis_repository.dart';
import 'package:olympus_go/features/analysis/domain/analysis_models.dart';
import 'package:olympus_go/features/analysis/presentation/analysis_screens.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/fitness/application/fitness_providers.dart';
import 'package:olympus_go/features/fitness/presentation/fitness_screens.dart';
import 'package:olympus_go/features/guardian/presentation/parent_link_screens.dart';

const _file = PickedClip(path: '/tmp/a.mp4', ext: 'mp4', bytes: 1000);

class _Repo extends DemoAnalysisRepository {
  var open = true;
  var childrenOpen = true;
  var failUploads = 0;
  final added = <Map<String, Object?>>[];
  final confirmed = <(List<Offset>, String)>[];
  final extended = <String>[];
  final withdrawn = <String>[];
  final deleted = <String>[];
  final stored = <String, AnalysisClip>{};
  var reads = 0;
  Object? failRead;

  @override
  Future<AnalysisStatus> status() async => AnalysisStatus(
    open: open,
    childrenOpen: childrenOpen,
    maxSeconds: 180,
    maxMb: 200,
  );

  @override
  Future<List<AnalysisClip>> clips() async => stored.values.toList();

  @override
  Future<List<AnalysisClip>> childClips(String childId) async =>
      stored.values.toList();

  @override
  Future<AnalysisClip> clip(String id) async {
    reads++;
    if (failRead != null) throw failRead!;
    final clip = stored[id];
    if (clip == null) throw const AuthFailure('Clip not found.');
    return clip;
  }

  @override
  Future<void> addClip({
    required String id,
    required PickedClip file,
    required int seconds,
    String? childId,
    String? consentVersion,
  }) async {
    added.add({
      'id': id,
      'seconds': seconds,
      'child': childId,
      'consent': consentVersion,
    });
    if (failUploads-- > 0) {
      throw const AuthFailure('The upload didn’t finish. Try again.');
    }
    stored[id] = clipIn(ClipStatus.uploaded, id: id);
  }

  @override
  Future<void> confirmCourt(
    String id, {
    required List<Offset> corners,
    required String side,
  }) async {
    confirmed.add((corners, side));
    stored[id] = stored[id]!.copy(status: ClipStatus.queued);
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    stored.remove(id);
  }

  @override
  Future<void> extend(String id) async {
    extended.add(id);
    stored[id] = stored[id]!.copy(canExtend: false);
  }

  @override
  Future<void> withdrawConsent(String id) async {
    withdrawn.add(id);
    stored[id] = stored[id]!.copy(status: ClipStatus.withdrawn);
  }
}

AnalysisClip clipIn(
  ClipStatus status, {
  String id = 'c1',
  String? errorCode,
  bool forChild = false,
  bool canExtend = false,
  bool fileGone = false,
  bool addedByMe = true,
  DateTime? createdAt,
  ClipReport? report,
}) => AnalysisClip(
  id: id,
  status: status,
  createdAt: createdAt ?? DateTime.now(),
  purgeAt: DateTime(2027, 1, 31),
  errorCode: errorCode,
  forChild: forChild,
  child: forChild ? 'Mia' : null,
  canExtend: canExtend,
  fileGone: fileGone,
  addedByMe: addedByMe,
  corners: status == ClipStatus.courtReady ? defaultCorners : null,
  report: report,
);

const _report = ClipReport(
  distanceM: 412.4,
  avgSpeedMs: 1.42,
  topSpeedMs: 4.2,
  movingSeconds: 96,
  heatmap: [
    [10, 0, 0, 0, 0, 0],
    [0, 90, 0, 0, 0, 0],
  ],
);

Future<void> _pump(
  WidgetTester tester,
  _Repo repo, {
  String start = Routes.analysis,
  Object? extra,
  ClipPicker? picker,
}) async {
  await tester.binding.setSurfaceSize(const Size(420, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
      GoRoute(path: Routes.analysis, builder: (_, _) => const MyClipsScreen()),
      GoRoute(
        path: Routes.analysisAdd,
        builder: (_, s) => AddClipScreen(child: s.extra as (String, String)?),
      ),
      GoRoute(
        path: '${Routes.analysis}/:id',
        builder: (_, s) => ClipScreen(id: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/kid',
        builder: (_, _) => const ChildClipsScreen(childId: 'k1', name: 'Mia'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        analysisRepositoryProvider.overrideWithValue(repo),
        if (picker != null) clipPickerProvider.overrideWithValue(picker),
      ],
      retry: (_, _) => null,
      child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  router.push<void>(start, extra: extra).ignore();
  await _settle(tester);
}

// Not pumpAndSettle: the waiting screen's spinner never stops.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

ClipPicker pickerGiving(PickedClip? file) =>
    ({required bool camera, required int maxSeconds}) async => file;

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await _settle(tester);
  await tester.tap(find.text(text).first);
  await _settle(tester);
}

KitButton button(WidgetTester tester, String label) =>
    tester.widget(find.widgetWithText(KitButton, label));

void main() {
  group('corners', () {
    test('a court seen from behind is fine', () {
      expect(cornersOk(defaultCorners), isTrue);
    });

    test('swapped or crossed corners are not', () {
      final d = defaultCorners;
      expect(cornersOk([d[1], d[0], d[2], d[3]]), isFalse);
      expect(cornersOk([d[2], d[3], d[0], d[1]]), isFalse);
      expect(cornersOk(d.reversed.toList()), isFalse);
    });
  });

  group('failure wording', () {
    test('every code the server sends has its own words', () {
      for (final code in [
        'bad_video',
        'too_long',
        'no_court',
        'no_player',
        'doubles',
        'not_allowed',
      ]) {
        expect(clipFailure(code), isNot(clipFailure('internal')), reason: code);
      }
    });

    test('doubles says singles only', () {
      expect(clipFailure('doubles').$1, 'Singles only for now');
    });
  });

  group('reading the server', () {
    test('a report and its grid', () {
      final clip = AnalysisClip.fromRow({
        'id': 'c1',
        'status': 'done',
        'created_at': '2026-11-02T00:00:00Z',
        'purge_at': '2027-01-31T00:00:00Z',
        'corners': [
          [0.1, 0.2],
          [0.9, 0.2],
          [1, 0.9],
          [0, 0.9],
        ],
        'report': {
          'distance_m': 12.5,
          'avg_speed_ms': 1,
          'top_speed_ms': 3.2,
          'moving_seconds': 9,
          'heatmap': [
            [1, 2],
          ],
        },
      });
      expect(clip.corners![2], const Offset(1, 0.9));
      expect(clip.report!.heatmap[0][1], 2);
    });

    test('court_ready is a status of its own', () {
      final clip = AnalysisClip.fromRow({
        'id': 'c1',
        'status': 'court_ready',
        'created_at': '2026-11-02T00:00:00Z',
        'purge_at': '2027-01-31T00:00:00Z',
      });
      expect(clip.status, ClipStatus.courtReady);
      expect(clip.working, isFalse);
    });
  });

  group('my clips', () {
    testWidgets('no clips yet', (tester) async {
      await _pump(tester, _Repo());
      expect(find.text('Add a clip'), findsOneWidget);
      expect(find.text('Your clips'), findsNothing);
    });

    testWidgets('closed, nothing to add', (tester) async {
      await _pump(tester, _Repo()..open = false);
      expect(find.text('Add a clip'), findsNothing);
      expect(find.text('Analysis isn’t open yet.'), findsOneWidget);
    });

    testWidgets('each clip says where it has got to', (tester) async {
      final repo = _Repo()
        ..stored['a'] = clipIn(ClipStatus.courtReady, id: 'a')
        ..stored['b'] = clipIn(
          ClipStatus.failed,
          id: 'b',
          errorCode: 'doubles',
        );
      await _pump(tester, repo);
      expect(find.text('Mark the court'), findsOneWidget);
      expect(find.text('Singles only for now'), findsOneWidget);
    });

    testWidgets('a failed load can be tried again', (tester) async {
      final repo = _FailingList();
      await _pump(tester, repo);
      expect(find.text('Try again'), findsOneWidget);
      repo.fail = false;
      await tapText(tester, 'Try again');
      expect(find.text('Add a clip'), findsOneWidget);
    });
  });

  group('adding a clip', () {
    testWidgets('needs a file and the tick', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        repo,
        start: Routes.analysisAdd,
        picker: pickerGiving(_file),
      );
      expect(button(tester, 'Upload clip').onPressed, isNull);
      await tapText(tester, 'Choose from my library');
      expect(find.text('Clip chosen.'), findsOneWidget);
      expect(button(tester, 'Upload clip').onPressed, isNull);
      await tapText(tester, 'Everyone in this clip has agreed to be filmed.');
      await tapText(tester, 'Upload clip');
      expect(repo.added.single['seconds'], 180);
      expect(repo.added.single['child'], isNull);
      expect(repo.added.single['consent'], isNull);
      expect(find.text('Reading the clip'), findsOneWidget);
    });

    testWidgets('a file that is too big never leaves the phone', (
      tester,
    ) async {
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        picker: pickerGiving(
          const PickedClip(path: '/a.mp4', ext: 'mp4', bytes: 201 * 1048576),
        ),
      );
      await tapText(tester, 'Choose from my library');
      expect(find.textContaining('The limit is 200 MB'), findsOneWidget);
      expect(find.text('Clip chosen.'), findsNothing);
    });

    testWidgets('another kind of file is turned away', (tester) async {
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        picker: pickerGiving(
          const PickedClip(path: '/a.3gp', ext: '3gp', bytes: 10),
        ),
      );
      await tapText(tester, 'Record a clip');
      expect(find.text('Choose an MP4 or MOV clip.'), findsOneWidget);
    });

    testWidgets('cancelling the picker changes nothing', (tester) async {
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        picker: pickerGiving(null),
      );
      await tapText(tester, 'Record a clip');
      expect(find.text('Clip chosen.'), findsNothing);
    });

    testWidgets('a retry reaches the same clip', (tester) async {
      final repo = _Repo()..failUploads = 1;
      await _pump(
        tester,
        repo,
        start: Routes.analysisAdd,
        picker: pickerGiving(_file),
      );
      await tapText(tester, 'Choose from my library');
      await tapText(tester, 'Everyone in this clip has agreed to be filmed.');
      await tapText(tester, 'Upload clip');
      expect(find.text('The upload didn’t finish. Try again.'), findsOneWidget);
      await tapText(tester, 'Try again');
      expect(repo.added, hasLength(2));
      expect(repo.added[0]['id'], repo.added[1]['id']);
      expect(find.text('Reading the clip'), findsOneWidget);
    });

    testWidgets('a new file needs agreeing again', (tester) async {
      var file = _file;
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        extra: ('k1', 'Mia'),
        picker: ({required camera, required maxSeconds}) async => file,
      );
      await tapText(tester, 'Choose from my library');
      await tapText(tester, 'Everyone in this clip has agreed to be filmed.');
      file = const PickedClip(path: '/b.mp4', ext: 'mp4', bytes: 99);
      await tapText(tester, 'Choose another');
      await tapText(tester, 'Clip chosen.');
      final box = tester.widget<KitConfirmBox>(
        find.byType(KitConfirmBox).first,
      );
      expect(box.checked, isFalse);
    });

    testWidgets('a rejected file can’t leave the old one ready', (
      tester,
    ) async {
      var file = _file;
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        picker: ({required camera, required maxSeconds}) async => file,
      );
      await tapText(tester, 'Choose from my library');
      await tapText(tester, 'Everyone in this clip has agreed to be filmed.');
      file = const PickedClip(path: '/b.mp4', ext: 'mp4', bytes: 201 * 1048576);
      await tapText(tester, 'Choose another');
      expect(find.text('Clip chosen.'), findsNothing);
      expect(button(tester, 'Upload clip').onPressed, isNull);
    });

    testWidgets('refused access says where to fix it', (tester) async {
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        picker: ({required camera, required maxSeconds}) async =>
            throw PlatformException(code: 'camera_access_denied'),
      );
      await tapText(tester, 'Record a clip');
      expect(find.textContaining('in Settings'), findsOneWidget);
    });

    testWidgets('a file that vanished doesn’t lock the buttons', (
      tester,
    ) async {
      var fail = true;
      await _pump(
        tester,
        _Repo(),
        start: Routes.analysisAdd,
        picker: ({required camera, required maxSeconds}) async {
          if (fail) throw const FileSystemException('gone');
          return _file;
        },
      );
      await tapText(tester, 'Choose from my library');
      expect(find.textContaining('Can’t open that'), findsOneWidget);
      fail = false;
      await tapText(tester, 'Choose from my library');
      expect(find.text('Clip chosen.'), findsOneWidget);
    });

    testWidgets('closed, the screen can’t add a clip', (tester) async {
      await _pump(tester, _Repo()..open = false, start: Routes.analysisAdd);
      expect(find.text('This isn’t open yet.'), findsOneWidget);
      expect(find.text('Record a clip'), findsNothing);
    });

    testWidgets('a parent has to give consent as well', (tester) async {
      final repo = _Repo();
      await _pump(
        tester,
        repo,
        start: Routes.analysisAdd,
        extra: ('k1', 'Mia'),
        picker: pickerGiving(_file),
      );
      await tapText(tester, 'Choose from my library');
      await tapText(tester, 'Everyone in this clip has agreed to be filmed.');
      expect(button(tester, 'Upload clip').onPressed, isNull);
      await tapText(
        tester,
        'I’m Mia’s parent or guardian, and I agree to OlympusGO analysing '
        'this clip of them.',
      );
      await tapText(tester, 'Upload clip');
      expect(repo.added.single['child'], 'k1');
      expect(repo.added.single['consent'], clipConsentVersion);
    });
  });

  group('a clip', () {
    testWidgets('while it works, it checks again and stops', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.uploaded);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tester.pump();
      expect(find.text('Reading the clip'), findsOneWidget);
      expect(find.textContaining('safe to leave'), findsOneWidget);
      final before = repo.reads;
      repo.stored['c1'] = clipIn(ClipStatus.courtReady);
      await tester.pump(clipPollEvery);
      await _settle(tester);
      expect(repo.reads, greaterThan(before));
      expect(find.text('Mark the court'), findsOneWidget);
      final after = repo.reads;
      await tester.pump(clipPollEvery * 3);
      expect(repo.reads, after);
    });

    testWidgets('a long wait asks less often', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.queued,
          createdAt: DateTime.now().subtract(clipPollSlowAfter),
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      final before = repo.reads;
      await tester.pump(clipPollEvery * 2);
      expect(repo.reads, before);
      await tester.pump(clipPollSlow);
      await tester.pump();
      expect(repo.reads, greaterThan(before));
    });

    testWidgets('leaving mid-upload doesn’t read as a failure', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.waiting);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('The upload didn’t finish'), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(ClipScreen)),
      );
      container.read(clipUploadsProvider.notifier).start('c1');
      await tester.pump();
      expect(find.text('Uploading your clip'), findsOneWidget);
      expect(find.text('Delete clip'), findsNothing);
      container.read(clipUploadsProvider.notifier).finish('c1');
      await tester.pump();
    });

    testWidgets('a withdrawal confirmed as the status moves still counts', (
      tester,
    ) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(ClipStatus.queued, forChild: true);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tester.ensureVisible(find.text('Withdraw consent'));
      await tester.tap(find.text('Withdraw consent'));
      await _settle(tester);
      repo.stored['c1'] = clipIn(
        ClipStatus.done,
        report: _report,
        forChild: true,
      );
      await tester.pump(clipPollEvery);
      await _settle(tester);
      await tester.tap(find.text('Withdraw consent').last);
      await _settle(tester);
      expect(repo.withdrawn, ['c1']);
    });

    testWidgets('a delete confirmed as the status moves leaves the page', (
      tester,
    ) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.queued);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tester.ensureVisible(find.text('Delete clip'));
      await tester.tap(find.text('Delete clip'));
      await _settle(tester);
      repo.stored['c1'] = clipIn(ClipStatus.done, report: _report);
      await tester.pump(clipPollEvery);
      await _settle(tester);
      await tester.tap(find.text('Delete clip').last);
      await _settle(tester);
      expect(repo.deleted, ['c1']);
      expect(find.byType(ClipScreen), findsNothing);
    });

    testWidgets('a clip’s list follows it while it’s open', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.uploaded);
      await _pump(tester, repo);
      expect(find.text('Reading the clip'), findsOneWidget);
      await tester.tap(find.text('Reading the clip'));
      await _settle(tester);
      repo.stored['c1'] = clipIn(ClipStatus.courtReady);
      await tester.pump(clipPollEvery);
      await _settle(tester);
      tester.element(find.byType(ClipScreen)).pop();
      await _settle(tester);
      expect(find.text('Mark the court'), findsOneWidget);
    });

    testWidgets('the other parent is told to wait for the court', (
      tester,
    ) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.courtReady,
          forChild: true,
          addedByMe: false,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('Waiting for the court to be marked'), findsOneWidget);
      expect(find.text('Analyse this game'), findsNothing);
      expect(find.text('Withdraw consent'), findsOneWidget);
    });

    testWidgets('the other parent is never told to delete an upload', (
      tester,
    ) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.waiting,
          forChild: true,
          addedByMe: false,
        );
      await _pump(tester, repo, start: '/kid');
      expect(find.text('Mia · Being added'), findsOneWidget);
      await tapText(tester, 'Mia · Being added');
      expect(find.text('Waiting for the upload'), findsOneWidget);
      expect(find.textContaining('add it again'), findsNothing);
    });

    testWidgets('the other parent’s page moves on by itself', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.courtReady,
          forChild: true,
          addedByMe: false,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      repo.stored['c1'] = clipIn(
        ClipStatus.done,
        report: _report,
        forChild: true,
        addedByMe: false,
      );
      await tester.pump(clipPollEvery);
      await _settle(tester);
      expect(find.text('Mia’s report'), findsOneWidget);
    });

    testWidgets('a child with no name on file reads sensibly', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = AnalysisClip(
          id: 'c1',
          status: ClipStatus.courtReady,
          createdAt: DateTime.now(),
          purgeAt: DateTime.now(),
          forChild: true,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('Which side was your child on?'), findsOneWidget);
    });

    testWidgets('a child’s clip is worded for the parent', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(ClipStatus.courtReady, forChild: true);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('Which side was Mia on?'), findsOneWidget);
      expect(find.textContaining('were you'), findsNothing);
    });

    testWidgets('a dropped check says so and can start again', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.queued);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      repo.failRead = const AuthFailure('Check your connection.');
      await tester.pump(clipPollEvery);
      await tester.pump();
      expect(find.textContaining('Can’t check on your clip'), findsOneWidget);
      repo
        ..failRead = null
        ..stored['c1'] = clipIn(ClipStatus.done, report: _report);
      await tester.ensureVisible(find.text('Try again'));
      await tester.tap(find.text('Try again'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Your report'), findsOneWidget);
    });

    testWidgets('a clip that is not yours is not found', (tester) async {
      await _pump(tester, _Repo(), start: Routes.analysisClip('nope'));
      expect(find.text('Clip not found.'), findsOneWidget);
    });

    testWidgets('marking the court needs a side', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.courtReady);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(button(tester, 'Analyse this game').onPressed, isNull);
      await tapText(tester, 'Far from the camera');
      await tapText(tester, 'Analyse this game');
      expect(repo.confirmed.single.$2, 'far');
      expect(repo.confirmed.single.$1, defaultCorners);
      await tester.pump();
      expect(find.text('Analysing the game'), findsOneWidget);
    });

    testWidgets('dragging a dot moves that corner only', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.courtReady);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tester.drag(
        find.bySemanticsLabel('Far left corner'),
        const Offset(20, 10),
      );
      await _settle(tester);
      await tapText(tester, 'Near the camera');
      await tapText(tester, 'Analyse this game');
      final corners = repo.confirmed.single.$1;
      expect(corners[0].dx, greaterThan(defaultCorners[0].dx));
      expect(corners[0].dy, greaterThan(defaultCorners[0].dy));
      expect(corners.sublist(1), defaultCorners.sublist(1));
    });

    testWidgets('crossed dots stop the analysis', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.courtReady);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tester.drag(
        find.bySemanticsLabel('Far left corner'),
        const Offset(300, 0),
      );
      await _settle(tester);
      await tapText(tester, 'Near the camera');
      expect(find.textContaining('crossed over'), findsOneWidget);
      expect(button(tester, 'Analyse this game').onPressed, isNull);
    });

    testWidgets('the report says it is an estimate', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(ClipStatus.done, report: _report);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.textContaining('estimates'), findsOneWidget);
      expect(find.text('412 m'), findsOneWidget);
      expect(find.text('1.4 m/s'), findsOneWidget);
      expect(find.text('4.2 m/s'), findsOneWidget);
      expect(find.text('1 min 36 s'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('map of the court')), findsOneWidget);
      expect(find.text('We’ll delete the clip on Sun 31 Jan.'), findsOneWidget);
    });

    testWidgets('after the file goes, the numbers stay', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.done,
          report: _report,
          fileGone: true,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.textContaining('Only the numbers remain'), findsOneWidget);
    });

    for (final (code, words) in [
      ('doubles', 'Singles only for now'),
      ('no_court', 'We couldn’t find the court'),
      ('internal', 'Something went wrong on our side'),
    ]) {
      testWidgets('a failure: $code', (tester) async {
        final repo = _Repo()
          ..stored['c1'] = clipIn(ClipStatus.failed, errorCode: code);
        await _pump(tester, repo, start: Routes.analysisClip('c1'));
        expect(find.text(words), findsOneWidget);
        expect(find.text('Delete clip'), findsOneWidget);
      });
    }

    testWidgets('after a withdrawal the numbers stay (Q207)', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.withdrawn,
          report: _report,
          forChild: true,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('412 m'), findsOneWidget);
      expect(find.textContaining('within 7 days'), findsOneWidget);
      expect(find.text('Withdraw consent'), findsNothing);
    });

    testWidgets('an unfinished upload', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.waiting);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('The upload didn’t finish'), findsOneWidget);
    });

    testWidgets('deleting asks first', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(ClipStatus.done, report: _report);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tapText(tester, 'Delete clip');
      expect(find.text('Delete this clip?'), findsOneWidget);
      await tapText(tester, 'Keep it');
      expect(repo.deleted, isEmpty);
      await tapText(tester, 'Delete clip');
      await tester.tap(find.text('Delete clip').last);
      await _settle(tester);
      expect(repo.deleted, ['c1']);
      expect(find.text('Your report'), findsNothing);
    });

    testWidgets('an adult sees no parent actions', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.done,
          report: _report,
          canExtend: true,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      expect(find.text('Keep this clip longer'), findsNothing);
      expect(find.text('Withdraw consent'), findsNothing);
    });
  });

  group('the way in', () {
    Future<void> show(WidgetTester tester, Widget screen, _Repo repo) async {
      await tester.binding.setSurfaceSize(const Size(420, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [analysisRepositoryProvider.overrideWithValue(repo)],
          retry: (_, _) => null,
          child: MaterialApp(theme: OgTheme.light(), home: screen),
        ),
      );
      await _settle(tester);
    }

    testWidgets('My workouts shows the row when open', (tester) async {
      await show(tester, const FitnessHomeScreen(), _Repo());
      expect(find.text('Analyse my game'), findsOneWidget);
      await show(
        tester,
        const FitnessHomeScreen(key: Key('closed')),
        _Repo()..open = false,
      );
      expect(find.text('Analyse my game'), findsNothing);
    });

    testWidgets('Fitness closing doesn’t strand them either', (tester) async {
      final repo = _Repo()..stored['c1'] = clipIn(ClipStatus.done);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analysisRepositoryProvider.overrideWithValue(repo),
            fitnessOpenProvider.overrideWith((_) async => false),
          ],
          retry: (_, _) => null,
          child: MaterialApp(
            theme: OgTheme.light(),
            home: const FitnessHomeScreen(),
          ),
        ),
      );
      await _settle(tester);
      expect(find.byType(MyClipsScreen), findsOneWidget);
    });

    testWidgets('closing it doesn’t strand a player’s clips', (tester) async {
      final repo = _Repo()
        ..open = false
        ..stored['c1'] = clipIn(ClipStatus.done);
      await show(tester, const FitnessHomeScreen(), repo);
      expect(find.text('Analyse my game'), findsOneWidget);
    });

    testWidgets('a child’s page shows clips when open', (tester) async {
      await show(tester, const ChildDetailScreen(childId: 'k1'), _Repo());
      expect(find.text('Game clips'), findsOneWidget);
      await show(
        tester,
        const ChildDetailScreen(key: Key('closed'), childId: 'k1'),
        _Repo()..childrenOpen = false,
      );
      expect(find.text('Game clips'), findsNothing);
    });

    testWidgets('closing it doesn’t strand a parent', (tester) async {
      final repo = _Repo()
        ..childrenOpen = false
        ..stored['c1'] = clipIn(ClipStatus.done, forChild: true);
      await show(tester, const ChildDetailScreen(childId: 'k1'), repo);
      expect(find.text('Game clips'), findsOneWidget);
    });
  });

  group('a parent', () {
    testWidgets('sees their child’s clips', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(ClipStatus.done, forChild: true);
      await _pump(tester, repo, start: '/kid');
      expect(find.text('Mia · Report ready'), findsOneWidget);
      expect(find.text('Add a clip'), findsOneWidget);
    });

    testWidgets('can’t add one while it is closed', (tester) async {
      await _pump(tester, _Repo()..childrenOpen = false, start: '/kid');
      expect(find.text('Add a clip'), findsNothing);
      expect(find.text('Clips of children aren’t open yet.'), findsOneWidget);
    });

    testWidgets('can keep a clip longer, once', (tester) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(
          ClipStatus.done,
          report: _report,
          forChild: true,
          canExtend: true,
        );
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tapText(tester, 'Keep this clip longer');
      expect(repo.extended, ['c1']);
      expect(find.text('Keep this clip longer'), findsNothing);
    });

    testWidgets('can withdraw, and the screen says what happens', (
      tester,
    ) async {
      final repo = _Repo()
        ..stored['c1'] = clipIn(ClipStatus.queued, forChild: true);
      await _pump(tester, repo, start: Routes.analysisClip('c1'));
      await tester.pump();
      await tester.ensureVisible(find.text('Withdraw consent'));
      await tester.tap(find.text('Withdraw consent'));
      await _settle(tester);
      await tester.tap(find.text('Withdraw consent').last);
      await _settle(tester);
      expect(repo.withdrawn, ['c1']);
      expect(find.textContaining('within 7 days'), findsOneWidget);
    });
  });
}

class _FailingList extends _Repo {
  var fail = true;

  @override
  Future<List<AnalysisClip>> clips() async {
    if (fail) throw const AuthFailure('Check your connection.');
    return const [];
  }
}
