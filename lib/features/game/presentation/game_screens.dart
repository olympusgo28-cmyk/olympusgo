import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../application/game_providers.dart';
import '../domain/game_models.dart';

/// "2,140".
String _n(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// A rank line with a face and a score.
class StandingRow extends StatelessWidget {
  const StandingRow({super.key, required this.s});

  final Standing s;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('${s.rank}', style: OgText.heading(17)),
          ),
          SolidAvatar.forId(
            s.name,
            initials: s.initials,
            size: 38,
            fontSize: 13,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.mine ? 'You' : s.name,
                  style: OgText.body(15, weight: FontWeight.w700),
                ),
                Text(
                  s.sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OgText.body(12, color: c.textMuted),
                ),
              ],
            ),
          ),
          Text(s.score, style: OgText.heading(18)),
        ],
      ),
    );
  }
}

/// A campaign card in its colour.
class CampaignCard extends StatelessWidget {
  const CampaignCard({super.key, required this.c});

  final Campaign c;

  @override
  Widget build(BuildContext context) {
    final ink = Color(c.ink);
    final live = c.state == CampaignState.live;
    return Pressable(
      semanticLabel: '${c.title}, ${c.task}',
      onPressed: () => context.push(Routes.campaign(c.id)),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Color(c.color),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                KitTag(
                  c.state.label,
                  background: live
                      ? const Color(0xFFC6FF00)
                      : const Color(0x33FFFFFF),
                  foreground: live ? OgColors.ink : const Color(0xFFFFFFFF),
                ),
                const Spacer(),
                Flexible(
                  child: Text(
                    c.reward,
                    textAlign: TextAlign.end,
                    style: OgText.body(13, weight: FontWeight.w800, color: ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.title, style: OgText.heading(24, color: ink)),
            const SizedBox(height: 4),
            Text(
              c.task,
              style: OgText.body(14, color: ink.withValues(alpha: 0.85)),
            ),
            const SizedBox(height: 8),
            Text(
              c.meta,
              style: OgText.body(13, color: ink.withValues(alpha: 0.7)),
            ),
            if (c.joined && c.target > 0 && c.state == CampaignState.live) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: c.progress / c.target,
                  minHeight: 8,
                  backgroundColor: const Color(0x33FFFFFF),
                  color: const Color(0xFFC6FF00),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Game: Live, Upcoming and Ended campaigns.
class GameHomeScreen extends ConsumerStatefulWidget {
  const GameHomeScreen({super.key});

  @override
  ConsumerState<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends ConsumerState<GameHomeScreen> {
  CampaignState _tab = CampaignState.live;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final all = ref.watch(campaignsProvider).value;
    final shown = (all ?? const <Campaign>[])
        .where((x) => x.state == _tab)
        .toList();
    return KitScaffold(
      header: KitHeader(
        title: 'Game',
        trailing: KitIconButton(
          icon: OgIcons.trophyCup,
          label: 'Leaderboards',
          onPressed: () => context.push(Routes.leaderboards),
        ),
      ),
      children: [
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.running,
              title: 'My workouts',
              subtitle: 'Camera-counted challenges you joined',
              onTap: () => context.push(Routes.campaign('legs-sprint')),
            ),
            KitNavTile(
              icon: OgIcons.flag,
              title: 'Creator challenges',
              subtitle: 'Run your own when you reach 1,000 followers',
              onTap: () => context.push(Routes.creatorChallenges),
            ),
          ],
        ),
        KitUnderlineTabs(
          labels: [for (final s in CampaignState.values) s.label],
          selected: _tab.index,
          spread: true,
          padding: EdgeInsets.zero,
          onSelect: (i) => setState(() => _tab = CampaignState.values[i]),
        ),
        if (all == null)
          const CupertinoActivityIndicator()
        else if (shown.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Nothing here yet', style: OgText.heading(20)),
                  const SizedBox(height: 6),
                  Text(
                    'New campaigns show up here when they start.',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          for (final x in shown) CampaignCard(c: x),
      ],
    );
  }
}

/// One campaign: what to do, your progress, rewards and rules.
class CampaignScreen extends ConsumerStatefulWidget {
  const CampaignScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CampaignScreen> createState() => _CampaignScreenState();
}

class _CampaignScreenState extends ConsumerState<CampaignScreen> {
  bool _busy = false;

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      await ref.read(gameRepositoryProvider).join(widget.id);
      HapticFeedback.mediumImpact();
      refreshGame(ref.invalidate);
      if (mounted) showOgToast(context, 'You’re in');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(campaignProvider(widget.id));
    final x = async.value;
    if (x == null) {
      return KitScaffold(
        header: const KitHeader(title: 'Campaign'),
        children: [
          if (async.hasError)
            KitNote(
              async.error is AuthFailure
                  ? (async.error! as AuthFailure).message
                  : 'This campaign isn’t available.',
              tone: KitTone.warn,
            )
          else
            const CupertinoActivityIndicator(),
        ],
      );
    }
    Crumbs.name(context, x.title);
    final c = context.og;
    final t = context.tones;
    final live = x.state == CampaignState.live;
    final workout = x.kind == CampaignKind.workout;
    final List<Widget> bottom;
    if (!live) {
      bottom = [
        KitButton(
          label: 'All campaigns',
          style: KitButtonStyle.outline,
          onPressed: () => context.go(Routes.game),
        ),
      ];
    } else if (!x.joined) {
      bottom = [
        KitButton(
          label: workout || x.kind == CampaignKind.creator
              ? 'Join the challenge'
              : 'Join the campaign',
          loading: _busy,
          onPressed: _join,
        ),
      ];
    } else if (workout) {
      bottom = [
        KitButton(
          label: 'Start an attempt',
          onPressed: () => context.push(Routes.cameraSetup(x.id)),
        ),
      ];
    } else {
      bottom = [
        KitButton(
          label: x.kind == CampaignKind.creator
              ? 'Find a ranked Meet'
              : 'Find a ranked Meet',
          onPressed: () => context.push(Routes.play),
        ),
      ];
    }
    final eyebrow = [
      if (x.by != null)
        'BY ${x.by!.toUpperCase()}'
      else
        (workout ? 'WORKOUT CHALLENGE' : 'OLYMPUS CAMPAIGN'),
      if (x.endsAt != null) 'ENDS ${Fmt.day(x.endsAt!).toUpperCase()}',
    ].join(' · ');
    return KitScaffold(
      header: KitHeader(
        title: x.by != null ? 'Challenge' : 'Campaign',
        crumb: x.title,
      ),
      bottom: bottom,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Color(x.color),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow,
                style: OgText.body(
                  12,
                  weight: FontWeight.w800,
                  color: Color(x.ink).withValues(alpha: 0.8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(x.title, style: OgText.heading(28, color: Color(x.ink))),
              if (x.about.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  x.about,
                  style: OgText.body(
                    14,
                    height: 1.4,
                    color: Color(x.ink).withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (x.result != null) KitNote(x.result!, tone: KitTone.info),
        if (x.joined && x.target > 0 && live)
          KitCard(
            padding: const EdgeInsets.all(16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          x.kind == CampaignKind.creator
                              ? 'Your count'
                              : 'Your progress',
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                      ),
                      Text(
                        '${x.progress} / ${x.target}',
                        style: OgText.heading(22),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: x.progress / x.target,
                      minHeight: 10,
                      backgroundColor: t.tag,
                      color: c.primary,
                    ),
                  ),
                  if (x.progressNote.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      x.progressNote,
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ],
                ],
              ),
            ],
          ),
        if (x.counted.isNotEmpty) ...[
          Text('Your Meets', style: OgText.heading(20)),
          KitCard(
            children: [
              for (final (title, sub) in x.counted)
                KitNavTile(
                  icon: OgIcons.tick,
                  title: title,
                  subtitle: sub,
                  chevron: false,
                  onTap: () {},
                ),
              if (x.target > x.counted.length)
                KitNavTile(
                  icon: OgIcons.plus,
                  title: '${x.target - x.counted.length} more ranked Meets',
                  subtitle: x.endsAt == null
                      ? 'Before it ends'
                      : 'Before ${Fmt.dayTimeComma(x.endsAt!)}',
                  onTap: () => context.push(Routes.play),
                ),
            ],
          ),
        ],
        if (workout) ...[
          Text('The set, in this order', style: OgText.heading(20)),
          KitCard(
            children: [
              for (final (i, e) in x.exercises.indexed)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${i + 1}. ${e.name}',
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                            Text(
                              e.form,
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${e.reps} reps',
                        style: OgText.body(14, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (x.joined)
            Row(
              children: [
                for (final (i, (big, small)) in [
                  (
                    x.bestSeconds == null ? '–' : clock(x.bestSeconds!),
                    'your best',
                  ),
                  (x.rank == null ? '–' : '#${x.rank}', 'of ${_n(x.players)}'),
                  ('${x.attempts}', 'attempts'),
                ].indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: t.tag,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(big, style: OgText.heading(22)),
                          Text(small, style: OgText.body(12, color: t.onTag)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
        ],
        if (x.standings.isNotEmpty) ...[
          Text(
            workout ? 'Fastest times' : 'Leaderboard',
            style: OgText.heading(20),
          ),
          KitCard(children: [for (final s in x.standings) StandingRow(s: s)]),
        ],
        if (x.rewards.isNotEmpty) ...[
          Text(
            x.kind == CampaignKind.creator ? 'Prize' : 'Rewards',
            style: OgText.heading(20),
          ),
          Column(
            children: [
              for (final r in x.rewards) KitKeyValue(r.condition, r.prize),
            ],
          ),
        ],
        if (x.rules.isNotEmpty) ...[
          Text(
            x.kind == CampaignKind.creator ? 'How it works' : 'Rules',
            style: OgText.heading(20),
          ),
          KitCheckList(x.rules),
        ],
        if (x.sponsor != null)
          Text(
            'Paid partnership with ${x.sponsor}',
            style: OgText.body(13, color: c.textMuted),
          ),
        Text(
          '${_n(x.players)} players ${live ? 'have joined' : 'took part'}. Free to join.${workout ? ' Stop if you feel pain.' : ''}',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Get in frame before an attempt.
class CameraSetupScreen extends ConsumerWidget {
  const CameraSetupScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    return KitScaffold(
      header: const KitHeader(title: 'Camera setup'),
      bottom: [
        KitButton(
          label: 'Start, 3 second countdown',
          onPressed: () => context.pushReplacement(Routes.attempt(id)),
        ),
      ],
      children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFF26292E),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 150,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(80),
                    border: Border.all(
                      color: const Color(0xFFC6FF00),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    CupertinoIcons.person_fill,
                    size: 120,
                    color: Color(0x55FFFFFF),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: KitTag(
                  'You’re in frame',
                  background: const Color(0xFFC6FF00),
                  foreground: OgColors.ink,
                ),
              ),
            ],
          ),
        ),
        Text('Set up your camera', style: OgText.heading(22)),
        const KitCheckList([
          'Prop your phone 2 to 3 metres away, at hip height',
          'Head to feet inside the dashed frame',
          'Good light in front of you, not behind',
        ]),
        KitNote(
          'Camera counting is a preview in this build: reps are simulated so '
          'you can try the flow. Real counting arrives with the camera release.',
          tone: KitTone.info,
        ),
        Text(
          'The attempt is recorded so top times can be checked.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// The attempt: clock, rep counter and form feedback, then the result.
class AttemptScreen extends ConsumerStatefulWidget {
  const AttemptScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<AttemptScreen> createState() => _AttemptScreenState();
}

class _AttemptScreenState extends ConsumerState<AttemptScreen> {
  Timer? _timer;
  int _countdown = 3;
  int _seconds = 0;
  int _exercise = 0;
  int _reps = 0;
  int _redone = 0;
  bool _paused = false;
  String _feedback = 'Get ready';
  bool _bad = false;
  AttemptResult? _result;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), _tickClock);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tickClock(Timer _) {
    if (!mounted || _paused || _result != null) return;
    if (_countdown > 0) {
      setState(() => _countdown--);
      return;
    }
    final x = ref.read(campaignProvider(widget.id)).value;
    if (x == null) return;
    setState(() {
      _seconds += 3;
      // Simulated reps: every now and then one is too shallow and redone.
      if (_exercise == 0 && _reps == 6 && _redone < 2) {
        _redone++;
        _bad = true;
        _feedback = 'No rep. Go lower.';
        return;
      }
      _bad = false;
      _reps++;
      _feedback =
          'Good ${x.exercises[_exercise].name.toLowerCase()}. Keep going.';
      if (_reps >= x.exercises[_exercise].reps) {
        _exercise++;
        _reps = 0;
      }
    });
    if (_exercise >= x.exercises.length) _finish();
  }

  Future<void> _finish() async {
    _timer?.cancel();
    try {
      final r = await ref
          .read(gameRepositoryProvider)
          .finishAttempt(widget.id, seconds: _seconds, redone: _redone);
      HapticFeedback.heavyImpact();
      refreshGame(ref.invalidate);
      if (mounted) setState(() => _result = r);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final x = ref.watch(campaignProvider(widget.id)).value;
    if (_result case final r?) return _resultPage(r);
    if (x == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Attempt'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final ex = x.exercises[_exercise.clamp(0, x.exercises.length - 1)];
    const white = Color(0xFFFFFFFF);
    return KitScaffold(
      header: const KitHeader(title: 'Attempt'),
      background: OgColors.ink,
      bottom: [
        KitButton(
          label: _paused ? 'Carry on' : 'Pause',
          style: KitButtonStyle.gold,
          onPressed: () => setState(() => _paused = !_paused),
        ),
        KitButton(
          label: 'Send the video for review',
          style: KitButtonStyle.outline,
          onPressed: () {
            _timer?.cancel();
            context.pushReplacement(
              Routes.attemptReview(widget.id),
              extra: (_seconds, _reps),
            );
          },
        ),
      ],
      children: [
        Center(
          child: Text(
            _countdown > 0 ? '$_countdown' : clock(_seconds),
            style: OgText.heading(72, color: white),
          ),
        ),
        Center(
          child: Text(
            '${_exercise + 1} OF ${x.exercises.length} · ${ex.name.toUpperCase()}',
            style: OgText.body(
              13,
              weight: FontWeight.w800,
              color: const Color(0xFFC9C6BC),
              letterSpacing: 0.8,
            ),
          ),
        ),
        Center(
          child: Text(
            '$_reps',
            style: OgText.heading(96, color: const Color(0xFFC6FF00)),
          ),
        ),
        Center(
          child: Text(
            'of ${ex.reps} ${ex.name.toLowerCase()}',
            style: OgText.body(16, color: white),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _bad ? const Color(0xFFD2342C) : const Color(0x22FFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _paused
                ? 'Paused at ${clock(_seconds)}. Your reps are kept.'
                : (_countdown > 0 ? 'Starting in $_countdown' : _feedback),
            textAlign: TextAlign.center,
            style: OgText.body(15, weight: FontWeight.w700, color: white),
          ),
        ),
        Text(
          'Preview: reps are simulated in this build.',
          textAlign: TextAlign.center,
          style: OgText.body(12, color: const Color(0xFFC9C6BC)),
        ),
      ],
    );
  }

  Widget _resultPage(AttemptResult r) {
    final c = context.og;
    final t = context.tones;
    return KitScaffold(
      header: const KitHeader(title: 'Result'),
      bottom: [
        KitButton(
          label: 'Try again',
          onPressed: () =>
              context.pushReplacement(Routes.cameraSetup(widget.id)),
        ),
        KitButton(
          label: 'See the leaderboard',
          style: KitButtonStyle.outline,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        if (r.best)
          KitTag('New personal best', background: t.gold, foreground: t.onGold),
        Text(clock(r.seconds), style: OgText.heading(64)),
        Row(
          children: [
            for (final (i, (big, small)) in [
              ('#${r.rank}', 'of ${_n(r.of)}'),
              ('${r.valid} / ${r.valid}', 'valid reps'),
              ('${r.redone}', 'no reps redone'),
            ].indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: t.tag,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text(big, style: OgText.heading(20)),
                      Text(small, style: OgText.body(12, color: t.onTag)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        Text('Split by exercise', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final (name, sub, time) in r.splits)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(sub, style: OgText.body(13, color: c.textMuted)),
                        ],
                      ),
                    ),
                    Text(time, style: OgText.heading(17)),
                  ],
                ),
              ),
          ],
        ),
        if (r.tip.isNotEmpty) KitNote(r.tip, tone: KitTone.info),
      ],
    );
  }
}

/// Send an attempt for a person to check, when the camera couldn't.
class AttemptReviewScreen extends ConsumerStatefulWidget {
  const AttemptReviewScreen({super.key, required this.id, this.recorded});

  final String id;

  /// Seconds and reps recorded so far.
  final (int, int)? recorded;

  @override
  ConsumerState<AttemptReviewScreen> createState() =>
      _AttemptReviewScreenState();
}

class _AttemptReviewScreenState extends ConsumerState<AttemptReviewScreen> {
  String? _why;
  bool _busy = false;
  bool _sent = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(gameRepositoryProvider)
          .sendForReview(widget.id, reason: _why!);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _sent = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (_sent) {
      return KitScaffold(
        header: const KitHeader(title: 'Send for review'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to the challenge',
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Sent'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'We’ll check your video. You get a message when it is reviewed. You can try again any time.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    final rec = widget.recorded;
    return KitScaffold(
      header: const KitHeader(title: 'Send for review'),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick what went wrong' : 'Send video',
          loading: _busy,
          onPressed: _why == null ? null : _send,
        ),
      ],
      children: [
        const KitTitle(
          'Send this attempt for review',
          lead: 'Use this when the camera could not track you, for example in poor light.',
        ),
        if (rec != null)
          KitKeyValue(
            'Recorded',
            '${clock(rec.$1)} so far, ${rec.$2} reps counted',
          ),
        const KitKeyValue('Reviewed by', 'The Olympus team, within 2 days'),
        const KitKeyValue('Until then', 'Your time is not on the leaderboard'),
        Text('What went wrong?', style: OgText.heading(20)),
        Column(
          children: [
            for (final (name, sub) in const [
              ('Camera kept losing me', 'I was in frame'),
              ('Reps were not counted', 'My form was right'),
              ('The app froze', ''),
            ])
              KitChoiceRow(
                title: name,
                subtitle: sub.isEmpty ? null : sub,
                selected: _why == name,
                onTap: () => setState(() => _why = name),
              ),
          ],
        ),
        Text(
          'A reviewed time can earn the finisher reward but not a top 10 prize. '
          'For a ranked time, try again with the camera tracking you.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Local (rating) and Tournament (points) leaderboards.
class LeaderboardsScreen extends ConsumerStatefulWidget {
  const LeaderboardsScreen({super.key});

  @override
  ConsumerState<LeaderboardsScreen> createState() => _LeaderboardsScreenState();
}

class _LeaderboardsScreenState extends ConsumerState<LeaderboardsScreen> {
  bool _local = true;
  String _sport = 'Badminton';
  String _area = 'Tampines';

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final areas = _local
        ? const ['Tampines', 'East', 'All Singapore']
        : const ['All Singapore'];
    final area = areas.contains(_area) ? _area : areas.last;
    final rows = ref.watch(leaderboardProvider(_local, _sport, area)).value;
    const podiumColors = [
      Color(0xFFF2C14E),
      Color(0xFFD9D9DE),
      Color(0xFFE0B08A),
    ];
    const heights = [92.0, 70.0, 54.0];
    final now = DateTime.now();
    final month = const [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ][now.month - 1];
    Widget podium(int i) {
      final s = rows![i];
      return Expanded(
        child: Column(
          children: [
            SolidAvatar.forId(
              s.name,
              initials: s.initials,
              size: i == 0 ? 56 : 46,
              fontSize: i == 0 ? 17 : 14,
            ),
            const SizedBox(height: 4),
            Text(
              s.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(13, weight: FontWeight.w700),
            ),
            Text(s.score, style: OgText.body(12, color: c.textMuted)),
            const SizedBox(height: 6),
            Container(
              height: heights[i],
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: podiumColors[i],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Text(
                '${i + 1}',
                style: OgText.heading(24, color: const Color(0xFF3A2C00)),
              ),
            ),
          ],
        ),
      );
    }

    return KitScaffold(
      header: const KitHeader(title: 'Leaderboards'),
      children: [
        KitSegments(
          labels: const ['Local', 'Tournament'],
          selected: _local ? 0 : 1,
          onSelect: (i) => setState(() => _local = i == 0),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in const ['Badminton', 'Pickleball'])
              KitChip(
                label: s,
                selected: _sport == s,
                onTap: () => setState(() => _sport = s),
              ),
            for (final a in areas)
              KitChip(
                label: a,
                selected: area == a,
                onTap: () => setState(() => _area = a),
              ),
          ],
        ),
        Text(
          _local ? '$area · $month' : '${now.year} season · Singapore',
          style: OgText.heading(22),
        ),
        Text(
          _local
              ? 'Skill rating from confirmed matches in ${_sport.toLowerCase()}'
              : 'Ranking points from tournament placings in ${_sport.toLowerCase()}',
          style: OgText.body(13, color: c.textMuted),
        ),
        if (rows == null)
          const CupertinoActivityIndicator()
        else if (rows.isEmpty)
          Text(
            'No ranked players yet.',
            style: OgText.body(14, color: c.textMuted),
          )
        else ...[
          if (rows.length >= 3)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                podium(1),
                const SizedBox(width: 8),
                podium(0),
                const SizedBox(width: 8),
                podium(2),
              ],
            ),
          KitCard(children: [for (final s in rows.skip(3)) StandingRow(s: s)]),
        ],
        if (_local && _sport == 'Badminton' && area == 'Tampines')
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: t.successFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Text('#12', style: OgText.heading(20, color: t.onSuccessFill)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You · 6 confirmed matches this month',
                    style: OgText.body(
                      14,
                      weight: FontWeight.w700,
                      color: t.onSuccessFill,
                    ),
                  ),
                ),
                Text('5.4', style: OgText.heading(18, color: t.onSuccessFill)),
              ],
            ),
          ),
        Text(
          _local
              ? 'Local ranks by skill rating. Only players with at least 4 confirmed matches this month appear. It resets on the 1st of each month; your rating does not reset.'
              : 'Tournament ranks by ranking points from placings, weighted by tier: Club, Regional or National. Points count only from verified organizers with 16 or more entries. It resets each January; titles stay on your Passport as badges.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
        Text(
          'Rank itself never earns points or money. The top 10 at the end of each season get a badge on their Passport.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
        Pressable(
          semanticLabel: 'Report a result that looks wrong',
          onPressed: () => context.push(Routes.help),
          child: Text(
            'Report a result that looks wrong',
            style: OgText.body(14, weight: FontWeight.w700, color: c.link),
          ),
        ),
      ],
    );
  }
}
