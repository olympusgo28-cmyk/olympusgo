import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../application/club_providers.dart';
import '../domain/club_models.dart';

/// Loads the team, then builds [body].
class _WithTeam extends ConsumerWidget {
  const _WithTeam({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final Widget Function(Team team) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(teamProvider(id))) {
        AsyncData(:final value) => body(value),
        AsyncError() => KitScaffold(
          header: KitHeader(title: title),
          children: const [KitNote("This team isn't available any more.")],
        ),
        _ => KitScaffold(
          header: KitHeader(title: title),
          children: const [CupertinoActivityIndicator()],
        ),
      };
}

/// The team's mark on its colour.
class TeamMark extends StatelessWidget {
  const TeamMark({super.key, required this.team, this.size = 56});

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) => ClubLogo(
    initials: team.mark,
    color: Color(team.logoColor),
    ink: Color(team.logoInk),
    size: size,
  );
}

/// "Doubles 1 with Mei Wong" for the viewer, from the lineup.
String? _myLine(Fixture f, String? me, Map<String, String> names) {
  if (me == null) return null;
  for (final s in f.slots) {
    final ids = f.lineup[s.key] ?? const [];
    if (ids.contains(me)) {
      final others = [
        for (final id in ids)
          if (id != null && id != me) names[id] ?? 'a teammate',
      ];
      return others.isEmpty
          ? s.label
          : '${s.label} with ${others.join(' and ')}';
    }
  }
  return null;
}

/// The team page: who it is, the next fixture, schedule and results.
class TeamPageScreen extends ConsumerWidget {
  const TeamPageScreen({super.key, required this.id});

  final String id;

  Future<void> _reply(
    BuildContext context,
    WidgetRef ref,
    String fixtureId,
    Availability a,
  ) async {
    try {
      await ref.read(clubRepositoryProvider).setAvailability(fixtureId, a);
      HapticFeedback.selectionClick();
      refreshTeam(ref.invalidate, id);
    } on AuthFailure catch (e) {
      if (context.mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => _WithTeam(
    id: id,
    title: 'Team',
    body: (team) {
      final c = context.og;
      final t = context.tones;
      Crumbs.name(context, team.name);
      final me = ref.watch(currentUserIdProvider).value;
      final members = ref.watch(teamMembersProvider(id)).value ?? const [];
      final names = {
        for (final m in members) m.player.id: m.player.displayName,
      };
      final nextId = ref.watch(nextFixtureIdProvider(id)).value;
      final fixture = nextId == null
          ? null
          : ref.watch(fixtureProvider(nextId)).value;
      final sessions = ref.watch(teamSessionsProvider(id)).value ?? const [];
      final results = ref.watch(teamResultsProvider(id)).value ?? const [];
      final myLine = fixture == null ? null : _myLine(fixture, me, names);
      return KitScaffold(
        header: KitHeader(
          title: team.name,
          crumb: team.name,
          trailing: team.isStaff
              ? KitIconButton(
                  icon: OgIcons.cog,
                  label: 'Team settings',
                  onPressed: () => context.push(Routes.teamSettings(id)),
                )
              : KitLink(
                  'Leave',
                  onPressed: () => context.push(Routes.teamLeave(id)),
                ),
        ),
        children: [
          Row(
            children: [
              TeamMark(team: team, size: 64),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(team.name, style: OgText.heading(24)),
                    if (team.represents.isNotEmpty)
                      Text(
                        'Represents ${team.represents}',
                        style: OgText.body(14, color: c.textMuted),
                      ),
                  ],
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              KitTag(team.sport.label, background: t.tag, foreground: t.onTag),
              if (team.season.isNotEmpty)
                KitTag(team.season, background: t.tag, foreground: t.onTag),
            ],
          ),
          Text(
            '${team.playerCount} players · ${team.reserveCount} reserves · '
            '${team.staffCount} staff',
            style: OgText.body(14, weight: FontWeight.w600),
          ),
          if (team.linkedClubs.isNotEmpty)
            Text(
              'Picks players from ${team.linkedClubs.length} '
              '${team.linkedClubs.length == 1 ? 'club' : 'clubs'}: '
              '${team.linkedClubs.map((c) => c.name).join(', ')}',
              style: OgText.body(13, height: 1.4, color: c.textMuted),
            ),
          Row(
            children: [
              Expanded(
                child: KitButton(
                  label: 'Team chat',
                  icon: OgIcons.chatRound,
                  style: KitButtonStyle.outline,
                  onPressed: () => context.push(Routes.teamChat(id)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: KitButton(
                  label: 'Roster',
                  icon: OgIcons.rosterCard,
                  style: KitButtonStyle.outline,
                  onPressed: () => context.push(Routes.teamRoster(id)),
                ),
              ),
            ],
          ),
          if (fixture != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: OgColors.ink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NEXT FIXTURE',
                          style: OgText.body(
                            12,
                            weight: FontWeight.w800,
                            color: t.gold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      if (fixture.lineupLocksAt != null)
                        Text(
                          'Lineup locks ${Fmt.dayTimeComma(fixture.lineupLocksAt!)}',
                          style: OgText.body(
                            12,
                            color: const Color(0xFFC9C6BC),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${fixture.competition.isEmpty ? '' : '${fixture.competition} '}vs ${fixture.opponent}',
                    style: OgText.heading(22, color: const Color(0xFFFFFFFF)),
                  ),
                  Text(
                    '${Fmt.dayTimeComma(fixture.startsAt)}${fixture.venue.isEmpty ? '' : ' · ${fixture.venue}'}',
                    style: OgText.body(14, color: const Color(0xFFC9C6BC)),
                  ),
                  if (myLine != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      "You're in · $myLine",
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: const Color(0xFFC6FF00),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (fixture.myAvailability == Availability.noReply) ...[
                    Text(
                      'Are you available?',
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: KitButton(
                            label: "Can't make it",
                            style: KitButtonStyle.outline,
                            height: 46,
                            onPressed: () => _reply(
                              context,
                              ref,
                              fixture.id,
                              Availability.unavailable,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KitButton(
                            label: "I'm available",
                            style: KitButtonStyle.gold,
                            height: 46,
                            onPressed: () => _reply(
                              context,
                              ref,
                              fixture.id,
                              Availability.available,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'You said: ${fixture.myAvailability.label}',
                            style: OgText.body(
                              14,
                              weight: FontWeight.w700,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                        ),
                        KitLink(
                          'Change',
                          color: t.gold,
                          onPressed: () => _reply(
                            context,
                            ref,
                            fixture.id,
                            Availability.noReply,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: KitLink(
                      'Fixture details',
                      underline: true,
                      color: const Color(0xFFFFFFFF),
                      onPressed: () =>
                          context.push(Routes.teamFixture(id, fixture.id)),
                    ),
                  ),
                ],
              ),
            ),
          if (sessions.isNotEmpty) ...[
            Text('Schedule', style: OgText.heading(20)),
            KitCard(
              children: [
                for (final s in sessions)
                  Pressable(
                    semanticLabel: s.title,
                    onPressed: s.fixture
                        ? () => context.push(Routes.teamFixture(id, s.id))
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 52,
                            decoration: BoxDecoration(
                              color: t.tag,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  const [
                                    'MON',
                                    'TUE',
                                    'WED',
                                    'THU',
                                    'FRI',
                                    'SAT',
                                    'SUN',
                                  ][s.startsAt.weekday - 1],
                                  style: OgText.body(
                                    11,
                                    weight: FontWeight.w800,
                                    color: t.onTag,
                                  ),
                                ),
                                Text(
                                  '${s.startsAt.day}',
                                  style: OgText.heading(18),
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
                                  s.title,
                                  style: OgText.body(
                                    15,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${Fmt.time(s.startsAt)}${s.venue.isEmpty ? '' : ' · ${s.venue}'}',
                                  style: OgText.body(13, color: c.textMuted),
                                ),
                              ],
                            ),
                          ),
                          KitTag(
                            s.fixture ? 'Fixture' : 'Training',
                            background: s.fixture ? t.gold : t.tag,
                            foreground: s.fixture ? t.onGold : t.onTag,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (results.isNotEmpty) ...[
            Text('Results', style: OgText.heading(20)),
            KitCard(
              children: [
                for (final r in results)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        KitTag(
                          r.won ? 'Won' : 'Lost',
                          background: r.won ? t.successFill : t.dangerFill,
                          foreground: r.won ? t.onSuccessFill : t.onDangerFill,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'vs ${r.opponent}',
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                [
                                  Fmt.day(r.at),
                                  if (r.competition.isNotEmpty) r.competition,
                                ].join(' · '),
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(r.score, style: OgText.heading(18)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}

/// Staff tools for a team.
class TeamSettingsScreen extends StatelessWidget {
  const TeamSettingsScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) => _WithTeam(
    id: id,
    title: 'Team settings',
    body: (team) => Consumer(
      builder: (context, ref, _) {
        final c = context.og;
        final nextId = ref.watch(nextFixtureIdProvider(id)).value;
        final fixture = nextId == null
            ? null
            : ref.watch(fixtureProvider(nextId)).value;
        return KitScaffold(
          header: const KitHeader(title: 'Team settings'),
          children: [
            Row(
              children: [
                TeamMark(team: team, size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(team.name, style: OgText.heading(20)),
                      Text(
                        '${team.sport.label} · ${team.playerCount} players · ${team.staffCount} staff · Private',
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            KitCard(
              children: [
                KitNavTile(
                  icon: OgIcons.pencil,
                  title: 'Overview',
                  subtitle: 'Name, logo, sport and sub-teams',
                  onTap: () => context.push(Routes.teamOverview(id)),
                ),
                KitNavTile(
                  icon: OgIcons.rosterCard,
                  title: 'Players and staff',
                  subtitle:
                      '${team.playerCount} players, ${team.reserveCount} reserves, ${team.staffCount} staff',
                  onTap: () =>
                      context.push(Routes.teamRoster(id, tab: 'players')),
                ),
                KitNavTile(
                  icon: OgIcons.personRequest,
                  title: 'Add players',
                  subtitle: 'From linked clubs or by invite link',
                  onTap: () => context.push(Routes.teamAdd(id)),
                ),
                if (fixture != null)
                  KitNavTile(
                    icon: OgIcons.clipboardList,
                    title: 'Lineup',
                    subtitle: 'Next fixture ${Fmt.day(fixture.startsAt)}',
                    onTap: () =>
                        context.push(Routes.teamLineup(id, fixture.id)),
                  ),
                KitNavTile(
                  icon: OgIcons.chatRound,
                  title: 'Team chat',
                  subtitle: team.unreadChat == 0
                      ? 'All caught up'
                      : '${team.unreadChat} unread',
                  onTap: () => context.push(Routes.teamChat(id)),
                ),
              ],
            ),
            KitCard(
              children: [
                KitNavTile(
                  icon: OgIcons.leave,
                  title: 'Leave team',
                  subtitle: 'You keep your results and rating',
                  danger: true,
                  onTap: () => context.push(Routes.teamLeave(id)),
                ),
                if (team.myRole == TeamRole.owner)
                  KitNavTile(
                    icon: OgIcons.trash,
                    title: 'Delete team',
                    subtitle:
                        'Owner only. Removes the roster, fixtures and chat',
                    danger: true,
                    onTap: () => context.push(Routes.teamDelete(id)),
                  ),
              ],
            ),
            const KitNote(
              'Teams are private. Only players and staff you add can see the '
              'team, its schedule and its chat.',
            ),
          ],
        );
      },
    ),
  );
}

/// Edit the team: name, who it represents, sub-teams.
class TeamOverviewScreen extends ConsumerStatefulWidget {
  const TeamOverviewScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TeamOverviewScreen> createState() => _TeamOverviewScreenState();
}

class _TeamOverviewScreenState extends ConsumerState<TeamOverviewScreen> {
  Team? _draft;
  final _name = TextEditingController();
  final _rep = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _rep.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .updateTeam(
            _draft!.copyWith(
              name: _name.text.trim(),
              represents: _rep.text.trim(),
            ),
          );
      HapticFeedback.mediumImpact();
      refreshTeam(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(context, 'Saved');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTeam(
    id: widget.id,
    title: 'Team overview',
    body: (team) {
      final c = context.og;
      if (_draft == null) {
        _draft = team;
        _name.text = team.name;
        _rep.text = team.represents;
      }
      final d = _draft!;
      return KitScaffold(
        header: const KitHeader(title: 'Team overview'),
        bottom: [KitButton(label: 'Save', loading: _busy, onPressed: _save)],
        children: [
          Row(
            children: [
              TeamMark(team: d, size: 64),
              const SizedBox(width: 14),
              KitButton(
                label: 'Change logo',
                expand: false,
                height: 40,
                radius: 20,
                fontSize: 14,
                style: KitButtonStyle.outline,
                onPressed: () =>
                    showOgToast(context, 'Logos come with photo uploads.'),
              ),
            ],
          ),
          KitInput(label: 'Team name', controller: _name, maxLength: 40),
          KitInput(
            label: 'Who does the team represent?',
            controller: _rep,
            hint: 'School name',
          ),
          KitKeyValue('Sport', '${d.sport.label} · set when created'),
          Text('Sub-teams', style: OgText.heading(20)),
          Column(
            children: [
              for (final (i, s) in d.subTeams.indexed)
                KitChoiceRow(
                  title: s.name,
                  subtitle: [
                    if (s.rule.isNotEmpty) s.rule,
                    if (s.players > 0) '${s.players} players',
                  ].join(' · '),
                  multi: true,
                  selected: s.enabled,
                  onTap: () => setState(() {
                    final list = [...d.subTeams];
                    list[i] = s.copyWith(enabled: !s.enabled);
                    _draft = d.copyWith(subTeams: list);
                  }),
                ),
            ],
          ),
          if (d.linkedClubs.isNotEmpty) ...[
            Text('Linked clubs', style: OgText.heading(20)),
            for (final club in d.linkedClubs)
              Row(
                children: [
                  ClubLogo(
                    initials: club.initials,
                    color: Color(club.logoColor),
                    ink: Color(club.logoInk),
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          club.name,
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                        Text(
                          'You can add players from this club',
                          style: OgText.body(13, color: c.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ],
      );
    },
  );
}

/// Lineup, players (with availability) and staff.
class TeamRosterScreen extends ConsumerStatefulWidget {
  const TeamRosterScreen({super.key, required this.id, this.tab = 'lineup'});

  final String id;
  final String tab;

  @override
  ConsumerState<TeamRosterScreen> createState() => _TeamRosterScreenState();
}

class _TeamRosterScreenState extends ConsumerState<TeamRosterScreen> {
  late int _tab = switch (widget.tab) {
    'players' => 1,
    'staff' => 2,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) => _WithTeam(
    id: widget.id,
    title: 'Roster',
    body: (team) {
      final c = context.og;
      final t = context.tones;
      final members = ref.watch(teamMembersProvider(widget.id)).value;
      final nextId = ref.watch(nextFixtureIdProvider(widget.id)).value;
      final fixture = nextId == null
          ? null
          : ref.watch(fixtureProvider(nextId)).value;
      final byId = {
        for (final m in members ?? const <TeamMember>[]) m.player.id: m,
      };
      final players = (members ?? const <TeamMember>[])
          .where((m) => !m.staff)
          .toList();
      final staff = (members ?? const <TeamMember>[])
          .where((m) => m.staff)
          .toList();
      Widget person(TeamMember m, String sub, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            SolidAvatar.forId(
              m.player.id,
              initials: m.player.initials,
              size: 40,
              fontSize: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.player.displayName,
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                      ),
                      if (m.captain != null) ...[
                        const SizedBox(width: 6),
                        KitTag(
                          m.captain!,
                          height: 20,
                          fontSize: 10,
                          background: t.gold,
                          foreground: t.onGold,
                        ),
                      ],
                    ],
                  ),
                  Text(sub, style: OgText.body(13, color: c.textMuted)),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      );
      String level(TeamMember m) => m.rating == null
          ? ''
          : '${m.band!.code} ${m.rating!.toStringAsFixed(1)}';
      return KitScaffold(
        header: KitHeader(
          title: 'Roster',
          subtitle: '${team.name} · ${team.sport.label}',
        ),
        bottom: team.isStaff && _tab == 1
            ? [
                KitButton(
                  label: 'Add players from linked clubs',
                  icon: OgIcons.plus,
                  onPressed: () => context.push(Routes.teamAdd(widget.id)),
                ),
              ]
            : null,
        children: [
          KitUnderlineTabs(
            labels: const ['Lineup', 'Players', 'Staff'],
            selected: _tab,
            spread: true,
            padding: EdgeInsets.zero,
            onSelect: (i) => setState(() => _tab = i),
          ),
          if (members == null)
            const CupertinoActivityIndicator()
          else
            ...switch (_tab) {
              0 =>
                fixture == null
                    ? [
                        const KitNote(
                          'No fixture coming up, so there is no lineup yet.',
                        ),
                      ]
                    : [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'vs ${fixture.opponent} · ${Fmt.day(fixture.startsAt)}',
                                    style: OgText.heading(18),
                                  ),
                                  if (fixture.lineupLocksAt != null)
                                    Text(
                                      'Locks ${Fmt.dayTimeComma(fixture.lineupLocksAt!)} · then only staff can change it',
                                      style: OgText.body(
                                        13,
                                        color: c.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            if (team.isStaff)
                              KitLink(
                                'Edit',
                                onPressed: () => context.push(
                                  Routes.teamLineup(widget.id, fixture.id),
                                ),
                              ),
                          ],
                        ),
                        KitCard(
                          children: [
                            for (final s in fixture.slots.where(
                              (s) => !s.isReserve,
                            ))
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      s.label.toUpperCase(),
                                      style: OgText.body(
                                        11,
                                        weight: FontWeight.w800,
                                        color: c.textMuted,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                    for (final id
                                        in fixture.lineup[s.key] ??
                                            const <String?>[])
                                      Text(
                                        id == null
                                            ? 'Open'
                                            : (byId[id]?.player.displayName ??
                                                  'Player'),
                                        style: OgText.body(
                                          15,
                                          weight: FontWeight.w700,
                                          color: id == null
                                              ? c.textMuted
                                              : c.text,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (fixture.slots.any((s) => s.isReserve)) ...[
                          Text('Reserves', style: OgText.heading(18)),
                          KitCard(
                            children: [
                              for (final s in fixture.slots.where(
                                (s) => s.isReserve,
                              ))
                                for (final id
                                    in fixture.lineup[s.key] ??
                                        const <String?>[])
                                  if (id != null && byId[id] != null)
                                    person(byId[id]!, level(byId[id]!)),
                            ],
                          ),
                        ],
                      ],
              1 => [
                Text(
                  '${players.length} players${fixture == null ? '' : ' · availability for ${Fmt.day(fixture.startsAt)}'}',
                  style: OgText.body(14, weight: FontWeight.w700),
                ),
                KitCard(
                  children: [
                    for (final m in players)
                      person(
                        m,
                        [
                          level(m),
                          if (m.club.isNotEmpty) 'from ${m.club}',
                          if (m.reserve) 'Reserve',
                        ].where((x) => x.isNotEmpty).join(' · '),
                        trailing: fixture == null
                            ? null
                            : KitTag(
                                m.availability.label,
                                background: switch (m.availability) {
                                  Availability.available => t.successFill,
                                  Availability.unavailable => t.dangerFill,
                                  _ => t.tag,
                                },
                                foreground: switch (m.availability) {
                                  Availability.available => t.onSuccessFill,
                                  Availability.unavailable => t.onDangerFill,
                                  _ => t.onTag,
                                },
                              ),
                      ),
                  ],
                ),
              ],
              _ => [
                KitCard(
                  children: [
                    for (final m in staff)
                      person(m, m.staffTitle.isEmpty ? 'Staff' : m.staffTitle),
                  ],
                ),
                const KitNote(
                  'Staff are in every team chat. Players under 18 can’t be '
                  'messaged privately by adults, and parents can see the roster '
                  'and schedule.',
                ),
              ],
            },
        ],
      );
    },
  );
}

/// Add players from linked clubs, or share an invite link.
class TeamAddPlayersScreen extends ConsumerStatefulWidget {
  const TeamAddPlayersScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TeamAddPlayersScreen> createState() =>
      _TeamAddPlayersScreenState();
}

class _TeamAddPlayersScreenState extends ConsumerState<TeamAddPlayersScreen> {
  int _source = 0;
  String _q = '';
  final _picked = <String>{};
  bool _busy = false;

  Future<void> _send() async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).addTeamPlayers(widget.id, _picked);
      HapticFeedback.mediumImpact();
      refreshTeam(ref.invalidate, widget.id);
      if (!mounted) return;
      showOgToast(
        context,
        '${_picked.length} ${_picked.length == 1 ? 'request' : 'requests'} sent',
      );
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTeam(
    id: widget.id,
    title: 'Add players',
    body: (team) {
      final c = context.og;
      final people = ref.watch(teamCandidatesProvider(widget.id)).value;
      final q = _q.trim().toLowerCase();
      final shown = (people ?? const <InviteCandidate>[])
          .where(
            (p) => q.isEmpty || p.player.displayName.toLowerCase().contains(q),
          )
          .toList();
      final link = Links.teamInvite(team.id);
      final sources = [...team.linkedClubs.map((c) => c.name), 'Invite link'];
      final onLink = _source == sources.length - 1;
      return KitScaffold(
        header: const KitHeader(title: 'Add players'),
        bottom: [
          onLink
              ? KitButton(label: 'Done', onPressed: () => context.pop())
              : KitButton(
                  label: _picked.isEmpty
                      ? 'Pick players to add'
                      : 'Send ${_picked.length} ${_picked.length == 1 ? 'request' : 'requests'}',
                  loading: _busy,
                  onPressed: _picked.isEmpty ? null : _send,
                ),
        ],
        children: [
          if (sources.length > 1)
            KitSegments(
              labels: sources,
              selected: _source,
              fontSize: 13,
              onSelect: (i) => setState(() => _source = i),
            ),
          if (onLink) ...[
            Text(
              'Send this link to players who are not in a linked club. It '
              'works for 7 days.',
              style: OgText.body(14, height: 1.45, color: c.textMuted),
            ),
            KitCard(
              padding: const EdgeInsets.all(14),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      link.replaceFirst('https://', ''),
                      style: OgText.body(15, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: KitButton(
                            label: 'Copy',
                            height: 44,
                            style: KitButtonStyle.outline,
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(text: link),
                              );
                              if (context.mounted) {
                                showOgToast(context, 'Link copied');
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: KitButton(
                            label: 'Share',
                            height: 44,
                            onPressed: () => shareLink(
                              context,
                              'Join ${team.name} on OlympusGO',
                              link,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Text(
              'Anyone with the link sends a request. You approve each one in '
              'the roster.',
              style: OgText.body(13, color: c.textMuted),
            ),
          ] else ...[
            KitSearchField(
              hint: 'Search by name',
              onChanged: (v) => setState(() => _q = v),
            ),
            Text(
              'Players from linked clubs. They get a request and join when they accept.',
              style: OgText.body(13, color: c.textMuted),
            ),
            if (people == null)
              const CupertinoActivityIndicator()
            else if (shown.isEmpty)
              Text(
                'Nothing matches. Check the spelling or clear the search.',
                style: OgText.body(14, color: c.textMuted),
              )
            else
              Column(
                children: [
                  for (final p in shown)
                    KitChoiceRow(
                      leading: SolidAvatar.forId(
                        p.player.id,
                        initials: p.player.initials,
                        size: 40,
                        fontSize: 14,
                      ),
                      title: p.player.displayName,
                      subtitle: [
                        if (p.age.isNotEmpty) p.age,
                        if (p.rating != null) SkillBandCode.of(p.rating!),
                      ].join(' · '),
                      tag: p.rating?.toStringAsFixed(1),
                      multi: true,
                      selected: _picked.contains(p.player.id),
                      onTap: () => setState(() {
                        if (!_picked.remove(p.player.id)) {
                          _picked.add(p.player.id);
                        }
                      }),
                    ),
                ],
              ),
          ],
        ],
      );
    },
  );
}

/// "MI" for a rating.
abstract final class SkillBandCode {
  static const _codes = ['LB', 'MB', 'HB', 'LI', 'MI', 'HI', 'AD', 'PRO'];
  static String of(double rating) => _codes[(rating.floor() - 1).clamp(0, 7)];
}

/// One fixture: can you play, the lineup and what to bring.
class TeamFixtureScreen extends ConsumerWidget {
  const TeamFixtureScreen({
    super.key,
    required this.teamId,
    required this.fixtureId,
  });

  final String teamId;
  final String fixtureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final f = ref.watch(fixtureProvider(fixtureId)).value;
    final members = ref.watch(teamMembersProvider(teamId)).value ?? const [];
    final me = ref.watch(currentUserIdProvider).value;
    if (f == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Fixture'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final names = {for (final m in members) m.player.id: m.player.displayName};
    String who(List<String?> ids) {
      final list = [
        for (final id in ids)
          if (id != null) (id == me ? 'You' : (names[id] ?? 'Player')),
      ];
      return list.isEmpty ? 'Open' : list.join(' and ');
    }

    Future<void> reply(Availability a) async {
      try {
        await ref.read(clubRepositoryProvider).setAvailability(fixtureId, a);
        HapticFeedback.selectionClick();
        refreshTeam(ref.invalidate, teamId);
      } on AuthFailure catch (e) {
        if (context.mounted) showOgToast(context, e.message, error: true);
      }
    }

    return KitScaffold(
      header: const KitHeader(title: 'Fixture'),
      children: [
        if (f.competition.isNotEmpty)
          Text(
            f.competition.toUpperCase(),
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        Text(
          '${f.teamName}\nvs ${f.opponent}',
          style: OgText.heading(26, height: 1.15),
        ),
        Text(
          '${Fmt.dayTimeComma(f.startsAt)}${f.venue.isEmpty ? '' : ' · ${f.venue}'}',
          style: OgText.body(14, color: c.textMuted),
        ),
        Text('Can you play?', style: OgText.heading(20)),
        Column(
          children: [
            for (final a in const [
              Availability.available,
              Availability.maybe,
              Availability.unavailable,
            ])
              KitChoiceRow(
                title: a.label,
                selected: f.myAvailability == a,
                onTap: () => reply(a),
              ),
          ],
        ),
        Text('Lineup', style: OgText.heading(20)),
        if (!f.published)
          const KitNote(
            'The lineup is not published yet. You are told when it is.',
          )
        else
          KitCard(
            children: [
              for (final s in f.slots)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          s.label,
                          style: OgText.body(
                            13,
                            weight: FontWeight.w700,
                            color: c.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          who(f.lineup[s.key] ?? const []),
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        if (f.notes.isNotEmpty) ...[
          Text('Before the day', style: OgText.heading(20)),
          KitCheckList(f.notes),
        ],
        if (f.lineupLocksAt != null)
          KitKeyValue('Lineup locks', Fmt.dayTimeComma(f.lineupLocksAt!)),
        if (f.setBy.isNotEmpty)
          Text(
            '${f.setBy} set the lineup. Tell them in team chat if anything changes.',
            style: OgText.body(13, height: 1.4, color: c.textMuted),
          ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.chatRound,
              title: 'Open team chat',
              onTap: () => context.push(Routes.teamChat(teamId)),
            ),
            if (f.venue.isNotEmpty)
              KitNavTile(
                icon: OgIcons.mapPin,
                title: 'Directions to the venue',
                tile: t.tag,
                onTap: () => launchUrl(
                  Uri.parse(
                    'https://maps.apple.com/?q=${Uri.encodeQueryComponent(f.venue)}',
                  ),
                  mode: LaunchMode.externalApplication,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pick who plays each slot, then publish to the team chat.
class EditLineupScreen extends ConsumerStatefulWidget {
  const EditLineupScreen({
    super.key,
    required this.teamId,
    required this.fixtureId,
  });

  final String teamId;
  final String fixtureId;

  @override
  ConsumerState<EditLineupScreen> createState() => _EditLineupScreenState();
}

class _EditLineupScreenState extends ConsumerState<EditLineupScreen> {
  Map<String, List<String?>>? _lineup;
  bool _busy = false;

  Future<void> _publish() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(clubRepositoryProvider)
          .saveLineup(widget.fixtureId, _lineup!, publish: true);
      HapticFeedback.mediumImpact();
      refreshTeam(ref.invalidate, widget.teamId);
      if (!mounted) return;
      showOgToast(context, 'Published to team chat');
      context.pop();
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pick(
    Fixture f,
    LineupSlot s,
    int index,
    List<TeamMember> members,
  ) async {
    final lineup = _lineup!;
    final used = {
      for (final e in lineup.entries)
        for (final id in e.value)
          if (id != null && !(e.key == s.key)) id,
    };
    final picked = await showKitSheet<String?>(
      context,
      builder: (sheet) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              s.isReserve ? 'Pick reserve' : 'Pick player for ${s.label}',
              style: OgText.heading(22),
            ),
            const SizedBox(height: 4),
            Text(
              s.isReserve
                  ? 'Reserves can’t also be in the lineup.'
                  : 'Players already in another slot are left out.',
              style: OgText.body(13, color: sheet.og.textMuted),
            ),
            const SizedBox(height: 10),
            KitChoiceRow(
              title: 'Leave open',
              selected: lineup[s.key]?[index] == null,
              onTap: () => Navigator.of(sheet).pop(''),
            ),
            for (final m in members.where(
              (m) => !m.staff && !used.contains(m.player.id),
            ))
              KitChoiceRow(
                leading: SolidAvatar.forId(
                  m.player.id,
                  initials: m.player.initials,
                  size: 40,
                  fontSize: 14,
                ),
                title: m.player.displayName,
                subtitle: [
                  if (m.rating != null)
                    '${m.band!.code} ${m.rating!.toStringAsFixed(1)}',
                  m.availability.label,
                ].join(' · '),
                selected: lineup[s.key]?[index] == m.player.id,
                onTap: () => Navigator.of(sheet).pop(m.player.id),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() {
      final row = [...?lineup[s.key]];
      while (row.length < s.size) {
        row.add(null);
      }
      row[index] = picked.isEmpty ? null : picked;
      lineup[s.key] = row;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final f = ref.watch(fixtureProvider(widget.fixtureId)).value;
    final members = ref.watch(teamMembersProvider(widget.teamId)).value;
    if (f == null || members == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Edit lineup'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final lineup = _lineup ??= {
      for (final s in f.slots) s.key: [...?f.lineup[s.key]],
    };
    final byId = {for (final m in members) m.player.id: m};
    final filled = f.slots
        .where((s) => !s.isReserve)
        .every(
          (s) =>
              (lineup[s.key] ?? const []).where((id) => id != null).length ==
              s.size,
        );
    return KitScaffold(
      header: KitHeader(
        title: 'Edit lineup',
        subtitle: 'vs ${f.opponent} · ${Fmt.day(f.startsAt)}',
      ),
      bottom: [
        KitButton(label: 'Publish lineup', loading: _busy, onPressed: _publish),
      ],
      children: [
        Text(
          [
            if (f.lineupLocksAt != null)
              'Locks ${Fmt.dayTimeComma(f.lineupLocksAt!)}',
            filled ? 'Every slot is filled.' : 'Some slots are still open.',
          ].join('. '),
          style: OgText.body(14, color: c.textMuted),
        ),
        if (f.lineupRule.isNotEmpty)
          KitNote(
            'Lineup rules: ${f.lineupRule}${f.setBy.isEmpty ? '' : '. Set by ${f.setBy}.'}',
          ),
        for (final s in f.slots)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(s.label, style: OgText.body(15, weight: FontWeight.w700)),
              const SizedBox(height: 6),
              for (var i = 0; i < s.size; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Pressable(
                    semanticLabel: '${s.label}, slot ${i + 1}',
                    onPressed: () => _pick(f, s, i, members),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.borderControl, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              () {
                                final id =
                                    (lineup[s.key] ?? const []).length > i
                                    ? lineup[s.key]![i]
                                    : null;
                                return id == null
                                    ? (s.isReserve
                                          ? 'Pick reserve'
                                          : 'Pick player')
                                    : (byId[id]?.player.displayName ??
                                          'Player');
                              }(),
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                          ),
                          OgIcon(
                            OgIcons.chevronDown,
                            size: 18,
                            color: c.textMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        Text(
          'Players are told and it is posted in the team chat.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
    );
  }
}

/// Leave a team.
class TeamLeaveScreen extends ConsumerStatefulWidget {
  const TeamLeaveScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TeamLeaveScreen> createState() => _TeamLeaveScreenState();
}

class _TeamLeaveScreenState extends ConsumerState<TeamLeaveScreen> {
  bool _understood = false;
  bool _busy = false;

  Future<void> _leave(Team team) async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).leaveTeam(widget.id);
      HapticFeedback.mediumImpact();
      ref.invalidate(teamListProvider);
      if (!mounted) return;
      showOgToast(context, 'You left ${team.name}');
      context.go(Routes.clubsTab(teams: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTeam(
    id: widget.id,
    title: 'Leave team',
    body: (team) {
      final nextId = ref.watch(nextFixtureIdProvider(widget.id)).value;
      final f = nextId == null
          ? null
          : ref.watch(fixtureProvider(nextId)).value;
      final me = ref.watch(currentUserIdProvider).value;
      final inLineup =
          f != null && f.lineup.values.any((ids) => ids.contains(me));
      return KitScaffold(
        header: const KitHeader(title: 'Leave team'),
        bottom: [
          KitButton(
            label: 'Leave team',
            style: KitButtonStyle.danger,
            loading: _busy,
            onPressed: inLineup && !_understood ? null : () => _leave(team),
          ),
          KitButton(
            label: 'Stay in team',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitTitle(
            'Leave ${team.name}?',
            lead: 'A coach or manager can add you again.',
          ),
          Text('You keep', style: OgText.heading(20)),
          const KitCheckList([
            'Your match results and rating',
            'Your Passport history',
          ]),
          Text('You lose', style: OgText.heading(20)),
          KitCheckList([
            if (inLineup)
              'Your place in the lineup for ${Fmt.day(f.startsAt)}. The coach is told.',
            'Team chat and the fixture schedule',
          ], crossed: true),
          if (inLineup)
            KitConfirmBox(
              label: 'I understand I come out of the lineup',
              checked: _understood,
              onChanged: (v) => setState(() => _understood = v),
            ),
        ],
      );
    },
  );
}

/// Delete a team, typing its name to confirm.
class TeamDeleteScreen extends ConsumerStatefulWidget {
  const TeamDeleteScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<TeamDeleteScreen> createState() => _TeamDeleteScreenState();
}

class _TeamDeleteScreenState extends ConsumerState<TeamDeleteScreen> {
  final _name = TextEditingController();
  bool _understood = false;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _delete(Team team) async {
    setState(() => _busy = true);
    try {
      await ref.read(clubRepositoryProvider).deleteTeam(widget.id);
      HapticFeedback.mediumImpact();
      ref.invalidate(teamListProvider);
      if (!mounted) return;
      showOgToast(context, '${team.name} deleted');
      context.go(Routes.clubsTab(teams: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTeam(
    id: widget.id,
    title: 'Delete team',
    body: (team) {
      final fixtures =
          ref
              .watch(teamSessionsProvider(widget.id))
              .value
              ?.where((s) => s.fixture)
              .length ??
          0;
      return KitScaffold(
        header: const KitHeader(title: 'Delete team'),
        bottom: [
          ListenableBuilder(
            listenable: _name,
            builder: (context, _) => KitButton(
              label: 'Delete team',
              style: KitButtonStyle.danger,
              loading: _busy,
              onPressed: _understood && _name.text.trim() == team.name
                  ? () => _delete(team)
                  : null,
            ),
          ),
          KitButton(
            label: 'Cancel',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitTitle(
            'Delete ${team.name}?',
            lead:
                'This cannot be undone. All ${team.playerCount} players and ${team.staffCount} staff are told.',
          ),
          Text('What is removed', style: OgText.heading(20)),
          KitCheckList([
            'The roster, lineups and sub-teams',
            '$fixtures upcoming ${fixtures == 1 ? 'fixture' : 'fixtures'}',
            'Team chat, photos and files',
          ], crossed: true),
          const KitNote(
            'Players keep their own results, ratings and Passport history.',
          ),
          KitInput(
            label: 'Type the team name to confirm',
            controller: _name,
            hint: team.name,
          ),
          KitConfirmBox(
            label: 'I understand this deletes the team for everyone',
            checked: _understood,
            onChanged: (v) => setState(() => _understood = v),
          ),
        ],
      );
    },
  );
}
