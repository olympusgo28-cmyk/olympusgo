import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/pressable.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/data/club_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../../home/home_rows.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/application/play_providers.dart';
import '../../play/domain/activity.dart';
import '../../shell/main_shell.dart';
import '../../social/application/social_providers.dart';
import '../../wallet/application/wallet_providers.dart';
import '../domain/profile.dart';

const _muted = Color(0xFFC9C6BC);

/// Profile: who I am, my Passport, points, badges, next sessions and the
/// account list.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(sessionProfileProvider.notifier).reload();
    ref.invalidate(mySportsProvider);
    ref.invalidate(mySummaryProvider);
    ref.invalidate(mySocialProvider);
    ref.invalidate(myScheduleProvider);
    ref.invalidate(walletSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final profile = ref.watch(sessionProfileProvider).value;
    final summary = ref.watch(mySummaryProvider).value;
    final sports = ref.watch(mySportsProvider).value ?? const [];
    final social = ref.watch(mySocialProvider).value;
    final wallet = ref.watch(walletSummaryProvider).value;
    final clubs = ref.watch(clubListProvider(ClubTab.mine)).value ?? const [];
    final teams = ref.watch(teamListProvider(ClubTab.mine)).value ?? const [];
    final upcoming = (ref.watch(myScheduleProvider).value ?? const [])
        .take(3)
        .toList();
    final top = MediaQuery.of(context).padding.top;

    final handle = [
      if (profile?.username != null) '@${profile!.username}',
      ?summary?.area,
    ].join(' · ');
    final levels = sports
        .map((s) {
          final sport = Sport.fromId(s.sport);
          return '${sport.label} ${SkillBand.forLevel(s.level).code}';
        })
        .join(' · ');
    final groups = [
      ...clubs.map((c) => c.club.name),
      ...teams.map((t) => t.team.name),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: StatusScrim(
        after: 0,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => _refresh(ref)),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                top + 20,
                16,
                24 + MainTabBar.reservedHeight(context),
              ),
              sliver: SliverList.list(
                children: kitSpaced([
                  Row(
                    children: [
                      SolidAvatar(
                        initials: profile?.initials ?? '?',
                        color: const Color(0xFFF2C14E),
                        ink: const Color(0xFF3A2C00),
                        size: 76,
                        fontSize: 26,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                profile?.fullName ?? profile?.username ?? '',
                                style: OgText.heading(24),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              handle,
                              style: OgText.body(14, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      KitIconButton(
                        icon: OgIcons.scan,
                        label: 'My QR code',
                        size: 20,
                        strokeWidth: 1.9,
                        background: c.bg,
                        border: true,
                        onPressed: () => context.push(Routes.shareProfile),
                      ),
                    ],
                  ),
                  if (sports.isNotEmpty)
                    _PassportCard(
                      sport: sports.first,
                      sessions: summary?.sessions ?? 0,
                      clubRank: summary?.clubRank,
                      clubs: clubs.length,
                      localRank: summary?.localRank,
                      area: summary?.area,
                    ),
                  if (wallet != null)
                    Pressable(
                      semanticLabel:
                          '${wallet.points.toStringAsFixed(1)} points. Use points',
                      onPressed: () => context.push(Routes.points),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE8CC),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${wallet.points.toStringAsFixed(1)} points',
                                    style: OgText.body(
                                      16,
                                      weight: FontWeight.w800,
                                      color: const Color(0xFF7A3B00),
                                    ),
                                  ),
                                  Text(
                                    wallet.pendingPoints > 0
                                        ? '${wallet.pendingPoints.toStringAsFixed(0)} more pending'
                                        : 'Earn points by playing',
                                    style: OgText.body(
                                      13,
                                      color: const Color(0xFF7A3B00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Use points',
                              style: OgText.body(
                                14,
                                weight: FontWeight.w700,
                                color: const Color(0xFF7A3B00),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (summary != null && summary.badges.isNotEmpty)
                    _Section(
                      title: 'Badges',
                      trailing: Text(
                        '${summary.badgeCount} earned',
                        style: OgText.body(13, color: c.textMuted),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final b in summary.badges) ...[
                                if (b != summary.badges.first)
                                  const SizedBox(width: 8),
                                _BadgeTile(b),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  _Section(
                    title: 'Next sessions',
                    trailing: KitLink(
                      'Shown to: ${summary?.sessionsShownTo ?? 'Followers'} · Change',
                      size: 13,
                      onPressed: () => context.push(Routes.privacy),
                    ),
                    child: KitCard(
                      children: [
                        if (upcoming.isEmpty)
                          _ListRow(
                            title: 'Nothing booked',
                            subtitle: 'Find a Meet, tournament or event',
                            onTap: () => context.push(Routes.play),
                          ),
                        for (final a in upcoming)
                          _ListRow(
                            title: a.title,
                            subtitle: _sessionLine(a, ref),
                            onTap: () => context.push(Routes.activity(a.id)),
                          ),
                      ],
                    ),
                  ),
                  _Section(
                    title: 'Account',
                    child: KitCard(
                      children: [
                        _ListRow(
                          title: 'Edit profile',
                          subtitle:
                              'Name, photo, username, who sees your sessions',
                          onTap: () => context.push(Routes.accountCentre),
                        ),
                        _ListRow(
                          title: 'Sessions and rating',
                          subtitle: 'Past Meets, tournaments and classes',
                          value: '${summary?.sessions ?? 0}',
                          onTap: () => context.push(Routes.passport),
                        ),
                        _ListRow(
                          title: 'Wallet',
                          subtitle:
                              'S\$${money(wallet?.balanceCents ?? 0)} · refunds, withdraw, history',
                          onTap: () => context.push(Routes.wallet),
                        ),
                        _ListRow(
                          title: 'Followers and following',
                          subtitle: social == null
                              ? 'Your people'
                              : '${social.followers} followers · ${social.following} following',
                          onTap: () =>
                              context.push(Routes.connections(followers: true)),
                        ),
                        _ListRow(
                          title: 'My orders',
                          subtitle: 'Gear from the shop',
                          onTap: () => context.push(Routes.orders()),
                        ),
                        _ListRow(
                          title: 'Sports and levels',
                          subtitle: levels.isEmpty ? 'Add your sports' : levels,
                          onTap: () => context.push(Routes.profileSports),
                        ),
                        _ListRow(
                          title: 'My clubs and teams',
                          subtitle: groups.isEmpty
                              ? 'Find a club to join'
                              : groups.take(2).join(', '),
                          value: groups.isEmpty ? null : '${groups.length}',
                          onTap: () => context.push(Routes.clubs),
                        ),
                        _ListRow(
                          title: 'Account Centre',
                          subtitle:
                              'Email, mobile, payments · opens with Face ID',
                          onTap: () => context.push(Routes.accountHub),
                        ),
                        _ListRow(
                          title: 'My gear',
                          subtitle: 'Racquets, paddles and shoes · string and rubber setup',
                          onTap: () => context.push(Routes.gear),
                        ),
                        _ListRow(
                          title: 'Challenges',
                          subtitle: 'Create and join challenges',
                          onTap: () => context.push(Routes.creatorChallenges),
                        ),
                        _ListRow(
                          title: 'Share profile',
                          subtitle: 'QR code and link',
                          onTap: () => context.push(Routes.shareProfile),
                        ),
                        _ListRow(
                          title: 'Saved',
                          subtitle: 'Meets, players and clubs you kept',
                          onTap: () => context.push(Routes.saved),
                        ),
                        _ListRow(
                          title: 'Settings',
                          subtitle: 'Notifications, privacy and safety',
                          onTap: () => context.push(Routes.settings),
                        ),
                        _ListRow(
                          title: 'Help',
                          subtitle: 'Questions, support, terms',
                          onTap: () => context.push(Routes.help),
                        ),
                      ],
                    ),
                  ),
                ], 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// "Tonight 8:00 PM · Tampines Smashers", or the venue without a club.
  static String _sessionLine(Activity a, WidgetRef ref) {
    final club = a.clubId == null
        ? null
        : ref.watch(clubProvider(a.clubId!)).value?.name;
    final when = nextLabel(a.startsAt).replaceFirst(', ', ' ');
    return '$when · ${club ?? a.venue.name}';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 32,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    title,
                    style: OgText.display(
                      18,
                      height: 1.2,
                      color: context.og.text,
                    ),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ListRow extends StatelessWidget {
  const _ListRow({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.value,
  });

  final String title;
  final String subtitle;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: [title, subtitle, ?value].join('. '),
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: OgText.body(15, weight: FontWeight.w700)),
                  const SizedBox(height: 1),
                  Text(subtitle, style: OgText.body(13, color: c.textMuted)),
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 12),
              Text(
                value!,
                style: OgText.body(
                  14,
                  weight: FontWeight.w600,
                  color: const Color(0xFF3A3F45),
                ),
              ),
            ],
            const SizedBox(width: 12),
            OgIcon(
              OgIcons.chevronRight,
              size: 20,
              strokeWidth: 2,
              color: const Color(0xFF9A9FA5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PassportCard extends StatelessWidget {
  const _PassportCard({
    required this.sport,
    required this.sessions,
    required this.clubRank,
    required this.clubs,
    required this.localRank,
    required this.area,
  });

  final PlayerSport sport;
  final int sessions;
  final int? clubRank;
  final int clubs;
  final int? localRank;
  final String? area;

  @override
  Widget build(BuildContext context) {
    final band = SkillBand.forLevel(sport.level);
    final label = Sport.fromId(sport.sport).label;
    Widget stat(String big, String small) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(big, style: OgText.heading(20, color: Colors.white)),
            const SizedBox(height: 2),
            Text(small, style: OgText.body(12, color: _muted)),
          ],
        ),
      ),
    );
    return Pressable(
      semanticLabel:
          'Passport, $label ${sport.level.toStringAsFixed(1)}, ${band.label}',
      onPressed: () => context.push(Routes.passport),
      child: Container(
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
                    'PASSPORT · ${label.toUpperCase()}',
                    style: OgText.body(
                      12,
                      weight: FontWeight.w800,
                      color: _muted,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2C14E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'MAIN SPORT',
                    style: OgText.body(
                      11,
                      weight: FontWeight.w800,
                      color: const Color(0xFF3A2C00),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  sport.level.toStringAsFixed(1),
                  style: OgText.heading(44, color: Colors.white, height: 1),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${band.label} · ${band.code}',
                    style: OgText.body(
                      16,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                stat('$sessions', 'sessions'),
                const SizedBox(width: 8),
                stat(clubRank == null ? '–' : '#$clubRank', 'club rank'),
                const SizedBox(width: 8),
                stat('$clubs', clubs == 1 ? 'club' : 'clubs'),
              ],
            ),
            const SizedBox(height: 14),
            Pressable(
              semanticLabel: 'See leaderboards',
              onPressed: () => context.push(Routes.leaderboards),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        localRank == null
                            ? 'See leaderboards'
                            : 'Local #$localRank${area == null ? '' : ' in $area'} · See leaderboards',
                        style: OgText.body(
                          14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Text('›', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile(this.badge);

  final ProfileBadge badge;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Column(
        children: [
          SolidAvatar(
            initials: badge.mark,
            color: Color(badge.color),
            ink: Color(badge.ink),
            size: 44,
            fontSize: 14,
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: OgText.body(12, weight: FontWeight.w700, height: 1.25),
          ),
        ],
      ),
    );
  }
}
