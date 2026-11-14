import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_home.dart';
import '../../core/theme/og_layout.dart';
import '../../core/theme/og_type.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/pressable.dart';
import '../game/application/game_providers.dart';
import '../game/domain/game_models.dart';
import 'application/home_categories.dart';
import 'home_rows.dart';
import 'home_screen.dart' show HomeHeading;

// ─── Hero and search ───────────────────────────────────────────────────────

/// The deep orange block from the top of the screen, with the greeting and
/// the Schedule and Saved buttons, and the search bar over its bottom edge.
class HomeHero extends ConsumerWidget {
  const HomeHero({super.key, required this.top});

  /// The status bar's height; the hero runs up under it.
  final double top;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final h = context.home;
    final first = ref.watch(sessionProfileProvider).value?.firstName ?? '';
    final name = first.isEmpty ? 'to OlympusGO' : first;
    return SizedBox(
      height: top + OgHomeSize.hero + OgHomeSize.searchOverlap,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: top + OgHomeSize.hero,
            child: ColoredBox(
              color: h.hero,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  OgHomeSize.side,
                  top + OgSpace.s4,
                  OgHomeSize.side,
                  OgSpace.s4,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        label: 'Welcome, $name',
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome,',
                                style: context.type.groupLabel.copyWith(
                                  color: h.onHero,
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.display.copyWith(
                                    color: h.onHero,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: OgSpace.s2),
                    KitIconButton(
                      icon: OgIcons.calendarBox,
                      label: 'My schedule',
                      strokeWidth: 1.9,
                      background: h.heroButton,
                      color: h.onHeroButton,
                      onPressed: () => context.push(Routes.schedule()),
                    ),
                    const SizedBox(width: OgSpace.s2),
                    KitIconButton(
                      icon: OgIcons.bookmark,
                      label: 'Saved',
                      strokeWidth: 1.9,
                      background: h.heroButton,
                      color: h.onHeroButton,
                      onPressed: () => context.push(Routes.saved),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Positioned(
            left: OgHomeSize.side,
            right: OgHomeSize.side,
            bottom: 0,
            child: HomeSearch(),
          ),
        ],
      ),
    );
  }
}

class HomeSearch extends StatelessWidget {
  const HomeSearch({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final c = context.og;
    return Pressable(
      semanticLabel: 'Search Meets, clubs, players, shops',
      onPressed: () => context.push(Routes.search),
      child: Container(
        height: OgHomeSize.search,
        padding: const EdgeInsets.symmetric(horizontal: OgSpace.s4),
        decoration: BoxDecoration(
          color: h.surface,
          borderRadius: BorderRadius.circular(OgRadius.lg),
          boxShadow: [
            BoxShadow(
              color: h.shadow,
              blurRadius: OgSpace.s6,
              offset: const Offset(0, OgSpace.s2),
            ),
          ],
        ),
        child: Row(
          children: [
            OgIcon(OgIcons.search, size: OgSize.icon, color: c.textMuted),
            const SizedBox(width: OgSpace.s3),
            Expanded(
              child: Text(
                'Search Meets, clubs, players, shops',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.type.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Your favourites ───────────────────────────────────────────────────────

/// The player's chosen shortcuts, two to a row.
class HomeFavourites extends ConsumerWidget {
  const HomeFavourites({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(homeCategoriesControllerProvider);
    final items = [
      for (final i in prefs.order)
        if (prefs.shown.contains(i)) i,
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: OgSpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeading(
            'Your favourites',
            link: 'Edit',
            onLink: () => context.push(Routes.editCategories),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: OgHomeSize.side),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i += 2) ...[
                  if (i > 0) const SizedBox(height: OgSpace.s3),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: _FavouriteCard(items[i])),
                        const SizedBox(width: OgSpace.s3),
                        Expanded(
                          child: i + 1 < items.length
                              ? _FavouriteCard(items[i + 1])
                              : const SizedBox.shrink(),
                        ),
                      ],
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

class _FavouriteCard extends StatelessWidget {
  const _FavouriteCard(this.item);

  final HomeCategory item;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Pressable(
      semanticLabel: '${item.label}, ${item.sub}',
      onPressed: () => context.push(item.route),
      child: Container(
        padding: const EdgeInsets.all(OgSpace.s4),
        decoration: BoxDecoration(
          color: h.surface,
          borderRadius: BorderRadius.circular(OgRadius.lg),
          border: Border.all(color: h.cardBorder, width: OgSize.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: OgHomeSize.favouriteIcon,
              height: OgHomeSize.favouriteIcon,
              decoration: BoxDecoration(
                color: h.iconTint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                item.icon,
                size: OgSize.icon,
                strokeWidth: 1.8,
                color: h.iconInk,
              ),
            ),
            const SizedBox(height: OgSpace.s3),
            Text(
              item.label,
              style: context.type.section.copyWith(color: h.heading),
            ),
            const SizedBox(height: OgSpace.s1),
            Text(
              item.sub,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.type.caption,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── More services ─────────────────────────────────────────────────────────

/// Label, icon and route. Orders has a function for a route, so it is built
/// when tapped.
final _services = <(String, String, String Function())>[
  ('Game', OgIcons.trophyTeam, () => Routes.game),
  ('Shop', OgIcons.bag, () => Routes.shop),
  ('Wallet', OgIcons.walletCard, () => Routes.wallet),
  ('Points', OgIcons.pointsStar, () => Routes.points),
  ('Tickets', OgIcons.ticket, () => Routes.myTickets),
  ('Rankings', OgIcons.trophyCup, () => Routes.leaderboards),
  ('My gear', OgIcons.racquetStrings, () => Routes.gear),
  ('Orders', OgIcons.clipboardList, Routes.orders),
];

/// A sideways row of round shortcuts.
class HomeServices extends StatelessWidget {
  const HomeServices({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Padding(
      padding: const EdgeInsets.only(top: OgHomeSize.block),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeHeading(
            'More services',
            link: 'View all',
            onLink: () => context.go(Routes.discover),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: OgHomeSize.side),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in _services)
                  Padding(
                    padding: const EdgeInsets.only(right: OgSpace.s2),
                    child: Pressable(
                      semanticLabel: s.$1,
                      onPressed: () => context.push(s.$3()),
                      child: SizedBox(
                        width: OgHomeSize.serviceItemWidth,
                        child: Column(
                          children: [
                            Container(
                              width: OgHomeSize.service,
                              height: OgHomeSize.service,
                              decoration: BoxDecoration(
                                color: h.surface,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: h.cardBorder,
                                  width: OgSize.hairline,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: OgIcon(
                                s.$2,
                                size: OgSize.icon,
                                strokeWidth: 1.8,
                                color: h.heading,
                              ),
                            ),
                            const SizedBox(height: OgSpace.s2),
                            Text(
                              s.$1,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.type.caption,
                            ),
                          ],
                        ),
                      ),
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

// ─── Ad ────────────────────────────────────────────────────────────────────

/// A dark card for the Shop. Tapping anywhere on it opens the Shop.
class HomeAd extends StatelessWidget {
  const HomeAd({super.key});

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OgHomeSize.side,
        OgHomeSize.block,
        OgHomeSize.side,
        0,
      ),
      child: Pressable(
        semanticLabel:
            'Ad. Gear up for game day. Rackets, shoes and strings. Shop now',
        onPressed: () => context.push(Routes.shop),
        child: Container(
          padding: const EdgeInsets.all(OgSpace.s4),
          decoration: BoxDecoration(
            color: h.adSurface,
            borderRadius: BorderRadius.circular(OgRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OgSpace.s2,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(OgRadius.sm),
                          border: Border.all(
                            color: h.adMuted,
                            width: OgSize.hairline,
                          ),
                        ),
                        child: Text(
                          'Ad',
                          style: context.type.caption.copyWith(
                            color: h.adMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: OgSpace.s2),
                      Text(
                        'Gear up for game day',
                        style: context.type.section.copyWith(color: h.onAd),
                      ),
                      const SizedBox(height: OgSpace.s1),
                      Text(
                        'Rackets, shoes and strings.',
                        style: context.type.caption.copyWith(color: h.adMuted),
                      ),
                      const SizedBox(height: OgSpace.s3),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: OgSize.tapTarget,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          widthFactor: 1,
                          child: Text(
                            'Shop now',
                            style: context.type.button.copyWith(
                              color: h.adAccent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: OgSpace.s3),
              ExcludeSemantics(
                child: Container(
                  width: OgHomeSize.service,
                  height: OgHomeSize.service,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: h.adAccent,
                      width: OgSize.hairline * 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: OgIcon(
                    OgIcons.racquet,
                    size: OgSize.icon + OgSpace.s2,
                    strokeWidth: 1.6,
                    color: h.adAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Challenges ────────────────────────────────────────────────────────────

/// Live campaigns as colourful cards. Not drawn until there is one.
class HomeChallenges extends ConsumerWidget {
  const HomeChallenges({super.key});

  static const _cardWidth = 260.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = [
      for (final c in ref.watch(campaignsProvider).value ?? const <Campaign>[])
        if (c.state == CampaignState.live) c,
    ];
    if (live.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: 'Challenges',
      home: true,
      onSeeAll: () => context.push(Routes.game),
      child: Shelf(
        children: [
          for (final c in live)
            SizedBox(width: _cardWidth, child: _ChallengeCard(c)),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard(this.c);

  final Campaign c;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final ink = Color(c.ink);
    final hasBar = c.target > 0;
    final shown = hasBar ? c.progress.clamp(0, c.target) : 0;
    final note = c.progressNote.isNotEmpty
        ? c.progressNote
        : '$shown of ${c.target}';
    return Pressable(
      semanticLabel: [
        'Live challenge',
        c.title,
        'Reward: ${c.reward}',
        if (hasBar) note,
      ].join('. '),
      onPressed: () => context.push(Routes.campaign(c.id)),
      child: Container(
        padding: const EdgeInsets.all(OgSpace.s4),
        decoration: BoxDecoration(
          color: Color(c.color),
          borderRadius: BorderRadius.circular(OgRadius.lg),
        ),
        child: ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KitTag(
                CampaignState.live.label,
                height: 22,
                background: h.adAccent,
                foreground: h.onAdAccent,
              ),
              const SizedBox(height: OgSpace.s3),
              Text(
                c.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type.section.copyWith(color: ink),
              ),
              const SizedBox(height: OgSpace.s1),
              Text(
                c.reward,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type.body.copyWith(color: ink),
              ),
              const Spacer(),
              if (hasBar) ...[
                const SizedBox(height: OgSpace.s3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(OgRadius.pill),
                  child: Stack(
                    children: [
                      Container(
                        height: OgSpace.s2,
                        color: ink.withValues(alpha: 0.2),
                      ),
                      FractionallySizedBox(
                        widthFactor: shown / c.target,
                        child: Container(height: OgSpace.s2, color: ink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: OgSpace.s1),
                Text(note, style: context.type.caption.copyWith(color: ink)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
