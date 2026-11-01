import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:og_design/og_design.dart';
import 'package:video_player/video_player.dart';

import '../../core/staff_api.dart';
import '../../core/ui.dart';

/// Makes a player. A provider so tests can leave the plugin out.
final postPlayerMakerProvider = Provider<VideoPlayerController Function(Uri)>(
  (ref) => VideoPlayerController.networkUrl,
);

/// Asks for a link, which records the look, and plays it in a dialog.
Future<void> showPostVideo(
  BuildContext context,
  WidgetRef ref,
  String post,
) async {
  final String url;
  try {
    url = await ref.read(staffApiProvider).postVideoUrl(post);
  } on StaffFailure catch (e) {
    if (context.mounted) toast(context, e.message);
    return;
  }
  if (!context.mounted) return;
  final maker = ref.read(postPlayerMakerProvider);
  await showDialog<void>(
    context: context,
    builder: (_) => _VideoDialog(player: maker(Uri.parse(url))),
  );
}

class _VideoDialog extends StatefulWidget {
  const _VideoDialog({required this.player});

  final VideoPlayerController player;

  @override
  State<_VideoDialog> createState() => _VideoDialogState();
}

class _VideoDialogState extends State<_VideoDialog> {
  late final Future<void> _ready = widget.player.initialize().then(
    (_) => widget.player.play(),
  );

  @override
  void dispose() {
    widget.player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    content: SizedBox(
      width: 560,
      child: FutureBuilder<void>(
        future: _ready,
        builder: (context, s) {
          if (s.hasError) {
            // Browsers can't play every phone format (Q220).
            return const Text('This browser can\'t play this video.');
          }
          if (s.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return AspectRatio(
            aspectRatio: widget.player.value.aspectRatio,
            child: VideoPlayer(widget.player),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  );
}

/// A user's first posts wait here for a person. The video and caption, and
/// nothing that says whose it is.
class FirstPostsScreen extends ConsumerStatefulWidget {
  const FirstPostsScreen({super.key});

  @override
  ConsumerState<FirstPostsScreen> createState() => _FirstPostsScreenState();
}

class _FirstPostsScreenState extends ConsumerState<FirstPostsScreen> {
  var _reload = 0;

  Future<void> _decide(String post, String outcome) async {
    final reason = await askReason(
      context,
      outcome == 'live' ? 'Approve this post' : 'Reject this post',
    );
    if (reason == null || !mounted) return;
    try {
      await ref.read(staffApiProvider).act('staff_post_decide', {
        'p_post': post,
        'p_outcome': outcome,
        'p_reason': reason,
      });
      if (!mounted) return;
      toast(context, outcome == 'live' ? 'Post approved' : 'Post rejected');
      setState(() => _reload++);
    } on StaffFailure catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  String _when(String at) => at.substring(0, 16).replaceFirst('T', ' ');

  @override
  Widget build(BuildContext context) => StaffPage(
    title: 'First posts',
    child: Loaded<List<dynamic>>(
      key: ValueKey(_reload),
      future: ref
          .read(staffApiProvider)
          .read('staff_post_queue')
          .then((r) => r! as List<dynamic>),
      isEmpty: (r) => r.isEmpty,
      emptyText: 'No posts are waiting.',
      builder: (rows) => ListView(
        children: [
          for (final p in rows.cast<Map<String, dynamic>>())
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      (p['caption'] as String).isEmpty
                          ? 'No caption'
                          : p['caption'] as String,
                      style: OgText.lead(context.og.text),
                    ),
                    Text(
                      '${p['sport']} · decide by '
                      '${_when(p['deadline_at'] as String)}',
                      style: OgText.body(13, color: context.og.textMuted),
                    ),
                    if (p['flagged'] == true)
                      const Text('The automatic check flagged this.'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton(
                          onPressed: () =>
                              showPostVideo(context, ref, p['id'] as String),
                          child: const Text('Play video'),
                        ),
                        FilledButton(
                          onPressed: () => _decide(p['id'] as String, 'live'),
                          child: const Text('Approve'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              _decide(p['id'] as String, 'rejected'),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
