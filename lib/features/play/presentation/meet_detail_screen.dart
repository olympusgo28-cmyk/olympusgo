import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/domain/club_sport.dart';
import '../../social/application/social_providers.dart';
import '../../social/domain/social_models.dart';
import '../../settings/application/settings_providers.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import 'event_screens.dart';
import 'tournament_screens.dart';
import 'create_meet_screens.dart' show editActivity;

/// A Meet, tournament or event: what, when, where, who is going, and
/// joining. Tournaments and events get their own pages in a later phase.
class MeetDetailScreen extends ConsumerWidget {
  const MeetDetailScreen({super.key, required this.activityId, this.tab});

  final String activityId;

  /// The tab to open on a tournament page: info, draw or matches.
  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(activityDetailProvider(activityId))) {
      AsyncData(:final value) => switch (value.kind) {
        ActivityKind.meet => _MeetPage(activity: value),
        ActivityKind.tournament => TournamentPageScreen(
          activityId: activityId,
          tab: switch (tab) {
            'draw' => 1,
            'matches' => 2,
            _ => 0,
          },
        ),
        ActivityKind.event => EventPageScreen(activityId: activityId),
      },
      AsyncError() => const KitScaffold(
        header: KitHeader(title: ''),
        children: [KitNote("This isn't available any more.")],
      ),
      _ => const KitScaffold(
        header: KitHeader(title: ''),
        children: [
          Padding(
            padding: EdgeInsets.only(top: 80),
            child: CupertinoActivityIndicator(),
          ),
        ],
      ),
    };
  }
}

class _MeetPage extends ConsumerStatefulWidget {
  const _MeetPage({required this.activity});

  final Activity activity;

  @override
  ConsumerState<_MeetPage> createState() => _MeetPageState();
}

class _MeetPageState extends ConsumerState<_MeetPage> {
  bool _busy = false;

  Activity get a => widget.activity;

  String get _noun => switch (a.kind) {
    ActivityKind.meet => 'Meet',
    ActivityKind.tournament => 'tournament',
    ActivityKind.event => 'event',
  };

  Future<void> _join() async {
    if (a.isFull) {
      await context.push(Routes.waitlist(a.id));
      return;
    }
    if (!a.isFree) {
      await startPayment(context, ref, a);
      return;
    }
    setState(() => _busy = true);
    try {
      final status = await ref.read(playRepositoryProvider).join(a.id);
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (mounted) {
        showOgToast(
          context,
          status == MyStatus.requested
              ? 'Request sent to the host'
              : "You're in",
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggleSave() async {
    HapticFeedback.selectionClick();
    try {
      final saved = await ref
          .read(savedIdsProvider(SavedKind.meet).notifier)
          .toggle(a.id);
      if (mounted) {
        showOgToast(context, saved ? 'Saved' : 'Removed from saved');
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _directions() async {
    final q = Uri.encodeQueryComponent('${a.venue.name}, ${a.venue.address}');
    final ok = await launchUrl(
      Uri.parse('https://maps.apple.com/?q=$q'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: a.venue.address));
      if (mounted) showOgToast(context, 'Address copied');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final top = MediaQuery.of(context).padding.top;
    final club = a.clubId == null
        ? null
        : ref.watch(clubProvider(a.clubId!)).value;
    final saved =
        ref.watch(savedIdsProvider(SavedKind.meet)).value?.contains(a.id) ??
        false;
    final heroHeight = 180 + top;
    Crumbs.name(context, a.title);
    final when = a.multiDay
        ? Fmt.dayRange(a.startsAt, a.endsAt)
        : Fmt.dayTimeRange(a.startsAt, a.endsAt);
    final whenSub =
        a.recurrence ??
        a.subtitle ??
        (a.registrationClosesAt == null
            ? null
            : 'Registration closes ${Fmt.day(a.registrationClosesAt!)}');
    final fee = 'S\$${money(a.totalCents)}';
    final levelSub = a.levelMin == null || a.levelMax == null
        ? 'Every level is welcome'
        : '${SkillBand.forLevel(a.levelMin!).label} to ${SkillBand.forLevel(a.levelMax!).label}';
    final count = switch (a.kind) {
      ActivityKind.meet =>
        '${a.spotsTaken}/${a.capacity} playing · ${a.spotsLeft} spots left',
      ActivityKind.tournament =>
        '${a.spotsTaken}/${a.capacity} entries · ${a.spotsLeft} slots left',
      ActivityKind.event => '${a.spotsTaken}/${a.capacity} going',
    };
    final listed = a.kind == ActivityKind.meet
        ? ref
              .watch(meetPlayersProvider(a.id))
              .value
              ?.where((p) => p.waitlistAt == null)
              .map((p) => p.player)
              .toList()
        : null;
    final shown = (listed ?? a.going).take(4).toList();
    final rest = a.spotsTaken - shown.length;

    Widget circle(
      String icon,
      String label,
      VoidCallback onTap, {
      bool fill = false,
    }) => KitIconButton(
      icon: icon,
      label: label,
      size: 20,
      background: const Color(0x5916181B),
      color: Colors.white,
      fill: fill,
      onPressed: onTap,
    );

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        height: heroHeight,
                        child: ColoredBox(
                          color: c.primary,
                          child: CustomPaint(painter: _CourtPainter(top)),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        top: top + 14,
                        child: Row(
                          children: [
                            const KitBackPill(
                              background: Color(0x5916181B),
                              color: Colors.white,
                            ),
                            const Spacer(),
                            if (a.iAmHost) ...[
                              circle(
                                OgIcons.pencil,
                                'Edit $_noun',
                                () => editActivity(context, ref, a),
                              ),
                              const SizedBox(width: 8),
                            ],
                            circle(
                              OgIcons.shareUp,
                              'Share $_noun',
                              () =>
                                  shareLink(context, a.title, Links.meet(a.id)),
                            ),
                            const SizedBox(width: 8),
                            circle(
                              OgIcons.heart,
                              saved ? 'Remove from saved' : 'Save $_noun',
                              _toggleSave,
                              fill: saved,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          heroHeight - 56,
                          16,
                          0,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F16181B),
                                blurRadius: 20,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: kitSpaced([
                                    Row(
                                      children: [
                                        _KindTile(kind: a.kind),
                                        const SizedBox(width: 8),
                                        Text(
                                          a.kind.label,
                                          style: OgText.body(
                                            15,
                                            weight: FontWeight.w700,
                                          ),
                                        ),
                                        if (a.ranked) ...[
                                          const SizedBox(width: 8),
                                          _Caps(
                                            'RANKED',
                                            bg: t.gold,
                                            ink: t.onGold,
                                          ),
                                        ],
                                        const SizedBox(width: 8),
                                        _Caps(
                                          a.sports.first.label.toUpperCase(),
                                          bg: t.tag,
                                          ink: t.onTag,
                                        ),
                                      ],
                                    ),
                                    Semantics(
                                      header: true,
                                      child: Text(
                                        a.title,
                                        style: OgText.heading(24, height: 1.15),
                                      ),
                                    ),
                                    _HostLine(
                                      activity: a,
                                      clubName: club?.name,
                                      clubLogo: club == null
                                          ? null
                                          : (
                                              club.initials,
                                              club.logoColor,
                                              club.logoInk,
                                            ),
                                    ),
                                    if (shown.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          top: 4,
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            for (final p in shown) ...[
                                              SolidAvatar.forId(
                                                p.id,
                                                initials: p.initials,
                                                size: 44,
                                                fontSize: 13,
                                              ),
                                              const SizedBox(width: 8),
                                            ],
                                            if (rest > 0)
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color: t.tag,
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  '+$rest',
                                                  style: OgText.body(
                                                    13,
                                                    weight: FontWeight.w800,
                                                    color: t.onTag,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    Text(
                                      count,
                                      style: OgText.body(
                                        14,
                                        weight: FontWeight.w600,
                                        color: t.onTag,
                                      ),
                                    ),
                                  ], 12),
                                ),
                              ),
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                color: t.divider,
                              ),
                              _InfoRow(
                                icon: OgIcons.calendarBox,
                                main: when,
                                sub: whenSub,
                              ),
                              _InfoRow(
                                icon: OgIcons.mapPin,
                                main: a.online
                                    ? '${a.venue.name} and online'
                                    : a.venue.name,
                                sub: a.court ?? a.venue.address,
                                action: KitLink(
                                  'Directions',
                                  onPressed: _directions,
                                ),
                              ),
                              if (a.kind == ActivityKind.meet)
                                _InfoRow(
                                  icon: OgIcons.group,
                                  main:
                                      '${a.gameType?.label ?? a.format.label} · up to ${a.capacity} players',
                                  sub: 'Extra sign-ups join a waitlist',
                                ),
                              if (a.kind != ActivityKind.event)
                                _InfoRow(
                                  icon: OgIcons.shieldTick,
                                  main: a.bands,
                                  sub: levelSub,
                                ),
                              _InfoRow(
                                icon: OgIcons.ticket,
                                main: a.isFree
                                    ? 'Free'
                                    : '$fee per ${a.kind == ActivityKind.tournament ? 'entry' : 'person'}',
                                sub: a.isFree
                                    ? 'No payment needed'
                                    : 'Includes the S\$${money(a.platformCents)} platform fee · refund if you cancel before it starts',
                                last: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                  sliver: SliverList.list(
                    children: kitSpaced([
                      if (a.ranked && a.kind == ActivityKind.meet)
                        _RankedCard(
                          onScore: a.myStatus == MyStatus.joined
                              ? () => context.push(Routes.scoreEntry(a.id))
                              : null,
                        ),
                      if (a.kind == ActivityKind.meet &&
                          a.myStatus == MyStatus.joined &&
                          a.startsAt.isBefore(DateTime.now()))
                        KitCard(
                          children: [
                            KitNavTile(
                              icon: OgIcons.pointsStar,
                              title: 'Your Meet recap',
                              subtitle: 'Games, rating and a card to share',
                              onTap: () => context.push(Routes.meetRecap(a.id)),
                            ),
                          ],
                        ),
                      if ((a.description ?? '').isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: c.bg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: c.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'About this $_noun',
                                style: OgText.display(17, color: c.text),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                a.description!,
                                style: OgText.body(
                                  15,
                                  height: 1.5,
                                  color: t.onTag,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (a.iAmHost && a.kind == ActivityKind.meet)
                        _HostCard(activity: a),
                      _Players(activity: a),
                      if (a.kind == ActivityKind.meet && !a.iAmHost)
                        KitNote(
                          '${a.host.displayName.split(' ').first} marks attendance. '
                          'If present, you get Passport credit, 4 points and a '
                          'stats card to share.',
                          tone: KitTone.info,
                        ),
                    ], 16),
                  ),
                ),
              ],
            ),
          ),
          _BottomBar(
            activity: a,
            busy: _busy,
            onJoin: _join,
            chatRoute: a.clubId != null
                ? Routes.clubChat(a.clubId!)
                : Routes.messagePlayer(a.host.id),
          ),
        ],
      ),
    );
  }
}

/// The court drawn on the header: a half court with a dashed centre line.
class _CourtPainter extends CustomPainter {
  const _CourtPainter(this.top);

  final double top;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = const Color(0x47FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final y0 = top + 24;
    canvas.drawRect(
      Rect.fromLTRB(60, y0, size.width - 60, size.height + 30),
      line,
    );
    canvas.drawLine(
      Offset(60, y0 + 72),
      Offset(size.width - 60, y0 + 72),
      line,
    );
    final x = size.width / 2;
    for (var y = y0; y < size.height; y += 10) {
      canvas.drawLine(Offset(x, y), Offset(x, y + 5), line);
    }
  }

  @override
  bool shouldRepaint(_CourtPainter old) => old.top != top;
}

class _KindTile extends StatelessWidget {
  const _KindTile({required this.kind});

  final ActivityKind kind;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final (bg, ink, icon) = switch (kind) {
      ActivityKind.meet => (t.successFill, t.onSuccessFill, OgIcons.racquet),
      ActivityKind.tournament => (t.warnFill, t.onWarnFill, OgIcons.trophyTeam),
      ActivityKind.event => (t.dangerFill, t.onDangerFill, OgIcons.heart),
    };
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
      ),
      alignment: Alignment.center,
      child: OgIcon(icon, size: 18, strokeWidth: 1.9, color: ink),
    );
  }
}

/// A small all-caps tag ("RANKED", "BADMINTON").
class _Caps extends StatelessWidget {
  const _Caps(this.text, {required this.bg, required this.ink});

  final String text;
  final Color bg;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: OgText.body(
          11,
          weight: FontWeight.w800,
          color: ink,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// "Tampines Smashers · by Hannah Goh", or the host alone.
class _HostLine extends StatelessWidget {
  const _HostLine({required this.activity, this.clubName, this.clubLogo});

  final Activity activity;
  final String? clubName;
  final (String, int, int)? clubLogo;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final host = activity.host.displayName;
    final logo = clubLogo;
    return Pressable(
      semanticLabel: clubName == null
          ? 'Hosted by $host'
          : '$clubName, by $host',
      onPressed: () => context.push(
        activity.clubId != null && clubName != null
            ? Routes.club(activity.clubId!)
            : Routes.player(activity.host.id),
      ),
      child: Row(
        children: [
          if (logo != null)
            ClubLogo(
              initials: logo.$1,
              color: Color(logo.$2),
              ink: Color(logo.$3),
              size: 24,
              radius: 7,
              fontSize: 10,
            )
          else
            SolidAvatar.forId(
              activity.host.id,
              initials: activity.host.initials,
              size: 24,
              fontSize: 10,
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              clubName == null ? 'Hosted by $host' : '$clubName · by $host',
              style: OgText.body(14, weight: FontWeight.w600, color: t.onTag),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.main,
    this.sub,
    this.action,
    this.last = false,
  });

  final String icon;
  final String main;
  final String? sub;
  final Widget? action;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: t.soft)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: OgIcon(icon, size: 22, strokeWidth: 1.8, color: c.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(main, style: OgText.body(15, weight: FontWeight.w700)),
                if (sub != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    sub!,
                    style: OgText.body(13, height: 1.4, color: c.textMuted),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) Center(child: action),
        ],
      ),
    );
  }
}

class _RankedCard extends StatelessWidget {
  const _RankedCard({required this.onScore});

  /// Null until the viewer is playing.
  final VoidCallback? onScore;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OgColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OgIcon(
                OgIcons.trophyCup,
                size: 22,
                strokeWidth: 1.8,
                color: t.gold,
              ),
              const SizedBox(width: 10),
              Text(
                'Ranked game',
                style: OgText.body(
                  16,
                  weight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Results update your rating and leaderboard spot. Both sides '
            'confirm each score.',
            style: OgText.body(
              14,
              height: 1.45,
              color: const Color(0xFFC9C6BC),
            ),
          ),
          if (onScore != null) ...[
            const SizedBox(height: 10),
            Pressable(
              semanticLabel: 'Enter a score',
              onPressed: onScore,
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: t.gold,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Enter a score',
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: t.onGold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Players extends ConsumerWidget {
  const _Players({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final a = activity;
    final noun = switch (a.kind) {
      ActivityKind.meet => 'Players',
      ActivityKind.tournament => 'Entries',
      ActivityKind.event => 'Going',
    };
    final list = a.kind == ActivityKind.meet
        ? ref.watch(meetPlayersProvider(a.id)).value
        : null;
    final rows = <(PlayerSummary, String, String?)>[
      if (list != null)
        for (final p in list.where((p) => p.waitlistAt == null).take(5))
          (p.player, p.meta, p.rating?.toStringAsFixed(1))
      else
        for (final p in a.going.take(5))
          (p, p.id == a.host.id ? 'Organizer · playing' : 'Member', null),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(noun, style: OgText.display(18, color: c.text)),
              ),
            ),
            Text(
              '${a.spotsTaken} going · waitlist ${a.waitlistCount}',
              style: OgText.body(13, color: c.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 10),
        KitCard(
          children: [
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No one yet. Be the first to join.',
                  style: OgText.body(14, color: c.textMuted),
                ),
              ),
            for (final (p, meta, rating) in rows)
              PlayerRow(player: p, meta: meta, rating: rating),
            if (a.spotsTaken > 0)
              Pressable(
                semanticLabel: 'See all ${a.spotsTaken} ${noun.toLowerCase()}',
                onPressed: () => context.push(
                  a.kind == ActivityKind.meet
                      ? Routes.meetPlayers(a.id)
                      : Routes.activity(a.id),
                ),
                child: SizedBox(
                  height: 48,
                  child: Center(
                    child: Text(
                      'See all ${a.spotsTaken} ${noun.toLowerCase()}',
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A face, a name, a line under it and a rating on the right. Guests have
/// no profile to open.
class PlayerRow extends StatelessWidget {
  const PlayerRow({
    super.key,
    required this.player,
    required this.meta,
    this.rating,
    this.trailing,
  });

  final PlayerSummary player;
  final String meta;
  final String? rating;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final guest = player.id.startsWith('g-') || player.id.endsWith(':guest');
    return Pressable(
      semanticLabel: '${player.displayName}, $meta',
      onPressed: guest ? null : () => context.push(Routes.player(player.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            SolidAvatar.forId(
              player.id,
              initials: player.initials,
              size: 40,
              fontSize: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    player.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (rating != null) Text(rating!, style: OgText.heading(17)),
            ?trailing,
          ],
        ),
      ),
    );
  }
}

/// The organizer's own spot: playing too, or organizing only.
class _HostCard extends ConsumerStatefulWidget {
  const _HostCard({required this.activity});

  final Activity activity;

  @override
  ConsumerState<_HostCard> createState() => _HostCardState();
}

class _HostCardState extends ConsumerState<_HostCard> {
  bool _busy = false;

  Activity get a => widget.activity;

  Future<void> _play() async {
    final fee = a.hostSpotCents;
    if (fee > 0) {
      final method = await showPaySheet(
        context,
        kicker: 'Play too',
        title: a.title,
        subtitle: '${meetWhen(a)} at ${a.venue.name}',
        lines: [
          ('Session', 'No fee for you'),
          ('Platform fee', 'S\$${money(fee)}'),
        ],
        totalCents: fee,
        payee: 'Olympus',
        notes: [
          'Paying the platform fee makes you 1 of the ${a.capacity} players.',
          'Give up your spot before the Meet starts and the '
              'S\$${money(fee)} goes back to your Wallet.',
        ],
      );
      if (method == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(playRepositoryProvider).hostPlays(a.id, playing: true);
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (!mounted) return;
      await showDoneSheet(
        context,
        title: "You're playing",
        body: 'You hold a spot at ${a.title} and you are still the organizer.',
        next: 'See my schedule',
        onNext: () => context.go(Routes.schedule(hosting: true)),
      );
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final fee = a.hostSpotCents;
    final going = a.spotsTaken;
    final playing = a.hostPlaying;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            playing ? 'You are playing too' : 'You are organizing only',
            style: OgText.display(17, color: c.text),
          ),
          const SizedBox(height: 6),
          Text(
            playing
                ? 'You hold 1 of the $going taken spots. '
                      '${fee > 0 ? 'S\$${money(fee)} platform fee paid, no' : 'No'} '
                      'session fee for you.'
                : 'You are not counted as a player, so $going of '
                      '${a.capacity} spots are taken. To play too, take a spot'
                      '${fee > 0 ? ' and pay the S\$${money(fee)} platform fee' : ''}. '
                      'There is no session fee for you.',
            style: OgText.body(14, height: 1.45, color: context.tones.onTag),
          ),
          const SizedBox(height: 12),
          if (playing)
            Align(
              alignment: Alignment.centerLeft,
              child: KitLink(
                'Give up my spot, keep organizing',
                underline: true,
                onPressed: () => showLeaveSheet(context, a),
              ),
            )
          else
            KitButton(
              label: fee > 0 ? 'Play too · S\$${money(fee)}' : 'Play too',
              loading: _busy,
              onPressed: a.isFull ? null : _play,
            ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.activity,
    required this.busy,
    required this.onJoin,
    required this.chatRoute,
  });

  final Activity activity;
  final bool busy;
  final VoidCallback onJoin;
  final String chatRoute;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final a = activity;
    final bottom = MediaQuery.of(context).padding.bottom;
    Widget pill(
      String label, {
      required VoidCallback? onTap,
      Color? bg,
      Color? fg,
      Color? border,
      bool expand = false,
      String? icon,
    }) {
      final child = Pressable(
        semanticLabel: label,
        onPressed: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: bg ?? c.bg,
            borderRadius: BorderRadius.circular(24),
            border: border == null
                ? null
                : Border.all(color: border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                OgIcon(icon, size: 20, strokeWidth: 2, color: fg ?? c.text),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: OgText.body(
                  15,
                  weight: FontWeight.w700,
                  color: fg ?? c.text,
                ),
              ),
            ],
          ),
        ),
      );
      return expand ? Expanded(child: child) : child;
    }

    final noun = a.kind == ActivityKind.meet
        ? 'Meet'
        : a.kind.label.toLowerCase();
    final children = <Widget>[
      if (a.iAmHost) ...[
        pill(
          'Cancel $noun',
          onTap: () => context.push(switch (a.kind) {
            ActivityKind.meet => Routes.meetCancel(a.id),
            ActivityKind.tournament => Routes.tournamentCancel(a.id),
            ActivityKind.event => Routes.eventCancel(a.id),
          }),
          fg: t.onDangerFill,
          border: c.borderControl,
        ),
        const SizedBox(width: 12),
        pill(
          'Mark attendance',
          onTap: () => context.push(Routes.meetAttendance(a.id)),
          bg: OgColors.ink,
          fg: Colors.white,
          icon: OgIcons.clipboardList,
          expand: true,
        ),
      ] else
        ...switch (a.myStatus) {
          MyStatus.joined => [
            Expanded(
              child: Row(
                children: [
                  OgIcon(
                    OgIcons.tick,
                    size: 22,
                    strokeWidth: 2.4,
                    color: t.successInk,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "You're going",
                      style: OgText.body(
                        16,
                        weight: FontWeight.w700,
                        color: t.successInk,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pill('Chat', onTap: () => context.push(chatRoute), border: c.text),
            const SizedBox(width: 8),
            pill(
              "Can't go",
              onTap: () => showLeaveSheet(context, a),
              fg: t.onDangerFill,
              border: c.borderControl,
            ),
          ],
          MyStatus.requested => [
            Expanded(
              child: Text(
                'Waiting for the host to accept you',
                style: OgText.body(
                  15,
                  weight: FontWeight.w600,
                  color: c.textMuted,
                ),
              ),
            ),
          ],
          MyStatus.waitlist => [
            Expanded(
              child: Text(
                "You're #${a.myWaitlistPosition} on the waitlist",
                style: OgText.body(16, weight: FontWeight.w700),
              ),
            ),
            pill(
              'Leave',
              onTap: () => showLeaveSheet(context, a),
              border: c.borderControl,
            ),
          ],
          MyStatus.none => [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.isFree ? 'Free' : 'S\$${money(a.totalCents)}',
                    style: OgText.heading(20),
                  ),
                  Text(
                    a.isFree
                        ? (a.kind == ActivityKind.event
                              ? 'Free entry'
                              : 'No fee')
                        : 'per ${a.kind == ActivityKind.tournament ? 'entry' : 'person'} · incl. S\$${money(a.platformCents)} fee',
                    style: OgText.body(12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            if (a.kind == ActivityKind.meet && a.allowGuests && !a.isFull) ...[
              pill(
                'Guest',
                icon: OgIcons.plus,
                onTap: () => context.push(Routes.guest(a.id)),
                border: c.borderControl,
              ),
              const SizedBox(width: 8),
            ],
            KitButton(
              label: a.isFull
                  ? 'Join waitlist'
                  : switch (a.kind) {
                      ActivityKind.meet => 'Join',
                      ActivityKind.tournament => 'Register',
                      ActivityKind.event => 'Get ticket',
                    },
              height: 52,
              radius: 26,
              padding: 28,
              expand: false,
              loading: busy,
              style: a.isFull ? KitButtonStyle.dark : KitButtonStyle.primary,
              onPressed: onJoin,
            ),
          ],
        },
    ];
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + (bottom > 0 ? bottom : 12)),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(children: children),
    );
  }
}

/// "Tonight, 8:00 to 10:00 PM", "Fri 2 Oct, 8:00 to 10:00 PM".
String meetWhen(Activity a) {
  final now = DateTime.now();
  final today =
      a.startsAt.year == now.year &&
      a.startsAt.month == now.month &&
      a.startsAt.day == now.day;
  final range = Fmt.timeRange(a.startsAt, a.endsAt).replaceAll(' – ', ' to ');
  return '${today ? (a.startsAt.hour >= 17 ? 'Tonight' : 'Today') : Fmt.day(a.startsAt)}, $range';
}

/// Review and pay, confirm with Face ID, then the receipt.
Future<void> startPayment(
  BuildContext context,
  WidgetRef ref,
  Activity a, {
  String? guestName,
  double? guestLevel,
}) async {
  // A guest of someone already going takes 1 more spot; otherwise the
  // player pays for their own spot too.
  final spots =
      (a.myStatus == MyStatus.joined ? 0 : 1) + (guestName == null ? 0 : 1);
  final fee = a.platformCents;
  final total = (a.feeCents + fee) * spots;
  final host = a.host.displayName.split(' ').first;
  final method = await showPaySheet(
    context,
    kicker: switch (a.kind) {
      ActivityKind.meet => guestName == null ? 'Join Meet' : 'You and a guest',
      ActivityKind.tournament => 'Register',
      ActivityKind.event => 'Ticket',
    },
    title: a.title,
    subtitle: '${meetWhen(a)} at ${a.venue.name}',
    lines: [
      (
        spots == 1
            ? (guestName == null ? 'Session' : 'Guest session')
            : 'Session, 2 spots',
        'S\$${money(a.feeCents * spots)}',
      ),
      ('Platform fee', 'S\$${money(fee * spots)}'),
    ],
    totalCents: total,
    payee: a.host.displayName,
    notes: [
      'Cancel before it starts: all S\$${money(total)} back to your Wallet, '
          'or S\$${money(a.feeCents * spots)} back to your card. The platform '
          'fee is not returned to a card.',
      "No refund once it starts or if you don't come. If $host cancels, you "
          'get all S\$${money(total)} back.',
      if (a.kind == ActivityKind.meet)
        'Olympus holds your payment until $host marks attendance. You earn '
            '4 points if you are Present.',
    ],
  );
  if (method == null || !context.mounted) return;

  try {
    final email = (await ref.read(privateInfoProvider.future)).email;
    final receipt = await ref
        .read(paymentGatewayProvider)
        .pay(
          activity: a,
          method: method,
          guestName: guestName,
          guestLevel: guestLevel,
          email: email,
        );
    HapticFeedback.mediumImpact();
    refreshPlay(ref.invalidate);
    if (!context.mounted) return;
    await showDoneSheet(
      context,
      title: guestName == null ? "You're in" : '$guestName is coming',
      body: guestName == null
          ? 'Spot ${a.spotsTaken + 1} of ${a.capacity} at ${a.title}, '
                '${meetWhen(a).toLowerCase().startsWith('tonight') ? 'tonight' : Fmt.day(a.startsAt)} at ${Fmt.time(a.startsAt)}.'
          : 'Spot ${a.spotsTaken + spots} of ${a.capacity}. $host sees them as '
                'your guest on the attendance list.',
      rows: [
        ('Paid', 'S\$${money(receipt.totalCents)}'),
        ('Paid with', receipt.paidWith),
        ('Date', Fmt.day(DateTime.now())),
        ('Receipt', receipt.receiptNo),
      ],
      next: 'See my schedule',
      onNext: () => context.go(Routes.schedule()),
    );
  } on AuthFailure catch (e) {
    if (context.mounted) showOgToast(context, e.message, error: true);
  }
}

/// The tick, a heading, what happened and the receipt lines, with a way on.
Future<void> showDoneSheet(
  BuildContext context, {
  required String title,
  required String body,
  List<(String, String)> rows = const [],
  String? next,
  VoidCallback? onNext,
}) => showKitSheet<void>(
  context,
  builder: (sheet) => _DoneSheet(
    title: title,
    body: body,
    rows: rows,
    next: next,
    onNext: onNext == null
        ? null
        : () {
            Navigator.of(sheet).pop();
            onNext();
          },
  ),
);

class _DoneSheet extends StatelessWidget {
  const _DoneSheet({
    required this.title,
    required this.body,
    required this.rows,
    this.next,
    this.onNext,
  });

  final String title;
  final String body;
  final List<(String, String)> rows;
  final String? next;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: t.successFill,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                OgIcons.check,
                size: 28,
                strokeWidth: 3,
                color: t.onSuccessFill,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(title, style: OgText.heading(26)),
          ),
          const SizedBox(height: 6),
          Text(body, style: OgText.body(15, height: 1.45, color: c.textMuted)),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final (k, v) in rows) KitKeyValue(k, v),
          ],
          const SizedBox(height: 20),
          if (next != null) ...[
            KitButton(label: next!, onPressed: onNext),
            const SizedBox(height: 10),
          ],
          KitButton(
            label: 'Done',
            style: next == null
                ? KitButtonStyle.primary
                : KitButtonStyle.outline,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

/// Give up a spot: where the refund goes, then "Spot released". The
/// organizer gives up their playing spot and keeps organizing.
Future<void> showLeaveSheet(BuildContext context, Activity a) =>
    showKitSheet<void>(context, builder: (_) => _LeaveSheet(activity: a));

class _LeaveSheet extends ConsumerStatefulWidget {
  const _LeaveSheet({required this.activity});

  final Activity activity;

  @override
  ConsumerState<_LeaveSheet> createState() => _LeaveSheetState();
}

class _LeaveSheetState extends ConsumerState<_LeaveSheet> {
  bool _toWallet = true;
  bool _busy = false;
  int? _refunded;

  Activity get a => widget.activity;
  bool get _org => a.iAmHost;

  /// The organizer's spot cost the platform fee only.
  int get _paid => _org ? a.hostSpotCents : a.totalCents;
  bool get _refundable => _paid > 0 && a.startsAt.isAfter(DateTime.now());
  int get _amount =>
      !_refundable ? 0 : (_org || _toWallet ? _paid : a.feeCents);

  Future<void> _leave() async {
    setState(() => _busy = true);
    try {
      final repo = ref.read(playRepositoryProvider);
      final refund = _org
          ? await repo.hostPlays(a.id, playing: false).then((_) => _amount)
          : await repo.leave(a.id, toWallet: _toWallet);
      HapticFeedback.mediumImpact();
      refreshPlay(ref.invalidate);
      if (mounted) setState(() => _refunded = refund);
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
    final host = a.host.displayName.split(' ').first;
    final refundTo = !_org && !_toWallet ? 'your card' : 'your Wallet';
    if (_refunded case final refunded?) {
      return _DoneSheet(
        title: 'Spot released',
        body: [
          if (refunded > 0)
            'S\$${money(refunded)} is on its way back to $refundTo.',
          _org
              ? 'You are organizing only now. You can take a spot again while one is open.'
              : 'You can join again while spots are open.',
        ].join(' '),
        rows: const [],
      );
    }
    final head = !_refundable
        ? (a.isFree ? 'Nothing to refund' : 'No refund')
        : _org
        ? 'Back to your Wallet'
        : _toWallet
        ? 'All of it back to your Wallet'
        : 'Back to your card';
    final sub = !_refundable
        ? (a.isFree
              ? 'It was free to join.'
              : 'It has started, so the payment stays with the organizer.')
        : _org
        ? 'Platform fees go back to your Wallet, instantly.'
        : _toWallet
        ? 'Platform fee included. Spend it on Olympus or withdraw it to your bank.'
        : 'The S\$${money(a.platformCents)} platform fee is not '
              'returned to a card. It arrives in 3 to 5 working days.';
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'YOUR SPOT',
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            header: true,
            child: Text('Give up your spot?', style: OgText.heading(26)),
          ),
          const SizedBox(height: 4),
          Text(
            '${a.title}, ${meetWhen(a).split(',').first.toLowerCase().startsWith('tonight') ? 'tonight' : Fmt.day(a.startsAt)} at ${Fmt.time(a.startsAt)}',
            style: OgText.body(15, color: c.textMuted),
          ),
          if (_refundable && !_org) ...[
            const SizedBox(height: 12),
            KitChoiceRow(
              title: 'Wallet',
              subtitle: 'S\$${money(_paid)} · instant',
              selected: _toWallet,
              onTap: () => setState(() => _toWallet = true),
            ),
            KitChoiceRow(
              title: 'Card',
              subtitle: 'S\$${money(a.feeCents)} · 3 to 5 days',
              selected: !_toWallet,
              onTap: () => setState(() => _toWallet = false),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: t.tag,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        head,
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                    ),
                    Text('S\$${money(_amount)}', style: OgText.heading(20)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(sub, style: OgText.body(13, height: 1.4, color: t.onTag)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _org
                ? 'Your spot opens for the next player. You are still the organizer.'
                : 'Your spot goes to the next player on the waitlist. $host is '
                      "told you can't come.",
            style: OgText.body(14, height: 1.45, color: c.textMuted),
          ),
          const SizedBox(height: 20),
          KitButton(
            label: 'Keep my spot',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(height: 10),
          KitButton(
            label: 'Give up my spot',
            style: KitButtonStyle.dangerOutline,
            loading: _busy,
            onPressed: _leave,
          ),
        ],
      ),
    );
  }
}
