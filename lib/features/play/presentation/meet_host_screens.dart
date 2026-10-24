import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

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
import '../application/play_providers.dart';
import '../domain/activity.dart';
import '../domain/meet_ops.dart';
import 'meet_action_screens.dart';
import 'meet_detail_screen.dart';
import 'create_meet_screens.dart' show editActivity;

/// Loads the Meet and its players, then builds [body].
class _WithPlayers extends ConsumerWidget {
  const _WithPlayers({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final Widget Function(Activity a, List<MeetPlayer> players) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) => WithActivity(
    id: id,
    title: title,
    body: (a) => switch (ref.watch(meetPlayersProvider(id))) {
      AsyncData(:final value) => body(a, value),
      AsyncError(:final error) => KitScaffold(
        header: KitHeader(title: title),
        children: [
          KitNote(
            error is AuthFailure
                ? error.message
                : "Couldn't load the players. Try again.",
            tone: KitTone.warn,
          ),
        ],
      ),
      _ => KitScaffold(
        header: KitHeader(title: title),
        children: const [CupertinoActivityIndicator()],
      ),
    },
  );
}

/// "Fri, 2 Oct" for screen subtitles.
String _short(Activity a) => '${a.title} · ${Fmt.day(a.startsAt)}';

/// Going and Waitlist, with levels and ratings.
class MeetPlayersScreen extends StatefulWidget {
  const MeetPlayersScreen({super.key, required this.activityId});

  final String activityId;

  @override
  State<MeetPlayersScreen> createState() => _MeetPlayersScreenState();
}

class _MeetPlayersScreenState extends State<MeetPlayersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => _WithPlayers(
    id: widget.activityId,
    title: 'Players',
    body: (a, players) {
      final c = context.og;
      final going = players.where((p) => p.waitlistAt == null).toList();
      final waiting = players.where((p) => p.waitlistAt != null).toList()
        ..sort((x, y) => x.waitlistAt!.compareTo(y.waitlistAt!));
      final list = _tab == 0 ? going : waiting;
      return KitScaffold(
        header: const KitHeader(title: 'Players'),
        bottom: [
          if (a.iAmHost)
            KitButton(
              label: 'Add a walk-in',
              icon: OgIcons.plus,
              onPressed: () => context.push(Routes.meetWalkIn(a.id)),
            )
          else if (a.isFull && a.myStatus == MyStatus.none)
            KitButton(
              label: 'Meet full? Join the waitlist',
              style: KitButtonStyle.dark,
              onPressed: () => context.push(Routes.waitlist(a.id)),
            )
          else if (a.allowGuests && !a.isFull)
            KitButton(
              label: 'Bring a guest',
              style: KitButtonStyle.outline,
              onPressed: () => context.push(Routes.guest(a.id)),
            ),
        ],
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: KitTitle(
                  '${a.spotsTaken} of ${a.capacity} playing',
                  lead: _short(a),
                  size: 28,
                ),
              ),
              if (a.men + a.women > 0) ...[
                OgIcon(OgIcons.male, size: 18, color: c.textMuted),
                Text(
                  ' ${a.men}  ',
                  style: OgText.body(14, weight: FontWeight.w700),
                ),
                OgIcon(OgIcons.female, size: 18, color: c.textMuted),
                Text(
                  ' ${a.women}',
                  style: OgText.body(14, weight: FontWeight.w700),
                ),
              ],
            ],
          ),
          KitUnderlineTabs(
            labels: ['Going ${going.length}', 'Waitlist ${waiting.length}'],
            selected: _tab,
            spread: true,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _tab = i),
          ),
          if (list.isEmpty)
            DashedBox(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _tab == 0 ? 'Nobody is going yet' : 'Nobody is waiting',
                      style: OgText.heading(20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tab == 0
                          ? 'Players who join show up here.'
                          : 'When the Meet is full, extra sign-ups queue here '
                                'in order. The first in the queue gets the '
                                'next free spot.',
                      style: OgText.body(14, height: 1.45, color: c.textMuted),
                    ),
                  ],
                ),
              ),
            )
          else
            KitCard(
              children: [
                for (final p in list)
                  PlayerRow(
                    player: p.player,
                    meta: p.waitlistAt == null
                        ? p.meta
                        : '#${p.waitlistAt} in line · ${p.meta}',
                    rating: p.rating?.toStringAsFixed(1),
                  ),
              ],
            ),
          if (a.levelMin != null)
            KitNote(
              'Level range for this Meet is ${a.bands}. Ratings come from '
              'ranked games.',
            ),
        ],
      );
    },
  );
}

/// Add a member who came without joining in the app.
class MeetWalkInScreen extends ConsumerStatefulWidget {
  const MeetWalkInScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<MeetWalkInScreen> createState() => _MeetWalkInScreenState();
}

class _MeetWalkInScreenState extends ConsumerState<MeetWalkInScreen> {
  String _query = '';
  String? _picked;
  bool _cash = false;
  bool _busy = false;

  Future<void> _add(Activity a) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(playRepositoryProvider)
          .addWalkIn(a.id, _picked!, cash: _cash);
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (!mounted) return;
      showOgToast(context, 'Added and marked Present');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Add a walk-in',
    body: (a) {
      final c = context.og;
      final all =
          ref.watch(walkInCandidatesProvider(a.id)).value ??
          const <MeetPlayer>[];
      final q = _query.trim().toLowerCase();
      final shown = q.isEmpty
          ? all
          : all
                .where(
                  (p) =>
                      p.player.displayName.toLowerCase().contains(q) ||
                      (p.player.username ?? '').toLowerCase().contains(q),
                )
                .toList();
      final fee = a.platformCents;
      return KitScaffold(
        header: const KitHeader(title: 'Add a walk-in'),
        bottom: [
          KitButton(
            label: 'Add and mark Present',
            loading: _busy,
            onPressed: _picked == null ? null : () => _add(a),
          ),
          KitButton(
            label: 'Cancel',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          const KitTitle(
            'Who turned up?',
            lead: 'Add a member who came without joining in the app.',
          ),
          KitSearchField(
            hint: 'Search members',
            onChanged: (v) => setState(() => _query = v),
          ),
          if (shown.isEmpty)
            Text(
              all.isEmpty
                  ? 'Everyone who has played with you is already on the list.'
                  : 'Nothing matches. Check the spelling or clear the search.',
              style: OgText.body(14, height: 1.45, color: c.textMuted),
            )
          else
            Column(
              children: [
                for (final p in shown.take(8))
                  KitChoiceRow(
                    leading: SolidAvatar.forId(
                      p.player.id,
                      initials: p.player.initials,
                      size: 40,
                      fontSize: 14,
                    ),
                    title: p.player.displayName,
                    subtitle: [p.role, ?p.band].join(' · '),
                    tag: p.rating?.toStringAsFixed(1),
                    selected: _picked == p.player.id,
                    onTap: () => setState(() => _picked = p.player.id),
                  ),
              ],
            ),
          if (!a.isFree)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('How did they pay?', style: OgText.heading(20)),
                const SizedBox(height: 6),
                KitChoiceRow(
                  title: 'Pay in app',
                  subtitle:
                      'They get a payment request for '
                      'S\$${money(a.feeCents + fee)}, fee included. Points go '
                      'to whoever pays, after you mark them Present.',
                  selected: !_cash,
                  onTap: () => setState(() => _cash = false),
                ),
                KitChoiceRow(
                  title: 'Cash to organizer',
                  subtitle:
                      'You collect S\$${money(a.feeCents)} yourself. The '
                      'S\$${money(fee)} platform fee is charged to the club, '
                      'and the club earns the points.',
                  selected: _cash,
                  onTap: () => setState(() => _cash = true),
                ),
              ],
            ),
        ],
      );
    },
  );
}

/// Present or Absent for everyone on the list, by 11:59 PM on the day.
class MeetAttendanceScreen extends ConsumerStatefulWidget {
  const MeetAttendanceScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<MeetAttendanceScreen> createState() =>
      _MeetAttendanceScreenState();
}

class _MeetAttendanceScreenState extends ConsumerState<MeetAttendanceScreen> {
  final _marks = <String, Attendance>{};
  bool _busy = false;
  bool _checkedIn = false;

  Attendance _mark(MeetPlayer p) => _marks[p.player.id] ?? p.attendance;

  Future<void> _checkIn(Activity a) async {
    try {
      await ref.read(playRepositoryProvider).checkIn(a.id);
      HapticFeedback.mediumImpact();
      setState(() {
        _checkedIn = true;
        _marks[a.host.id] = Attendance.present;
      });
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _save(Activity a, List<MeetPlayer> going) async {
    setState(() => _busy = true);
    try {
      await ref.read(playRepositoryProvider).saveAttendance(a.id, {
        for (final p in going) p.player.id: _mark(p),
      });
      HapticFeedback.mediumImpact();
      ref.invalidate(meetPlayersProvider(a.id));
      if (!mounted) return;
      final present = going.where((p) => _mark(p) == Attendance.present).length;
      await showDoneSheet(
        context,
        title: 'Attendance saved',
        body:
            '$present present. They get Passport credit, points and a stats '
            "card, and their payments go to your earnings.",
        next: 'See my recap',
        onNext: () => context.push(Routes.meetRecap(a.id)),
      );
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithPlayers(
    id: widget.activityId,
    title: 'Attendance',
    body: (a, players) {
      final c = context.og;
      final t = context.tones;
      final going = players.where((p) => p.waitlistAt == null).toList();
      final now = DateTime.now();
      final opens = a.startsAt.subtract(const Duration(minutes: 30));
      final closes = DateTime(
        a.startsAt.year,
        a.startsAt.month,
        a.startsAt.day + 1,
      );
      final open = now.isAfter(opens) && now.isBefore(closes);
      final present = going.where((p) => _mark(p) == Attendance.present).length;
      final unmarked = going
          .where((p) => _mark(p) == Attendance.unmarked)
          .length;
      final host = going.where((p) => p.isHost).firstOrNull;
      final hostIn = host != null && _mark(host) == Attendance.present;
      final today = Fmt.day(now) == Fmt.day(a.startsAt);

      Widget pill(
        String label,
        bool on,
        Color bg,
        Color fg,
        VoidCallback tap,
      ) => Pressable(
        semanticLabel: label,
        selected: on,
        onPressed: open ? tap : null,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? bg : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: OgText.body(
              13,
              weight: FontWeight.w700,
              color: on ? fg : c.textMuted,
            ),
          ),
        ),
      );

      return KitScaffold(
        header: const KitHeader(title: 'Attendance'),
        bottom: [
          KitButton(
            label: !open
                ? (now.isBefore(opens)
                      ? 'Opens at ${Fmt.time(opens)}'
                      : 'Attendance has closed')
                : unmarked == 0
                ? 'Confirm attendance'
                : 'Mark $unmarked more to confirm',
            loading: _busy,
            onPressed: open && unmarked == 0 ? () => _save(a, going) : null,
          ),
        ],
        children: [
          Text(_short(a), style: OgText.body(14, color: c.textMuted)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$present', style: OgText.heading(44)),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'of ${going.length} present',
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                      Text(
                        unmarked == 0
                            ? 'Everyone is marked'
                            : '$unmarked not marked yet',
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              if (open)
                KitChip(
                  label: 'All present',
                  onTap: () => setState(() {
                    for (final p in going) {
                      if (p.isHost && !hostIn) continue;
                      if (_mark(p) != Attendance.absent) {
                        _marks[p.player.id] = Attendance.present;
                      }
                    }
                  }),
                ),
            ],
          ),
          KitNote(
            'Mark by 11:59 PM ${today ? 'tonight' : 'on ${Fmt.day(a.startsAt)}'}. '
            'Only present players get Passport credit, points and a stats '
            'card. Saving releases the players’ payments to your earnings. If '
            'you don’t save, they are released 24 hours after the Meet ends.',
          ),
          if (host != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hostIn ? t.successFill : t.warnFill,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    !hostIn
                        ? 'You have not been detected at ${a.venue.name}'
                        : _checkedIn
                        ? 'You checked in'
                        : 'Your own attendance is automatic',
                    style: OgText.body(
                      15,
                      weight: FontWeight.w700,
                      color: hostIn ? t.onSuccessFill : t.onWarnFill,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    !hostIn
                        ? 'Your location may be off. Tap Check in on your row '
                              'when you are there. Check in works from '
                              '${Fmt.time(opens)}, 30 minutes before the '
                              'start, until the Meet ends. You mark the other '
                              'players below.'
                        : _checkedIn
                        ? 'You are marked Present. You mark the other players '
                              'below.'
                        : 'You are marked Present when your phone reaches '
                              '${a.venue.name}. Keep location on. You mark the '
                              'other players below.',
                    style: OgText.body(
                      13,
                      height: 1.45,
                      color: hostIn ? t.onSuccessFill : t.onWarnFill,
                    ),
                  ),
                ],
              ),
            ),
          KitCard(
            children: [
              for (final p in going)
                PlayerRow(
                  player: p.player,
                  meta: p.isHost
                      ? (hostIn
                            ? 'You · ${_checkedIn ? 'checked in ${Fmt.time(now)}' : 'arrived'}'
                            : 'You · not detected at ${a.venue.name}')
                      : [
                          p.meta,
                          if (p.checkedInAt != null)
                            'checked in ${Fmt.time(p.checkedInAt!)}',
                        ].join(' · '),
                  trailing: p.isHost
                      ? (hostIn
                            ? KitTag(
                                'Present',
                                background: c.primary,
                                foreground: c.onPrimary,
                              )
                            : KitButton(
                                label: 'Check in',
                                height: 36,
                                radius: 18,
                                fontSize: 13,
                                padding: 12,
                                expand: false,
                                onPressed: open ? () => _checkIn(a) : null,
                              ))
                      : Semantics(
                          label: 'Attendance for ${p.player.displayName}',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              pill(
                                'Present',
                                _mark(p) == Attendance.present,
                                c.primary,
                                c.onPrimary,
                                () => setState(
                                  () =>
                                      _marks[p.player.id] = Attendance.present,
                                ),
                              ),
                              pill(
                                'Absent',
                                _mark(p) == Attendance.absent,
                                t.dangerFill,
                                t.onDangerFill,
                                () => setState(
                                  () => _marks[p.player.id] = Attendance.absent,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              Pressable(
                semanticLabel: 'Add a walk-in member',
                onPressed: () => context.push(Routes.meetWalkIn(a.id)),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OgIcon(OgIcons.plus, size: 18, color: c.text),
                      const SizedBox(width: 6),
                      Text(
                        'Add a walk-in member',
                        style: OgText.body(14, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}

/// The player's stats card for one Meet, to keep or share.
class MeetRecapScreen extends ConsumerStatefulWidget {
  const MeetRecapScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<MeetRecapScreen> createState() => _MeetRecapScreenState();
}

class _MeetRecapScreenState extends ConsumerState<MeetRecapScreen> {
  final _card = GlobalKey();
  bool _rating = true;
  bool _record = true;
  bool _partner = true;
  bool _sharing = false;

  Future<void> _share(Activity a) async {
    setState(() => _sharing = true);
    final box = context.findRenderObject() as RenderBox?;
    try {
      final boundary =
          _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              png!.buffer.asUint8List(),
              mimeType: 'image/png',
              name: 'olympus-recap.png',
            ),
          ],
          text: 'My ${a.title} recap',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        showOgToast(
          context,
          "Couldn't make the image. Try again.",
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Meet recap',
    body: (a) {
      final c = context.og;
      final r = ref.watch(meetRecapProvider(a.id)).value;
      if (r == null) {
        return const KitScaffold(
          header: KitHeader(title: 'Meet recap'),
          children: [CupertinoActivityIndicator()],
        );
      }
      final hours = a.endsAt.difference(a.startsAt).inMinutes / 60;
      final tiles = _record
          ? [
              ('${r.games}', 'games'),
              ('${r.wins} – ${r.losses}', 'wins – losses'),
              (r.bestGame ?? '–', 'best game'),
            ]
          : [
              ('${r.games}', 'games'),
              ('${hours % 1 == 0 ? hours.toInt() : hours} h', 'on court'),
              ('${r.session}', 'sessions'),
            ];
      final me = ref.watch(currentUserIdProvider).value;
      final name =
          a.going.where((p) => p.id == me).firstOrNull?.displayName ??
          (a.iAmHost ? a.host.displayName : 'You');
      final link = r.clubLink;
      return KitScaffold(
        header: const KitHeader(title: 'Meet recap'),
        children: [
          KitTitle('Your Meet recap', lead: _short(a)),
          RepaintBoundary(
            key: _card,
            child: _RecapCard(
              activity: a,
              recap: r,
              tiles: tiles,
              showRating: _rating && r.ratingChange != null,
              showPartner: _partner && r.bestPartner != null,
              playerName: name,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Show on the card', style: OgText.heading(20)),
              const SizedBox(height: 4),
              for (final (label, hint, on, set) in [
                (
                  'Rating change',
                  'Your level and how it moved',
                  _rating,
                  (bool v) => _rating = v,
                ),
                (
                  'Wins and losses',
                  'Off shows games and time only',
                  _record,
                  (bool v) => _record = v,
                ),
                (
                  'Best partner',
                  'First name and initial only',
                  _partner,
                  (bool v) => _partner = v,
                ),
              ])
                MergeSemantics(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 64),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                hint,
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        CupertinoSwitch(
                          value: on,
                          activeTrackColor: c.primary,
                          onChanged: (v) => setState(() => set(v)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          KitButton(
            label: 'Share stats card',
            icon: OgIcons.shareUp,
            loading: _sharing,
            onPressed: () => _share(a),
          ),
          if (link != null)
            KitButton(
              label: 'Copy club link',
              style: KitButtonStyle.outline,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: 'https://$link'));
                if (context.mounted) showOgToast(context, 'Link copied');
              },
            ),
          KitNote(
            'You earned ${r.points} points for showing up.',
            tone: KitTone.info,
            child: Align(
              alignment: Alignment.centerLeft,
              child: KitLink(
                'See your points',
                underline: true,
                onPressed: () => context.push(Routes.points),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _RecapCard extends StatelessWidget {
  const _RecapCard({
    required this.activity,
    required this.recap,
    required this.tiles,
    required this.showRating,
    required this.showPartner,
    required this.playerName,
  });

  final Activity activity;
  final MeetRecap recap;
  final List<(String, String)> tiles;
  final bool showRating;
  final bool showPartner;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final a = activity;
    final r = recap;
    const muted = Color(0xFFC9C6BC);
    final change = r.ratingChange ?? 0;
    final partner = r.bestPartner?.displayName.split(' ');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: OgColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            a.eyebrow.toUpperCase(),
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: t.gold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(a.title, style: OgText.heading(28, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
            [Fmt.day(a.startsAt), ?r.clubName].join(' · '),
            style: OgText.body(14, color: muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final (i, (big, small)) in tiles.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x1AFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        FittedBox(
                          child: Text(
                            big,
                            style: OgText.heading(24, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          small,
                          textAlign: TextAlign.center,
                          style: OgText.body(12, color: muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (showRating) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'RATING',
                        style: OgText.body(
                          11,
                          weight: FontWeight.w800,
                          color: muted,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        '${r.ratingBefore!.toStringAsFixed(1)} → ${r.ratingAfter!.toStringAsFixed(1)}${r.band == null ? '' : ' · ${r.band}'}',
                        style: OgText.body(
                          16,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                KitTag(
                  '${change >= 0 ? '+' : '−'}${change.abs().toStringAsFixed(1)}',
                  background: t.gold,
                  foreground: t.onGold,
                  height: 30,
                  fontSize: 14,
                ),
              ],
            ),
          ],
          if (showPartner) ...[
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Best partner tonight: '),
                  TextSpan(
                    text:
                        '${partner!.first}${partner.length > 1 ? ' ${partner.last[0]}.' : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  TextSpan(
                    text:
                        ' · ${r.partnerWins} ${r.partnerWins == 1 ? 'win' : 'wins'} together',
                  ),
                ],
              ),
              style: OgText.body(14, color: muted),
            ),
          ],
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x26FFFFFF)),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '$playerName · session ${r.session}',
                style: OgText.body(13, weight: FontWeight.w700, color: muted),
              ),
            ],
          ),
          if (r.clubLink != null)
            Text(
              'Play with us: ${r.clubLink}',
              style: OgText.body(12, color: muted),
            ),
        ],
      ),
    );
  }
}

/// Cancel this Meet, or the rest of its series: refunds, card fees and a
/// message to the players.
class MeetCancelScreen extends ConsumerStatefulWidget {
  const MeetCancelScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<MeetCancelScreen> createState() => _MeetCancelScreenState();
}

class _MeetCancelScreenState extends ConsumerState<MeetCancelScreen> {
  final _message = TextEditingController();
  bool _series = false;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _cancel(Activity a) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(playRepositoryProvider)
          .cancel(a.id, series: _series, message: _message.text.trim());
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (!mounted) return;
      showOgToast(context, 'Meet cancelled. Players are refunded.');
      context.go(Routes.schedule(hosting: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Cancel Meet',
    body: (a) {
      final c = context.og;
      Crumbs.name(context, 'Cancel Meet');
      final p = ref.watch(cancelPreviewProvider(a.id)).value;
      if (p == null) {
        return const KitScaffold(
          header: KitHeader(title: 'Cancel Meet'),
          children: [CupertinoActivityIndicator()],
        );
      }
      final present =
          ref
              .watch(meetPlayersProvider(a.id))
              .value
              ?.where((x) => x.attendance == Attendance.present && !x.isHost)
              .length ??
          0;
      return KitScaffold(
        header: const KitHeader(title: 'Cancel Meet'),
        bottom: [
          KitButton(
            label: a.isFree || p.players == 0
                ? 'Cancel Meet'
                : 'Cancel Meet and refund',
            style: KitButtonStyle.danger,
            loading: _busy,
            onPressed: () => _cancel(a),
          ),
          KitButton(
            label: 'Keep Meet',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitTitle(
            'Cancel ${a.title}?',
            lead:
                '${Fmt.day(a.startsAt)}, ${Fmt.timeRange(a.startsAt, a.endsAt)} · '
                '${p.players} ${p.players == 1 ? 'player' : 'players'} joined',
          ),
          if (a.recurrence != null && p.laterMeets > 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Which Meets?', style: OgText.heading(20)),
                const SizedBox(height: 6),
                KitChoiceRow(
                  title: 'This Meet only',
                  subtitle: Fmt.day(a.startsAt),
                  selected: !_series,
                  onTap: () => setState(() => _series = false),
                ),
                KitChoiceRow(
                  title: 'This and all later Meets',
                  subtitle:
                      '${p.laterMeets} Meets, last one ${Fmt.day(p.lastMeet!)}',
                  selected: _series,
                  onTap: () => setState(() => _series = true),
                ),
              ],
            ),
          if (!a.isFree)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Refunds', style: OgText.heading(20)),
                const SizedBox(height: 4),
                KitKeyValue('Players refunded', '${p.players}'),
                KitKeyValue(
                  'Each gets back',
                  'S\$${money(p.eachCents)}, fee included',
                ),
                KitKeyValue(
                  'Card fees, from your earnings',
                  'S\$${money(p.cardFeeCents)}',
                ),
                KitKeyValue(
                  'Points',
                  present == 0
                      ? 'None, nobody was marked Present'
                      : '$present present keep theirs',
                ),
                const SizedBox(height: 8),
                Text(
                  'Each player picks their Wallet or card. Card companies keep '
                  'their fee when a card payment is refunded, so the '
                  'S\$${money(p.cardFeeCents)} for ${p.cardPayments} card '
                  '${p.cardPayments == 1 ? 'payment' : 'payments'} comes off '
                  'your earnings.',
                  style: OgText.body(13, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          KitTextArea(
            label: 'Message to players',
            optional: true,
            controller: _message,
            hint:
                'Sorry, the courts are closed for maintenance. See you next '
                'week.',
          ),
          KitNote(
            'Only need to change the time or venue? Edit the Meet instead and '
            'players are told.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: KitLink(
                'Edit the Meet',
                underline: true,
                onPressed: () => editActivity(context, ref, a),
              ),
            ),
          ),
        ],
      );
    },
  );
}
