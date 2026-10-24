import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/presentation/play_screen.dart' show BandRangePicker;
import '../application/club_providers.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';

/// Header for a create step: title, "Step n of m" and a progress bar.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.title,
    required this.step,
    required this.of,
    this.close = false,
  });

  final String title;
  final int step;
  final int of;
  final bool close;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          KitHeader(
            title: title,
            subtitle: 'Step $step of $of',
            lead: close ? KitLead.close : KitLead.back,
            titleSize: 19,
            border: false,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
            child: Row(
              children: [
                for (var i = 1; i <= of; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: i <= step ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A titled block of a create step.
class _Group extends StatelessWidget {
  const _Group(this.title, {required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: kitSpaced([
      Text(title, style: OgText.body(15, weight: FontWeight.w700)),
      ...children,
    ], 12),
  );
}

/// Next button that explains what is missing while it is off.
List<Widget> _next(String label, VoidCallback? onNext, {String? missing}) => [
  KitButton(label: label, radius: 27, onPressed: onNext),
  if (onNext == null && missing != null)
    Builder(
      builder: (context) => Text(
        missing,
        textAlign: TextAlign.center,
        style: OgText.body(13, color: context.og.textMuted),
      ),
    ),
];

/// Leaves the create flow for [route]. `go` replaces the whole stack, so the
/// flow's steps can't be reached with Back; Back from there goes Home.
void _finish(BuildContext context, String route) => context.go(route);

// ─── What are you starting? ────────────────────────────────────────────────

class CreateGroupTypeScreen extends ConsumerWidget {
  const CreateGroupTypeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    Widget card({
      required String title,
      required String sub,
      required Color color,
      required String icon,
      required List<String> points,
      required VoidCallback onTap,
    }) => Pressable(
      semanticLabel: '$title. $sub',
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: OgIcon(icon, size: 30, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: OgText.heading(28)),
                      Text(sub, style: OgText.body(14, color: c.textMuted)),
                    ],
                  ),
                ),
                OgIcon(OgIcons.chevronRight, size: 20, color: c.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            for (final p in points)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    OgIcon(
                      OgIcons.tick,
                      size: 16,
                      strokeWidth: 2.4,
                      color: c.link,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: OgText.body(14))),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
    return KitScaffold(
      header: const KitHeader(title: 'Create', lead: KitLead.close),
      gap: 14,
      children: [
        Text('What are you starting?', style: OgText.heading(30)),
        card(
          title: 'Club',
          sub: 'Open community for regular play',
          color: const Color(0xFF0E6B4E),
          icon: OgIcons.group,
          points: const [
            'Anyone at the right level can join',
            'Meets, tournaments, events and club chat',
            'Roles for admins and organizers',
          ],
          onTap: () {
            ref.read(clubDraftControllerProvider.notifier).reset();
            context.push(Routes.newClub);
          },
        ),
        card(
          title: 'Team',
          sub: 'Fixed squad that plays fixtures',
          color: const Color(0xFF2F3A5F),
          icon: OgIcons.shieldPlain,
          points: const [
            'Private, invite only',
            'Lineups, fixtures and results',
            'Optional sub-teams by age group',
          ],
          onTap: () {
            ref.read(teamDraftControllerProvider.notifier).reset();
            context.push(Routes.newTeam);
          },
        ),
        Text(
          'You can run both. Meets, tournaments and events are hosted by a '
          'club. A team can pick its players from your clubs.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

// ─── Club 1: details ───────────────────────────────────────────────────────

class NewClubScreen extends ConsumerWidget {
  const NewClubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(clubDraftControllerProvider);
    final draft = ref.read(clubDraftControllerProvider.notifier);
    final gaps = [
      if (d.name.trim().isEmpty) 'a club name',
      if (d.venueId == null) 'a home venue',
    ];
    Widget choice(String title, String desc, bool on, VoidCallback onTap) =>
        KitChoiceRow(title: title, subtitle: desc, selected: on, onTap: onTap);
    return KitScaffold(
      header: const _StepHeader(
        title: 'Your club',
        step: 1,
        of: 4,
        close: true,
      ),
      bottom: _next(
        'Next',
        gaps.isEmpty ? () => context.push(Routes.newClubSports) : null,
        missing: 'Add ${gaps.join(' and ')} to continue.',
      ),
      children: [
        KitInput(
          label: 'Club name',
          hint: 'e.g. Tampines Smashers',
          initialValue: d.name,
          maxLength: 50,
          counter: true,
          onChanged: (v) => draft.edit((x) => x.copyWith(name: v)),
        ),
        KitTextArea(
          label: 'Club description',
          optional: true,
          hint: 'Who the club is for, when you play and what to expect.',
          lines: 4,
          initialValue: d.description,
          onChanged: (v) => draft.edit((x) => x.copyWith(description: v)),
        ),
        _Group(
          'Where does your club play?',
          children: [
            if (d.venueId == null)
              KitButton.outline(
                label: 'Select home venue',
                onPressed: () => context.push(Routes.newClubVenue),
              )
            else
              Container(
                padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: OgColors.tangerineLine, width: 2),
                ),
                child: Row(
                  children: [
                    OgIcon(OgIcons.mapPin, size: 20, color: c.text),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.venueName ?? '',
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          Text(
                            'Area: ${d.area}',
                            style: OgText.body(13, color: c.textMuted),
                          ),
                        ],
                      ),
                    ),
                    KitLink(
                      'Change',
                      onPressed: () => context.push(Routes.newClubVenue),
                    ),
                  ],
                ),
              ),
            Text(
              "Players nearby find your club by area, and it sets your club's "
              'Local leaderboard.',
              style: OgText.body(13, height: 1.45, color: c.textMuted),
            ),
          ],
        ),
        _Group(
          'Club visibility',
          children: [
            choice(
              'Public club',
              'Anyone can find the club and see its Meets, members and leaderboard.',
              d.visibility == ClubVisibility.public,
              () => draft.edit(
                (x) => x.copyWith(visibility: ClubVisibility.public),
              ),
            ),
            choice(
              'Private club',
              'Anyone can find the club, but only members can see inside.',
              d.visibility == ClubVisibility.private,
              () => draft.edit(
                (x) => x.copyWith(visibility: ClubVisibility.private),
              ),
            ),
            choice(
              'Hidden club',
              "The club can't be found in search. Only members can see inside.",
              d.visibility == ClubVisibility.hidden,
              () => draft.edit(
                (x) => x.copyWith(visibility: ClubVisibility.hidden),
              ),
            ),
          ],
        ),
        _Group(
          'Join preference',
          children: [
            if (d.visibility == ClubVisibility.public) ...[
              choice(
                'Anyone can join',
                'Players join straight away.',
                d.joinMode == JoinMode.anyone,
                () => draft.edit((x) => x.copyWith(joinMode: JoinMode.anyone)),
              ),
              choice(
                'Request to join',
                'Joining needs admin approval.',
                d.joinMode == JoinMode.request,
                () => draft.edit((x) => x.copyWith(joinMode: JoinMode.request)),
              ),
            ] else
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.softer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  d.visibility == ClubVisibility.private
                      ? 'Request to join. Private clubs always need an admin to approve new members.'
                      : 'Invite only. Hidden clubs can only be joined with an invite link.',
                  style: OgText.body(14, height: 1.45, color: t.onTag),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Club 2: sports ────────────────────────────────────────────────────────

class NewClubSportsScreen extends ConsumerWidget {
  const NewClubSportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final d = ref.watch(clubDraftControllerProvider);
    final draft = ref.read(clubDraftControllerProvider.notifier);
    final full = d.sports.length >= 3;
    return KitScaffold(
      header: const _StepHeader(title: 'Sport interest', step: 2, of: 4),
      bottom: _next(
        'Next',
        d.sports.isEmpty ? null : () => context.push(Routes.newClubLevels),
        missing: 'Pick at least one sport to continue.',
      ),
      gap: 16,
      children: [
        KitTitle(
          'What does your club play?',
          size: 24,
          lead: 'Pick up to 3. The first one is your primary sport, shown on your club card.',
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${d.sports.length}/3 selected',
            style: OgText.body(13, weight: FontWeight.w600, color: c.textMuted),
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final s in ClubSport.values)
              _SportCard(
                sport: s,
                on: d.sports.contains(s),
                primary: d.sports.firstOrNull == s,
                off: full && !d.sports.contains(s),
                onTap: () {
                  HapticFeedback.selectionClick();
                  draft.edit(
                    (x) => x.copyWith(
                      sports: x.sports.contains(s)
                          ? ([...x.sports]..remove(s))
                          : [...x.sports, s],
                    ),
                  );
                },
              ),
          ],
        ),
        Text(
          'Each sport gets its own ratings and leaderboard. Tap a picked '
          'sport to remove it; the next one becomes primary.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

class _SportCard extends StatelessWidget {
  const _SportCard({
    required this.sport,
    required this.on,
    required this.onTap,
    this.primary = false,
    this.off = false,
  });

  final ClubSport sport;
  final bool on;
  final bool primary;
  final bool off;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Opacity(
      opacity: off ? 0.5 : 1,
      child: Pressable(
        semanticLabel: '${sport.label}${primary ? ', primary' : ''}',
        selected: on,
        onPressed: off ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: off ? t.soft : c.bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: on ? OgColors.tangerineLine : c.borderControl,
              width: on ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: on ? c.primary : t.soft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: OgIcon(
                      sport.icon,
                      size: 24,
                      strokeWidth: 1.9,
                      color: on ? c.onPrimary : c.text,
                    ),
                  ),
                  const Spacer(),
                  if (primary)
                    KitTag(
                      'Primary',
                      height: 20,
                      fontSize: 11,
                      background: t.gold,
                      foreground: t.onGold,
                    ),
                ],
              ),
              const Spacer(),
              Text(
                sport.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OgText.body(16, weight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Club 3: levels ────────────────────────────────────────────────────────

class NewClubLevelsScreen extends ConsumerWidget {
  const NewClubLevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final d = ref.watch(clubDraftControllerProvider);
    final draft = ref.read(clubDraftControllerProvider.notifier);
    void set(ClubSport s, LevelRange r) =>
        draft.edit((x) => x.copyWith(ranges: {...x.ranges, s: r}));
    return KitScaffold(
      header: const _StepHeader(title: 'Skill level', step: 3, of: 4),
      bottom: _next('Next', () => context.push(Routes.newClubInvite)),
      gap: 16,
      children: [
        KitTitle(
          'Who is your club for?',
          size: 24,
          lead:
              'Set the lowest and highest level for each sport. Players '
              'outside the range can still ask to join; admins see a warning.',
        ),
        for (final s in d.sports)
          Builder(
            builder: (context) {
              final r = d.ranges[s] ?? const LevelRange.all();
              final on = d.ranges.containsKey(s);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.label,
                            style: OgText.body(17, weight: FontWeight.w700),
                          ),
                        ),
                        if (s == d.sports.first) ...[
                          KitTag(
                            'Primary',
                            background: t.gold,
                            foreground: t.onGold,
                          ),
                          const SizedBox(width: 8),
                        ],
                        KitTag(
                          r.label,
                          background: t.successFill,
                          foreground: t.onSuccessFill,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SwitchRow(
                      title: 'Set a level range',
                      subtitle: on
                          ? 'Only players in this range can join'
                          : 'Off: open to all levels',
                      compact: true,
                      value: on,
                      // On starts at Low to High Intermediate; off clears it.
                      onChanged: (v) => v
                          ? set(s, const LevelRange(3, 5))
                          : draft.edit(
                              (x) =>
                                  x.copyWith(ranges: {...x.ranges}..remove(s)),
                            ),
                    ),
                    if (on) ...[
                      const SizedBox(height: 8),
                      BandRangePicker(
                        lo: r.min,
                        hi: r.max,
                        onChanged: (lo, hi) => set(s, LevelRange(lo, hi)),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        Text(
          'New Meets start with this range. Organizers can narrow it for a '
          'single Meet.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

// ─── Club 4: invite ────────────────────────────────────────────────────────

class NewClubInviteScreen extends ConsumerStatefulWidget {
  const NewClubInviteScreen({super.key});

  @override
  ConsumerState<NewClubInviteScreen> createState() =>
      _NewClubInviteScreenState();
}

class _NewClubInviteScreenState extends ConsumerState<NewClubInviteScreen> {
  String _q = '';
  bool _busy = false;

  Future<void> _create({required bool invite}) async {
    final draft = ref.read(clubDraftControllerProvider.notifier);
    if (!invite) draft.edit((x) => x.copyWith(invite: const {}));
    setState(() => _busy = true);
    try {
      final id = await draft.create();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showOgToast(context, 'Club created');
      _finish(context, Routes.club(id));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final d = ref.watch(clubDraftControllerProvider);
    final draft = ref.read(clubDraftControllerProvider.notifier);
    final people = ref.watch(inviteCandidatesProvider).value ?? const [];
    final q = _q.trim().toLowerCase();
    final shown = people
        .where(
          (p) => q.isEmpty || p.player.displayName.toLowerCase().contains(q),
        )
        .toList();
    final n = d.invite.length;
    return KitScaffold(
      header: const _StepHeader(title: 'Invite members', step: 4, of: 4),
      bottom: [
        KitButton(
          label: n > 0 ? 'Create club and invite $n' : 'Create club',
          radius: 27,
          loading: _busy,
          onPressed: () => _create(invite: true),
        ),
        if (n > 0)
          KitButton.outline(
            label: 'Skip for now',
            radius: 27,
            onPressed: _busy ? null : () => _create(invite: false),
          ),
      ],
      gap: 14,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Players you've played with",
                style: OgText.body(15, weight: FontWeight.w700),
              ),
            ),
            Text('$n selected', style: OgText.body(13, color: c.textMuted)),
          ],
        ),
        KitSearchField(
          hint: 'Search by name or username',
          soft: true,
          onChanged: (v) => setState(() => _q = v),
        ),
        if (shown.isEmpty)
          Text(
            people.isEmpty
                ? 'No one yet. Share your invite link from the club page after you create it.'
                : 'Nobody matches. Check the spelling or clear the search.',
            style: OgText.body(14, color: c.textMuted),
          ),
        for (final p in shown)
          _PersonRow(
            candidate: p,
            meta: [
              if (p.rating != null) SkillBand.forLevel(p.rating!).code,
              '${p.meetsTogether} ${p.meetsTogether == 1 ? 'Meet' : 'Meets'} together',
            ].join(' · '),
            on: d.invite.contains(p.player.id),
            verb: 'Invite',
            onTap: () => draft.edit(
              (x) => x.copyWith(
                invite: x.invite.contains(p.player.id)
                    ? ({...x.invite}..remove(p.player.id))
                    : {...x.invite, p.player.id},
              ),
            ),
          ),
        Text(
          'After you create the club, share its invite link or QR code from '
          'the club page.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.candidate,
    required this.meta,
    required this.on,
    required this.verb,
    required this.onTap,
  });

  final InviteCandidate candidate;
  final String meta;
  final bool on;
  final String verb;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final p = candidate.player;
    return Pressable(
      semanticLabel: '$verb ${p.displayName}. $meta',
      selected: on,
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            SolidAvatar.forId(
              p.id,
              initials: p.initials,
              size: 42,
              fontSize: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.displayName,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  Text(meta, style: OgText.body(13, color: c.textMuted)),
                ],
              ),
            ),
            KitTickBox(on: on, multi: true),
          ],
        ),
      ),
    );
  }
}

// ─── Team 1: details ───────────────────────────────────────────────────────

const _subTeams = [
  ('Under 13', 'Born 2014 or later'),
  ('Under 15', 'Born 2012 or later'),
  ('Under 17', 'Born 2010 or later'),
  ('Open', 'Any age'),
];

class NewTeamScreen extends ConsumerWidget {
  const NewTeamScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final d = ref.watch(teamDraftControllerProvider);
    final draft = ref.read(teamDraftControllerProvider.notifier);
    return KitScaffold(
      header: const _StepHeader(title: 'New team', step: 1, of: 3, close: true),
      bottom: _next(
        'Next',
        d.name.trim().isEmpty ? null : () => context.push(Routes.newTeamSport),
        missing: 'Add a team name to continue.',
      ),
      children: [
        KitNote(
          'Teams are private. Only players and staff you add can see the '
          'team, its schedule and its chat.',
        ),
        KitInput(
          label: 'Team name',
          hint: 'e.g. School Team A',
          initialValue: d.name,
          maxLength: 50,
          onChanged: (v) => draft.edit((x) => x.copyWith(name: v)),
        ),
        KitInput(
          label: 'Who does the team represent?',
          hint: 'e.g. your school, company or club',
          initialValue: d.represents,
          onChanged: (v) => draft.edit((x) => x.copyWith(represents: v)),
        ),
        _Group(
          'Sub-teams',
          children: [
            Text(
              'Optional. Split the team by age group. Each sub-team gets its '
              'own roster, lineup and fixtures.',
              style: OgText.body(13, height: 1.45, color: c.textMuted),
            ),
            for (final (name, rule) in _subTeams)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: OgText.body(15, weight: FontWeight.w700),
                        ),
                        Text(rule, style: OgText.body(13, color: c.textMuted)),
                      ],
                    ),
                  ),
                  KitChip(
                    label: d.subTeams.contains(name) ? 'Added' : 'Add',
                    height: 44,
                    selected: d.subTeams.contains(name),
                    onTap: () => draft.edit(
                      (x) => x.copyWith(
                        subTeams: x.subTeams.contains(name)
                            ? ({...x.subTeams}..remove(name))
                            : {...x.subTeams, name},
                      ),
                    ),
                  ),
                ],
              ),
            KitInput(
              label: 'Your own sub-team',
              hint: 'e.g. Girls Under 15',
              initialValue: d.ownSubTeam,
              onChanged: (v) => draft.edit((x) => x.copyWith(ownSubTeam: v)),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Team 2: sport ─────────────────────────────────────────────────────────

class NewTeamSportScreen extends ConsumerWidget {
  const NewTeamSportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(teamDraftControllerProvider);
    final draft = ref.read(teamDraftControllerProvider.notifier);
    return KitScaffold(
      header: const _StepHeader(title: 'New team', step: 2, of: 3),
      bottom: _next('Next', () => context.push(Routes.newTeamMembers)),
      gap: 16,
      children: [
        KitTitle(
          'Which sport does the team play?',
          size: 24,
          lead:
              'A team plays one sport. Its lineup positions and results '
              'follow that sport.',
        ),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (final s in ClubSport.values)
              _SportCard(
                sport: s,
                on: d.sport == s,
                onTap: () => draft.edit((x) => x.copyWith(sport: s)),
              ),
          ],
        ),
      ],
    );
  }
}

// ─── Team 3: players ───────────────────────────────────────────────────────

class NewTeamMembersScreen extends ConsumerStatefulWidget {
  const NewTeamMembersScreen({super.key});

  @override
  ConsumerState<NewTeamMembersScreen> createState() =>
      _NewTeamMembersScreenState();
}

class _NewTeamMembersScreenState extends ConsumerState<NewTeamMembersScreen> {
  String _q = '';
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    try {
      await ref.read(teamDraftControllerProvider.notifier).create();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      showOgToast(context, 'Team created');
      // shortcut: team pages are not rebuilt yet, so land on the Teams list.
      _finish(context, Routes.clubsTab(teams: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final d = ref.watch(teamDraftControllerProvider);
    final draft = ref.read(teamDraftControllerProvider.notifier);
    final people = ref.watch(inviteCandidatesProvider).value ?? const [];
    final q = _q.trim().toLowerCase();
    final shown = people
        .where(
          (p) => q.isEmpty || p.player.displayName.toLowerCase().contains(q),
        )
        .toList();
    final n = d.players.length;
    return KitScaffold(
      header: const _StepHeader(title: 'Players and staff', step: 3, of: 3),
      bottom: [
        KitButton(
          label: n > 0 ? 'Create team and invite $n' : 'Create team',
          radius: 27,
          loading: _busy,
          onPressed: _create,
        ),
      ],
      gap: 14,
      children: [
        Text('Staff', style: OgText.body(15, weight: FontWeight.w700)),
        Text(
          'You: head coach · team owner. Add coaches and managers later from '
          'the team settings.',
          style: OgText.body(14, color: c.textMuted),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                'Players',
                style: OgText.body(15, weight: FontWeight.w700),
              ),
            ),
            Text('$n selected', style: OgText.body(13, color: c.textMuted)),
          ],
        ),
        KitSearchField(
          hint: 'Search players',
          soft: true,
          onChanged: (v) => setState(() => _q = v),
        ),
        if (shown.isEmpty)
          Text(
            'Nobody matches. Check the spelling or clear the search.',
            style: OgText.body(14, color: c.textMuted),
          ),
        for (final p in shown)
          _PersonRow(
            candidate: p,
            meta: p.rating == null
                ? 'Played with you'
                : SkillBand.forLevel(p.rating!).code,
            on: d.players.contains(p.player.id),
            verb: 'Add',
            onTap: () => draft.edit(
              (x) => x.copyWith(
                players: x.players.contains(p.player.id)
                    ? ({...x.players}..remove(p.player.id))
                    : {...x.players, p.player.id},
              ),
            ),
          ),
        Text(
          'Players get an invite and join once they accept. For U-age teams, '
          'a parent confirms too. Set captain and lineup positions later.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}
