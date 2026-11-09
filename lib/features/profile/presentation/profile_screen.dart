import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:og_money/og_money.dart' show pointsText;

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_layout.dart';
import '../../../core/theme/og_type.dart';
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
import '../../earnings/application/earnings_providers.dart';
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
    ref.invalidate(pointsSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final profile = ref.watch(sessionProfileProvider).value;
    final summary = ref.watch(mySummaryProvider).value;
    final sports = ref.watch(mySportsProvider).value ?? const [];
    final wallet = ref.watch(pointsSummaryProvider).value;
    final clubs = ref.watch(clubListProvider(ClubTab.mine)).value ?? const [];
    final upcoming = (ref.watch(myScheduleProvider).value ?? const [])
        .take(3)
        .toList();
    final top = MediaQuery.of(context).padding.top;

    final handle = [
      if (profile?.username != null) '@${profile!.username}',
      ?summary?.area,
    ].join(' · ');

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
                                style: context.type.title,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(handle, style: context.type.secondary),
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
                      const SizedBox(width: OgSpace.s2),
                      // Everything that was the Account list lives in
                      // Settings and activity now.
                      KitIconButton(
                        icon: OgIcons.menu,
                        label: 'Settings and activity',
                        size: 20,
                        strokeWidth: 1.9,
                        background: c.bg,
                        border: true,
                        onPressed: () => context.push(Routes.settings),
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
                  if (wallet != null && wallet.worthShowing)
                    Pressable(
                      semanticLabel:
                          '${pointsText(wallet.minor)} points. Use points',
                      onPressed: () => context.push(Routes.points),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE6D6),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${pointsText(wallet.minor)} points',
                                    style: context.type.body.copyWith(
                                      color: const Color(0xFF7A3B00),
                                    ),
                                  ),
                                  Text(
                                    wallet.pendingMinor > 0
                                        ? '${pointsText(wallet.pendingMinor)} more pending'
                                        : wallet.earning
                                        ? 'Earn points by playing'
                                        : 'Use them in the Shop',
                                    style: context.type.caption.copyWith(
                                      color: const Color(0xFF7A3B00),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Use points',
                              style: context.type.body.copyWith(
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
                        style: context.type.caption,
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
                    style: context.type.section.copyWith(height: 1.2),
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
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: '$title. $subtitle',
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
                  Text(title, style: context.type.body),
                  const SizedBox(height: 1),
                  Text(subtitle, style: context.type.caption),
                ],
              ),
            ),
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
            Text(
              big,
              style: context.type.section.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(small, style: context.type.caption.copyWith(color: _muted)),
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
                    style: context.type.caption.copyWith(
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
                    style: context.type.caption.copyWith(
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
                  style: context.type.score.copyWith(
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    '${band.label} · ${band.code}',
                    style: context.type.body.copyWith(color: Colors.white),
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
                        style: context.type.body.copyWith(color: Colors.white),
                      ),
                    ),
                    Text(
                      '›',
                      style: context.type.body.copyWith(color: Colors.white),
                    ),
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
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: context.type.caption.copyWith(height: 1.25),
          ),
        ],
      ),
    );
  }
}
