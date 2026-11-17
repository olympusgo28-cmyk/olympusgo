import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/domain/country.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/format.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/data/club_repository.dart';
import '../../home/home_rows.dart' show StatusScrim;
import '../../onboarding/domain/sport.dart';
import '../../play/application/play_providers.dart';
import '../../play/domain/activity.dart';
import '../../settings/application/settings_providers.dart';
import '../../social/application/social_providers.dart';
import '../domain/passport.dart';
import '../domain/profile.dart';
import 'passport_card.dart';
import 'passport_history_screen.dart';

/// The player's Passport: hero card, sport switcher and four tabs.
class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key, this.initialSport});

  /// Opens on this sport (a sport id) when the player has it, from a sport
  /// row on the Sport Passport.
  final String? initialSport;

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  int _sport = 0;
  bool _startedOnSport = false;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final mq = MediaQuery.of(context);
    final profile = ref.watch(sessionProfileProvider).value;
    final mine = ref.watch(mySportsProvider).value ?? const <PlayerSport>[];
    // The main sports, at most five: the first five on the Passport. A sport
    // opened from the Sport Passport list that is not among them takes the
    // fifth place.
    final sports = [...mine.take(5)];
    final opened = mine.indexWhere((s) => s.sport == widget.initialSport);
    if (opened >= 5) sports[4] = mine[opened];
    // Once the sports arrive, start on the one the player tapped.
    if (!_startedOnSport && sports.isNotEmpty) {
      _startedOnSport = true;
      final i = sports.indexWhere((s) => s.sport == widget.initialSport);
      if (i >= 0) _sport = i;
    }
    final info = ref.watch(privateInfoProvider).value;
    final social = ref.watch(mySocialProvider).value;
    final current = sports.isEmpty
        ? null
        : sports[math.min(_sport, sports.length - 1)];
    final sport = current == null
        ? Sport.badminton
        : Sport.fromId(current.sport);
    final demo = !Env.hasSupabase;
    final stats = demo ? DemoPassport.stats(sport.id) : null;

    final age = info?.birthday == null ? null : _age(info!.birthday!);
    final summary = ref.watch(mySummaryProvider).value;
    final heroHeight = mq.padding.top + 176;
    return Scaffold(
      backgroundColor: c.bg,
      // The hero is dark, so the status bar's icons are light until the hero
      // has scrolled away; then a page-coloured band sits behind the clock.
      body: StatusScrim(
        after: heroHeight - mq.padding.top - 20,
        darkHero: true,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              // The personal card overlaps the hero's bottom 56 points.
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: heroHeight,
                    child: _HeroBanner(top: mq.padding.top),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: heroHeight - 56),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _PersonalCard(
                          profile: profile,
                          country: info?.country ?? Country.singapore,
                          age: age,
                          rank: summary?.localRank,
                          area: summary?.area,
                          bestDoublesRank: summary?.bestDoublesRank,
                          bestDoublesPartner: summary?.bestDoublesPartner,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The main sports and the tabs for the one selected.
            SliverToBoxAdapter(
              child: _SportTabs(
                sports: sports.map((s) => Sport.fromId(s.sport)).toList(),
                sportIndex: math.min(_sport, math.max(0, sports.length - 1)),
                tab: _tab,
                onSport: (i) => setState(() => _sport = i),
                onTab: (i) => setState(() => _tab = i),
                colors: c,
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, mq.padding.bottom + 32),
              sliver: SliverList.list(
                children: switch (_tab) {
                  0 => _overview(context, current, stats, demo),
                  1 => _gear(
                    context,
                    demo ? DemoPassport.gear(sport.id) : const [],
                    sport,
                  ),
                  2 => _upcoming(
                    context,
                    demo
                        ? DemoPassport.upcoming
                        : [
                            for (final a
                                in ref.watch(myScheduleProvider).value ??
                                    const <Activity>[])
                              UpcomingGame(
                                when: Fmt.dayTime(a.startsAt),
                                title: a.title,
                                place: a.venue.name,
                                waitlist: a.myStatus == MyStatus.waitlist,
                              ),
                          ],
                  ),
                  _ => _challenges(context, social?.followers ?? 0),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static int _age(DateTime b) {
    final now = DateTime.now();
    var years = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      years--;
    }
    return years;
  }

  Widget _title(
    String text, {
    String? trailing,
    Widget? action,
    double top = 20,
  }) {
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: context.type.section),
            ),
          ),
          if (trailing != null) Text(trailing, style: context.type.secondary),
          ?action,
        ],
      ),
    );
  }

  List<Widget> _overview(
    BuildContext context,
    PlayerSport? level,
    PassportStats? s,
    bool demo,
  ) {
    final c = context.og;
    final summary = ref.watch(mySummaryProvider).value;
    final mine = ref.watch(mySportsProvider).value ?? const <PlayerSport>[];
    final clubs = ref.watch(clubListProvider(ClubTab.mine)).value ?? const [];
    return [
      const SizedBox(height: 12),
      // The Passport card moved here from Profile (owner, 16 Nov 2026).
      if (level != null) ...[
        PassportCard(
          sport: level,
          sessions: summary?.sessions ?? 0,
          clubRank: summary?.clubRank,
          clubs: clubs.length,
          localRank: summary?.localRank,
          area: summary?.area,
          isMainSport: mine.isNotEmpty && mine.first.sport == level.sport,
        ),
        const SizedBox(height: 12),
      ],
      KitCard(
        children: [
          KitNavTile(
            icon: OgIcons.clipboardList,
            title: 'Sessions and rating history',
            subtitle: 'Every Meet, tournament and class, with results',
            onTap: () => context.push(
              Routes.passportHistory(level?.sport ?? 'badminton'),
            ),
          ),
        ],
      ),
      if (s != null) ...[
        _title('This season', top: 16),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 2),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                for (final (i, (label, value)) in [
                  ('Win rate', '${s.winRate}%'),
                  ('Matches', '${s.matches}'),
                  ('Meets', '${s.meets}'),
                  ('Streak', s.streak),
                ].indexed) ...[
                  if (i > 0)
                    VerticalDivider(width: 2, thickness: 2, color: c.border),
                  Expanded(
                    child: Column(
                      children: [
                        Text(label, style: context.type.caption),
                        Text(value, style: context.type.section),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _title('Recent form', trailing: 'Last 5 matches'),
        const SizedBox(height: 10),
        Semantics(
          label:
              'Recent form: ${s.form.map((w) => w ? 'win' : 'loss').join(', ')}',
          child: ExcludeSemantics(
            child: Row(
              children: [
                for (final win in s.form) ...[
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: win ? c.primary : null,
                      border: win ? null : Border.all(color: c.text, width: 2),
                    ),
                    child: Text(
                      win ? 'W' : 'L',
                      style: context.type.section.copyWith(
                        color: win ? c.onPrimary : c.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ] else ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Consumer(
            builder: (context, ref, _) {
              final played = level == null
                  ? 0
                  : ref.watch(ratingCardProvider(level.sport)).value?.matches ??
                        0;
              return Text(
                played == 0
                    ? 'Play your first ranked match to start your season, form '
                          'and stats.'
                    : played < 5
                    ? '$played of 5 ranked matches played. Your form and '
                          'stats start after 5.'
                    : 'See your matches in Sessions and rating.',
                style: context.type.secondary.copyWith(height: 1.45),
              );
            },
          ),
        ),
      ],
      if (level != null) ...[
        _title('Level and range'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label:
                    'Level ${level.level.toStringAsFixed(1)}, plays with ${level.playMin.toStringAsFixed(1)} to ${level.playMax.toStringAsFixed(1)}',
                child: SizedBox(
                  height: 54,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _LevelPainter(level, c, context.type),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text.rich(
                TextSpan(
                  text: 'Plays with levels ',
                  children: [
                    TextSpan(
                      text:
                          '${level.playMin.toStringAsFixed(1)} to ${level.playMax.toStringAsFixed(1)}',
                      // The range stands out by colour, not weight.
                      style: context.type.body,
                    ),
                  ],
                ),
                style: context.type.secondary,
              ),
            ],
          ),
        ),
      ],
      if (demo) ...[
        _title('Next up'),
        const SizedBox(height: 10),
        Pressable(
          onPressed: () => setState(() => _tab = 2),
          semanticLabel: 'Next up: ${DemoPassport.upcoming.first.title}',
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.inverseCard,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEXT UP · TUE 13 OCT · 7:30 PM',
                        style: context.type.caption.copyWith(
                          color: c.highlight,
                          letterSpacing: 0.72,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DemoPassport.upcoming.first.title,
                        style: context.type.section.copyWith(
                          color: c.onInverseCard,
                        ),
                      ),
                      Text(
                        DemoPassport.upcoming.first.place,
                        style: context.type.body.copyWith(
                          color: c.onInverseCardMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                OgIcon(
                  OgIcons.chevronRight,
                  size: 22,
                  color: c.highlight,
                  strokeWidth: 2.5,
                ),
              ],
            ),
          ),
        ),
      ],
      if (s != null) ...[
        _title('Stats'),
        const SizedBox(height: 10),
        for (final row in [
          s.cards.take(3).toList(),
          s.cards.skip(3).toList(),
        ]) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, card) in row.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: c.border, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.label, style: context.type.caption),
                          Text(
                            card.value,
                            style: context.type.score.copyWith(height: 1.15),
                          ),
                          Text(card.note, style: context.type.caption),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        _title('Breakdown', top: 12),
        const SizedBox(height: 4),
        for (final (label, pct) in s.breakdown)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border, width: 2)),
            ),
            child: Semantics(
              label: '$label $pct percent',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(label, style: context.type.body)),
                        Text('$pct%', style: context.type.section),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        minHeight: 8,
                        color: c.primary,
                        backgroundColor: c.border,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        _title('Win rate over time'),
        const SizedBox(height: 8),
        _WinRateChart(months: s.months),
      ],
    ];
  }

  List<Widget> _gear(BuildContext context, List<GearItem> gear, Sport sport) {
    final c = context.og;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your ${sport.label.toLowerCase()} gear',
                    style: context.type.section,
                  ),
                  Text(
                    'Tap an item for details.',
                    style: context.type.secondary,
                  ),
                ],
              ),
            ),
            OgButton.outline(
              label: 'Add gear',
              icon: OgIcons.plus,
              height: 44,
              expand: false,
              onPressed: () => context.push(Routes.gearEdit('new')),
            ),
          ],
        ),
      ),
      if (gear.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'Add your racquet, shoes and strings to track restrings and wear.',
            style: context.type.secondary.copyWith(height: 1.45),
          ),
        ),
      for (final g in gear)
        Container(
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border, width: 2),
          ),
          child: Column(
            children: [
              Pressable(
                onPressed: () => context.push(Routes.gear),
                semanticLabel: '${g.name}, ${g.type}',
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: SvgPicture.string(
                          _gearArt(g.kind),
                          width: 53,
                          height: 53,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.name,
                              style: context.type.body.copyWith(height: 1.25),
                            ),
                            Text(g.type, style: context.type.caption),
                            if (g.tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final t in g.tags)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: c.surface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        t,
                                        style: context.type.caption,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      OgIcon(
                        OgIcons.chevronRight,
                        size: 22,
                        color: c.text,
                        strokeWidth: 2.5,
                      ),
                    ],
                  ),
                ),
              ),
              if (g.price != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(g.price!, style: context.type.section),
                      ),
                      OgButton(
                        label: 'Add to cart',
                        icon: OgIcons.cart,
                        height: 40,
                        expand: false,
                        onPressed: () => context.push(Routes.cart),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _upcoming(BuildContext context, List<UpcomingGame> games) {
    final c = context.og;
    if (games.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            'No games coming up. Join a Meet and it shows here.',
            style: context.type.secondary.copyWith(height: 1.45),
          ),
        ),
      ];
    }
    return [
      const SizedBox(height: 8),
      for (final g in games)
        Container(
          constraints: const BoxConstraints(minHeight: 84),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: c.border, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      g.when,
                      style: context.type.caption.copyWith(color: c.link),
                    ),
                    Text(g.title, style: context.type.body),
                    Text(g.place, style: context.type.secondary),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: g.waitlist ? 10 : 12,
                  vertical: g.waitlist ? 2 : 4,
                ),
                decoration: BoxDecoration(
                  color: g.waitlist ? null : c.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: g.waitlist
                      ? Border.all(color: c.text, width: 2)
                      : null,
                ),
                child: Text(
                  g.waitlist ? 'Waitlist' : 'Going',
                  style: context.type.caption.copyWith(
                    color: g.waitlist ? c.text : c.onPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _challenges(BuildContext context, int followers) {
    final c = context.og;
    final progress = (followers / 1000).clamp(0.0, 1.0);
    return [
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(OgIcons.lock, size: 26, color: c.onPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Challenges are for creators',
              style: context.type.title.copyWith(height: 1.2),
            ),
            const SizedBox(height: 6),
            Text(
              'Reach 1,000 followers to set challenges for your fans, track who joins and reward the winners. If you later drop below 1,000, you keep access for 30 days to get back.',
              style: context.type.secondary.copyWith(height: 1.45),
            ),
            const SizedBox(height: 16),
            Semantics(
              label: '$followers of 1,000 followers',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  color: c.primary,
                  backgroundColor: c.border,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text('$followers followers', style: context.type.body),
                ),
                Text('1,000 to unlock', style: context.type.secondary),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OgButton.outline(
        label: 'See the creator view',
        height: 52,
        onPressed: () => context.push(Routes.creatorChallenges),
      ),
    ];
  }
}

String _gearArt(GearKind kind) => switch (kind) {
  GearKind.shoe => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><path d="M22 132V98q42-4 62-30l30 10q8 22 38 28 36 4 38 26z" fill="#E8590C"/><path d="M30 104q36-2 54-22" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linecap="round"/><rect x="16" y="128" width="176" height="18" rx="9" fill="#1C1F23"/><path d="M92 76l8 8M104 82l8 8" stroke="#FFFFFF" stroke-width="4" stroke-linecap="round"/></svg>',
  GearKind.paddle => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><g transform="rotate(30 100 100)"><rect x="56" y="14" width="88" height="110" rx="40" fill="#E8590C"/><rect x="66" y="24" width="68" height="90" rx="32" fill="none" stroke="#FFFFFF" stroke-width="4"/><rect x="90" y="120" width="20" height="66" rx="6" fill="#1C1F23"/></g></svg>',
  GearKind.racquet => '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><g transform="rotate(30 100 100)"><defs><clipPath id="cp"><ellipse cx="100" cy="62" rx="34" ry="46"/></clipPath></defs><g clip-path="url(#cp)" stroke="#7A8088" stroke-width="1.5"><line x1="76" x2="76" y1="14" y2="110"/><line x1="84" x2="84" y1="14" y2="110"/><line x1="92" x2="92" y1="14" y2="110"/><line x1="100" x2="100" y1="14" y2="110"/><line x1="108" x2="108" y1="14" y2="110"/><line x1="116" x2="116" y1="14" y2="110"/><line x1="124" x2="124" y1="14" y2="110"/><line x1="60" x2="140" y1="26" y2="26"/><line x1="60" x2="140" y1="34" y2="34"/><line x1="60" x2="140" y1="42" y2="42"/><line x1="60" x2="140" y1="50" y2="50"/><line x1="60" x2="140" y1="58" y2="58"/><line x1="60" x2="140" y1="66" y2="66"/><line x1="60" x2="140" y1="74" y2="74"/><line x1="60" x2="140" y1="82" y2="82"/><line x1="60" x2="140" y1="90" y2="90"/><line x1="60" x2="140" y1="98" y2="98"/></g><ellipse cx="100" cy="62" rx="34" ry="46" fill="none" stroke="#1C1F23" stroke-width="7"/><path d="M84 98L100 128L116 98" fill="none" stroke="#1C1F23" stroke-width="6" stroke-linejoin="round"/><line x1="100" y1="126" x2="100" y2="158" stroke="#1C1F23" stroke-width="6"/><rect x="93" y="150" width="14" height="42" rx="5" fill="#E8590C"/></g></svg>',
};

/// The hero (owner, 17 Nov 2026): the screen's full width, dark with court
/// lines, bottom corners rounded to 28. Over it, the back button at the left
/// and the share button at the right, below the status bar. [top] is the
/// status bar's height.
class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.top});

  final double top;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: OgColors.charcoal900,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 342 244" preserveAspectRatio="xMidYMid slice"><g fill="none" stroke="#FF7A1A" stroke-opacity=".12" stroke-width="3"><rect x="-30" y="90" width="230" height="190" rx="6"/><path d="M85 90v190M-30 185h230"/><rect x="170" y="40" width="230" height="190" rx="6"/><path d="M285 40v190M170 135h230"/></g></svg>',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: top + 8,
            child: _CircleButton(
              icon: OgIcons.back,
              label: 'Back',
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            right: 12,
            top: top + 8,
            child: _CircleButton(
              icon: OgIcons.share,
              label: 'Share',
              onTap: () => context.push(Routes.shareProfile),
            ),
          ),
        ],
      ),
    );
  }
}

/// A country's flag in a circle.
class _Flag extends StatelessWidget {
  const _Flag(this.code);

  final String code;

  /// The flag is 20 points across.
  static const _size = 20.0;

  static const _flags = {
    'SG': '<rect width="44" height="44" fill="#FFFFFF"/><rect width="44" height="22" fill="#E03C31"/><circle cx="14" cy="11" r="6" fill="#FFFFFF"/><circle cx="16.5" cy="11" r="5.4" fill="#E03C31"/><circle cx="22" cy="7" r="1.3" fill="#FFFFFF"/><circle cx="26" cy="10.5" r="1.3" fill="#FFFFFF"/><circle cx="24.5" cy="15" r="1.3" fill="#FFFFFF"/><circle cx="19.5" cy="15" r="1.3" fill="#FFFFFF"/><circle cx="18" cy="10.5" r="1.3" fill="#FFFFFF"/>',
    'MY': '<rect width="44" height="44" fill="#FFFFFF"/><rect y="0" width="44" height="6.3" fill="#CC0001"/><rect y="12.6" width="44" height="6.3" fill="#CC0001"/><rect y="25.2" width="44" height="6.3" fill="#CC0001"/><rect y="37.8" width="44" height="6.3" fill="#CC0001"/><rect width="22" height="25" fill="#010066"/><circle cx="11" cy="12" r="6" fill="#FFCC00"/>',
    'ID': '<rect width="44" height="44" fill="#FFFFFF"/><rect width="44" height="22" fill="#CE1126"/>',
    'TH': '<rect width="44" height="44" fill="#F4F5F8"/><rect width="44" height="7.3" fill="#A51931"/><rect y="14.7" width="44" height="14.6" fill="#2D2A4A"/><rect y="36.7" width="44" height="7.3" fill="#A51931"/>',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.og.border),
      ),
      child: ClipOval(
        child: SvgPicture.string(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">${_flags[code] ?? _flags['SG']}</svg>',
          width: _size,
          height: _size,
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onPressed: onTap,
    semanticLabel: label,
    child: Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF3A4048), width: 2),
      ),
      alignment: Alignment.center,
      child: OgIcon(icon, size: 22, color: OgColors.offWhite),
    ),
  );
}

/// The personal card (owner, 17 Nov 2026), over the hero's bottom edge: the
/// player's photo (or initials), full name, country flag and country; then
/// Age, Height and Birthplace; then Ranking and, when there is one, the best
/// doubles ranking with the partner it was reached with.
class _PersonalCard extends StatelessWidget {
  const _PersonalCard({
    required this.profile,
    required this.country,
    required this.age,
    required this.rank,
    required this.area,
    required this.bestDoublesRank,
    required this.bestDoublesPartner,
  });

  final Profile? profile;
  final Country country;
  final int? age;
  final int? rank;
  final String? area;
  final int? bestDoublesRank;
  final String? bestDoublesPartner;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    Widget box(String label, String value, {String? note}) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: context.type.caption),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.section.copyWith(height: 1.2),
            ),
            if (note != null)
              Text(
                note,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption,
              ),
          ],
        ),
      ),
    );
    final height = profile?.heightCm;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x291C1F23),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Avatar(
                initials: profile?.initials ?? '?',
                tone: AvatarTone.brand,
                imageUrl: profile?.avatarUrl,
                size: 72,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.type.title.copyWith(height: 1.1),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _Flag(country.code),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            country.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.type.secondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              box('Age', age == null ? '—' : '$age'),
              const SizedBox(width: 6),
              box('Height', height == null ? '—' : '$height cm'),
              const SizedBox(width: 6),
              box('Birthplace', profile?.birthplace ?? '—'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              box('Ranking', rank == null ? '—' : '#$rank', note: area),
              if (bestDoublesRank != null) ...[
                const SizedBox(width: 6),
                box(
                  'Best doubles',
                  '#$bestDoublesRank',
                  note: bestDoublesPartner == null
                      ? null
                      : 'with $bestDoublesPartner',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// The player's main sports (at most five), the selected one dark with its
/// name and the others icon-only, over the tab strip for the selected sport.
class _SportTabs extends StatelessWidget {
  const _SportTabs({
    required this.sports,
    required this.sportIndex,
    required this.tab,
    required this.onSport,
    required this.onTab,
    required this.colors,
  });
  final List<Sport> sports;
  final int sportIndex;
  final int tab;
  final ValueChanged<int> onSport;
  final ValueChanged<int> onTab;
  final OgColors colors;

  static const _tabs = ['Overview', 'Gear', 'Upcoming', 'Challenges'];
  @override
  Widget build(BuildContext context) {
    final c = colors;
    return Container(
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final (i, s) in sports.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Semantics(
                  button: true,
                  selected: i == sportIndex,
                  label: s.label,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      onSport(i);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      height: 48,
                      constraints: const BoxConstraints(minWidth: 48),
                      padding: EdgeInsets.symmetric(
                        horizontal: i == sportIndex ? 18 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: i == sportIndex
                            ? OgColors.charcoal900
                            : c.surfaceRaised,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: i == sportIndex
                              ? OgColors.charcoal900
                              : c.borderControl,
                          width: 2,
                        ),
                      ),
                      child: ExcludeSemantics(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OgIcon(
                              s.icon,
                              color: i == sportIndex
                                  ? OgColors.orange300
                                  : c.text,
                            ),
                            if (i == sportIndex) ...[
                              const SizedBox(width: 8),
                              Text(
                                s.label,
                                style: context.type.body.copyWith(
                                  color: OgColors.offWhite,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: c.border, width: 2)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, t) in _tabs.indexed)
                    Semantics(
                      button: true,
                      selected: i == tab,
                      label: t,
                      child: GestureDetector(
                        onTap: () {
                          if (i != tab) HapticFeedback.selectionClick();
                          onTab(i);
                        },
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: i == tab
                                    ? c.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                          ),
                          child: ExcludeSemantics(
                            child: Text(
                              t,
                              style: context.type.body.copyWith(
                                color: i == tab ? c.text : c.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
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

/// Level marker on the 1.0–8.0 track with the play-with range shaded.
class _LevelPainter extends CustomPainter {
  _LevelPainter(this.sport, this.c, this.type);

  final PlayerSport sport;
  final OgColors c;
  final OgType type;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 8.0;
    final width = size.width - 16;
    double x(double v) => left + (v - 1) / 7 * width;
    final track = RRect.fromLTRBR(
      left,
      26,
      left + width,
      36,
      const Radius.circular(5),
    );
    canvas.drawRRect(track, Paint()..color = c.border);
    canvas.drawRRect(
      RRect.fromLTRBR(
        x(sport.playMin),
        26,
        x(sport.playMax),
        36,
        const Radius.circular(5),
      ),
      Paint()..color = c.primary.withValues(alpha: 0.35),
    );
    final cx = x(sport.level);
    canvas.drawCircle(
      Offset(cx, 31),
      11,
      Paint()..color = OgColors.charcoal900,
    );
    canvas.drawCircle(
      Offset(cx, 31),
      11,
      Paint()
        ..color = OgColors.orange300
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    _text(
      canvas,
      sport.level.toStringAsFixed(1),
      Offset(cx, 0),
      type.section,
      center: true,
    );
    _text(canvas, '1.0', const Offset(left, 40), type.caption);
    _text(canvas, '8.0', Offset(left + width, 40), type.caption, right: true);
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    TextStyle style, {
    bool center = false,
    bool right = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center
        ? at.dx - tp.width / 2
        : (right ? at.dx - tp.width : at.dx);
    tp.paint(canvas, Offset(dx, at.dy));
  }

  @override
  bool shouldRepaint(_LevelPainter old) => old.sport != sport || old.c != c;
}

/// Win rate by month; tap a month to see its numbers.
class _WinRateChart extends StatefulWidget {
  const _WinRateChart({required this.months});

  final List<MonthPoint> months;

  @override
  State<_WinRateChart> createState() => _WinRateChartState();
}

class _WinRateChartState extends State<_WinRateChart> {
  late int _selected = 3.clamp(0, widget.months.length - 1);

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final m = widget.months[_selected];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 2),
      ),
      child: Semantics(
        label:
            'Win rate by month. ${widget.months.map((p) => '${p.label} ${p.winRate}%').join(', ')}',
        child: LayoutBuilder(
          builder: (context, box) => GestureDetector(
            onTapDown: (d) {
              final step = (box.maxWidth - 46) / (widget.months.length - 1);
              final i = ((d.localPosition.dx - 40) / step).round().clamp(
                0,
                widget.months.length - 1,
              );
              if (i != _selected) HapticFeedback.selectionClick();
              setState(() => _selected = i);
            },
            child: SizedBox(
              height: box.maxWidth * 170 / 342,
              width: box.maxWidth,
              child: CustomPaint(
                painter: _WinRatePainter(
                  widget.months,
                  _selected,
                  c,
                  '${m.label} ${m.year}',
                  context.type,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinRatePainter extends CustomPainter {
  _WinRatePainter(this.months, this.selected, this.c, this.title, this.type);

  final List<MonthPoint> months;
  final int selected;
  final OgColors c;
  final String title;
  final OgType type;

  @override
  void paint(Canvas canvas, Size size) {
    final sy = size.height / 170;
    const left = 40.0;
    final right = size.width - 6;
    double y(int pct) => (130 - pct * 1.2) * sy;
    final step = (right - left) / (months.length - 1);
    double x(int i) => left + i * step;
    final muted = type.caption;

    for (final pct in [0, 25, 50, 75, 100]) {
      canvas.drawLine(
        Offset(left, y(pct)),
        Offset(size.width - 4, y(pct)),
        Paint()..color = c.border,
      );
      _text(canvas, '$pct%', Offset(0, y(pct) - 8), muted);
    }

    final points = [
      for (var i = 0; i < months.length; i++)
        Offset(x(i), y(months[i].winRate)),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[math.max(0, i - 1)];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[math.min(points.length - 1, i + 2)];
      line.cubicTo(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
        p2.dx,
        p2.dy,
      );
    }
    final fill = Path.from(line)
      ..lineTo(points.last.dx, y(0))
      ..lineTo(points.first.dx, y(0))
      ..close();
    canvas.drawPath(fill, Paint()..color = c.primary.withValues(alpha: 0.12));
    canvas.drawPath(
      line,
      Paint()
        ..color = c.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final sel = points[selected];
    final dash = Paint()
      ..color = c.text
      ..strokeWidth = 1.5;
    for (var d = y(100); d < y(0); d += 6) {
      canvas.drawLine(
        Offset(sel.dx, d),
        Offset(sel.dx, math.min(d + 3, y(0))),
        dash,
      );
    }
    canvas.drawCircle(sel, 6, Paint()..color = c.surfaceRaised);
    canvas.drawCircle(
      sel,
      6,
      Paint()
        ..color = c.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (var i = 0; i < months.length; i++) {
      _text(
        canvas,
        months[i].label,
        Offset(x(i), 148 * sy),
        type.caption.copyWith(color: i == selected ? c.text : c.textMuted),
        center: true,
      );
    }

    // Tooltip, kept inside the chart.
    const w = 120.0, h = 58.0;
    var tx = sel.dx + 10;
    if (tx + w > size.width) tx = sel.dx - 10 - w;
    final box = RRect.fromLTRBR(
      tx,
      14 * sy,
      tx + w,
      14 * sy + h,
      const Radius.circular(10),
    );
    canvas.drawRRect(box, Paint()..color = c.surfaceRaised);
    canvas.drawRRect(
      box,
      Paint()
        ..color = c.borderControl
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    _text(canvas, title, Offset(tx + 10, 14 * sy + 7), type.caption);
    _rich(
      canvas,
      'Win rate  ',
      '${months[selected].winRate}%',
      Offset(tx + 10, 14 * sy + 25),
    );
    _rich(
      canvas,
      'Matches  ',
      '${months[selected].matches}',
      Offset(tx + 10, 14 * sy + 40),
    );
  }

  void _rich(Canvas canvas, String a, String b, Offset at) {
    final tp = TextPainter(
      text: TextSpan(
        text: a,
        style: type.caption,
        children: [
          // The value stands out by colour, not weight.
          TextSpan(
            text: b,
            style: type.caption.copyWith(color: c.text),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  void _text(
    Canvas canvas,
    String s,
    Offset at,
    TextStyle style, {
    bool center = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center ? at.dx - tp.width / 2 : at.dx, at.dy));
  }

  @override
  bool shouldRepaint(_WinRatePainter old) =>
      old.selected != selected || old.months != months || old.c != c;
}
