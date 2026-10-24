import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/format.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/application/play_providers.dart';
import '../../play/domain/activity.dart';
import '../../settings/application/settings_providers.dart';
import '../../social/application/social_providers.dart';
import '../domain/passport.dart';
import '../domain/profile.dart';

/// The player's Passport: hero card, sport switcher and four tabs.
class PassportScreen extends ConsumerStatefulWidget {
  const PassportScreen({super.key});

  @override
  ConsumerState<PassportScreen> createState() => _PassportScreenState();
}

class _PassportScreenState extends ConsumerState<PassportScreen> {
  int _sport = 0;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final mq = MediaQuery.of(context);
    final profile = ref.watch(sessionProfileProvider).value;
    final sports = ref.watch(mySportsProvider).value ?? const <PlayerSport>[];
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: c.bg,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  math.max(4, 56 - mq.padding.top),
                  24,
                  0,
                ),
                sliver: SliverToBoxAdapter(
                  // The info card overlaps the hero's bottom 34px.
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        child: _Hero(
                          profile: profile,
                          sport: sport,
                          level: current?.level,
                          country: info?.country.code ?? 'SG',
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 210),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: _InfoCard(
                              profile: profile,
                              country: info?.country.name ?? 'Singapore',
                              stats: [
                                ('Age', age == null ? '—' : '$age'),
                                (
                                  'Play',
                                  demo ? '48' : '${stats?.matches ?? 0}',
                                ),
                                ('Hand', demo ? 'Right' : '—'),
                                ('Since', '${DateTime.now().year}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _NavHeader(
                  sports: sports.map((s) => Sport.fromId(s.sport)).toList(),
                  sportIndex: math.min(_sport, math.max(0, sports.length - 1)),
                  tab: _tab,
                  onSport: (i) => setState(() => _sport = i),
                  onTab: (i) => setState(() => _tab = i),
                  colors: c,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(24, 0, 24, mq.padding.bottom + 32),
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
    final c = context.og;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(text, style: OgText.display(20, color: c.text)),
            ),
          ),
          if (trailing != null)
            Text(trailing, style: OgText.body(14, color: c.textMuted)),
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
    return [
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
                        Text(label, style: OgText.body(12, color: c.textMuted)),
                        Text(value, style: OgText.display(20, color: c.text)),
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
                      style: OgText.display(
                        17,
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
          child: Text(
            'Play your first ranked match to start your season, form and stats.',
            style: OgText.body(15, height: 1.45, color: c.textMuted),
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
                  child: CustomPaint(painter: _LevelPainter(level, c)),
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
                      style: TextStyle(
                        color: c.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                style: OgText.body(14, color: c.textMuted),
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
                        style: OgText.body(
                          12,
                          weight: FontWeight.w600,
                          letterSpacing: 0.72,
                          color: c.highlight,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DemoPassport.upcoming.first.title,
                        style: OgText.body(
                          17,
                          weight: FontWeight.w600,
                          color: c.onInverseCard,
                        ),
                      ),
                      Text(
                        DemoPassport.upcoming.first.place,
                        style: OgText.body(14, color: c.onInverseCardMuted),
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
                          Text(
                            card.label,
                            style: OgText.body(13, color: c.textMuted),
                          ),
                          Text(
                            card.value,
                            style: OgText.display(
                              26,
                              height: 1.15,
                              color: c.text,
                            ),
                          ),
                          Text(
                            card.note,
                            style: OgText.body(13, color: c.textMuted),
                          ),
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
                        Expanded(
                          child: Text(
                            label,
                            style: OgText.body(
                              15,
                              weight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ),
                        Text('$pct%', style: OgText.display(18, color: c.text)),
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
                    style: OgText.display(20, color: c.text),
                  ),
                  Text(
                    'Tap an item for details.',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ],
              ),
            ),
            OgButton.outline(
              label: 'Add gear',
              icon: OgIcons.plus,
              height: 44,
              fontSize: 15,
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
            style: OgText.body(15, height: 1.45, color: c.textMuted),
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
                              style: OgText.body(
                                16,
                                weight: FontWeight.w600,
                                height: 1.25,
                                color: c.text,
                              ),
                            ),
                            Text(
                              g.type,
                              style: OgText.body(13, color: c.textMuted),
                            ),
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
                                        style: OgText.body(
                                          12,
                                          weight: FontWeight.w600,
                                          color: c.text,
                                        ),
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
                        child: Text(
                          g.price!,
                          style: OgText.display(20, color: c.text),
                        ),
                      ),
                      OgButton(
                        label: 'Add to cart',
                        icon: OgIcons.cart,
                        height: 40,
                        fontSize: 16,
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
            style: OgText.body(15, height: 1.45, color: c.textMuted),
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
                      style: OgText.body(
                        13,
                        weight: FontWeight.w600,
                        color: c.link,
                      ),
                    ),
                    Text(
                      g.title,
                      style: OgText.body(
                        16,
                        weight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    Text(g.place, style: OgText.body(14, color: c.textMuted)),
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
                  style: OgText.body(
                    13,
                    weight: FontWeight.w600,
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
              style: OgText.display(22, height: 1.2, color: c.text),
            ),
            const SizedBox(height: 6),
            Text(
              'Reach 1,000 followers to set challenges for your fans, track who joins and reward the winners. If you later drop below 1,000, you keep access for 30 days to get back.',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
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
                  child: Text(
                    '$followers followers',
                    style: OgText.body(
                      14,
                      weight: FontWeight.w600,
                      color: c.text,
                    ),
                  ),
                ),
                Text(
                  '1,000 to unlock',
                  style: OgText.body(14, color: c.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      OgButton.outline(
        label: 'See the creator view',
        height: 52,
        fontSize: 18,
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

/// Dark hero: court lines, sport and flag badges, first name, level, portrait.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.profile,
    required this.sport,
    required this.level,
    required this.country,
  });

  final Profile? profile;
  final Sport sport;
  final double? level;
  final String country;

  static const _flags = {
    'SG': '<rect width="44" height="44" fill="#FFFFFF"/><rect width="44" height="22" fill="#E03C31"/><circle cx="14" cy="11" r="6" fill="#FFFFFF"/><circle cx="16.5" cy="11" r="5.4" fill="#E03C31"/><circle cx="22" cy="7" r="1.3" fill="#FFFFFF"/><circle cx="26" cy="10.5" r="1.3" fill="#FFFFFF"/><circle cx="24.5" cy="15" r="1.3" fill="#FFFFFF"/><circle cx="19.5" cy="15" r="1.3" fill="#FFFFFF"/><circle cx="18" cy="10.5" r="1.3" fill="#FFFFFF"/>',
    'MY': '<rect width="44" height="44" fill="#FFFFFF"/><rect y="0" width="44" height="6.3" fill="#CC0001"/><rect y="12.6" width="44" height="6.3" fill="#CC0001"/><rect y="25.2" width="44" height="6.3" fill="#CC0001"/><rect y="37.8" width="44" height="6.3" fill="#CC0001"/><rect width="22" height="25" fill="#010066"/><circle cx="11" cy="12" r="6" fill="#FFCC00"/>',
    'ID': '<rect width="44" height="44" fill="#FFFFFF"/><rect width="44" height="22" fill="#CE1126"/>',
    'TH': '<rect width="44" height="44" fill="#F4F5F8"/><rect width="44" height="7.3" fill="#A51931"/><rect y="14.7" width="44" height="14.6" fill="#2D2A4A"/><rect y="36.7" width="44" height="7.3" fill="#A51931"/>',
  };

  @override
  Widget build(BuildContext context) {
    final first = profile?.firstName ?? '';
    return Container(
      height: 244,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: OgColors.charcoal900,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ExcludeSemantics(
              child: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 342 244" preserveAspectRatio="xMidYMid slice"><g fill="none" stroke="#FF7A1A" stroke-opacity=".12" stroke-width="3"><rect x="-30" y="90" width="230" height="190" rx="6"/><path d="M85 90v190M-30 185h230"/></g></svg>',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 0,
            child: ExcludeSemantics(
              child: SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 230"><path d="M0 230C0 172 40 150 100 146c60 4 100 26 100 84z" fill="#E8590C"/><path d="M70 150L100 184L130 150" fill="none" stroke="#FF7A1A" stroke-width="9" stroke-linejoin="round"/><rect x="84" y="116" width="32" height="38" rx="12" fill="#D39A72"/><ellipse cx="60" cy="86" rx="7" ry="11" fill="#D39A72"/><ellipse cx="140" cy="86" rx="7" ry="11" fill="#D39A72"/><ellipse cx="100" cy="84" rx="41" ry="47" fill="#E3AE85"/><path d="M58 80C54 40 76 24 102 24s46 16 40 56c-6-18-16-26-42-26S64 62 58 80z" fill="#1C1F23"/><circle cx="84" cy="88" r="3.4" fill="#1C1F23"/><circle cx="116" cy="88" r="3.4" fill="#1C1F23"/><path d="M85 108q15 11 30 0" fill="none" stroke="#1C1F23" stroke-width="3.4" stroke-linecap="round"/></svg>',
                width: 184,
                height: 212,
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 12,
            child: _CircleButton(
              icon: OgIcons.back,
              label: 'Back',
              onTap: () => context.pop(),
            ),
          ),
          Positioned(
            right: 12,
            top: 12,
            child: _CircleButton(
              icon: OgIcons.share,
              label: 'Share',
              onTap: () => context.push(Routes.shareProfile),
            ),
          ),
          Positioned(
            left: 18,
            top: 68,
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2A2F35),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: OgIcon(sport.icon, color: OgColors.orange300),
                ),
                const SizedBox(width: 8),
                ClipOval(
                  child: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 44 44">${_flags[country] ?? _flags['SG']}</svg>',
                    width: 44,
                    height: 44,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            top: 118,
            right: 150,
            child: Text(
              first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.display(54, height: 1, color: OgColors.offWhite),
            ),
          ),
          if (level != null)
            Positioned(
              left: 18,
              top: 186,
              child: Row(
                children: [
                  SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M8 3l-5 3 2 4 2-1v11h10V9l2 1 2-4-5-3c-.5 1.5-2 2.3-4 2.3S8.5 4.5 8 3z" fill="#E8590C"/></svg>',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'DOUBLES · LEVEL ${level!.toStringAsFixed(1)}',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      letterSpacing: 0.78,
                      color: OgColors.grey400,
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.profile,
    required this.country,
    required this.stats,
  });

  final Profile? profile;
  final String country;
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      padding: const EdgeInsets.all(14),
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
                size: 60,
                fontSize: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile?.fullName ?? '',
                      style: OgText.display(24, height: 1.1, color: c.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        OgIcon(OgIcons.location, size: 16, color: c.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          country,
                          style: OgText.body(15, color: c.textMuted),
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
              for (final (i, (label, value)) in stats.indexed) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(label, style: OgText.body(12, color: c.textMuted)),
                        Text(
                          value,
                          style: OgText.display(19, height: 1.2, color: c.text),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Sticky sport switcher and tab strip.
class _NavHeader extends SliverPersistentHeaderDelegate {
  _NavHeader({
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
  static const _height = 10 + 48 + 6 + 46.0;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final c = colors;
    return Container(
      color: c.bg,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
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
                                style: OgText.body(
                                  16,
                                  weight: FontWeight.w600,
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
                              style: OgText.body(
                                15,
                                weight: FontWeight.w600,
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

  @override
  bool shouldRebuild(_NavHeader old) =>
      old.sportIndex != sportIndex ||
      old.tab != tab ||
      old.sports.length != sports.length ||
      old.colors != colors;
}

/// Level marker on the 1.0–8.0 track with the play-with range shaded.
class _LevelPainter extends CustomPainter {
  _LevelPainter(this.sport, this.c);

  final PlayerSport sport;
  final OgColors c;

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
      OgText.display(14, color: c.text),
      center: true,
    );
    _text(
      canvas,
      '1.0',
      const Offset(left, 40),
      OgText.body(11, color: c.textMuted),
    );
    _text(
      canvas,
      '8.0',
      Offset(left + width, 40),
      OgText.body(11, color: c.textMuted),
      right: true,
    );
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
  _WinRatePainter(this.months, this.selected, this.c, this.title);

  final List<MonthPoint> months;
  final int selected;
  final OgColors c;
  final String title;

  @override
  void paint(Canvas canvas, Size size) {
    final sy = size.height / 170;
    const left = 40.0;
    final right = size.width - 6;
    double y(int pct) => (130 - pct * 1.2) * sy;
    final step = (right - left) / (months.length - 1);
    double x(int i) => left + i * step;
    final muted = OgText.body(11, color: c.textMuted);

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
        OgText.body(
          12,
          weight: i == selected ? FontWeight.w800 : FontWeight.w400,
          color: i == selected ? c.text : c.textMuted,
        ),
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
    _text(
      canvas,
      title,
      Offset(tx + 10, 14 * sy + 7),
      OgText.body(13, weight: FontWeight.w800, color: c.text),
    );
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
        style: OgText.body(12, color: c.textMuted),
        children: [
          TextSpan(
            text: b,
            style: OgText.body(12, weight: FontWeight.w800, color: c.text),
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
