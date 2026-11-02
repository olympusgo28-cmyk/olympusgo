import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../analysis/application/analysis_providers.dart';
import '../../analysis/domain/analysis_models.dart';
import '../../auth/data/auth_repository.dart';
import '../../fitness/application/fitness_providers.dart';
import '../../fitness/presentation/fitness_screens.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/application/play_providers.dart';
import '../../social/application/social_providers.dart';
import '../application/feed_providers.dart';
import '../domain/feed_models.dart';

void _refreshLists(ProviderContainer container) {
  container.invalidate(feedFollowingProvider);
  container.invalidate(feedDiscoverProvider);
  container.invalidate(myPostsProvider);
}

/// Following for everyone, and Discover for adults. Both lists end.
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final status = ref.watch(feedStatusProvider);
    const title = 'Videos';
    final blocked = fitnessWaiting(status, title, () {
      ref.invalidate(feedStatusProvider);
    });
    if (blocked != null) return blocked;
    final s = status.requireValue;
    if (!s.open) {
      return const KitScaffold(
        header: KitHeader(title: title),
        children: [KitNote('Videos aren’t open yet.')],
      );
    }
    final discover = s.canDiscover && _tab == 1;
    final provider = discover ? feedDiscoverProvider : feedFollowingProvider;
    final posts = ref.watch(provider);
    return KitScaffold(
      header: KitHeader(
        title: title,
        trailing: s.canPost
            ? KitIconButton(
                icon: OgIcons.person,
                label: 'My posts',
                onPressed: () => context.push(Routes.myPosts),
              )
            : null,
      ),
      children: [
        if (s.canDiscover)
          KitUnderlineTabs(
            labels: const ['Following', 'Discover'],
            selected: _tab,
            spread: true,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _tab = i),
          ),
        ...switch (posts) {
          AsyncValue(hasError: true, isLoading: false, :final error) => [
            KitNote(
              error is AuthFailure
                  ? error.message
                  : 'Can’t load this right now. Check your connection.',
              tone: KitTone.warn,
            ),
            KitButton.outline(
              label: 'Try again',
              onPressed: () => ref.invalidate(provider),
            ),
          ],
          AsyncValue(hasValue: true, :final value?) when value.isEmpty => [
            Text(
              discover
                  ? 'No videos here yet. Public posts in your sports show up '
                        'here.'
                  : 'No videos yet. Follow people to see theirs here.',
              style: OgText.body(16, height: 1.45, color: c.textMuted),
            ),
          ],
          AsyncValue(hasValue: true, :final value?) => [
            _PostList(value),
            Text(
              'That’s everything for now.',
              textAlign: TextAlign.center,
              style: OgText.body(14, color: c.textMuted),
            ),
          ],
          _ => [const Center(child: CupertinoActivityIndicator())],
        },
      ],
    );
  }
}

class _PostList extends ConsumerWidget {
  const _PostList(this.posts);

  final List<FeedPost> posts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wanted = [
      for (final p in posts)
        if (p.hasPoster) p.id,
    ];
    final posters = wanted.isEmpty
        ? const <String, String>{}
        : ref.watch(feedPostersProvider(wanted.join(','))).value ?? const {};
    return Column(
      spacing: 22,
      children: [
        for (final p in posts)
          _PostCard(key: ValueKey(p.id), post: p, poster: posters[p.id]),
      ],
    );
  }
}

class _PostCard extends ConsumerStatefulWidget {
  const _PostCard({super.key, required this.post, this.poster});

  final FeedPost post;
  final String? poster;

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  late var _post = widget.post;

  @override
  void didUpdateWidget(_PostCard old) {
    super.didUpdateWidget(old);
    if (old.post != widget.post) _post = widget.post;
  }

  Future<void> _like() async {
    final before = _post;
    final liked = !before.liked;
    HapticFeedback.selectionClick();
    setState(() {
      _post = before.copy(liked: liked, likes: before.likes + (liked ? 1 : -1));
    });
    final repo = ref.read(feedRepositoryProvider);
    try {
      await (liked ? repo.like(before.id) : repo.unlike(before.id));
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _post = before);
      showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _block() async {
    final name = _post.author;
    final yes = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitTitle(
            'Block $name?',
            lead: 'You won’t see each other’s videos or profiles.',
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Block',
            style: KitButtonStyle.danger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Cancel',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await container.read(socialRepositoryProvider).block(_post.authorId);
      _refreshLists(container);
      container
        ..invalidate(blockedPlayersProvider)
        ..invalidate(myFollowingProvider);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _more() async {
    final post = _post;
    final action = await showKitSheet<String>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitButton(
            label: 'Report this video',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop('report'),
          ),
          if (!post.mine) ...[
            const SizedBox(height: 10),
            KitButton(
              label: 'Block ${post.author}',
              style: KitButtonStyle.outline,
              onPressed: () => Navigator.of(sheet).pop('block'),
            ),
          ],
          const SizedBox(height: 26),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'report') {
      await context.push(Routes.reportVideo(post.id));
      if (mounted) {
        _refreshLists(ProviderScope.containerOf(context, listen: false));
      }
    } else if (action == 'block') {
      await _block();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final post = _post;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          children: [
            Expanded(
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                minimumSize: const Size(44, 44),
                onPressed: () => context.push(Routes.player(post.authorId)),
                child: Text(
                  post.author,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OgText.body(16, weight: FontWeight.w600),
                ),
              ),
            ),
            KitIconButton(
              icon: OgIcons.flag,
              label: 'Report or block',
              onPressed: _more,
            ),
          ],
        ),
        PostPlayer(id: post.id, poster: widget.poster),
        if (post.caption.isNotEmpty)
          Text(post.caption, style: OgText.body(15, height: 1.4)),
        Row(
          children: [
            Semantics(
              button: true,
              toggled: post.liked,
              label: post.liked ? 'Unlike' : 'Like',
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: _like,
                child: OgIcon(
                  OgIcons.heart,
                  size: 24,
                  color: post.liked ? c.primary : c.textMuted,
                  fill: post.liked,
                ),
              ),
            ),
            Text('${post.likes}', style: OgText.body(14, color: c.textMuted)),
          ],
        ),
      ],
    );
  }
}

/// Plays one video. Nothing loads until a tap, for anyone: under-18s must never
/// get autoplay, and nothing here assumes who's watching (Q215).
class PostPlayer extends ConsumerStatefulWidget {
  const PostPlayer({super.key, required this.id, this.poster});

  final String id;
  final String? poster;

  @override
  ConsumerState<PostPlayer> createState() => _PostPlayerState();
}

class _PostPlayerState extends ConsumerState<PostPlayer> {
  VideoPlayerController? _player;
  ScrollPosition? _scroll;
  var _loading = false;
  var _failed = false;
  var _playing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scroll = Scrollable.maybeOf(context)?.position;
    if (scroll != _scroll) {
      _scroll?.removeListener(_onScroll);
      _scroll = scroll?..addListener(_onScroll);
    }
    // Another page opened on top, so this one's sound stops.
    if (ModalRoute.of(context)?.isCurrent == false) _player?.pause();
  }

  @override
  void dispose() {
    _scroll?.removeListener(_onScroll);
    _player?.removeListener(_onValue);
    _player?.dispose();
    super.dispose();
  }

  bool get _onScreen {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) return true;
    final top = box.localToGlobal(Offset.zero).dy;
    return top + box.size.height > 0 && top < MediaQuery.sizeOf(context).height;
  }

  void _onScroll() {
    if (_player != null && !_onScreen) _player?.pause();
  }

  void _onValue() {
    final player = _player;
    if (player == null || !mounted) return;
    // A link that ran out or a dropped signal. A tap asks for a new link.
    if (player.value.hasError) {
      player.removeListener(_onValue);
      player.dispose();
      setState(() {
        _player = null;
        _playing = false;
        _failed = true;
      });
    } else if (player.value.isPlaying != _playing) {
      setState(() => _playing = player.value.isPlaying);
    }
  }

  Future<void> _start() async {
    final maker = ref.read(postPlayerMakerProvider);
    final repo = ref.read(feedRepositoryProvider);
    setState(() {
      _loading = true;
      _failed = false;
    });
    ref.read(activePostProvider.notifier).play(widget.id);
    VideoPlayerController? player;
    try {
      final url = await repo.playUrl(widget.id);
      player = maker(Uri.parse(url));
      await player.initialize();
      if (!mounted) {
        await player.dispose();
        return;
      }
      // The person may have moved on while it loaded.
      final wanted =
          ModalRoute.of(context)?.isCurrent != false &&
          _onScreen &&
          ref.read(activePostProvider) == widget.id;
      if (wanted) await player.play();
      if (!mounted) {
        await player.dispose();
        return;
      }
      player.addListener(_onValue);
      setState(() {
        _player = player;
        _playing = wanted;
      });
    } on Exception {
      await player?.dispose();
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggle() {
    final player = _player!;
    if (player.value.isPlaying) {
      player.pause();
    } else {
      ref.read(activePostProvider.notifier).play(widget.id);
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final player = _player;
    ref.listen(activePostProvider, (_, active) {
      if (active != widget.id) _player?.pause();
    });
    if (player != null) {
      return Semantics(
        button: true,
        label: _playing ? 'Pause' : 'Play',
        child: GestureDetector(
          onTap: _toggle,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: player.value.aspectRatio,
              child: VideoPlayer(player),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      label: 'Play video',
      child: GestureDetector(
        onTap: _loading ? null : _start,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.poster != null)
                  Image.network(
                    widget.poster!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                Center(
                  child: _loading
                      ? const CupertinoActivityIndicator()
                      : _failed
                      ? Text(
                          'Can’t play this. Tap to try again.',
                          style: OgText.body(14, color: c.textMuted),
                        )
                      : OgIcon(OgIcons.video, size: 40, color: c.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Adults post. What to do, the file, the tick, then the upload.
class AddPostScreen extends ConsumerStatefulWidget {
  const AddPostScreen({super.key});

  @override
  ConsumerState<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends ConsumerState<AddPostScreen> {
  static const _maxCaption = 300;

  // Stays the same on a retry, so a dropped signal reaches the same post.
  var _id = newFitnessId();
  final _caption = TextEditingController();
  PickedClip? _file;
  var _sport = Sport.badminton.id;
  var _audience = PostAudience.followers;
  var _noMinors = false;
  var _picking = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(FeedStatus status, {required bool camera}) async {
    setState(() {
      _picking = true;
      _error = null;
    });
    PickedClip? file;
    String? problem;
    try {
      file = await ref.read(clipPickerProvider)(
        camera: camera,
        maxSeconds: status.maxSeconds,
      );
    } on PlatformException catch (e) {
      problem = e.code.endsWith('access_denied')
          ? 'Allow OlympusGO to use your ${camera ? 'camera' : 'photos'} in '
                'Settings, then try again.'
          : 'Can’t open that right now. Try again.';
    } on Exception {
      problem = 'Can’t open that right now. Try again.';
    }
    if (!mounted) return;
    setState(() {
      _picking = false;
      _error = problem;
      if (file == null) return;
      // The tick was about the video that was chosen, not this one.
      _file = null;
      _noMinors = false;
      if (file.ext != 'mp4' && file.ext != 'mov') {
        _error = 'Choose an MP4 or MOV video.';
      } else if (file.bytes > status.maxMb * 1048576) {
        _error = 'That video is too big. The limit is ${status.maxMb} MB.';
      } else {
        _file = file;
        _id = newFitnessId();
      }
    });
  }

  Future<void> _send(FeedStatus status) async {
    if (_caption.text.trim().length > _maxCaption) {
      setState(() => _error = 'Keep your caption to $_maxCaption characters.');
      return;
    }
    // Outlives this screen, so leaving during the upload can't lose the post.
    final container = ProviderScope.containerOf(context, listen: false);
    final uploads = container.read(postUploadsProvider.notifier);
    final id = _id;
    setState(() {
      _busy = true;
      _error = null;
    });
    uploads.start(id);
    try {
      // The phone can't read a video's length, so this is the most it can be.
      // The worker measures it, and fails one that's over.
      await container
          .read(feedRepositoryProvider)
          .addPost(
            id: id,
            file: _file!,
            seconds: status.maxSeconds,
            caption: _caption.text.trim(),
            sport: _sport,
            audience: _audience,
            noMinors: _noMinors,
          );
      if (mounted) context.pushReplacement(Routes.myPosts);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      uploads.finish(id);
      _refreshLists(container);
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final status = ref.watch(feedStatusProvider);
    const title = 'Add a post';
    final blocked = fitnessWaiting(status, title, () {
      ref.invalidate(feedStatusProvider);
    });
    if (blocked != null) return blocked;
    final s = status.requireValue;
    if (!s.canPost) {
      return const KitScaffold(
        header: KitHeader(title: title),
        children: [KitNote('Posting is for adults for now.')],
      );
    }
    final idle = !_busy && !_picking;
    final ready = _file != null && _noMinors;
    final sports = ref.watch(liveSportsProvider).value ?? const <Sport>[];
    return KitScaffold(
      header: const KitHeader(title: title),
      bottom: [
        KitButton(
          label: 'Post',
          loading: _busy,
          onPressed: ready && idle ? () => _send(s) : null,
        ),
      ],
      children: [
        KitCheckList([
          'Up to ${s.maxSeconds} seconds and ${s.maxMb} MB',
          'No one under 18 in the video',
          'Everyone in it knows you’re posting it',
          'We check every video before it shows',
        ]),
        const KitSection('Your video'),
        if (_file == null) ...[
          KitButton(
            label: 'Record a video',
            onPressed: idle ? () => _pick(s, camera: true) : null,
          ),
          KitButton.outline(
            label: 'Choose from my library',
            onPressed: idle ? () => _pick(s, camera: false) : null,
          ),
        ] else ...[
          Text('Video chosen', style: OgText.body(16, weight: FontWeight.w600)),
          KitLink(
            'Choose another',
            onPressed: idle ? () => _pick(s, camera: false) : null,
          ),
        ],
        KitTextArea(
          label: 'Caption',
          optional: true,
          controller: _caption,
          lines: 2,
        ),
        const KitSection('Sport'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final sport in sports)
              KitChip(
                label: sport.label,
                height: 44,
                selected: sport.id == _sport,
                onTap: () => setState(() => _sport = sport.id),
              ),
          ],
        ),
        const KitSection('Who can see this'),
        KitSegments(
          labels: [for (final a in PostAudience.values) a.label],
          selected: _audience.index,
          onSelect: (i) => setState(() => _audience = PostAudience.values[i]),
        ),
        KitConfirmBox(
          label: 'No one under 18 is in this video.',
          checked: _noMinors,
          onChanged: _file == null
              ? (_) {}
              : (v) => setState(() => _noMinors = v),
        ),
        if (_error != null) KitNote(_error!, tone: KitTone.warn),
        Text(
          'A person checks your first posts, so they may take a while to show.',
          style: OgText.body(14, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Where each of your posts stands.
class MyPostsScreen extends ConsumerWidget {
  const MyPostsScreen({super.key});

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FeedPost post,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final yes = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const KitTitle(
            'Delete this post?',
            lead: 'It goes from the feed now, and we can’t bring it back.',
          ),
          const SizedBox(height: 18),
          KitButton(
            label: 'Delete post',
            style: KitButtonStyle.danger,
            onPressed: () => Navigator.of(sheet).pop(true),
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Keep it',
            style: KitButtonStyle.outline,
            onPressed: () => Navigator.of(sheet).pop(false),
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await container.read(feedRepositoryProvider).delete(post.id);
      _refreshLists(container);
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _retry(
    BuildContext context,
    WidgetRef ref,
    FeedPost post,
  ) async {
    final container = ProviderScope.containerOf(context, listen: false);
    try {
      await container.read(feedRepositoryProvider).retry(post.id);
      _refreshLists(container);
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final status = ref.watch(feedStatusProvider);
    final posts = ref.watch(myPostsProvider);
    final uploads = ref.watch(postUploadsProvider);
    const title = 'My posts';
    final blocked =
        fitnessWaiting(status, title, () {
          ref.invalidate(feedStatusProvider);
        }) ??
        fitnessWaiting(posts, title, () {
          ref.invalidate(myPostsProvider);
        });
    if (blocked != null) return blocked;
    final list = posts.requireValue;
    return KitScaffold(
      header: const KitHeader(title: title),
      children: [
        if (status.requireValue.canPost)
          KitButton(
            label: 'Add a post',
            onPressed: () => context.push(Routes.addPost),
          ),
        if (list.isEmpty)
          Text('No posts yet.', style: OgText.body(16, color: c.textMuted))
        else
          for (final post in list)
            Builder(
              builder: (context) {
                final uploading = uploads.contains(post.id);
                final (line, detail) = postStatusLine(
                  post.status,
                  uploading: uploading,
                  reason: post.reason,
                );
                return KitCard(
                  padding: const EdgeInsets.all(14),
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 6,
                      children: [
                        Text(
                          post.caption.isEmpty ? 'No caption' : post.caption,
                          style: OgText.body(16, weight: FontWeight.w600),
                        ),
                        Text(line, style: OgText.body(14, color: c.textMuted)),
                        if (detail != null)
                          Text(
                            detail,
                            style: OgText.body(
                              14,
                              height: 1.45,
                              color: c.textMuted,
                            ),
                          ),
                        if (post.canRetry)
                          KitLink(
                            'Try again',
                            onPressed: () => _retry(context, ref, post),
                          ),
                        if (!uploading)
                          KitLink(
                            'Delete',
                            onPressed: () => _delete(context, ref, post),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
      ],
    );
  }
}
