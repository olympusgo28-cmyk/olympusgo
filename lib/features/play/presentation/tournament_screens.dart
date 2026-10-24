import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/format.dart';
import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../social/application/social_providers.dart';
import '../../social/domain/social_models.dart';
import '../application/competition_providers.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import '../domain/tournament_models.dart';

/// "Sat 24 – Sun 25 Oct".
String tournamentDates(Activity a) => a.multiDay
    ? Fmt.dayRange(a.startsAt, a.endsAt)
    : Fmt.dayTimeRange(a.startsAt, a.endsAt);

/// A cover: the banner colour with its title, the back pill and actions.
class CompetitionBanner extends StatelessWidget {
  const CompetitionBanner({
    super.key,
    required this.activity,
    required this.height,
    this.actions = const [],
    this.live = false,
  });

  final Activity activity;
  final double height;
  final List<Widget> actions;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final a = activity;
    final top = MediaQuery.of(context).padding.top;
    final ink = Color(a.coverInk);
    return AnnotatedRegion(
      // Light status bar text on dark covers.
      value: Color(a.coverColor).computeLuminance() < 0.4
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: SizedBox(
        height: height,
        child: CourtHero(
          color: Color(a.coverColor),
          height: height,
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, top + 14, 16, 70),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const KitBackPill(
                      background: Color(0x59FFFFFF),
                      color: Colors.white,
                    ),
                    const Spacer(),
                    for (final (i, w) in actions.indexed) ...[
                      if (i > 0) const SizedBox(width: 8),
                      w,
                    ],
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    if (live) ...[
                      KitTag(
                        'LIVE',
                        background: const Color(0xFFD2342C),
                        foreground: Colors.white,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        a.coverTitle ?? a.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: OgText.heading(34, color: ink, height: 1.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A glassy circle for the banner.
Widget bannerButton(
  String icon,
  String label,
  VoidCallback onTap, {
  bool fill = false,
}) => KitIconButton(
  icon: icon,
  label: label,
  size: 20,
  background: const Color(0x38FFFFFF),
  color: Colors.white,
  fill: fill,
  onPressed: onTap,
);

/// Dark status bar text for the page; the banner sets its own while it
/// is under the status bar.
Widget coverStatusBar(Activity a, Widget child) =>
    AnnotatedRegion(value: SystemUiOverlayStyle.dark, child: child);

/// The tournament page: Info, Draw and My matches.
class TournamentPageScreen extends ConsumerStatefulWidget {
  const TournamentPageScreen({
    super.key,
    required this.activityId,
    this.tab = 0,
  });

  final String activityId;
  final int tab;

  @override
  ConsumerState<TournamentPageScreen> createState() =>
      _TournamentPageScreenState();
}

class _TournamentPageScreenState extends ConsumerState<TournamentPageScreen> {
  late int _tab = widget.tab;

  Future<void> _toggleSave(Activity a) async {
    HapticFeedback.selectionClick();
    try {
      final saved = await ref
          .read(savedIdsProvider(SavedKind.meet).notifier)
          .toggle(a.id);
      if (mounted) showOgToast(context, saved ? 'Saved' : 'Removed from saved');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = ref.watch(tournamentInfoProvider(widget.activityId));
    return switch (info) {
      AsyncData(:final value) => _page(value),
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

  Widget _page(TournamentInfo t) {
    final c = context.og;
    final t2 = context.tones;
    final a = t.activity;
    final top = MediaQuery.of(context).padding.top;
    final heroHeight = 210 + top;
    Crumbs.name(context, a.title);
    final saved =
        ref.watch(savedIdsProvider(SavedKind.meet)).value?.contains(a.id) ??
        false;
    final tabs = ['Info', 'Draw', if (t.mine != null) 'My matches'];
    final tab = _tab.clamp(0, tabs.length - 1);
    return coverStatusBar(
      a,
      Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  CupertinoSliverRefreshControl(
                    onRefresh: () async {
                      refreshCompetition(ref.invalidate);
                      await ref.read(tournamentInfoProvider(a.id).future);
                    },
                  ),
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        CompetitionBanner(
                          activity: a,
                          height: heroHeight,
                          actions: [
                            bannerButton(
                              OgIcons.shareUp,
                              'Share tournament',
                              () => shareLink(
                                context,
                                a.title,
                                Links.tournament(a.id),
                              ),
                            ),
                            bannerButton(
                              OgIcons.heart,
                              saved ? 'Remove from saved' : 'Save tournament',
                              () => _toggleSave(a),
                              fill: saved,
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            heroHeight - 50,
                            16,
                            0,
                          ),
                          child: _IdentityCard(info: t),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: KitUnderlineTabs(
                        labels: tabs,
                        selected: tab,
                        spread: true,
                        onSelect: (i) => setState(() => _tab = i),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    sliver: SliverList.list(
                      children: kitSpaced(switch (tab) {
                        0 => _infoTab(t),
                        1 => [_DrawTab(info: t)],
                        _ => [_MatchesTab(info: t)],
                      }, 16),
                    ),
                  ),
                ],
              ),
            ),
            _bottomBar(t, c, t2),
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(TournamentInfo t, OgColors c, OgTones tones) {
    final a = t.activity;
    final bottom = MediaQuery.of(context).padding.bottom;
    final children = a.iAmHost
        ? [
            Expanded(
              child: KitButton(
                label: 'Manage tournament',
                style: KitButtonStyle.dark,
                icon: OgIcons.clipboardList,
                onPressed: () => context.push(Routes.tournamentManage(a.id)),
              ),
            ),
          ]
        : t.mine != null
        ? [
            OgIcon(
              OgIcons.tick,
              size: 22,
              strokeWidth: 2.4,
              color: tones.successInk,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "You're in",
                style: OgText.body(
                  16,
                  weight: FontWeight.w700,
                  color: tones.successInk,
                ),
              ),
            ),
            KitButton(
              label: 'My matches',
              expand: false,
              style: KitButtonStyle.outline,
              onPressed: () => setState(() => _tab = 2),
            ),
          ]
        : [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    t.fromCents == 0
                        ? 'Free'
                        : 'From S\$${money(t.fromCents, decimals: t.fromCents % 100 != 0)}',
                    style: OgText.heading(20),
                  ),
                  Text(
                    t.fromCents == 0
                        ? 'No entry fee'
                        : 'per entry · plus platform fee',
                    style: OgText.body(12, color: c.textMuted),
                  ),
                ],
              ),
            ),
            KitButton(
              label: 'Register',
              expand: false,
              padding: 32,
              radius: 26,
              onPressed: () => context.push(Routes.tournamentRegister(a.id)),
            ),
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

  List<Widget> _infoTab(TournamentInfo t) {
    final c = context.og;
    final tones = context.tones;
    final a = t.activity;
    final mine = t.mine;
    final closes = a.registrationClosesAt;
    return [
      if (t.invite case final inv?) _InviteCard(activityId: a.id, invite: inv),
      if (mine == null && !a.iAmHost && t.invite == null)
        KitCard(
          padding: const EdgeInsets.all(16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    KitTag(
                      'Registration open',
                      background: tones.successFill,
                      foreground: tones.onSuccessFill,
                    ),
                    const SizedBox(width: 8),
                    if (closes != null)
                      Text(
                        'Closes ${Fmt.day(closes)}',
                        style: OgText.body(13, color: c.textMuted),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  t.fromCents == 0
                      ? 'Free to enter'
                      : 'From S\$${money(t.fromCents, decimals: t.fromCents % 100 != 0)} per entry',
                  style: OgText.heading(22),
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.fromCents == 0 ? '' : 'Plus a platform fee of 10% (minimum S\$2) per entry. '}'
                  'Enter up to ${t.maxEvents} events. Doubles need a partner '
                  'who accepts before the close date.',
                  style: OgText.body(14, height: 1.45, color: c.textMuted),
                ),
                const SizedBox(height: 12),
                KitButton(
                  label: 'Register',
                  onPressed: () =>
                      context.push(Routes.tournamentRegister(a.id)),
                ),
              ],
            ),
          ],
        ),
      if (mine != null)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: tones.successFill,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  "You're in",
                  ?mine.group,
                  if (mine.seed != null) 'Seed ${mine.seed}',
                ].join(' · '),
                style: OgText.body(
                  13,
                  weight: FontWeight.w800,
                  color: tones.onSuccessFill,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mine.partner == null
                    ? mine.divisionName
                    : '${mine.divisionName} with ${mine.partner!.displayName}',
                style: OgText.heading(20, color: tones.onSuccessFill),
              ),
              if (mine.firstMatchAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  'First match ${Fmt.dayTimeComma(mine.firstMatchAt!)}'
                  '${mine.firstCourt == null ? '' : ' · ${mine.firstCourt}'}. '
                  'Check in by ${Fmt.time(mine.firstMatchAt!.subtract(const Duration(minutes: 30)))}.',
                  style: OgText.body(
                    14,
                    height: 1.4,
                    color: tones.onSuccessFill,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 6),
                Text(
                  'You get the draw and your first match time once '
                  'registration closes.',
                  style: OgText.body(
                    14,
                    height: 1.4,
                    color: tones.onSuccessFill,
                  ),
                ),
              ],
              if (mine.group != null) ...[
                const SizedBox(height: 8),
                KitLink(
                  'See my group',
                  underline: true,
                  color: tones.onSuccessFill,
                  onPressed: () => setState(() => _tab = 1),
                ),
              ],
            ],
          ),
        ),
      Text('Events', style: OgText.heading(20)),
      KitCard(
        children: [for (final d in t.divisions) _DivisionRow(division: d)],
      ),
      Text('Format and rules', style: OgText.heading(20)),
      Column(
        children: [
          KitKeyValue('Draw', t.drawFormat),
          KitKeyValue('Seeding', t.seeding),
          KitKeyValue('Divisions', t.divisionsText),
          KitKeyValue('Entry', Env.hasSupabase ? 'Everyone' : t.entryRule),
        ],
      ),
      KitCheckList([
        'Check in at the desk or by QR 30 minutes before your first match.',
        Env.hasSupabase
            ? 'The umpire enters each score, and it counts for ratings.'
            : 'Scores are confirmed by the umpire or both sides, then update ratings.',
        Env.hasSupabase
            ? 'Finishes earn points on the Tournament leaderboard.'
            : 'Counts for the Tournament leaderboard once 16+ entries are confirmed.',
      ]),
      KitCard(
        children: [
          KitNavTile(
            icon: OgIcons.flagClub,
            tile: OgColors.ink,
            ink: const Color(0xFFF2C14E),
            title: t.host,
            subtitle: Env.hasSupabase ? 'Organizer' : 'Organizer · Verified',
            trailing: Text(
              'Contact',
              style: OgText.body(14, weight: FontWeight.w700, color: c.link),
            ),
            onTap: () => context.push(
              a.clubId != null
                  ? Routes.clubChat(a.clubId!)
                  : Routes.messagePlayer(a.host.id),
            ),
          ),
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: KitLink(
          'Report this tournament',
          color: c.textMuted,
          onPressed: () => context.push(Routes.reportActivity(a.id)),
        ),
      ),
    ];
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.info});

  final TournamentInfo info;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final a = info.activity;
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: kitSpaced([
          Row(
            children: [
              KitTag(
                a.sports.first.label,
                background: t.tag,
                foreground: t.onTag,
              ),
              if (a.tier != null) ...[
                const SizedBox(width: 8),
                KitTag(a.tier!, background: t.gold, foreground: t.onGold),
              ],
              if (a.ranked) ...[
                const SizedBox(width: 8),
                KitTag('Ranked', background: t.gold, foreground: t.onGold),
              ],
            ],
          ),
          Semantics(
            header: true,
            child: Text(a.title, style: OgText.heading(24, height: 1.15)),
          ),
          Text(
            'Hosted by ${info.host}',
            style: OgText.body(14, weight: FontWeight.w600, color: t.onTag),
          ),
          _Line(icon: OgIcons.calendarBox, text: tournamentDates(a)),
          _Line(
            icon: OgIcons.mapPin,
            text: info.courts > 0
                ? '${a.venue.name} · ${info.courts} courts'
                : a.venue.name,
          ),
          if (info.spectatorEventId != null)
            Pressable(
              semanticLabel: 'Spectator page, ${info.spectatorTitle}',
              onPressed: () =>
                  context.push(Routes.activity(info.spectatorEventId!)),
              child: _Line(
                icon: OgIcons.ticket,
                text: 'Spectator page · ${info.spectatorTitle}',
                link: true,
              ),
            ),
        ], 8),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.link = false});

  final String icon;
  final String text;
  final bool link;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Row(
      children: [
        OgIcon(icon, size: 18, color: link ? c.link : c.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: OgText.body(
              14,
              weight: link ? FontWeight.w700 : FontWeight.w500,
              color: link ? c.link : c.text,
            ),
          ),
        ),
        if (link) OgIcon(OgIcons.chevronRight, size: 16, color: c.link),
      ],
    );
  }
}

/// "Priya asked you to partner them", with yes and no.
class _InviteCard extends ConsumerStatefulWidget {
  const _InviteCard({required this.activityId, required this.invite});

  final String activityId;
  final PartnerInvite invite;

  @override
  ConsumerState<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends ConsumerState<_InviteCard> {
  bool? _busy;

  Future<void> _answer(bool accept) async {
    setState(() => _busy = accept);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .answerInvite(
            widget.activityId,
            widget.invite.entryId,
            accept: accept,
          );
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (mounted) {
        showOgToast(
          context,
          accept ? "You're partners. See you on court" : 'Invite turned down',
        );
      }
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final inv = widget.invite;
    return KitCard(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            SolidAvatar.forId(
              inv.from.id,
              initials: inv.from.initials,
              size: 44,
              fontSize: 15,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${inv.from.displayName} asked you to partner them',
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  Text(
                    inv.divisionName,
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: KitButton(
                label: 'Not this time',
                style: KitButtonStyle.outline,
                loading: _busy == false,
                onPressed: _busy == null ? () => _answer(false) : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: KitButton(
                label: 'Partner up',
                loading: _busy == true,
                onPressed: _busy == null ? () => _answer(true) : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DivisionRow extends StatelessWidget {
  const _DivisionRow({required this.division});

  final Division division;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final d = division;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  d.name,
                  style: OgText.body(15, weight: FontWeight.w700),
                ),
              ),
              KitTag(
                d.full ? 'Full · waitlist' : '${d.left} spots left',
                background: d.full ? t.dangerFill : t.successFill,
                foreground: d.full ? t.onDangerFill : t.onSuccessFill,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${d.entries} of ${d.capacity} entries · ${d.priceLine}',
            style: OgText.body(13, color: c.textMuted),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: d.capacity == 0 ? 0 : d.entries / d.capacity,
              minHeight: 6,
              backgroundColor: t.tag,
              color: d.full ? const Color(0xFFD2342C) : c.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Divisions as chips, then groups or the knockout.
class _DrawTab extends ConsumerStatefulWidget {
  const _DrawTab({required this.info});

  final TournamentInfo info;

  @override
  ConsumerState<_DrawTab> createState() => _DrawTabState();
}

class _DrawTabState extends ConsumerState<_DrawTab> {
  late String _division =
      widget.info.mine?.divisionId ?? widget.info.divisions.first.id;
  bool _knockout = false;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final info = widget.info;
    final id = info.activity.id;
    final groups = ref.watch(drawGroupsProvider(id, _division)).value;
    final rounds = ref.watch(drawKnockoutProvider(id, _division)).value;
    final next = ref
        .watch(myTournamentMatchesProvider(id))
        .value
        ?.where(
          (m) => m.state == MatchState.called || m.state == MatchState.next,
        )
        .firstOrNull;
    final empty = (groups?.isEmpty ?? true) && (rounds?.isEmpty ?? true);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        if (info.divisions.length > 1)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final d in info.divisions) ...[
                  KitChip(
                    label: d.name,
                    selected: d.id == _division,
                    onTap: () => setState(() => _division = d.id),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        if (empty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('The draw is not out yet', style: OgText.heading(20)),
                  const SizedBox(height: 6),
                  Text(
                    'It is made the day after registration closes. Every '
                    'entrant is told their group and first match.',
                    style: OgText.body(14, height: 1.45, color: c.textMuted),
                  ),
                ],
              ),
            ),
          )
        else ...[
          KitSegments(
            labels: const ['Groups', 'Knockout'],
            selected: _knockout ? 1 : 0,
            onSelect: (i) => setState(() => _knockout = i == 1),
          ),
          if (next != null && info.mine?.divisionId == _division)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: OgColors.ink,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: t.gold,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'COURT',
                          style: OgText.body(
                            9,
                            weight: FontWeight.w800,
                            color: t.onGold,
                          ),
                        ),
                        Text(
                          next.court.replaceAll('Court ', ''),
                          style: OgText.heading(20, color: t.onGold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your next match · ${Fmt.dayTimeComma(next.at)}',
                          style: OgText.body(
                            12,
                            color: const Color(0xFFC9C6BC),
                          ),
                        ),
                        Text(
                          'You${info.mine?.partner == null ? '' : ' / ${info.mine!.partner!.displayName}'} vs ${next.opponent.replaceAll(' and ', ' / ')}',
                          style: OgText.body(
                            15,
                            weight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (!_knockout)
            for (final g in groups ?? const <DrawGroup>[])
              _GroupTable(
                group: g,
                doubles:
                    info.divisions
                        .where((d) => d.id == _division)
                        .firstOrNull
                        ?.doubles ??
                    true,
              )
          else if (rounds != null) ...[
            Text(
              'Swipe to see the final',
              style: OgText.body(13, color: c.textMuted),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final r in rounds) ...[
                    SizedBox(
                      width: 200,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            r.name,
                            style: OgText.body(13, weight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          for (final m in r.matches) ...[
                            _KoCard(match: m),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ],
          Text(
            Env.hasSupabase
                ? 'Scores show as soon as the umpire enters them. Pull down to refresh.'
                : 'Scores update live once the umpire or both sides confirm.',
            style: OgText.body(13, height: 1.4, color: c.textMuted),
          ),
        ],
      ], 14),
    );
  }
}

class _GroupTable extends StatelessWidget {
  const _GroupTable({required this.group, this.doubles = true});

  final DrawGroup group;
  final bool doubles;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    TextStyle head() =>
        OgText.body(12, weight: FontWeight.w700, color: c.textMuted);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    group.name,
                    style: OgText.body(15, weight: FontWeight.w800),
                  ),
                ),
                Text(
                  'Top 2 go through',
                  style: OgText.body(12, color: c.textMuted),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                SizedBox(width: 22, child: Text('#', style: head())),
                Expanded(
                  child: Text(doubles ? 'Pair' : 'Player', style: head()),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    'W–L',
                    textAlign: TextAlign.center,
                    style: head(),
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Text('Pts', textAlign: TextAlign.end, style: head()),
                ),
              ],
            ),
          ),
          for (final r in group.rows)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: r.mine ? t.successFill : c.bg,
                border: Border(
                  top: BorderSide(color: c.border),
                  left: BorderSide(
                    color: r.pos <= 2 ? c.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${r.pos}',
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                r.names,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OgText.body(14, weight: FontWeight.w700),
                              ),
                            ),
                            if (r.mine) ...[
                              const SizedBox(width: 6),
                              KitTag(
                                'YOU',
                                height: 20,
                                fontSize: 10,
                                background: t.onSuccessFill,
                                foreground: Colors.white,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Seed ${r.seed} · avg ${r.rating.toStringAsFixed(1)}',
                          style: OgText.body(12, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    child: Text(
                      '${r.wins}–${r.losses}',
                      textAlign: TextAlign.center,
                      style: OgText.body(14),
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text(
                      '${r.points}',
                      textAlign: TextAlign.end,
                      style: OgText.body(14, weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _KoCard extends StatelessWidget {
  const _KoCard({required this.match});

  final KnockoutMatch match;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final m = match;
    Widget side(String name, int? score, bool win, bool line) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: line ? Border(bottom: BorderSide(color: c.border)) : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(
                13,
                weight: win ? FontWeight.w700 : FontWeight.w500,
                color: win ? c.text : c.textMuted,
              ),
            ),
          ),
          Text(
            score == null ? '' : '$score',
            style: OgText.body(13, weight: FontWeight.w700),
          ),
        ],
      ),
    );
    final aw = m.scoreA != null && m.scoreB != null && m.scoreA! > m.scoreB!;
    final bw = m.scoreA != null && m.scoreB != null && m.scoreB! > m.scoreA!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: [
              side(m.a, m.scoreA, aw, true),
              side(m.b, m.scoreB, bw, false),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(m.when, style: OgText.body(11, color: c.textMuted)),
      ],
    );
  }
}

/// The viewer's matches, the next one first.
class _MatchesTab extends ConsumerWidget {
  const _MatchesTab({required this.info});

  final TournamentInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final a = info.activity;
    final mine = info.mine!;
    final matches = ref.watch(myTournamentMatchesProvider(a.id)).value;
    if (matches == null) return const CupertinoActivityIndicator();
    final next = matches
        .where(
          (m) => m.state == MatchState.called || m.state == MatchState.next,
        )
        .firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              [mine.divisionName, ?mine.group].join(' · '),
              style: OgText.body(
                13,
                weight: FontWeight.w700,
                color: c.textMuted,
              ),
            ),
            Text(
              mine.partner == null
                  ? 'You'
                  : 'You and ${mine.partner!.displayName}',
              style: OgText.heading(22),
            ),
          ],
        ),
        if (matches.isEmpty)
          const KitNote(
            'Your matches show here once the draw is made, the day after '
            'registration closes.',
          ),
        if (next != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OgColors.ink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  next.state == MatchState.called
                      ? 'NEXT MATCH · CALLED TO COURT'
                      : 'NEXT MATCH',
                  style: OgText.body(
                    12,
                    weight: FontWeight.w800,
                    color: t.gold,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${next.court}, ${Fmt.time(next.at)}',
                  style: OgText.heading(26, color: Colors.white),
                ),
                Text(
                  'vs ${next.opponent} · best of 3 games to 21',
                  style: OgText.body(14, color: const Color(0xFFC9C6BC)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: KitButton(
                        label: 'I’m at the court',
                        style: KitButtonStyle.gold,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          showOgToast(context, 'The umpire knows you are here');
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    KitButton(
                      label: 'Open draw',
                      expand: false,
                      style: KitButtonStyle.outline,
                      onPressed: () =>
                          context.push(Routes.tournamentTab(a.id, 'draw')),
                    ),
                  ],
                ),
              ],
            ),
          ),
        if (matches.isNotEmpty)
          KitCard(children: [for (final m in matches) MatchRow(match: m)]),
        if (matches.isNotEmpty)
          Text(
            'The umpire enters each score and it is final. Your rating updates '
            'after every match. Top 2 in the group go to the semi-finals.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        if (matches.isNotEmpty)
          KitButton(
            label: 'See results',
            style: KitButtonStyle.outline,
            onPressed: () => context.push(Routes.tournamentResults(a.id)),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Withdraw from the tournament',
            color: t.onDangerFill,
            onPressed: () => context.push(Routes.tournamentWithdraw(a.id)),
          ),
        ),
      ], 14),
    );
  }
}

/// One match: who, when and where, and how it went.
class MatchRow extends StatelessWidget {
  const MatchRow({super.key, required this.match, this.showDay = false});

  final MyMatch match;
  final bool showDay;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final m = match;
    final (label, bg, fg) = switch (m.state) {
      MatchState.done when m.won == true => (
        'Won',
        t.successFill,
        t.onSuccessFill,
      ),
      MatchState.done => ('Lost', t.dangerFill, t.onDangerFill),
      MatchState.called || MatchState.next => ('Next', c.primary, c.onPrimary),
      MatchState.later => ('Later', t.tag, t.onTag),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${m.opponent}',
                  style: OgText.body(15, weight: FontWeight.w700),
                ),
                Text(
                  showDay
                      ? '${const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][m.at.weekday - 1]}, ${m.stage} · ${m.court}'
                      : '${Fmt.time(m.at)} · ${m.court}',
                  style: OgText.body(13, color: c.textMuted),
                ),
              ],
            ),
          ),
          if (m.score != null) ...[
            Text(m.score!, style: OgText.body(14, weight: FontWeight.w700)),
            const SizedBox(width: 10),
          ],
          KitTag(label, background: bg, foreground: fg),
        ],
      ),
    );
  }
}

/// Pick events and a partner, then pay.
class TournamentRegisterScreen extends ConsumerStatefulWidget {
  const TournamentRegisterScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<TournamentRegisterScreen> createState() =>
      _TournamentRegisterScreenState();
}

class _TournamentRegisterScreenState
    extends ConsumerState<TournamentRegisterScreen> {
  final _picked = <String>{};
  PartnerPick? _partner;
  bool _busy = false;
  bool _done = false;

  Future<void> _pay(TournamentInfo t, int entry, int fee) async {
    final a = t.activity;
    final picked = t.divisions.where((d) => _picked.contains(d.id)).toList();
    if (entry > 0) {
      final method = await showPaySheet(
        context,
        kicker: 'Register',
        title: a.title,
        subtitle:
            '${picked.length} ${picked.length == 1 ? 'event' : 'events'} · ${tournamentDates(a)}',
        lines: [
          for (final d in picked)
            d.full
                ? ('${d.name} (waitlist)', 'Charged if a spot opens')
                : (d.name, 'S\$${money(d.feeCents)}'),
          if (fee > 0) ('Platform fee', 'S\$${money(fee)}'),
        ],
        totalCents: entry + fee,
        payee: t.host,
        notes: [
          'Withdraw before registration closes: all of it back to your '
              'Wallet, or the entry fee to your card. The platform fee is not '
              'returned to a card.',
          'You earn ${fee ~/ 50} points after you check in.',
        ],
      );
      if (method == null || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .register(
            a.id,
            divisionIds: _picked.toList(),
            partnerId: _partner?.player.id,
          );
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (mounted) setState(() => _done = true);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final info = ref.watch(tournamentInfoProvider(widget.activityId)).value;
    if (info == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Register'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final a = info.activity;
    if (_done) {
      return KitScaffold(
        header: const KitHeader(title: 'Register'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to tournament',
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Registered'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _partner != null
                  ? '${_partner!.player.displayName} has been invited to '
                        'partner you. You’ll both get the draw and your first '
                        'match time once registration closes.'
                  : 'You’ll get the draw and your first match time once '
                        'registration closes.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    final picked = info.divisions.where((d) => _picked.contains(d.id)).toList();
    final needsPartner = picked.any((d) => d.doubles);
    var entry = 0;
    var fee = 0;
    for (final d in picked.where((d) => !d.full)) {
      entry += d.feeCents;
      fee += platformFee(d.feeCents);
    }
    final ready = picked.isNotEmpty && (!needsPartner || _partner != null);
    final partners = ref.watch(partnerPicksProvider(a.id)).value ?? const [];
    final closes = a.registrationClosesAt;
    return KitScaffold(
      header: KitHeader(title: 'Register', subtitle: a.title),
      bottom: [
        KitButton(
          label: !ready
              ? (picked.isEmpty
                    ? 'Choose at least one event'
                    : 'Pick a doubles partner')
              : entry > 0
              ? 'Continue to pay'
              : picked.every((d) => d.full)
              ? 'Join waitlist'
              : 'Register',
          loading: _busy,
          onPressed: ready ? () => _pay(info, entry, fee) : null,
        ),
      ],
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Choose events', style: OgText.heading(20)),
                ),
                Text(
                  '${picked.length} of ${info.maxEvents}',
                  style: OgText.body(13, color: c.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (final d in info.divisions)
              Opacity(
                opacity:
                    !_picked.contains(d.id) && _picked.length >= info.maxEvents
                    ? 0.5
                    : 1,
                child: KitChoiceRow(
                  title: d.name,
                  subtitle: d.full
                      ? '${d.priceLine} · Full, join the waitlist'
                      : '${d.priceLine} · ${d.left} spots left',
                  multi: true,
                  selected: _picked.contains(d.id),
                  onTap: () => setState(() {
                    if (_picked.remove(d.id)) return;
                    if (_picked.length < info.maxEvents) _picked.add(d.id);
                  }),
                ),
              ),
          ],
        ),
        if (needsPartner)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Doubles partner', style: OgText.heading(20)),
              const SizedBox(height: 4),
              if (_partner != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: c.primary, width: 2),
                  ),
                  child: Row(
                    children: [
                      SolidAvatar.forId(
                        _partner!.player.id,
                        initials: _partner!.player.initials,
                        size: 40,
                        fontSize: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _partner!.player.displayName,
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                            Text(
                              'Invite sent when you pay${closes == null ? '' : ' · must accept by ${Fmt.day(closes)}'}',
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      KitLink(
                        'Change',
                        onPressed: () => setState(() => _partner = null),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  "Suggested · players you've played with in range",
                  style: OgText.body(13, color: c.textMuted),
                ),
                if (partners.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'No suggestions yet. Ask your partner to register, or '
                      'play a few Meets together first.',
                      style: OgText.body(14, color: c.textMuted),
                    ),
                  ),
                for (final p in partners)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SolidAvatar.forId(
                          p.player.id,
                          initials: p.player.initials,
                          size: 40,
                          fontSize: 14,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.player.displayName,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                p.meta,
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        KitButton(
                          label: 'Invite',
                          expand: false,
                          height: 40,
                          radius: 20,
                          fontSize: 14,
                          style: KitButtonStyle.outline,
                          onPressed: () => setState(() => _partner = p),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Eligibility', style: OgText.heading(20)),
            const SizedBox(height: 4),
            KitKeyValue(
              'Verified account',
              _mobileVerified
                  ? 'Mobile verified'
                  : 'Add your mobile in Account Centre',
            ),
            KitKeyValue(
              'Level in range',
              info.myLevel == null
                  ? 'Checked when you pay'
                  : '${SkillBandName.of(info.myLevel!)} (${info.myLevel!.toStringAsFixed(1)})',
            ),
            KitKeyValue('Division', info.divisionsText.split(',').first),
          ],
        ),
        if (picked.isNotEmpty)
          KitCard(
            padding: const EdgeInsets.all(14),
            children: [
              Column(
                children: [
                  for (final d in picked)
                    KitKeyValue(
                      d.full ? '${d.name} (waitlist)' : d.name,
                      d.full
                          ? 'Charged if a spot opens'
                          : 'S\$${money(d.feeCents)}',
                    ),
                  if (fee > 0)
                    KitKeyValue(
                      'Platform fee${picked.where((d) => !d.full).length > 1 ? ' (${picked.where((d) => !d.full).length} entries)' : ''}',
                      'S\$${money(fee)}',
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Total', style: OgText.heading(18)),
                        ),
                        Text(
                          'S\$${money(entry + fee)}',
                          style: OgText.heading(18),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        Text(
          entry == 0
              ? 'Free to enter. Withdraw any time before registration closes. '
                    'Doubles entries are confirmed when your partner says yes.'
              : 'Withdraw before registration closes: all of it back to your Wallet, '
                    'or the entry fee to your card. If your partner declines, you get '
                    'all of it back. Nothing is charged until you confirm on the next '
                    'step.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// "MI" for a level, for the eligibility line.
abstract final class SkillBandName {
  static const _codes = ['LB', 'MB', 'HB', 'LI', 'MI', 'HI', 'AD', 'PRO'];
  static String of(double level) => _codes[(level.floor() - 1).clamp(0, 7)];
}

/// Withdraw: why, where the refund goes, then "Withdrawn".
class TournamentWithdrawScreen extends ConsumerStatefulWidget {
  const TournamentWithdrawScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<TournamentWithdrawScreen> createState() =>
      _TournamentWithdrawScreenState();
}

class _TournamentWithdrawScreenState
    extends ConsumerState<TournamentWithdrawScreen> {
  String? _why;
  bool _toWallet = true;
  bool _busy = false;
  int? _refunded;

  Future<void> _withdraw(String id) async {
    setState(() => _busy = true);
    try {
      final back = await ref
          .read(tournamentRepositoryProvider)
          .withdraw(id, toWallet: _toWallet, injury: _why == 'injury');
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (mounted) setState(() => _refunded = back);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final info = ref.watch(tournamentInfoProvider(widget.activityId)).value;
    final partner = info?.mine?.partner?.displayName.split(' ').first;
    if (_refunded case final back?) {
      return KitScaffold(
        header: const KitHeader(title: 'Withdraw'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to Play',
            onPressed: () => context.go(Routes.play),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Withdrawn'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  back > 0 ? 'S\$${money(back)} refunded' : 'No refund',
                  style: OgText.heading(24),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (back > 0)
                      'It goes to ${_toWallet ? 'your Wallet, now' : 'your card, in 3 to 5 working days'}.',
                    if (partner != null) '$partner has been told.',
                  ].join(' '),
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final mine = info?.mine;
    if (info == null || mine == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Withdraw'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final a = info.activity;
    final closes = a.registrationClosesAt;
    final open = closes == null || DateTime.now().isBefore(closes);
    final refundable = open || _why == 'injury';
    final back = !refundable
        ? 0
        : (_toWallet ? mine.paidCents : mine.entryCents);
    return KitScaffold(
      header: const KitHeader(title: 'Withdraw'),
      bottom: [
        KitButton(
          label: _why == null ? 'Pick a reason' : 'Withdraw',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: _why == null ? null : () => _withdraw(a.id),
        ),
      ],
      children: [
        KitTitle(
          'Withdraw from ${a.title}?',
          size: 26,
          lead:
              '${mine.partner == null ? mine.divisionName : '${mine.divisionName} with ${mine.partner!.displayName}'} · ${Fmt.day(a.startsAt)}',
        ),
        Column(
          children: [
            KitKeyValue('You paid', 'S\$${money(mine.paidCents)}'),
            KitKeyValue('Entry fee', 'S\$${money(mine.entryCents)}'),
            KitKeyValue('Platform fee', 'S\$${money(mine.feeCents)}'),
            if (closes != null)
              KitKeyValue('Registration closes', Fmt.day(closes)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Why are you withdrawing?', style: OgText.heading(20)),
            const SizedBox(height: 6),
            for (final (key, title, sub) in const [
              (
                'injury',
                'Injury or illness',
                'All of it back at any time, with a medical note',
              ),
              (
                'date',
                'Can’t make the date',
                'Refund until registration closes',
              ),
              ('other', 'Other', 'Refund until registration closes'),
            ])
              KitChoiceRow(
                title: title,
                subtitle: sub,
                selected: _why == key,
                onTap: () => setState(() => _why = key),
              ),
          ],
        ),
        if (refundable && mine.paidCents > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Where should the refund go?', style: OgText.heading(20)),
              const SizedBox(height: 6),
              KitChoiceRow(
                title: 'Wallet',
                subtitle: 'All S\$${money(mine.paidCents)} · instant',
                selected: _toWallet,
                onTap: () => setState(() => _toWallet = true),
              ),
              KitChoiceRow(
                title: 'Card',
                subtitle:
                    'S\$${money(mine.entryCents)} · the S\$${money(mine.feeCents)} platform fee stays · 3 to 5 working days',
                selected: !_toWallet,
                onTap: () => setState(() => _toWallet = false),
              ),
            ],
          )
        else if (!refundable)
          const KitNote(
            'Registration has closed, so there is no refund unless you are '
            'injured or ill.',
            tone: KitTone.warn,
          ),
        KitKeyValue('You get back', 'S\$${money(back)}'),
        if (mine.partner != null)
          Text(
            '${mine.partner!.displayName.split(' ').first} is told and can find another '
            'partner until registration closes. After that the pair is '
            'withdrawn.',
            style: OgText.body(14, height: 1.45, color: c.textMuted),
          ),
      ],
    );
  }
}

/// How the viewer's tournament went.
class TournamentResultsScreen extends ConsumerWidget {
  const TournamentResultsScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final info = ref.watch(tournamentInfoProvider(activityId)).value;
    final r = ref.watch(tournamentResultProvider(activityId));
    if (info == null || r.isLoading) {
      return const KitScaffold(
        header: KitHeader(title: 'Results'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final result = r.value;
    if (result == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Results'),
        children: [KitNote('Results show here once your matches are played.')],
      );
    }
    final a = info.activity;
    const ord = ['', '1st', '2nd', '3rd', '4th'];
    Widget step(int place, double height) => Expanded(
      child: Column(
        children: [
          Text(
            result.podium[place - 1],
            textAlign: TextAlign.center,
            maxLines: 2,
            style: OgText.body(13, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: place == 1
                  ? t.gold
                  : (place == result.place ? c.primary : t.tag),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Text('$place', style: OgText.heading(28)),
          ),
        ],
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Results'),
      children: [
        KitTitle(
          'Final · ${result.division}',
          size: 26,
          lead: '${a.title} · ${Fmt.day(a.endsAt)} · ${result.entries} pairs',
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            step(2, 80),
            const SizedBox(width: 8),
            step(1, 110),
            const SizedBox(width: 8),
            step(3, 60),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: t.successFill,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You finished ${result.place < ord.length ? ord[result.place] : '${result.place}th'}',
                style: OgText.heading(22, color: t.onSuccessFill),
              ),
              const SizedBox(height: 4),
              Text(
                '${result.wins} ${result.wins == 1 ? 'win' : 'wins'}, ${result.losses} ${result.losses == 1 ? 'loss' : 'losses'}.'
                '${result.ratingFrom == null ? '' : ' Your rating moved from ${result.ratingFrom!.toStringAsFixed(1)} to ${result.ratingTo!.toStringAsFixed(1)}'}'
                '${result.points > 0 ? ' and you earned ${result.points} points.' : '.'}',
                style: OgText.body(14, height: 1.45, color: t.onSuccessFill),
              ),
            ],
          ),
        ),
        Text('Your matches', style: OgText.heading(20)),
        KitCard(
          children: [
            for (final m in result.matches) MatchRow(match: m, showDay: true),
          ],
        ),
        KitButton(
          label: 'See the full draw',
          style: KitButtonStyle.outline,
          onPressed: () => context.push(Routes.tournamentTab(a.id, 'draw')),
        ),
      ],
    );
  }
}

/// Whether the player has a verified mobile number. Demo players have one.
bool get _mobileVerified =>
    !Env.hasSupabase ||
    (Supabase.instance.client.auth.currentUser?.phone ?? '').isNotEmpty;
