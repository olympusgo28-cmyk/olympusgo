import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/theme/og_tones.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/pressable.dart';
import '../game/application/game_providers.dart';
import '../play/application/play_providers.dart';
import '../play/domain/activity.dart';
import '../shell/main_shell.dart';
import '../shop/application/shop_providers.dart';
import '../social/application/social_providers.dart';
import 'application/home_services.dart';
import 'home_rows.dart';
import 'service_widgets.dart';

/// Home: greeting, hero and search, Your favourites, More services, an ad,
/// then rows of challenges, Meets, events, tournaments, players and popular
/// items. Rows with nothing in them don't show.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(sessionProfileProvider.notifier).reload();
    ref.invalidate(campaignsProvider);
    ref.invalidate(upcomingOfKindProvider);
    ref.invalidate(suggestedPlayersProvider);
    ref.invalidate(popularProductsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    return Scaffold(
      backgroundColor: c.bg,
      body: StatusScrim(
        after: 0,
        darkHero: Theme.of(context).brightness == Brightness.dark,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => _refresh(ref)),
            const SliverToBoxAdapter(child: _Header()),
            const SliverToBoxAdapter(child: _HeroWithSearch()),
            const SliverToBoxAdapter(child: _Favourites()),
            const SliverToBoxAdapter(child: _MoreServices()),
            const SliverToBoxAdapter(child: _AdBanner()),
            const SliverToBoxAdapter(child: ChallengeShelf()),
            const SliverToBoxAdapter(
              child: ActivityShelf(kind: ActivityKind.meet, title: 'Meets'),
            ),
            const SliverToBoxAdapter(
              child: ActivityShelf(kind: ActivityKind.event, title: 'Events'),
            ),
            const SliverToBoxAdapter(
              child: ActivityShelf(
                kind: ActivityKind.tournament,
                title: 'Tournaments',
              ),
            ),
            const SliverToBoxAdapter(child: PlayerShelf()),
            const SliverToBoxAdapter(child: ProductShelf()),
            SliverToBoxAdapter(
              child: SizedBox(height: MainTabBar.reservedHeight(context)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────

/// "Welcome," and my first name, with My schedule and Saved on the right.
class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final top = MediaQuery.of(context).padding.top;
    final first = ref.watch(sessionProfileProvider).value?.firstName ?? '';
    final name = first.isEmpty ? 'to OlympusGO' : first;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 10, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              label: 'Welcome, $name',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome,',
                      style: OgText.body(
                        15,
                        weight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: OgText.heading(30, color: c.text),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          KitIconButton(
            icon: OgIcons.calendarBox,
            label: 'My schedule',
            strokeWidth: 1.8,
            background: t.soft,
            onPressed: () => context.push(Routes.schedule()),
          ),
          const SizedBox(width: 8),
          KitIconButton(
            icon: OgIcons.bookmark,
            label: 'Saved',
            strokeWidth: 1.8,
            background: t.soft,
            onPressed: () => context.push(Routes.saved),
          ),
        ],
      ),
    );
  }
}

// ─── Hero and search ───────────────────────────────────────────────────────

/// A plain deep orange banner, with the search bar floating over its
/// bottom edge.
class _HeroWithSearch extends StatelessWidget {
  const _HeroWithSearch();

  static const _heroHeight = 168.0;
  static const _overlap = 28.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16 + _heroHeight + _overlap,
      child: Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: 16,
            height: _heroHeight,
            child: Container(
              decoration: BoxDecoration(
                color: OgColors.deepOrange,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          const Positioned(left: 32, right: 32, bottom: 0, child: SearchPill()),
        ],
      ),
    );
  }
}

// ─── Services ──────────────────────────────────────────────────────────────

class _Favourites extends ConsumerWidget {
  const _Favourites();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(homeServicesControllerProvider);
    return HomeSection(
      title: 'Your favourites',
      linkLabel: 'Edit',
      onSeeAll: () => context.push(Routes.editFavourites),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: FavouriteGrid(services: services.favouriteList),
      ),
    );
  }
}

class _MoreServices extends ConsumerWidget {
  const _MoreServices();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final more = ref.watch(homeServicesControllerProvider).moreList;
    if (more.isEmpty) return const SizedBox.shrink();
    return HomeSection(
      title: 'More services',
      linkLabel: 'View all',
      onSeeAll: () => context.push(Routes.services),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Lines the first circle up with the 20px page gutter.
        padding: EdgeInsets.symmetric(
          horizontal: 20 - (ServiceCircle.width - 60) / 2,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final s in more) ServiceCircle(service: s)],
        ),
      ),
    );
  }
}

// ─── Advertisement ─────────────────────────────────────────────────────────

/// The ad slot. Until paid placements exist it promotes the Shop.
class _AdBanner extends StatelessWidget {
  const _AdBanner();

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
      child: Pressable(
        semanticLabel:
            'Ad. Gear up for game day. Rackets, shoes and strings from shops '
            'near you. Shop now',
        onPressed: () => context.push(Routes.shop),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 18),
          decoration: BoxDecoration(
            color: c.inverseCard,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    KitTag(
                      'Ad',
                      height: 20,
                      fontSize: 11,
                      background: const Color(0x33FFFFFF),
                      foreground: c.onInverseCard,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Gear up for game day',
                      style: OgText.heading(22, color: c.onInverseCard),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rackets, shoes and strings from shops near you',
                      style: OgText.body(
                        13,
                        height: 1.35,
                        color: c.onInverseCardMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Shop now',
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(
                  color: Color(0x1FFFFFFF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: OgIcon(
                  OgIcons.racquetStrings,
                  size: 38,
                  strokeWidth: 1.3,
                  color: c.accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
