import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../fitness/application/fitness_providers.dart';
import '../../fitness/presentation/fitness_screens.dart';
import '../application/analysis_providers.dart';
import '../domain/analysis_models.dart';

String _name(AnalysisClip clip) => clip.child ?? 'your child';

String _their(AnalysisClip clip) => !clip.forChild
    ? 'Your'
    : clip.child == null
    ? 'Your child’s'
    : '${clip.child}’s';

String _statusLine(AnalysisClip clip, {required bool uploading}) {
  final status = switch (clip.status) {
    ClipStatus.waiting when uploading => 'Uploading',
    ClipStatus.waiting when !clip.addedByMe => 'Being added',
    ClipStatus.waiting => 'Upload didn’t finish',
    ClipStatus.uploaded => 'Reading the clip',
    ClipStatus.courtReady when !clip.addedByMe => 'Waiting for the court',
    ClipStatus.courtReady => 'Mark the court',
    ClipStatus.queued => 'Analysing',
    ClipStatus.done => 'Report ready',
    ClipStatus.failed => clipFailure(clip.errorCode).$1,
    ClipStatus.withdrawn => 'Consent withdrawn',
  };
  return clip.forChild ? '${clip.child ?? 'Your child'} · $status' : status;
}

String _keptLine(AnalysisClip clip) => clip.fileGone
    ? 'Clip deleted. Only the numbers remain.'
    : 'We’ll delete the clip on ${Fmt.day(clip.purgeAt)}.';

String _withdrawnLine(AnalysisClip clip) => clip.fileGone
    ? 'Consent withdrawn. The clip has been deleted.'
    : 'Consent withdrawn. We’ll delete the clip within 7 days.';

void _refreshLists(ProviderContainer container) {
  container.invalidate(myClipsProvider);
  container.invalidate(childClipsProvider);
}

class _ClipList extends ConsumerWidget {
  const _ClipList(this.clips, {required this.onOpen});

  final List<AnalysisClip> clips;
  final ValueChanged<AnalysisClip> onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploads = ref.watch(clipUploadsProvider);
    return Column(
      children: [
        for (final (i, clip) in clips.indexed)
          KitNavTile(
            icon: OgIcons.video,
            title: Fmt.day(clip.createdAt),
            subtitle: _statusLine(clip, uploading: uploads.contains(clip.id)),
            padding: EdgeInsets.zero,
            minHeight: 68,
            ruleAbove: i > 0,
            onTap: () => onOpen(clip),
          ),
      ],
    );
  }
}

/// The player's clips, and the way to add one.
class MyClipsScreen extends ConsumerWidget {
  const MyClipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(analysisStatusProvider);
    final clips = ref.watch(myClipsProvider);
    const title = 'Analyse my game';
    final blocked =
        fitnessWaiting(status, title, () {
          ref.invalidate(analysisStatusProvider);
        }) ??
        fitnessWaiting(clips, title, () => ref.invalidate(myClipsProvider));
    if (blocked != null) return blocked;
    final list = clips.requireValue;
    final open = status.requireValue.open;
    return KitScaffold(
      header: const KitHeader(title: title),
      children: [
        Text(
          'Film a singles game from a tripod. You get your distance, your '
          'speed and a map of where you moved.',
          style: context.type.secondary.copyWith(height: 1.45),
        ),
        if (open)
          KitButton(
            label: 'Add a clip',
            onPressed: () => context.push(Routes.analysisAdd),
          )
        else
          const KitNote('Analysis isn’t open yet.'),
        if (list.isNotEmpty) ...[
          const KitSection('Your clips'),
          _ClipList(
            list,
            onOpen: (clip) async {
              await context.push(Routes.analysisClip(clip.id));
              ref.invalidate(myClipsProvider);
            },
          ),
        ],
      ],
    );
  }
}

/// A parent's view of their child's clips.
class ChildClipsScreen extends ConsumerWidget {
  const ChildClipsScreen({super.key, required this.childId, this.name});

  final String childId;
  final String? name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(analysisStatusProvider);
    final clips = ref.watch(childClipsProvider(childId));
    const title = 'Game clips';
    final blocked =
        fitnessWaiting(status, title, () {
          ref.invalidate(analysisStatusProvider);
        }) ??
        fitnessWaiting(clips, title, () {
          ref.invalidate(childClipsProvider(childId));
        });
    if (blocked != null) return blocked;
    final list = clips.requireValue;
    final open = status.requireValue.childrenOpen;
    return KitScaffold(
      header: const KitHeader(title: title),
      children: [
        if (open)
          KitButton(
            label: 'Add a clip',
            onPressed: () => context.push(
              Routes.analysisAdd,
              extra: (childId, name ?? 'this child'),
            ),
          )
        else
          const KitNote('Clips of children aren’t open yet.'),
        if (list.isEmpty)
          Text('No clips yet.', style: context.type.secondary)
        else
          _ClipList(
            list,
            onOpen: (clip) async {
              await context.push(Routes.analysisClip(clip.id));
              ref.invalidate(childClipsProvider(childId));
            },
          ),
      ],
    );
  }
}

/// Where to put the phone, the file, the agreement, then the upload.
class AddClipScreen extends ConsumerStatefulWidget {
  const AddClipScreen({super.key, this.child});

  /// The child's id and name, when a parent is adding their clip.
  final (String, String)? child;

  @override
  ConsumerState<AddClipScreen> createState() => _AddClipScreenState();
}

class _AddClipScreenState extends ConsumerState<AddClipScreen> {
  // Stays the same on a retry, so a dropped signal reaches the same clip.
  var _id = newFitnessId();
  PickedClip? _file;
  var _agreed = false;
  var _consent = false;
  var _picking = false;
  var _busy = false;
  var _failed = false;
  String? _error;

  Future<void> _pick(AnalysisStatus status, {required bool camera}) async {
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
      // Agreeing was about the clip that was chosen, not this one.
      _file = null;
      _agreed = false;
      _consent = false;
      _failed = false;
      if (file.ext != 'mp4' && file.ext != 'mov') {
        _error = 'Choose an MP4 or MOV clip.';
      } else if (file.bytes > status.maxMb * 1048576) {
        _error = 'That clip is too big. The limit is ${status.maxMb} MB.';
      } else {
        _file = file;
        _id = newFitnessId();
      }
    });
  }

  Future<void> _send(AnalysisStatus status) async {
    // Outlives this screen, so leaving during the upload can't lose the clip.
    final container = ProviderScope.containerOf(context, listen: false);
    final child = widget.child;
    final uploads = container.read(clipUploadsProvider.notifier);
    final id = _id;
    setState(() {
      _busy = true;
      _failed = false;
      _error = null;
    });
    uploads.start(id);
    try {
      // The phone can't read a clip's length, so this is the most it can be.
      // The worker measures it, and refuses one that's over.
      await container
          .read(analysisRepositoryProvider)
          .addClip(
            id: id,
            file: _file!,
            seconds: status.maxSeconds,
            childId: child?.$1,
            consentVersion: child == null ? null : clipConsentVersion,
          );
      if (mounted) context.pushReplacement(Routes.analysisClip(id));
    } on AuthFailure catch (e) {
      if (mounted) {
        setState(() {
          _failed = true;
          _error = e.message;
        });
      }
    } finally {
      _refreshLists(container);
      if (mounted) setState(() => _busy = false);
      try {
        // First, or an open page shows the old status as a failed upload.
        await container.refresh(analysisClipProvider(id).future);
      } on Exception {
        // That page has its own Try again.
      }
      uploads.finish(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(analysisStatusProvider);
    const title = 'Add a clip';
    final blocked = fitnessWaiting(status, title, () {
      ref.invalidate(analysisStatusProvider);
    });
    if (blocked != null) return blocked;
    final s = status.requireValue;
    final child = widget.child;
    if (!(child == null ? s.open : s.childrenOpen)) {
      return const KitScaffold(
        header: KitHeader(title: title),
        children: [KitNote('This isn’t open yet.')],
      );
    }
    final minutes = s.maxSeconds ~/ 60;
    final ready = _file != null && _agreed && (child == null || _consent);
    final idle = !_busy && !_picking;
    return KitScaffold(
      header: const KitHeader(title: title),
      children: [
        const KitSection('Set up your phone'),
        KitCheckList([
          'Tripod behind a baseline, as high as you can',
          'All four corners of the court in the frame',
          'Keep the phone still the whole time',
          'Singles only for now, with no change of ends',
          'Up to ${plural(minutes, 'minute')} and ${s.maxMb} MB',
        ]),
        const KitSection('Your clip'),
        if (_file == null) ...[
          KitButton(
            label: 'Record a clip',
            onPressed: idle ? () => _pick(s, camera: true) : null,
          ),
          KitButton.outline(
            label: 'Choose from my library',
            onPressed: idle ? () => _pick(s, camera: false) : null,
          ),
        ] else ...[
          const KitNote('Clip chosen.', tone: KitTone.success),
          KitButton.outline(
            label: 'Choose another',
            onPressed: idle ? () => _pick(s, camera: false) : null,
          ),
        ],
        KitConfirmBox(
          label: 'Everyone in this clip has agreed to be filmed.',
          checked: _agreed,
          onChanged: (v) => setState(() => _agreed = v),
        ),
        if (child != null)
          KitConfirmBox(
            label:
                'I’m ${child.$2}’s parent or guardian, and I agree to '
                'OlympusGO analysing this clip of them.',
            checked: _consent,
            onChanged: (v) => setState(() => _consent = v),
          ),
        Text(
          child == null
              ? 'Only you can see this. We never show the clip to anyone, and '
                    'we don’t keep any numbers about the other player.'
              : 'Only you and ${child.$2}’s other linked parents can see this. '
                    'You can withdraw at any time, and we delete the clip '
                    'within 7 days.',
          style: context.type.secondary.copyWith(height: 1.45),
        ),
        if (_error != null) KitNote(_error!, tone: KitTone.warn),
        if (_busy)
          const KitNote(
            'Uploading your clip. Keep the app open until it finishes.',
          ),
        KitButton(
          label: _failed ? 'Try again' : 'Upload clip',
          loading: _busy,
          onPressed: ready && !_busy ? () => _send(s) : null,
        ),
      ],
    );
  }
}

/// One clip, whatever state it has reached.
class ClipScreen extends ConsumerWidget {
  const ClipScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(analysisClipProvider(id));
    final uploading = ref.watch(
      clipUploadsProvider.select((ids) => ids.contains(id)),
    );
    // The lists behind this screen would otherwise show the last status.
    ref.listen(analysisClipProvider(id), (before, now) {
      final was = before?.value?.status;
      if (was != null && was != now.value?.status) {
        ref
          ..invalidate(myClipsProvider)
          ..invalidate(childClipsProvider);
      }
    });
    void retry() => ref.invalidate(analysisClipProvider(id));
    final blocked = fitnessWaiting(value, 'Your clip', retry);
    if (blocked != null) return blocked;
    final clip = value.requireValue;
    return switch (clip.status) {
      ClipStatus.courtReady when !clip.addedByMe => _Plain(
        clip,
        page: context,
        title: 'Waiting for the court to be marked',
        body:
            'The parent who added this clip marks the court. The report '
            'comes after that.',
        stuck: value.hasError ? retry : null,
        waiting: true,
      ),
      ClipStatus.courtReady => _CourtScreen(clip, page: context),
      ClipStatus.done => _ReportScreen(clip, page: context),
      ClipStatus.waiting when !clip.addedByMe => _Plain(
        clip,
        page: context,
        title: 'Waiting for the upload',
        body: 'The parent who added this clip is uploading it.',
        stuck: value.hasError ? retry : null,
        waiting: true,
      ),
      ClipStatus.waiting when uploading => _Plain(
        clip,
        page: context,
        title: 'Uploading your clip',
        body: 'Keep the app open until it finishes.',
        waiting: true,
        actions: false,
      ),
      ClipStatus.uploaded || ClipStatus.queued => _Plain(
        clip,
        page: context,
        title: clip.status == ClipStatus.uploaded
            ? 'Reading the clip'
            : 'Analysing the game',
        body:
            'This can take a few minutes. It’s safe to leave, and your clip '
            'will be here when you come back.',
        // A failed check stops the asking, so the player has to start it again.
        stuck: value.hasError ? retry : null,
        waiting: true,
      ),
      ClipStatus.waiting => _Plain(
        clip,
        page: context,
        title: 'The upload didn’t finish',
        body: 'Delete this clip and add it again.',
        stuck: value.hasError ? retry : null,
      ),
      ClipStatus.failed => _Plain(
        clip,
        page: context,
        title: clipFailure(clip.errorCode).$1,
        body: clipFailure(clip.errorCode).$2,
      ),
      // The numbers stay after a withdrawal (Q207).
      ClipStatus.withdrawn when clip.report != null => _ReportScreen(
        clip,
        page: context,
      ),
      ClipStatus.withdrawn => _Plain(
        clip,
        page: context,
        title: 'Consent withdrawn',
        body: _withdrawnLine(clip),
      ),
    };
  }
}

class _Plain extends StatelessWidget {
  const _Plain(
    this.clip, {
    required this.page,
    required this.title,
    required this.body,
    this.stuck,
    this.waiting = false,
    this.actions = true,
  });

  final AnalysisClip clip;
  final BuildContext page;
  final String title;
  final String body;
  final VoidCallback? stuck;
  final bool waiting;
  final bool actions;

  @override
  Widget build(BuildContext context) {
    return KitScaffold(
      header: KitHeader(title: '${_their(clip)} clip'),
      children: [
        if (waiting) const CupertinoActivityIndicator(),
        Text(title, style: context.type.section),
        Text(body, style: context.type.secondary.copyWith(height: 1.45)),
        if (stuck != null) ...[
          const KitNote(
            'Can’t check on your clip right now. Check your connection.',
            tone: KitTone.warn,
          ),
          KitButton.outline(label: 'Try again', onPressed: stuck),
        ],
        if (actions) _ClipActions(clip, page: page),
      ],
    );
  }
}

/// Keep, withdraw and delete, for every state of a clip.
class _ClipActions extends ConsumerStatefulWidget {
  const _ClipActions(this.clip, {required this.page});

  final AnalysisClip clip;
  final BuildContext page;

  @override
  ConsumerState<_ClipActions> createState() => _ClipActionsState();
}

class _ClipActionsState extends ConsumerState<_ClipActions> {
  var _busy = false;

  Future<bool> _sure(String title, String lead, String yes) async {
    final answer = await showKitSheet<bool>(
      context,
      builder: (sheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitTitle(title, lead: lead),
          const SizedBox(height: 18),
          KitButton(
            label: yes,
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
    return answer == true;
  }

  /// A new status can swap this widget out while the sheet is open, or while
  /// the work runs. An answer the player gave still has to count, so nothing
  /// here relies on this widget being on screen.
  Future<void> _run(
    ProviderContainer container,
    Future<void> Function() work, {
    bool leave = false,
  }) async {
    // Stays while the status swaps what's inside it.
    final page = widget.page;
    if (mounted) setState(() => _busy = true);
    try {
      await work();
      _refreshLists(container);
      if (leave) {
        if (page.mounted) page.pop();
      } else {
        container.invalidate(analysisClipProvider(widget.clip.id));
      }
    } on AuthFailure catch (e) {
      if (page.mounted) showOgToast(page, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = ref.read(analysisRepositoryProvider);
    final withdrawn = clip.status == ClipStatus.withdrawn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        if (clip.forChild && clip.canExtend)
          KitButton.outline(
            label: 'Keep this clip longer',
            onPressed: _busy
                ? null
                : () => _run(container, () => repo.extend(clip.id)),
          ),
        if (clip.forChild && !withdrawn && !clip.fileGone)
          KitButton.outline(
            label: 'Withdraw consent',
            onPressed: _busy
                ? null
                : () async {
                    final yes = await _sure(
                      'Withdraw consent?',
                      'We stop analysing straight away and delete the clip '
                          'within 7 days.',
                      'Withdraw consent',
                    );
                    if (yes) {
                      await _run(
                        container,
                        () => repo.withdrawConsent(clip.id),
                      );
                    }
                  },
          ),
        KitButton(
          label: 'Delete clip',
          style: KitButtonStyle.danger,
          onPressed: _busy
              ? null
              : () async {
                  final yes = await _sure(
                    'Delete this clip?',
                    'The clip and its report go for good.',
                    'Delete clip',
                  );
                  if (yes) {
                    await _run(
                      container,
                      () => repo.delete(clip.id),
                      leave: true,
                    );
                  }
                },
        ),
      ],
    );
  }
}

/// Marks the court's corners on a still, and picks the player's side.
class _CourtScreen extends ConsumerStatefulWidget {
  const _CourtScreen(this.clip, {required this.page});

  final AnalysisClip clip;
  final BuildContext page;

  @override
  ConsumerState<_CourtScreen> createState() => _CourtScreenState();
}

class _CourtScreenState extends ConsumerState<_CourtScreen> {
  late final _corners = List.of(widget.clip.corners ?? defaultCorners);
  String? _side;
  var _busy = false;

  Future<void> _confirm() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final id = widget.clip.id;
    setState(() => _busy = true);
    try {
      await container
          .read(analysisRepositoryProvider)
          .confirmCourt(id, corners: _corners, side: _side!);
      _refreshLists(container);
      container.invalidate(analysisClipProvider(id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.clip;
    final path = clip.framePath;
    final frame = path == null ? null : ref.watch(clipFrameProvider(path));
    final shaped = cornersOk(_corners);
    return KitScaffold(
      header: const KitHeader(title: 'Mark the court'),
      children: [
        Text(
          'Drag each dot onto a corner of the court, then choose a side.',
          style: context.type.secondary.copyWith(height: 1.45),
        ),
        if (frame?.hasError ?? false) ...[
          const KitNote(
            'Can’t load the picture of your court. Check your connection.',
            tone: KitTone.warn,
          ),
          KitButton.outline(
            label: 'Try again',
            onPressed: () => ref.invalidate(clipFrameProvider(path!)),
          ),
        ] else if (frame != null && !frame.hasValue)
          const CupertinoActivityIndicator()
        else
          _CornerEditor(
            frame: frame?.value,
            corners: _corners,
            onMove: (i, p) => setState(() => _corners[i] = p),
          ),
        if (!shaped)
          const KitNote(
            'The dots have crossed over. Far corners go at the far end, near '
            'corners at the near end.',
            tone: KitTone.warn,
          ),
        KitSection(
          clip.forChild
              ? 'Which side was ${_name(clip)} on?'
              : 'Which side were you on?',
        ),
        KitChoiceRow(
          title: 'Near the camera',
          selected: _side == 'near',
          onTap: () => setState(() => _side = 'near'),
        ),
        KitChoiceRow(
          title: 'Far from the camera',
          selected: _side == 'far',
          onTap: () => setState(() => _side = 'far'),
        ),
        Text(
          'We measure only the player on that side, and keep no numbers about '
          'the other player.',
          style: context.type.secondary.copyWith(height: 1.45),
        ),
        KitButton(
          label: 'Analyse this game',
          loading: _busy,
          onPressed: _side != null && shaped && !_busy ? _confirm : null,
        ),
        _ClipActions(clip, page: widget.page),
      ],
    );
  }
}

class _CornerEditor extends StatelessWidget {
  const _CornerEditor({
    required this.frame,
    required this.corners,
    required this.onMove,
  });

  // Half a dot's tap target, so a dot on the picture's edge stays reachable.
  static const _margin = 22.0;
  static const _names = [
    'Far left corner',
    'Far right corner',
    'Near right corner',
    'Near left corner',
  ];

  final ClipFrame? frame;
  final List<Offset> corners;
  final void Function(int index, Offset point) onMove;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final shot = frame;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth - _margin * 2;
        final height = shot == null
            ? width * 9 / 16
            : width * shot.height / shot.width;
        return SizedBox(
          width: box.maxWidth,
          height: height + _margin * 2,
          child: Stack(
            children: [
              Positioned(
                left: _margin,
                top: _margin,
                width: width,
                height: height,
                child: shot == null
                    ? ColoredBox(color: c.surfaceRaised)
                    : Semantics(
                        image: true,
                        label: 'A still from your clip, showing the court',
                        child: Image.memory(
                          shot.bytes,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) =>
                              ColoredBox(color: c.surfaceRaised),
                        ),
                      ),
              ),
              Positioned(
                left: _margin,
                top: _margin,
                width: width,
                height: height,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _CourtPainter(corners, c.primary),
                  ),
                ),
              ),
              for (final (i, p) in corners.indexed)
                Positioned(
                  left: p.dx * width,
                  top: p.dy * height,
                  child: _CornerDot(
                    name: _names[i],
                    color: c.primary,
                    ring: c.onPrimary,
                    // From the list, not p: several moves can land in a frame.
                    onDrag: (d) => onMove(
                      i,
                      Offset(
                        (corners[i].dx + d.dx / width).clamp(0, 1),
                        (corners[i].dy + d.dy / height).clamp(0, 1),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CornerDot extends StatelessWidget {
  const _CornerDot({
    required this.name,
    required this.color,
    required this.ring,
    required this.onDrag,
  });

  final String name;
  final Color color;
  final Color ring;
  final ValueChanged<Offset> onDrag;

  @override
  Widget build(BuildContext context) => Semantics(
    label: name,
    // Eager, or the page's scrolling takes a vertical drag from the dot.
    child: RawGestureDetector(
      gestures: {
        EagerGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<EagerGestureRecognizer>(
              EagerGestureRecognizer.new,
              (_) {},
            ),
      },
      child: Listener(
        onPointerMove: (e) => onDrag(e.delta),
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CourtPainter extends CustomPainter {
  const _CourtPainter(this.corners, this.color);

  final List<Offset> corners;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      for (final p in corners) Offset(p.dx * size.width, p.dy * size.height),
    ];
    canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_CourtPainter old) => true;
}

String _time(double seconds) {
  final s = seconds.round();
  return s < 60 ? '$s s' : '${s ~/ 60} min ${s % 60} s';
}

class _ReportScreen extends StatelessWidget {
  const _ReportScreen(this.clip, {required this.page});

  final AnalysisClip clip;
  final BuildContext page;

  @override
  Widget build(BuildContext context) {
    final report = clip.report;
    return KitScaffold(
      header: KitHeader(title: '${_their(clip)} report'),
      children: [
        if (clip.status == ClipStatus.withdrawn)
          KitNote(_withdrawnLine(clip), tone: KitTone.warn),
        const KitNote(
          'These are estimates from one camera, not exact measurements.',
        ),
        if (report != null) ...[
          Column(
            children: [
              KitKeyValue('Distance', '${report.distanceM.round()} m'),
              KitKeyValue(
                'Average speed',
                '${report.avgSpeedMs.toStringAsFixed(1)} m/s',
              ),
              KitKeyValue(
                'Top speed',
                '${report.topSpeedMs.toStringAsFixed(1)} m/s',
              ),
              KitKeyValue('Time moving', _time(report.movingSeconds)),
            ],
          ),
          const KitSection('Movement on court'),
          Center(child: _Heatmap(report.heatmap)),
        ],
        if (clip.status != ClipStatus.withdrawn)
          Text(
            _keptLine(clip),
            style: context.type.secondary.copyWith(height: 1.45),
          ),
        _ClipActions(clip, page: page),
      ],
    );
  }
}

class _Heatmap extends StatelessWidget {
  const _Heatmap(this.grid);

  // A badminton court, far end at the top.
  static const _width = 6.1;
  static const _length = 13.4;

  final List<List<double>> grid;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Semantics(
      image: true,
      label: 'A map of the court, darker where more time was spent',
      child: SizedBox(
        width: 200,
        child: AspectRatio(
          aspectRatio: _width / _length,
          child: CustomPaint(
            painter: _HeatmapPainter(
              grid,
              fill: c.primary,
              court: t.soft,
              line: c.borderControl,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  const _HeatmapPainter(
    this.grid, {
    required this.fill,
    required this.court,
    required this.line,
  });

  final List<List<double>> grid;
  final Color fill;
  final Color court;
  final Color line;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = court);
    final top = grid
        .expand((row) => row)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final h = size.height / grid.length;
    for (final (y, row) in grid.indexed) {
      final w = size.width / row.length;
      for (final (x, v) in row.indexed) {
        if (v <= 0) continue;
        canvas.drawRect(
          Rect.fromLTWH(x * w, y * h, w, h),
          Paint()..color = fill.withValues(alpha: 0.15 + 0.85 * v / top),
        );
      }
    }
    final pen = Paint()
      ..color = line
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, pen);
    final net = size.height / 2;
    canvas.drawLine(
      Offset(0, net),
      Offset(size.width, net),
      pen..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_HeatmapPainter old) => old.grid != grid;
}
