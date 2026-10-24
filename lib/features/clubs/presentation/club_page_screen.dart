import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../play/presentation/create_screens.dart' show showCreateMenu;
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/domain/activity.dart';
import '../../play/presentation/play_card.dart';
import '../application/club_providers.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';
import 'club_widgets.dart';

/// "LI–HI" for a Meet's level range, "All levels" when open.
String bandRange(Activity a) {
  if (a.levelMin == null || a.levelMax == null) return 'All levels';
  final lo = SkillBand.forLevel(a.levelMin!);
  final hi = SkillBand.forLevel(a.levelMax!);
  return LevelRange(lo.index, hi.index).label;
}

/// A club invite link: opens the club the code belongs to.
class ClubInviteLinkScreen extends ConsumerWidget {
  const ClubInviteLinkScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(clubIdForCodeProvider(code))) {
      AsyncData(value: final id?) => ClubScreen(id: id),
      AsyncData() || AsyncError() => const KitScaffold(
        header: KitHeader(title: 'Club invite'),
        children: [
          KitNote(
            'This invite code is wrong or has expired. Ask the club for a new link.',
          ),
        ],
      ),
      _ => const KitScaffold(
        header: KitHeader(title: 'Club invite'),
        children: [CupertinoActivityIndicator()],
      ),
    };
  }
}

/// A club: the member page, or the public or private outsider page.
class ClubScreen extends ConsumerWidget {
  const ClubScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final club = ref.watch(clubProvider(id));
    if (club.value case final c?) Crumbs.name(context, c.name);
    return switch (club) {
      AsyncData(:final value) => switch (value) {
        Club(isMember: true) => _MemberClubPage(club: value),
        Club(visibility: ClubVisibility.public) => _PublicClubPage(club: value),
        _ => _PrivateClubPage(club: value),
      },
      AsyncError(:final error) => KitScaffold(
        header: const KitHeader(title: 'Club'),
        children: [
          OgErrorText(
            error is AuthFailure
                ? error.message
                : "This club isn't loading. Try again.",
          ),
        ],
      ),
      _ => const Scaffold(body: Center(child: CupertinoActivityIndicator())),
    };
  }
}

// ─── Member page ───────────────────────────────────────────────────────────

const _sessionFilters = [
  FilterGroup('schedule', 'Schedule', [
    'Upcoming',
    'Today',
    'Tomorrow',
    'Weekend',
  ]),
  FilterGroup('style', 'Play style', ['Casual', 'Ranked']),
  FilterGroup('gender', 'Gender', ['Male', 'Female']),
  FilterGroup('type', 'Play type', ['Meet', 'Tournament', 'Event']),
];

class _MemberClubPage extends ConsumerStatefulWidget {
  const _MemberClubPage({required this.club});

  final Club club;

  @override
  ConsumerState<_MemberClubPage> createState() => _MemberClubPageState();
}

class _MemberClubPageState extends ConsumerState<_MemberClubPage> {
  late ClubSport? _sport = widget.club.primarySport;
  var _filters = <String, String>{};

  bool _keep(Activity a) {
    if (_sport != null && !a.sports.contains(_sport!.playSport)) return false;
    final now = DateTime.now();
    final d = DateTime(a.startsAt.year, a.startsAt.month, a.startsAt.day);
    final today = DateTime(now.year, now.month, now.day);
    switch (_filters['schedule']) {
      case 'Today':
        if (d != today) return false;
      case 'Tomorrow':
        if (d != today.add(const Duration(days: 1))) return false;
      case 'Weekend':
        if (a.startsAt.weekday < DateTime.saturday) return false;
    }
    switch (_filters['style']) {
      case 'Casual':
        if (a.ranked) return false;
      case 'Ranked':
        if (!a.ranked) return false;
    }
    switch (_filters['gender']) {
      case 'Male':
        if (a.men == 0) return false;
      case 'Female':
        if (a.women == 0) return false;
    }
    final type = _filters['type'];
    if (type != null && a.kind.label != type) return false;
    return true;
  }

  Future<void> _openFilters() async {
    final picked = await showFilterSheet(
      context,
      groups: _sessionFilters,
      selected: _filters,
    );
    if (picked != null) setState(() => _filters = picked);
  }

  Future<void> _refresh() async {
    refreshClub(ref.invalidate, widget.club.id);
    await ref.read(clubProvider(widget.club.id).future);
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final c = context.og;
    final top = MediaQuery.of(context).padding.top;
    final sessions = ref.watch(clubSessionsProvider(club.id));
    final shown = sessions.value?.where(_keep).toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refresh),
            // One box: the card and tabs overlap the hero, and a later sliver
            // would paint under it and miss its taps.
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CourtHero(
                        color: Color(club.coverColor),
                        height: 200 + top,
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        top: top + 12,
                        child: Row(
                          children: [
                            const KitBackPill(),
                            const Spacer(),
                            Builder(
                              builder: (context) => _whiteButton(
                                OgIcons.shareTray,
                                'Share',
                                () => shareLink(
                                  context,
                                  club.name,
                                  Links.club(club.id),
                                ),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _whiteButton(
                              OgIcons.cog,
                              'Club settings',
                              () => context.push(Routes.clubSettings(club.id)),
                              size: 20,
                              stroke: 1.9,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, -64),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _ClubCard(club: club),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -44),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _tabsRow(context),
                        const SizedBox(height: 18),
                        _filterRows(context),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  'Play sessions',
                                  style: OgText.heading(26, color: c.text),
                                ),
                              ),
                              if (shown != null)
                                Text(
                                  '${shown.length} in ${_sport?.label ?? 'all sports'}',
                                  style: OgText.body(13, color: c.textMuted),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...switch (sessions) {
                          AsyncData() when shown!.isEmpty => [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: KitNote(
                                club.can(ClubPermission.createMeet)
                                    ? 'No sessions match. Clear a filter, or create one.'
                                    : 'No sessions match. Clear a filter or check back soon.',
                              ),
                            ),
                          ],
                          AsyncData() => [
                            for (final s in shown!)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  0,
                                  20,
                                  12,
                                ),
                                child: PlayCard(activity: s),
                              ),
                          ],
                          AsyncError() => [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: OgErrorText(
                                "Sessions aren't loading. Pull to try again.",
                              ),
                            ),
                          ],
                          _ => [
                            const Padding(
                              padding: EdgeInsets.all(24),
                              child: CupertinoActivityIndicator(),
                            ),
                          ],
                        },
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            20,
                            8,
                            20,
                            MediaQuery.of(context).padding.bottom,
                          ),
                          child: KitLink(
                            'Report this club',
                            color: c.textMuted,
                            onPressed: () =>
                                context.push(Routes.clubReport(club.id)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whiteButton(
    String icon,
    String label,
    VoidCallback onPressed, {
    double size = 22,
    double stroke = 2,
  }) => KitIconButton(
    icon: icon,
    label: label,
    background: Colors.white,
    color: OgColors.charcoal900,
    size: size,
    strokeWidth: stroke,
    onPressed: onPressed,
  );

  Widget _tabsRow(BuildContext context) {
    final club = widget.club;
    final c = context.og;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: KitSegments(
              labels: const ['Play', 'Ranks', 'Chat'],
              selected: 0,
              onSelect: (i) => switch (i) {
                1 => context.push(Routes.clubLeaderboard(club.id)),
                2 => context.push(Routes.clubChat(club.id)),
                _ => null,
              },
              children: [
                Text(
                  'Play',
                  style: OgText.body(
                    15,
                    weight: FontWeight.w600,
                    color: c.text,
                  ),
                ),
                Text(
                  'Ranks',
                  style: OgText.body(
                    15,
                    weight: FontWeight.w600,
                    color: c.textMuted,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Chat',
                      style: OgText.body(
                        15,
                        weight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                    if (club.unreadChat > 0) ...[
                      const SizedBox(width: 6),
                      KitCountBadge(club.unreadChat, size: 20),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (club.can(ClubPermission.createMeet)) ...[
            const SizedBox(width: 10),
            KitButton(
              label: 'Create',
              icon: OgIcons.plus,
              height: 52,
              fontSize: 15,
              expand: false,
              padding: 16,
              onPressed: () => showCreateMenu(context, clubId: club.id),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterRows(BuildContext context) {
    final club = widget.club;
    final c = context.og;
    Widget scroller(List<Widget> children) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: kitRowSpaced(children, 8)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        scroller([
          for (final g in _sessionFilters.take(3))
            KitChip(
              label: _filters[g.key] ?? g.title,
              selected: _filters.containsKey(g.key),
              trailingIcon: OgIcons.chevronDown,
              onTap: _openFilters,
            ),
        ]),
        const SizedBox(height: 12),
        scroller([
          KitChip(
            label: 'All',
            height: 44,
            selected: _sport == null,
            onTap: () => setState(() {
              _sport = null;
              _filters = {};
            }),
          ),
          for (final s in club.sports)
            if (_sport == s.sport)
              Container(
                height: 44,
                padding: const EdgeInsets.only(left: 12, right: 2),
                decoration: BoxDecoration(
                  color: c.text,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    OgIcon(
                      s.sport.icon,
                      size: 20,
                      color: c.bg,
                      strokeWidth: 1.9,
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 20, color: c.bg.withAlpha(77)),
                    const SizedBox(width: 8),
                    Text(
                      s.range.label,
                      style: OgText.body(
                        14,
                        weight: FontWeight.w600,
                        color: c.bg,
                      ),
                    ),
                    KitIconButton(
                      icon: OgIcons.close,
                      label: 'Clear ${s.sport.label}',
                      size: 16,
                      strokeWidth: 2.4,
                      color: c.bg,
                      onPressed: () => setState(() => _sport = null),
                    ),
                  ],
                ),
              )
            else
              Pressable(
                semanticLabel: s.sport.label,
                onPressed: () => setState(() => _sport = s.sport),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.bg,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: OgIcon(
                    s.sport.icon,
                    size: 20,
                    color: c.text,
                    strokeWidth: 1.9,
                  ),
                ),
              ),
        ]),
      ],
    );
  }
}

/// Puts [gap] between widgets in a row.
List<Widget> kitRowSpaced(List<Widget> children, double gap) => [
  for (var i = 0; i < children.length; i++) ...[
    if (i > 0) SizedBox(width: gap),
    children[i],
  ],
];

/// The white card over the hero: logo, name, rating, then member links.
class _ClubCard extends StatelessWidget {
  const _ClubCard({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget link(
      String icon,
      String label,
      VoidCallback onTap, {
      Widget? trailing,
      Color? color,
      double iconSize = 22,
    }) => Pressable(
      semanticLabel: label,
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 54),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            OgIcon(
              icon,
              size: iconSize,
              color: color ?? c.text,
              strokeWidth: 1.8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: OgText.body(
                  15,
                  weight: FontWeight.w600,
                  color: color ?? c.text,
                ),
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 12)],
            OgIcon(OgIcons.chevronRight, size: 20, color: c.textMuted),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F17171A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Pressable(
            semanticLabel: '${club.name}. Club info',
            onPressed: () => context.push(Routes.clubAbout(club.id)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  ClubMark(club, size: 76, radius: 20, fontSize: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: OgText.heading(28, color: c.text),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          [
                            club.primarySport?.label,
                            club.area,
                          ].whereType<String>().join(', '),
                          style: OgText.body(13, color: c.textMuted),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            if (club.rating != null) ...[
                              Text(
                                '${club.rating!.toStringAsFixed(1)} (${club.ratingCount})',
                                style: OgText.body(
                                  13,
                                  weight: FontWeight.w600,
                                  color: c.text,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            LevelTag(club.primaryRange.label, height: 22),
                          ],
                        ),
                      ],
                    ),
                  ),
                  OgIcon(OgIcons.chevronRight, size: 20, color: c.textMuted),
                ],
              ),
            ),
          ),
          link(
            OgIcons.group,
            '${club.memberCount} members',
            () => context.push(Routes.clubMembers(club.id)),
          ),
          if (club.can(ClubPermission.approve))
            link(
              OgIcons.personRequest,
              'Join requests',
              () => context.push(Routes.clubRequests(club.id)),
              trailing: club.pendingRequests > 0
                  ? KitCountBadge(club.pendingRequests)
                  : null,
            ),
          link(
            OgIcons.megaphone,
            'Announcements',
            () => context.push(Routes.clubAnnouncements(club.id)),
            iconSize: 20,
          ),
          link(
            OgIcons.plus,
            'Invite members',
            () => context.push(Routes.clubInvite(club.id)),
            color: c.link,
          ),
        ],
      ),
    );
  }
}

// ─── Public outsider page ──────────────────────────────────────────────────

class _PublicClubPage extends ConsumerStatefulWidget {
  const _PublicClubPage({required this.club});

  final Club club;

  @override
  ConsumerState<_PublicClubPage> createState() => _PublicClubPageState();
}

class _PublicClubPageState extends ConsumerState<_PublicClubPage> {
  var _busy = false;

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).join(widget.club.id);
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.club.id);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    await ref.read(clubRepositoryProvider).cancelRequest(widget.club.id);
    refreshClub(ref.invalidate, widget.club.id);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final c = context.og;
    final t = context.tones;
    final sessions = ref.watch(clubSessionsProvider(club.id)).value ?? [];
    final runners = ref.watch(clubMembersProvider(club.id)).value ?? [];
    final roles = ref.watch(clubRolesProvider(club.id)).value ?? [];
    String roleOf(ClubMember m) {
      final r = roles.where((r) => m.roleIds.contains(r.id)).toList()
        ..sort((a, b) => a.position.compareTo(b.position));
      return r.isEmpty ? 'Member' : r.first.name;
    }

    final leaders =
        runners
            .where((m) => roleOf(m) == 'Owner' || roleOf(m) == 'Admin')
            .toList()
          ..sort(
            (a, b) =>
                roleOf(a) == 'Owner' ? -1 : (roleOf(b) == 'Owner' ? 1 : 0),
          );
    final requested = club.standing == ClubStanding.requested;
    final instant = club.joinMode == JoinMode.anyone;
    return KitScaffold(
      header: const KitHeader(title: 'Club'),
      bottom: [
        if (requested) ...[
          KitNote(
            'Request sent. An owner or admin reviews each request.',
            tone: KitTone.success,
          ),
          KitButton.outline(
            label: 'Cancel request',
            loading: _busy,
            onPressed: _cancel,
          ),
        ] else
          KitButton(
            label: instant ? 'Join club' : 'Ask to join',
            loading: _busy,
            onPressed: _join,
          ),
      ],
      children: [
        Transform.translate(
          offset: const Offset(0, -20),
          child: OverflowBox(
            maxWidth: MediaQuery.of(context).size.width,
            child: CourtHero(
              color: Color(club.logoColor),
              height: 170,
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                  child: Text(
                    club.initials,
                    style: OgText.heading(52, color: Color(club.logoInk)),
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(club.name, style: OgText.heading(32, color: c.text)),
            const SizedBox(height: 4),
            Text(
              '${club.sportLabels} · ${club.area} · ${club.memberCount} members',
              style: OgText.body(13, color: c.textMuted),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                KitTag(
                  instant ? 'Open to join' : 'Ask to join',
                  background: instant ? t.successFill : t.soft,
                  foreground: instant ? t.onSuccessFill : c.text,
                ),
                KitTag(club.primaryRange.spoken),
                if (club.meetsPerWeek > 0)
                  KitTag(
                    '${club.meetsPerWeek} Meet${club.meetsPerWeek == 1 ? '' : 's'} a week',
                  ),
              ],
            ),
          ],
        ),
        if (club.description.isNotEmpty)
          Text(club.description, style: OgText.body(15, height: 1.5)),
        if (sessions.isNotEmpty)
          KitBlock(
            title: 'Next Meets anyone can join',
            child: Column(
              children: [
                for (final s in sessions.take(3))
                  Pressable(
                    semanticLabel: s.title,
                    onPressed: () => context.push(Routes.activity(s.id)),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 60),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.title,
                                  style: OgText.body(
                                    15,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${Fmt.dayTimeComma(s.startsAt)} · ${bandRange(s)}',
                                  style: OgText.body(13, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            s.isFree ? 'Free' : 'S\$${money(s.feeCents)}',
                            style: OgText.body(15, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const KitBlock(
          title: 'What members get',
          child: KitCheckList([
            'Member-only Meets and the club ladder',
            'Club chat and announcements',
            'A share of the club reward voucher',
          ]),
        ),
        if (leaders.isNotEmpty)
          KitBlock(
            title: 'Run by',
            child: Column(
              children: [
                for (final m in leaders.take(3))
                  Pressable(
                    semanticLabel: '${m.player.displayName}, ${roleOf(m)}',
                    onPressed: () => context.push(Routes.player(m.player.id)),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 64),
                      decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: c.border)),
                      ),
                      child: Row(
                        children: [
                          PlayerFace(m.player),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m.player.displayName,
                                  style: OgText.body(
                                    15,
                                    weight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  [
                                    roleOf(m),
                                    if (m.band != null)
                                      '${m.band!.code} ${m.rating!.toStringAsFixed(1)}',
                                  ].join(' · '),
                                  style: OgText.body(13, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const KitNote(
          'You are seeing the public page because you are not a member yet.',
        ),
        KitLink(
          'Report this club',
          color: c.textMuted,
          onPressed: () => context.push(Routes.clubReport(club.id)),
        ),
      ],
    );
  }
}

// ─── Private outsider page ─────────────────────────────────────────────────

class _PrivateClubPage extends ConsumerStatefulWidget {
  const _PrivateClubPage({required this.club});

  final Club club;

  @override
  ConsumerState<_PrivateClubPage> createState() => _PrivateClubPageState();
}

class _PrivateClubPageState extends ConsumerState<_PrivateClubPage> {
  final _message = TextEditingController();
  var _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .join(widget.club.id, message: _message.text.trim());
      HapticFeedback.mediumImpact();
      refreshClub(ref.invalidate, widget.club.id);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    await ref.read(clubRepositoryProvider).cancelRequest(widget.club.id);
    refreshClub(ref.invalidate, widget.club.id);
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final club = widget.club;
    final c = context.og;
    final t = context.tones;
    final top = MediaQuery.of(context).padding.top;
    final sent = club.standing == ClubStanding.requested;
    Widget dimButton(String icon, String label, VoidCallback onTap) =>
        KitIconButton(
          icon: icon,
          label: label,
          background: const Color(0x7316181B),
          color: Colors.white,
          size: icon == OgIcons.arrowBack ? 22 : 20,
          strokeWidth: icon == OgIcons.arrowBack ? 2 : 1.9,
          onPressed: onTap,
        );
    final card = Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: sent ? t.successFill : t.tag,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                sent ? OgIcons.tick : OgIcons.padlock,
                size: 26,
                strokeWidth: sent ? 2 : 1.8,
                color: sent ? t.onSuccessFill : c.text,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            sent ? 'Request sent' : 'This club is private',
            textAlign: TextAlign.center,
            style: OgText.display(19, height: 1.2, color: c.text),
          ),
          const SizedBox(height: 10),
          Text(
            sent ? "You'll get a notification when an admin responds." : 'Meets, members and the leaderboard are visible only to members.',
            textAlign: TextAlign.center,
            style: OgText.body(15, height: 1.5, color: c.textMuted),
          ),
          const SizedBox(height: 10),
          if (!sent) ...[
            const SizedBox(height: 8),
            KitTextArea(
              label: 'Message to the admins',
              optional: true,
              controller: _message,
              hint: 'Say hi and share your level',
              background: t.softer,
            ),
            const SizedBox(height: 14),
            KitButton(
              label: 'Request to join',
              height: 50,
              radius: 25,
              loading: _busy,
              onPressed: _send,
            ),
            const SizedBox(height: 10),
            Text(
              'An owner or admin reviews each request.',
              textAlign: TextAlign.center,
              style: OgText.body(13, color: c.textMuted),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Pressable(
              semanticLabel: 'Cancel request',
              onPressed: _busy ? null : _cancel,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: c.text, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel request',
                  style: OgText.body(16, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return Scaffold(
      backgroundColor: c.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          children: [
            Stack(
              children: [
                CourtHero(
                  color: Color(club.logoColor),
                  height: 220 + top,
                  style: CourtLines.half,
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: top + 14,
                  child: Row(
                    children: [
                      const KitBackPill(
                        background: Color(0x7316181B),
                        color: Colors.white,
                      ),
                      const Spacer(),
                      Builder(
                        builder: (context) => dimButton(
                          OgIcons.shareUp,
                          'Share club',
                          () => shareLink(
                            context,
                            club.name,
                            Links.club(club.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -64),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _privateHeader(context),
                    const SizedBox(height: 16),
                    card,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privateHeader(BuildContext context) {
    final club = widget.club;
    final c = context.og;
    return Container(
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
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClubMark(club, size: 84, radius: 18, fontSize: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        club.name,
                        style: OgText.display(
                          22,
                          height: 1.15,
                          color: c.text,
                        ).copyWith(letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          OgIcon(
                            OgIcons.mapPin,
                            size: 15,
                            color: c.textMuted,
                            strokeWidth: 1.8,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${club.primarySport?.label ?? 'Club'} · ${club.area}',
                            style: OgText.body(14, color: c.textMuted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2F36),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OgIcon(
                              OgIcons.padlock,
                              size: 12,
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              club.visibility.label,
                              style: OgText.body(
                                12,
                                weight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: context.tones.divider,
          ),
          SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  OgIcon(OgIcons.group, size: 22, strokeWidth: 1.8),
                  const SizedBox(width: 12),
                  Text(
                    '${club.memberCount} members',
                    style: OgText.body(15, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
