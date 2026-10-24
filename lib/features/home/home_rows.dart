import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/format.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/theme/og_tones.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/og_toast.dart';
import '../../core/widgets/pressable.dart';
import '../auth/data/auth_repository.dart';
import '../clubs/application/club_providers.dart';
import '../clubs/data/club_repository.dart';
import '../clubs/domain/club_models.dart';
import '../play/application/play_providers.dart';
import '../play/domain/activity.dart';
import '../play/presentation/play_card.dart';
import '../shop/application/shop_providers.dart';
import '../shop/domain/shop_models.dart';
import '../social/application/social_providers.dart';
import '../social/domain/social_models.dart';

const weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// "Tonight, 8:00 PM", "Tomorrow, 9:00 AM", "Sat, 9:00 AM", "Sat 24 Oct".
String nextLabel(DateTime at) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final diff = day.difference(today).inDays;
  final time = Fmt.time(at);
  if (diff == 0) return '${at.hour >= 17 ? 'Tonight' : 'Today'}, $time';
  if (diff == 1) return 'Tomorrow, $time';
  if (diff < 7) return '${weekdayNames[at.weekday - 1].substring(0, 3)}, $time';
  return Fmt.day(at);
}

/// Fades in a page-coloured band behind the status bar once the hero has
/// scrolled away, so the clock never sits on top of cards.
class StatusScrim extends StatefulWidget {
  const StatusScrim({
    super.key,
    required this.after,
    required this.child,
    this.darkHero = false,
  });

  final double after;
  final Widget child;

  /// Light status bar text while the hero is dark.
  final bool darkHero;

  @override
  State<StatusScrim> createState() => _StatusScrimState();
}

class _StatusScrimState extends State<StatusScrim> {
  bool _shown = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth == 0 && n.metrics.axis == Axis.vertical) {
      final shown = n.metrics.pixels > widget.after;
      if (shown != _shown) setState(() => _shown = shown);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (_shown
              ? Theme.of(context).brightness == Brightness.dark
              : widget.darkHero)
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: widget.child,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: MediaQuery.of(context).padding.top,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: _shown ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: ColoredBox(color: c.bg),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A hero with the search pill overlapping its bottom edge by 28. Both share
/// one box, since a later sliver would paint underneath the hero.
class HeroWithSearch extends StatelessWidget {
  const HeroWithSearch({
    super.key,
    required this.hero,
    required this.height,
    this.searchRoute = Routes.search,
  });

  final Widget hero;
  final double height;
  final String searchRoute;

  /// Hero height for a 320pt artboard hero under the status bar.
  static double heroHeight(BuildContext context) =>
      320 + MediaQuery.of(context).padding.top;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + 28,
      child: Stack(
        children: [
          Positioned(left: 0, right: 0, top: 0, child: hero),
          Positioned(
            left: 20,
            right: 20,
            bottom: 0,
            child: SearchPill(route: searchRoute),
          ),
        ],
      ),
    );
  }
}

class SearchPill extends StatelessWidget {
  const SearchPill({super.key, this.route = Routes.search});

  final String route;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: 'Search Meets, clubs, players, shops',
      onPressed: () => context.push(route),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2417171A),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            OgIcon(OgIcons.searchCircle, size: 22, color: c.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search Meets, clubs, players, shops',
                style: OgText.body(16, color: c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Sections ──────────────────────────────────────────────────────────────

/// "Meets" heading with a "See all" link, 26px from the block above.
class HomeSection extends StatelessWidget {
  const HomeSection({
    super.key,
    required this.title,
    required this.child,
    this.onSeeAll,
    this.linkLabel = 'See all',
    this.top = 26,
  });

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;
  final String linkLabel;
  final double top;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: OgText.display(26, height: 1.1, color: c.text),
                    ),
                  ),
                ),
                if (onSeeAll != null)
                  KitLink(linkLabel, onPressed: onSeeAll, minHeight: 32),
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A sideways row of cards with the page gutters.
class Shelf extends StatelessWidget {
  const Shelf({super.key, required this.children, this.stretch = true});

  final List<Widget> children;

  /// Tiles share the tallest one's height; activity cards keep their own,
  /// since a cover on one would leave a gap in the next.
  final bool stretch;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: stretch
          ? CrossAxisAlignment.stretch
          : CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          children[i],
        ],
      ],
    );
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: stretch ? IntrinsicHeight(child: row) : row,
    );
  }
}

class ActivityShelf extends ConsumerWidget {
  const ActivityShelf({
    super.key,
    required this.kind,
    required this.title,
    this.where,
  });

  final ActivityKind kind;
  final String title;

  /// Narrows the row, as Discover's filters do.
  final bool Function(Activity)? where;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(upcomingOfKindProvider(kind)).value;
    final list = where == null ? all : all?.where(where!).toList();
    if (list == null || list.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: title,
      onSeeAll: () => context.push(Routes.playKind(kind)),
      child: Shelf(
        stretch: false,
        children: [
          for (final a in list)
            SizedBox(width: 318, child: PlayCard(activity: a)),
        ],
      ),
    );
  }
}

class ClubShelf extends ConsumerWidget {
  const ClubShelf({super.key, this.title = 'Clubs', this.tab = ClubTab.mine});

  final String title;

  /// Mine shows my clubs and teams; other tabs show clubs only.
  final ClubTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubs = ref.watch(clubListProvider(tab)).value ?? [];
    final teams = tab == ClubTab.mine
        ? ref.watch(teamListProvider(tab)).value ?? []
        : const <TeamListItem>[];
    if (clubs.isEmpty && teams.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: title,
      onSeeAll: () => context.push(Routes.clubs),
      child: Shelf(
        children: [
          for (final item in clubs) _ClubTile.club(item.club),
          for (final item in teams) _ClubTile.team(item),
        ],
      ),
    );
  }
}

class _ClubTile extends ConsumerWidget {
  const _ClubTile.club(Club this.club) : team = null;
  const _ClubTile.team(TeamListItem this.team) : club = null;

  final Club? club;
  final TeamListItem? team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final isClub = club != null;
    final name = isClub ? club!.name : team!.team.name;
    final mark = isClub ? club!.initials : team!.team.mark;
    final color = Color(isClub ? club!.logoColor : team!.team.logoColor);
    final ink = Color(isClub ? club!.logoInk : team!.team.logoInk);
    final unread = isClub ? club!.unreadChat : team!.team.unreadChat;
    final count = isClub
        ? club!.memberCount
        : team!.team.playerCount + team!.team.staffCount;
    final sessions = isClub
        ? ref.watch(clubSessionsProvider(club!.id)).value
        : null;
    final fixtures = isClub
        ? null
        : ref.watch(teamSessionsProvider(team!.team.id)).value;
    final members = isClub
        ? ref.watch(clubMembersProvider(club!.id)).value
        : ref
              .watch(teamMembersProvider(team!.team.id))
              .value
              ?.map((m) => ClubMember(player: m.player));
    final next = isClub
        ? (sessions == null || sessions.isEmpty
              ? null
              : 'Next: ${nextLabel(sessions.first.startsAt)}')
        : switch (fixtures?.where((s) => s.fixture).firstOrNull) {
            final f? => 'Next: ${Fmt.day(f.startsAt)}, fixture',
            _ => null,
          };
    final faces = (members ?? const <ClubMember>[]).take(3).toList();
    return Pressable(
      semanticLabel: '$name, $count members',
      onPressed: () => context.push(
        isClub ? Routes.club(club!.id) : Routes.team(team!.team.id),
      ),
      child: Container(
        width: 208,
        decoration: BoxDecoration(
          color: t.soft,
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 104,
              child: CourtHero(
                color: color,
                height: 104,
                style: CourtLines.tile,
                child: Stack(
                  children: [
                    Positioned(
                      left: 14,
                      bottom: 10,
                      child: Text(mark, style: OgText.heading(44, color: ink)),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 10,
                        top: 10,
                        child: KitTag(
                          '$unread new',
                          height: 22,
                          fontSize: 11,
                          background: c.accent,
                          foreground: OgColors.ink,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(16, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    next ?? (isClub ? 'No sessions this week' : team!.meta),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: c.link,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: faces.isEmpty ? 0 : 24 + (faces.length - 1) * 16,
                        height: 24,
                        child: Stack(
                          children: [
                            for (var i = 0; i < faces.length; i++)
                              Positioned(
                                left: i * 16.0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: t.soft, width: 2),
                                  ),
                                  child: SolidAvatar.forId(
                                    faces[i].player.id,
                                    initials: faces[i].player.initials,
                                    size: 20,
                                    fontSize: 8,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (faces.isNotEmpty) const SizedBox(width: 8),
                      Text(
                        '$count members',
                        style: OgText.body(
                          12,
                          weight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerShelf extends ConsumerWidget {
  const PlayerShelf({
    super.key,
    this.title = 'Players',
    this.linkLabel = 'See all',
    this.linkRoute,
  });

  final String title;
  final String linkLabel;

  /// Pushed from the link; without one the link opens Discover.
  final String? linkRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final players = ref.watch(suggestedPlayersProvider).value ?? [];
    if (players.isEmpty) return const SizedBox.shrink();
    final following = ref.watch(myFollowingProvider).value ?? const {};
    return HomeSection(
      title: title,
      linkLabel: linkLabel,
      onSeeAll: () => linkRoute == null
          ? context.go(Routes.discover)
          : context.push(linkRoute!),
      child: Shelf(
        children: [
          for (final p in players)
            _PlayerTile(p: p, following: following.contains(p.player.id)),
        ],
      ),
    );
  }
}

class _PlayerTile extends ConsumerWidget {
  const _PlayerTile({required this.p, required this.following});

  final SuggestedPlayer p;
  final bool following;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    return Pressable(
      semanticLabel: '${p.player.displayName}, ${p.note}',
      onPressed: () => context.push(Routes.player(p.player.id)),
      child: Container(
        width: 132,
        padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
        decoration: BoxDecoration(
          color: t.soft,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                SolidAvatar.forId(
                  p.player.id,
                  initials: p.player.initials,
                  size: 60,
                  fontSize: 18,
                ),
                if (p.level != null)
                  Positioned(
                    bottom: -8,
                    child: Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      decoration: BoxDecoration(
                        color: c.inverseCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: t.soft, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        p.level!.toStringAsFixed(1),
                        style: OgText.body(
                          11,
                          weight: FontWeight.w700,
                          color: c.accent,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              p.player.displayName,
              textAlign: TextAlign.center,
              style: OgText.body(14, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              p.note,
              textAlign: TextAlign.center,
              style: OgText.body(12, color: c.textMuted),
            ),
            const SizedBox(height: 8),
            const Spacer(),
            Pressable(
              semanticLabel: following
                  ? 'Following ${p.player.displayName}'
                  : 'Follow ${p.player.displayName}',
              onPressed: () async {
                HapticFeedback.selectionClick();
                try {
                  await ref
                      .read(myFollowingProvider.notifier)
                      .toggle(p.player.id);
                } on AuthFailure catch (e) {
                  if (context.mounted) {
                    showOgToast(context, e.message, error: true);
                  }
                }
              },
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: following ? c.bg : c.inverseCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: following ? c.borderControl : c.inverseCard,
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  following ? 'Following' : 'Follow',
                  style: OgText.body(
                    13,
                    weight: FontWeight.w700,
                    color: following ? c.text : c.onInverseCard,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MallShelf extends ConsumerWidget {
  const MallShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final malls = ref.watch(mallsProvider).value ?? [];
    if (malls.isEmpty) return const SizedBox.shrink();
    final c = context.og;
    return HomeSection(
      title: 'Malls',
      onSeeAll: () => context.push(Routes.shop),
      child: Shelf(
        children: [
          for (final m in malls)
            // Same shape as a Popular items card: a square tile, then the
            // name, a line under it and a chip.
            Pressable(
              semanticLabel: [
                m.name,
                m.blurb,
                if (m.pointsAccepted) 'Points accepted',
              ].join('. '),
              onPressed: () => context.push(Routes.mallPage(m.id)),
              child: SizedBox(
                width: 156,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 156,
                      decoration: BoxDecoration(
                        color: Color(m.color),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m.initials,
                        style: OgText.heading(44, color: Color(m.ink)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: OgText.body(12, color: c.textMuted),
                    ),
                    if (m.pointsAccepted) ...[
                      const SizedBox(height: 6),
                      KitTag(
                        'Points accepted',
                        height: 20,
                        fontSize: 11,
                        background: c.primaryTint,
                        foreground: const Color(0xFF7A3B00),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductShelf extends ConsumerWidget {
  const ProductShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(popularProductsProvider).value ?? [];
    if (items.isEmpty) return const SizedBox.shrink();
    final c = context.og;
    final t = context.tones;
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: HomeSection(
        title: 'Popular items',
        onSeeAll: () => context.push(Routes.shop),
        child: Shelf(
          children: [
            for (final p in items)
              Pressable(
                semanticLabel: '${p.name}, S\$${money(p.priceCents)}',
                onPressed: () => context.push(Routes.product(p.id)),
                child: SizedBox(
                  width: 156,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 156,
                        decoration: BoxDecoration(
                          color: t.soft,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        alignment: Alignment.center,
                        child: OgIcon(
                          p.art == ProductArt.racquet
                              ? OgIcons.racquet
                              : OgIcons.bag,
                          size: 44,
                          strokeWidth: 1.2,
                          color: const Color(0xFF9A9AA0),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        p.name,
                        style: OgText.body(
                          14,
                          weight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.mallName,
                        style: OgText.body(12, color: c.textMuted),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'S\$${money(p.priceCents, decimals: p.priceCents % 100 != 0)}',
                            style: OgText.body(15, weight: FontWeight.w700),
                          ),
                          if (p.maxPoints > 0) ...[
                            const SizedBox(width: 8),
                            KitTag(
                              'up to ${p.maxPoints} pts',
                              height: 20,
                              fontSize: 11,
                              background: c.primaryTint,
                              foreground: const Color(0xFF7A3B00),
                            ),
                          ],
                        ],
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
