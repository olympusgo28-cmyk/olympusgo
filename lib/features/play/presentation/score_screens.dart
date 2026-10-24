import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../social/domain/social_models.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import '../domain/meet_ops.dart';
import 'meet_action_screens.dart';

const _lime = Color(0xFFC6FF00);
const _muted = Color(0xFFC9C6BC);

/// "You and Priya Raman", "Hannah Goh and Daniel Tan".
String _side(List<PlayerSummary> side, {String? me}) =>
    [for (final p in side) p.id == me ? 'You' : p.displayName].join(' and ');

/// "10 minutes ago".
String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) {
    return '${d.inMinutes} ${d.inMinutes == 1 ? 'minute' : 'minutes'} ago';
  }
  if (d.inHours < 24) {
    return '${d.inHours} ${d.inHours == 1 ? 'hour' : 'hours'} ago';
  }
  return 'on ${Fmt.day(t)}';
}

/// Type the final score of each game; the other side confirms it.
class ScoreEntryScreen extends ConsumerStatefulWidget {
  const ScoreEntryScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends ConsumerState<ScoreEntryScreen> {
  bool _camera = false;
  bool _pickSides = true;
  String? _partner;
  final _opponents = <String>[];

  /// Points per box: game 1 left, game 1 right, game 2 left...
  final _cells = List<String>.filled(6, '');
  int _cur = 0;
  bool _fresh = true;
  bool _busy = false;
  MatchScore? _sent;

  int? _n(String v) => v.isEmpty ? null : int.parse(v);
  List<(int?, int?)> get _games => [
    for (var g = 0; g < 3; g++) (_n(_cells[g * 2]), _n(_cells[g * 2 + 1])),
  ];
  List<int> get _results => [for (final g in _games) gameWinner(g.$1, g.$2)];
  bool get _showThird {
    final r = _results;
    return r[0] > 0 && r[1] > 0 && r[0] != r[1] ||
        _cells[4].isNotEmpty ||
        _cells[5].isNotEmpty;
  }

  void _put(String v, {required bool advance}) {
    HapticFeedback.selectionClick();
    setState(() {
      _cells[_cur] = v;
      _fresh = false;
      final last = _showThird ? 5 : 3;
      if (advance && _cur < last) {
        _cur++;
        _fresh = true;
      }
    });
  }

  void _digit(int d) {
    var v = _fresh ? '' : _cells[_cur];
    if (v.length >= 2) v = '';
    v = '$v$d';
    if (v.length == 2 && int.parse(v) > 30) v = '$d';
    _put(v, advance: v.length == 2);
  }

  void _delete() {
    final v = _cells[_cur];
    _put(
      _fresh || v.isEmpty ? '' : v.substring(0, v.length - 1),
      advance: false,
    );
  }

  void _next() {
    final last = _showThird ? 5 : 3;
    if (_cur < last) {
      setState(() {
        _cur++;
        _fresh = true;
      });
    }
  }

  Future<void> _send(Activity a) async {
    final games = [
      for (final g in _games)
        if (g.$1 != null && g.$2 != null) (g.$1!, g.$2!),
    ];
    setState(() => _busy = true);
    try {
      final s = await ref
          .read(playRepositoryProvider)
          .submitScore(
            a.id,
            partners: [?_partner],
            opponents: _opponents,
            games: games,
          );
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _sent = s);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Enter score',
    body: (a) {
      final me = ref.watch(currentUserIdProvider).value;
      final players = (ref.watch(meetPlayersProvider(a.id)).value ?? const [])
          .where((p) => p.waitlistAt == null && !p.isGuest && p.player.id != me)
          .toList();
      final singles = a.gameType == GameType.singles;
      final ready =
          (singles || _partner != null) &&
          _opponents.length == (singles ? 1 : 2);
      final byId = {for (final p in players) p.player.id: p.player};
      final sideA = [
        if (me != null) PlayerSummary(id: me, fullName: 'You'),
        if (_partner != null) ?byId[_partner],
      ];
      final sideB = [for (final id in _opponents) ?byId[id]];
      final where = [a.title, ?a.court].join(', ');

      if (_sent case final s?) {
        return KitScaffold(
          header: const KitHeader(title: 'Enter score'),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          bottom: [
            KitButton(label: 'Back to Meet', onPressed: () => context.pop()),
          ],
          children: [
            const KitDoneBanner(title: 'Sent'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Waiting for ${s.sideB.map((p) => p.displayName.split(' ').first).join(' or ')}',
                    style: OgText.heading(22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s.sideB.length > 1 ? 'Either of them' : 'They'} can '
                    'confirm. If nobody answers in 24 hours, the organizer '
                    'decides.',
                    style: OgText.body(
                      15,
                      height: 1.45,
                      color: context.og.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      if (_pickSides || !ready) {
        return _SidesPicker(
          players: players,
          singles: singles,
          partner: _partner,
          opponents: _opponents,
          where: where,
          onPartner: (id) => setState(() {
            _partner = id;
            _opponents.remove(id);
          }),
          onOpponent: (id) => setState(() {
            if (_opponents.remove(id)) return;
            if (_opponents.length == (singles ? 1 : 2)) _opponents.removeAt(0);
            _opponents.add(id);
            if (_partner == id) _partner = null;
          }),
          onDone: ready ? () => setState(() => _pickSides = false) : null,
        );
      }

      final r = _results;
      final winsA = r.where((x) => x == 1).length;
      final winsB = r.where((x) => x == 2).length;
      final decided = matchDecided(_games.take(_showThird ? 3 : 2).toList());
      final bad = r.indexOf(-1);
      final head = _camera
          ? 'Camera scoring is coming'
          : decided
          ? (winsA > winsB ? 'You won $winsA–$winsB' : 'You lost $winsB–$winsA')
          : bad >= 0
          ? 'Check game ${bad + 1}'
          : 'Type each game';
      final hint = _camera
          ? 'Courts with a camera will score on their own in Phase 2. Type '
                'the score by hand for now.'
          : bad >= 0
          ? 'A game is won at 21 with 2 clear, or at 30.'
          : decided
          ? 'Ratings change after the other ${singles ? 'player' : 'pair'} '
                'confirms.'
          : 'Tap a box to change it. Game 3 appears if it is 1 game each.';

      return KitScaffold(
        header: KitHeader(title: 'Enter score', subtitle: 'Ranked · $where'),
        gap: 12,
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        bottom: _camera
            ? null
            : [
                _Keypad(onDigit: _digit, onNext: _next, onDelete: _delete),
                KitButton(
                  label: 'Send for confirmation',
                  loading: _busy,
                  onPressed: decided ? () => _send(a) : null,
                ),
              ],
        children: [
          KitSegments(
            labels: const ['Camera', 'Manual'],
            selected: _camera ? 0 : 1,
            onSelect: (i) => setState(() => _camera = i == 0),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OgColors.ink,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                _TeamLine(
                  name: _side(sideA, me: me),
                  wins: winsA,
                  onTap: () => setState(() => _pickSides = true),
                ),
                const SizedBox(height: 6),
                _TeamLine(
                  name: _side(sideB),
                  wins: winsB,
                  onTap: () => setState(() => _pickSides = true),
                ),
                const SizedBox(height: 14),
                for (var g = 0; g < 3; g++)
                  if (g < 2 || _showThird)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          for (final side in [0, 1]) ...[
                            if (side == 1)
                              Expanded(
                                child: Text(
                                  'Game ${g + 1}',
                                  textAlign: TextAlign.center,
                                  style: OgText.body(
                                    13,
                                    weight: FontWeight.w700,
                                    color: _muted,
                                  ),
                                ),
                              ),
                            _ScoreBox(
                              text: _cells[g * 2 + side],
                              label:
                                  'Game ${g + 1}, ${side == 0 ? 'your side' : 'their side'}',
                              active: !_camera && _cur == g * 2 + side,
                              won: r[g] == side + 1,
                              done: r[g] > 0,
                              onTap: _camera
                                  ? null
                                  : () => setState(() {
                                      _cur = g * 2 + side;
                                      _fresh = true;
                                    }),
                            ),
                          ],
                        ],
                      ),
                    ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(head, style: OgText.heading(22)),
              const SizedBox(height: 4),
              Text(
                hint,
                style: OgText.body(
                  14,
                  height: 1.4,
                  color: context.og.textMuted,
                ),
              ),
            ],
          ),
          if (_camera)
            KitButton(
              label: 'Switch to manual',
              style: KitButtonStyle.outline,
              onPressed: () => setState(() => _camera = false),
            ),
        ],
      );
    },
  );
}

class _TeamLine extends StatelessWidget {
  const _TeamLine({required this.name, required this.wins, this.onTap});

  final String name;
  final int wins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel:
        '$name, $wins ${wins == 1 ? 'game' : 'games'}. Change players',
    onPressed: onTap,
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OgText.body(
              16,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          '$wins ${wins == 1 ? 'game' : 'games'}',
          style: OgText.body(14, weight: FontWeight.w600, color: _muted),
        ),
      ],
    ),
  );
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.text,
    required this.label,
    required this.active,
    required this.won,
    required this.done,
    this.onTap,
  });

  final String text;
  final String label;
  final bool active;
  final bool won;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    semanticLabel: '$label, ${text.isEmpty ? 'empty' : text}',
    selected: active,
    onPressed: onTap,
    child: Container(
      width: 96,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? const Color(0x24C6FF00) : const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: active ? _lime : Colors.transparent,
          width: 3,
        ),
      ),
      child: Text(
        text.isEmpty ? '–' : text,
        style: OgText.heading(
          36,
          color: active
              ? Colors.white
              : won
              ? _lime
              : done
              ? const Color(0x8CFFFFFF)
              : Colors.white,
        ),
      ),
    ),
  );
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onNext,
    required this.onDelete,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onNext;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    Widget key(String label, VoidCallback onTap, {Widget? child}) => Expanded(
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Pressable(
          semanticLabel: label,
          onPressed: onTap,
          child: Container(
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: t.tag,
              borderRadius: BorderRadius.circular(14),
            ),
            child: child ?? Text(label, style: OgText.heading(22)),
          ),
        ),
      ),
    );
    return Column(
      children: [
        for (final row in const [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
        ])
          Row(children: [for (final d in row) key('$d', () => onDigit(d))]),
        Row(
          children: [
            key(
              'Next',
              onNext,
              child: Text(
                'Next',
                style: OgText.body(16, weight: FontWeight.w700),
              ),
            ),
            key('0', () => onDigit(0)),
            key(
              'Delete',
              onDelete,
              child: const Icon(CupertinoIcons.delete_left, size: 24),
            ),
          ],
        ),
      ],
    );
  }
}

/// Who played: your partner (doubles) and the other side.
class _SidesPicker extends StatelessWidget {
  const _SidesPicker({
    required this.players,
    required this.singles,
    required this.partner,
    required this.opponents,
    required this.where,
    required this.onPartner,
    required this.onOpponent,
    required this.onDone,
  });

  final List<MeetPlayer> players;
  final bool singles;
  final String? partner;
  final List<String> opponents;
  final String where;
  final ValueChanged<String> onPartner;
  final ValueChanged<String> onOpponent;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    Widget avatar(MeetPlayer p) => SolidAvatar.forId(
      p.player.id,
      initials: p.player.initials,
      size: 40,
      fontSize: 14,
    );
    return KitScaffold(
      header: const KitHeader(title: 'Enter score'),
      bottom: [
        KitButton(
          label: onDone == null
              ? (singles ? 'Pick who you played' : 'Pick all three players')
              : 'Type the score',
          onPressed: onDone,
        ),
      ],
      children: [
        KitTitle('Who played?', lead: where),
        if (players.isEmpty)
          const KitNote('Nobody else is on this Meet yet.')
        else ...[
          if (!singles)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Your partner', style: OgText.heading(20)),
                const SizedBox(height: 6),
                for (final p in players)
                  KitChoiceRow(
                    leading: avatar(p),
                    title: p.player.displayName,
                    subtitle: p.meta,
                    selected: partner == p.player.id,
                    onTap: () => onPartner(p.player.id),
                  ),
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                singles ? 'You played' : 'The other pair',
                style: OgText.heading(20),
              ),
              const SizedBox(height: 6),
              for (final p in players.where((p) => p.player.id != partner))
                KitChoiceRow(
                  leading: avatar(p),
                  title: p.player.displayName,
                  subtitle: p.meta,
                  multi: !singles,
                  selected: opponents.contains(p.player.id),
                  onTap: () => onOpponent(p.player.id),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The other side checks a score: confirm it, or say what is wrong.
class ScoreConfirmScreen extends ConsumerStatefulWidget {
  const ScoreConfirmScreen({super.key, required this.scoreId});

  final String scoreId;

  @override
  ConsumerState<ScoreConfirmScreen> createState() => _ScoreConfirmScreenState();
}

class _ScoreConfirmScreenState extends ConsumerState<ScoreConfirmScreen> {
  bool _saying = false;
  String? _why;
  bool _busy = false;

  Future<void> _answer(bool ok) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(playRepositoryProvider)
          .answerScore(widget.scoreId, confirm: ok, reason: ok ? null : _why);
      HapticFeedback.mediumImpact();
      ref.invalidate(matchScoreProvider(widget.scoreId));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final me = ref.watch(currentUserIdProvider).value;
    final s = ref.watch(matchScoreProvider(widget.scoreId)).value;
    if (s == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Confirm score'),
        children: [CupertinoActivityIndicator()],
      );
    }
    // Show it from the viewer's side.
    final flip = s.sideB.any((p) => p.id == me);
    final top = flip ? s.sideB : s.sideA;
    final bottom = flip ? s.sideA : s.sideB;
    final games = [for (final g in s.games) flip ? (g.$2, g.$1) : g];
    final winsTop = flip ? s.winsB : s.winsA;
    final winsBottom = flip ? s.winsA : s.winsB;
    final org = s.organizer?.displayName ?? 'the organizer';
    final entered = s.enteredBy.displayName.split(' ').first;
    final mine = s.sideA.any((p) => p.id == me);

    Widget table() => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OgColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          for (final (side, wins, isTop) in [
            (top, winsTop, true),
            (bottom, winsBottom, false),
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _side(side, me: me),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: OgText.body(
                            16,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$wins ${wins == 1 ? 'game' : 'games'}',
                          style: OgText.body(13, color: _muted),
                        ),
                      ],
                    ),
                  ),
                  for (final g in games)
                    SizedBox(
                      width: 48,
                      child: Text(
                        '${isTop ? g.$1 : g.$2}',
                        textAlign: TextAlign.center,
                        style: OgText.heading(
                          26,
                          color: (isTop ? g.$1 > g.$2 : g.$2 > g.$1)
                              ? _lime
                              : const Color(0x8CFFFFFF),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Row(
            children: [
              const Spacer(),
              for (var i = 0; i < games.length; i++)
                SizedBox(
                  width: 48,
                  child: Text(
                    'Game ${i + 1}',
                    textAlign: TextAlign.center,
                    style: OgText.body(11, color: _muted),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    final header = Row(
      children: [
        KitTag('Ranked', background: t.gold, foreground: t.onGold),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            [s.activityTitle, Fmt.day(s.enteredAt), ?s.court].join(', '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: OgText.body(14, color: c.textMuted),
          ),
        ),
      ],
    );

    final (List<Widget> body, List<Widget> actions) = switch (s.status) {
      ScoreStatus.confirmed => (
        [
          Text('Confirmed', style: OgText.heading(26)),
          if (s.ratingBefore != null && s.ratingAfter != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  s.ratingBefore!.toStringAsFixed(1),
                  style: OgText.heading(40, color: c.textMuted),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  child: Text('to', style: OgText.body(15, color: c.textMuted)),
                ),
                Text(
                  s.ratingAfter!.toStringAsFixed(1),
                  style: OgText.heading(40),
                ),
              ],
            ),
          Text(
            s.ratingBefore == null
                ? 'It counts toward ratings and the leaderboard.'
                : 'Your rating went ${s.ratingAfter! >= s.ratingBefore! ? 'up' : 'down'}. '
                      'It counts toward the leaderboard too.',
            style: OgText.body(15, height: 1.45, color: c.textMuted),
          ),
        ],
        [
          KitButton(
            label: 'Share my stats card',
            onPressed: () => context.push(Routes.meetRecap(s.activityId)),
          ),
          KitButton(
            label: 'Back to Inbox',
            style: KitButtonStyle.outline,
            onPressed: () => context.go(Routes.inbox),
          ),
        ],
      ),
      ScoreStatus.disputed => (
        [
          Text('Sent to $org', style: OgText.heading(26)),
          Text(
            'You and $entered are told when they set the final score. Ratings '
            'wait until then.',
            style: OgText.body(15, height: 1.45, color: c.textMuted),
          ),
          if (s.reason != null) KitKeyValue('Your reason', s.reason!),
        ],
        [
          KitButton(
            label: 'Back to Inbox',
            onPressed: () => context.go(Routes.inbox),
          ),
        ],
      ),
      ScoreStatus.waiting when mine => (
        [
          Text(
            'Waiting for ${s.sideB.map((p) => p.displayName.split(' ').first).join(' or ')}',
            style: OgText.heading(26),
          ),
          Text(
            'You sent this ${_ago(s.enteredAt)}. If nobody answers in 24 '
            'hours, $org decides.',
            style: OgText.body(15, height: 1.45, color: c.textMuted),
          ),
        ],
        [KitButton(label: 'Done', onPressed: () => kitPop(context))],
      ),
      ScoreStatus.waiting when _saying => (
        [
          Text('What is wrong?', style: OgText.heading(26)),
          Column(
            children: [
              for (final why in const [
                'Wrong score',
                'Wrong players',
                'Game was not finished',
              ])
                KitChoiceRow(
                  title: why,
                  selected: _why == why,
                  onTap: () => setState(() => _why = why),
                ),
            ],
          ),
          KitNote(
            'Your reason goes to $org, who organized the Meet. They set the '
            'final score. Ratings wait until then.',
          ),
        ],
        [
          KitButton(
            label: 'Send to organizer',
            loading: _busy,
            onPressed: _why == null ? null : () => _answer(false),
          ),
          KitButton(
            label: 'Go back',
            style: KitButtonStyle.outline,
            onPressed: () => setState(() => _saying = false),
          ),
        ],
      ),
      ScoreStatus.waiting => (
        [
          Text('Is this score right?', style: OgText.heading(26)),
          Text(
            '$entered entered it ${_ago(s.enteredAt)}. Your rating changes '
            'only after you confirm.',
            style: OgText.body(15, height: 1.45, color: c.textMuted),
          ),
        ],
        [
          KitButton(
            label: 'Yes, confirm',
            loading: _busy,
            onPressed: () => _answer(true),
          ),
          KitButton(
            label: 'No, it is wrong',
            style: KitButtonStyle.dangerOutline,
            onPressed: () => setState(() => _saying = true),
          ),
        ],
      ),
    };

    return KitScaffold(
      header: const KitHeader(title: 'Confirm score'),
      gap: 14,
      bottom: actions,
      children: [header, table(), ...body],
    );
  }
}
