import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:olympus_go/core/providers.dart';
import 'package:olympus_go/core/router/routes.dart';
import 'package:olympus_go/core/theme/og_theme.dart';
import 'package:olympus_go/core/widgets/og_kit.dart';
import 'package:olympus_go/features/analysis/application/analysis_providers.dart';
import 'package:olympus_go/features/analysis/domain/analysis_models.dart';
import 'package:olympus_go/features/auth/data/auth_repository.dart';
import 'package:olympus_go/features/clubs/presentation/group_chat_screens.dart';
import 'package:olympus_go/features/feed/application/feed_providers.dart';
import 'package:olympus_go/features/feed/data/feed_repository.dart';
import 'package:olympus_go/features/feed/domain/feed_models.dart';
import 'package:olympus_go/features/feed/presentation/feed_screens.dart';
import 'package:olympus_go/features/onboarding/domain/sport.dart';
import 'package:olympus_go/features/play/application/play_providers.dart';
import 'package:olympus_go/features/social/data/social_repository.dart';
import 'package:olympus_go/features/social/domain/social_models.dart';
import 'package:video_player/video_player.dart';

FeedPost post(
  String id, {
  PostStatus status = PostStatus.live,
  bool liked = false,
  int likes = 2,
  String caption = 'Smash practice',
  bool mine = false,
}) => FeedPost(
  id: id,
  authorId: 'a-$id',
  author: 'Mei Tan',
  caption: caption,
  sport: 'badminton',
  seconds: 20,
  hasPoster: false,
  likes: likes,
  liked: liked,
  mine: mine,
  status: status,
);

class _Repo extends DemoFeedRepository {
  var open = true;
  var canPost = true;
  var canDiscover = true;
  var following_ = <FeedPost>[];
  var discover_ = <FeedPost>[];
  var mine_ = <FeedPost>[];
  var failList = false;
  var failUpload = 0;
  var failLike = false;
  final added = <Map<String, Object?>>[];
  final likes = <String>[];
  final unlikes = <String>[];
  final played = <String>[];
  final deleted = <String>[];
  final retried = <String>[];
  var discoverReads = 0;

  @override
  Future<FeedStatus> status() async => FeedStatus(
    open: open,
    canPost: canPost,
    canDiscover: canDiscover,
    maxSeconds: 60,
    maxMb: 100,
  );

  @override
  Future<List<FeedPost>> following() async {
    if (failList) throw const AuthFailure('No.');
    return following_;
  }

  @override
  Future<List<FeedPost>> discover() async {
    discoverReads++;
    return discover_;
  }

  @override
  Future<List<FeedPost>> mine() async => mine_;

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
    added.add({
      'id': id,
      'caption': caption,
      'sport': sport,
      'audience': audience,
      'noMinors': noMinors,
    });
    if (failUpload-- > 0) {
      throw const AuthFailure('The upload didn’t finish. Try again.');
    }
  }

  @override
  Future<void> like(String id) async {
    likes.add(id);
    if (failLike) throw const AuthFailure('This video isn’t available.');
  }

  @override
  Future<void> unlike(String id) async => unlikes.add(id);

  @override
  Future<String> playUrl(String id) async {
    played.add(id);
    return 'http://local/$id.mp4';
  }

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    mine_ = [...mine_]..removeWhere((p) => p.id == id);
  }

  @override
  Future<void> retry(String id) async => retried.add(id);
}

class _Social implements SocialRepository {
  final blocked_ = <String>[];

  @override
  Future<void> block(String id) async => blocked_.add(id);

  @override
  Future<List<PlayerSummary>> blocked() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// No plugin in a test, so loading fails unless a test says otherwise.
class _Player extends VideoPlayerController {
  _Player(super.url, {this.playable = false}) : super.networkUrl() {
    live.add(this);
  }

  static final live = <_Player>[];
  final bool playable;
  var paused = 0;

  void fail() => value = value.copyWith(errorDescription: 'link ran out');

  @override
  Future<void> initialize() async {
    if (!playable) throw Exception('no plugin');
    value = value.copyWith(size: const Size(16, 9), isInitialized: true);
  }

  @override
  Future<void> play() async => value = value.copyWith(isPlaying: true);

  @override
  Future<void> pause() async {
    paused++;
    value = value.copyWith(isPlaying: false);
  }

  @override
  // ignore: must_call_super
  Future<void> dispose() async {}
}

const _file = PickedClip(path: '/tmp/a.mp4', ext: 'mp4', bytes: 1000);

ClipPicker pickerGiving(PickedClip? file) =>
    ({required bool camera, required int maxSeconds}) async => file;

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<List<Uri>> _pump(
  WidgetTester tester,
  _Repo repo, {
  String start = Routes.videos,
  ClipPicker? picker,
  _Social? social,
  bool playable = false,
}) async {
  _Player.live.clear();
  await tester.binding.setSurfaceSize(const Size(420, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final made = <Uri>[];
  final router = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/home', builder: (_, _) => const SizedBox()),
      GoRoute(path: Routes.videos, builder: (_, _) => const FeedScreen()),
      GoRoute(path: Routes.addPost, builder: (_, _) => const AddPostScreen()),
      GoRoute(path: Routes.myPosts, builder: (_, _) => const MyPostsScreen()),
      GoRoute(
        path: '${Routes.videos}/:id/report',
        builder: (_, s) =>
            ReportContentScreen.video(postId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/players/:id',
        builder: (_, s) => Text('player ${s.pathParameters['id']}'),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        feedRepositoryProvider.overrideWithValue(repo),
        liveSportsProvider.overrideWith(
          (_) async => const [Sport.badminton, Sport.tennis],
        ),
        postPlayerMakerProvider.overrideWithValue((url) {
          made.add(url);
          return _Player(url, playable: playable);
        }),
        if (picker != null) clipPickerProvider.overrideWithValue(picker),
        if (social != null) socialRepositoryProvider.overrideWithValue(social),
      ],
      retry: (_, _) => null,
      child: MaterialApp.router(theme: OgTheme.light(), routerConfig: router),
    ),
  );
  await tester.pump();
  router.push<void>(start).ignore();
  await _settle(tester);
  return made;
}

Future<void> tapText(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text).first);
  await _settle(tester);
  await tester.tap(find.text(text).first);
  await _settle(tester);
}

KitButton button(WidgetTester tester, String label) => tester.widget<KitButton>(
  find.ancestor(of: find.text(label), matching: find.byType(KitButton)).first,
);

void main() {
  group('feed', () {
    testWidgets('an adult gets both tabs', (tester) async {
      await _pump(tester, _Repo()..following_ = [post('1')]);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Discover'), findsOneWidget);
      expect(find.text('Smash practice'), findsOneWidget);
    });

    testWidgets('a teen gets Following alone, and never asks for Discover', (
      tester,
    ) async {
      final repo = _Repo()
        ..canDiscover = false
        ..canPost = false
        ..following_ = [post('1')];
      await _pump(tester, repo);
      expect(find.text('Discover'), findsNothing);
      expect(find.bySemanticsLabel('My posts'), findsNothing);
      expect(repo.discoverReads, 0);
    });

    testWidgets('Discover shows its own list', (tester) async {
      final repo = _Repo()
        ..discover_ = [post('2', caption: 'Open court tonight')];
      await _pump(tester, repo);
      await tapText(tester, 'Discover');
      expect(find.text('Open court tonight'), findsOneWidget);
    });

    testWidgets('a list ends', (tester) async {
      await _pump(tester, _Repo()..following_ = [post('1')]);
      expect(find.text('That’s everything for now.'), findsOneWidget);
    });

    testWidgets('an empty Following says what to do', (tester) async {
      await _pump(tester, _Repo());
      expect(
        find.text('No videos yet. Follow people to see theirs here.'),
        findsOneWidget,
      );
    });

    testWidgets('a closed feed says so', (tester) async {
      await _pump(tester, _Repo()..open = false);
      expect(find.text('Videos aren’t open yet.'), findsOneWidget);
    });

    testWidgets('a failed list offers Try again', (tester) async {
      final repo = _Repo()..failList = true;
      await _pump(tester, repo);
      expect(find.text('No.'), findsOneWidget);
      repo
        ..failList = false
        ..following_ = [post('1')];
      await tapText(tester, 'Try again');
      expect(find.text('Smash practice'), findsOneWidget);
    });
  });

  group('playing', () {
    testWidgets('nothing loads until a tap', (tester) async {
      final repo = _Repo()..following_ = [post('1'), post('2')];
      final made = await _pump(tester, repo);
      expect(made, isEmpty, reason: 'no autoplay, for anyone');
      expect(repo.played, isEmpty, reason: 'no link is even asked for');
      await tester.tap(find.bySemanticsLabel('Play video').first);
      await _settle(tester);
      expect(repo.played, ['1']);
      expect(made.map((u) => u.toString()), ['http://local/1.mp4']);
    });

    testWidgets('a video that can\'t play says so', (tester) async {
      await _pump(tester, _Repo()..following_ = [post('1')]);
      await tester.tap(find.bySemanticsLabel('Play video').first);
      await _settle(tester);
      expect(find.text('Can’t play this. Tap to try again.'), findsOneWidget);
    });

    testWidgets('starting a second video pauses the first', (tester) async {
      final repo = _Repo()..following_ = [post('1'), post('2')];
      final made = await _pump(tester, repo, playable: true);
      await tester.tap(find.bySemanticsLabel('Play video').first);
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Play video').first);
      await _settle(tester);
      expect(made.length, 2);
      expect(_Player.live.first.paused, greaterThan(0));
    });

    testWidgets('opening another page stops the sound', (tester) async {
      final repo = _Repo()..following_ = [post('1')];
      await _pump(tester, repo, playable: true);
      await tester.tap(find.bySemanticsLabel('Play video').first);
      await _settle(tester);
      await tapText(tester, 'Mei Tan');
      expect(_Player.live.first.paused, greaterThan(0));
    });

    testWidgets('a playback error goes back to a tap for a new link', (
      tester,
    ) async {
      final repo = _Repo()..following_ = [post('1')];
      await _pump(tester, repo, playable: true);
      await tester.tap(find.bySemanticsLabel('Play video').first);
      await _settle(tester);
      expect(repo.played, ['1']);
      _Player.live.first.fail();
      await _settle(tester);
      await tapText(tester, 'Can’t play this. Tap to try again.');
      expect(repo.played, ['1', '1']);
    });
  });

  group('responding', () {
    testWidgets('a like counts at once', (tester) async {
      final repo = _Repo()..following_ = [post('1')];
      await _pump(tester, repo);
      await tester.tap(find.bySemanticsLabel('Like'));
      await _settle(tester);
      expect(repo.likes, ['1']);
      expect(find.text('3'), findsOneWidget);
      expect(find.bySemanticsLabel('Unlike'), findsOneWidget);
    });

    testWidgets('a like that fails goes back', (tester) async {
      final repo = _Repo()
        ..failLike = true
        ..following_ = [post('1')];
      await _pump(tester, repo);
      await tester.tap(find.bySemanticsLabel('Like'));
      await _settle(tester);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('This video isn’t available.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('unliking', (tester) async {
      final repo = _Repo()..following_ = [post('1', liked: true)];
      await _pump(tester, repo);
      await tester.tap(find.bySemanticsLabel('Unlike'));
      await _settle(tester);
      expect(repo.unlikes, ['1']);
    });

    testWidgets('every post can be reported, with a neutral answer', (
      tester,
    ) async {
      await _pump(tester, _Repo()..following_ = [post('1')]);
      await tester.tap(find.bySemanticsLabel('Report or block'));
      await _settle(tester);
      await tapText(tester, 'Report this video');
      expect(find.text('Report a video'), findsOneWidget);
      expect(find.text('Hide this club from my results'), findsNothing);
    });

    testWidgets('blocking asks first, then refreshes the list', (tester) async {
      final social = _Social();
      final repo = _Repo()..following_ = [post('1')];
      await _pump(tester, repo, social: social);
      await tester.tap(find.bySemanticsLabel('Report or block'));
      await _settle(tester);
      await tapText(tester, 'Block Mei Tan');
      expect(find.text('Block Mei Tan?'), findsOneWidget);
      repo.following_ = [];
      await tapText(tester, 'Block');
      expect(social.blocked_, ['a-1']);
      expect(find.text('Smash practice'), findsNothing);
    });

    testWidgets('your own post has no block', (tester) async {
      await _pump(tester, _Repo()..following_ = [post('1', mine: true)]);
      await tester.tap(find.bySemanticsLabel('Report or block'));
      await _settle(tester);
      expect(find.text('Block Mei Tan'), findsNothing);
    });

    testWidgets('the author opens their profile', (tester) async {
      await _pump(tester, _Repo()..following_ = [post('1')]);
      await tapText(tester, 'Mei Tan');
      expect(find.text('player a-1'), findsOneWidget);
    });
  });

  group('adding a post', () {
    Future<_Repo> ready(WidgetTester tester, {_Repo? with_}) async {
      final repo = with_ ?? _Repo();
      await _pump(
        tester,
        repo,
        start: Routes.addPost,
        picker: pickerGiving(_file),
      );
      return repo;
    }

    testWidgets('a teen sees it isn\'t for them', (tester) async {
      await _pump(tester, _Repo()..canPost = false, start: Routes.addPost);
      expect(find.text('Posting is for adults for now.'), findsOneWidget);
    });

    testWidgets('posting needs a file and the tick', (tester) async {
      final repo = await ready(tester);
      expect(button(tester, 'Post').onPressed, isNull);
      await tapText(tester, 'Choose from my library');
      expect(find.text('Video chosen'), findsOneWidget);
      expect(button(tester, 'Post').onPressed, isNull);
      await tapText(tester, 'No one under 18 is in this video.');
      await tapText(tester, 'Post');
      expect(repo.added.single['noMinors'], true);
      expect(repo.added.single['audience'], PostAudience.followers);
    });

    testWidgets('the tick can\'t come before the file', (tester) async {
      await ready(tester);
      await tapText(tester, 'No one under 18 is in this video.');
      await tapText(tester, 'Choose from my library');
      expect(button(tester, 'Post').onPressed, isNull);
    });

    testWidgets('a new file needs the tick again', (tester) async {
      await ready(tester);
      await tapText(tester, 'Choose from my library');
      await tapText(tester, 'No one under 18 is in this video.');
      await tapText(tester, 'Choose another');
      expect(button(tester, 'Post').onPressed, isNull);
    });

    testWidgets('sport, audience and caption reach the server', (tester) async {
      final repo = await ready(tester);
      await tapText(tester, 'Choose from my library');
      await tester.enterText(find.byType(EditableText).first, ' Hello ');
      await tapText(tester, 'Tennis');
      await tapText(tester, 'Everyone');
      await tapText(tester, 'No one under 18 is in this video.');
      await tapText(tester, 'Post');
      expect(repo.added.single['caption'], 'Hello');
      expect(repo.added.single['sport'], 'tennis');
      expect(repo.added.single['audience'], PostAudience.public);
    });

    testWidgets('a retry reaches the same post', (tester) async {
      final repo = await ready(tester, with_: _Repo()..failUpload = 1);
      await tapText(tester, 'Choose from my library');
      await tapText(tester, 'No one under 18 is in this video.');
      await tapText(tester, 'Post');
      expect(find.text('The upload didn’t finish. Try again.'), findsOneWidget);
      await tapText(tester, 'Post');
      expect(repo.added[0]['id'], repo.added[1]['id']);
      expect(find.text('My posts'), findsWidgets);
    });

    testWidgets('a big file is refused on the phone', (tester) async {
      await _pump(
        tester,
        _Repo(),
        start: Routes.addPost,
        picker: pickerGiving(
          const PickedClip(path: '/a.mp4', ext: 'mp4', bytes: 200 * 1048576),
        ),
      );
      await tapText(tester, 'Choose from my library');
      expect(
        find.text('That video is too big. The limit is 100 MB.'),
        findsOneWidget,
      );
    });

    testWidgets('another format is refused', (tester) async {
      await _pump(
        tester,
        _Repo(),
        start: Routes.addPost,
        picker: pickerGiving(
          const PickedClip(path: '/a.avi', ext: 'avi', bytes: 1000),
        ),
      );
      await tapText(tester, 'Choose from my library');
      expect(find.text('Choose an MP4 or MOV video.'), findsOneWidget);
    });

    testWidgets('a long caption stops before the upload', (tester) async {
      final repo = await ready(tester);
      await tapText(tester, 'Choose from my library');
      await tester.enterText(find.byType(EditableText).first, 'a' * 301);
      await tapText(tester, 'No one under 18 is in this video.');
      await tapText(tester, 'Post');
      expect(repo.added, isEmpty);
      expect(find.text('Keep your caption to 300 characters.'), findsOneWidget);
    });
  });

  group('my posts', () {
    testWidgets('each state says where it stands', (tester) async {
      await _pump(
        tester,
        _Repo()
          ..mine_ = [
            post('1', status: PostStatus.checking),
            post('2', status: PostStatus.review),
            post('3', status: PostStatus.rejected),
            post('4', status: PostStatus.failed),
            post('5', status: PostStatus.removed),
            post('6', status: PostStatus.waiting),
            post('7'),
          ],
        start: Routes.myPosts,
      );
      for (final line in [
        'Checking',
        'Waiting for review',
        'Not posted',
        'We couldn’t check this',
        'Taken down',
        'Upload didn’t finish',
        'Live',
      ]) {
        expect(find.text(line), findsOneWidget, reason: line);
      }
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('empty says so', (tester) async {
      await _pump(tester, _Repo(), start: Routes.myPosts);
      expect(find.text('No posts yet.'), findsOneWidget);
    });

    testWidgets('deleting asks first', (tester) async {
      final repo = _Repo()..mine_ = [post('1')];
      await _pump(tester, repo, start: Routes.myPosts);
      await tapText(tester, 'Delete');
      expect(find.text('Delete this post?'), findsOneWidget);
      await tapText(tester, 'Keep it');
      expect(repo.deleted, isEmpty);
      await tapText(tester, 'Delete');
      await tapText(tester, 'Delete post');
      expect(repo.deleted, ['1']);
      expect(find.text('No posts yet.'), findsOneWidget);
    });

    testWidgets('a video that\'s too long doesn\'t offer Try again', (
      tester,
    ) async {
      final failed = FeedPost.fromRow({
        'id': '1',
        'author_id': 'a',
        'sport': 'tennis',
        'seconds': 5,
        'likes': 0,
        'status': 'failed',
        'reason': 'too_long',
      });
      await _pump(tester, _Repo()..mine_ = [failed], start: Routes.myPosts);
      expect(find.text('This video is too long'), findsOneWidget);
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('a failed post can try again', (tester) async {
      final repo = _Repo()..mine_ = [post('1', status: PostStatus.failed)];
      await _pump(tester, repo, start: Routes.myPosts);
      await tapText(tester, 'Try again');
      expect(repo.retried, ['1']);
    });
  });

  group('the row models', () {
    test('a row reads whatever the server sends', () {
      final p = FeedPost.fromRow({
        'id': 'x',
        'author_id': 'a',
        'author': null,
        'caption': null,
        'sport': 'tennis',
        'seconds': 5,
        'likes': 0,
        'status': 'blocked',
        'created_at': '2026-11-02T08:00:00Z',
      });
      expect(p.author, 'Player');
      expect(p.status, PostStatus.rejected);
    });

    test('nothing in the app can read as a match', () {
      for (final status in PostStatus.values) {
        final (line, detail) = postStatusLine(status, uploading: false);
        expect('$line ${detail ?? ''}'.toLowerCase(), isNot(contains('match')));
        expect('$line ${detail ?? ''}'.toLowerCase(), isNot(contains('abuse')));
      }
    });
  });
}
