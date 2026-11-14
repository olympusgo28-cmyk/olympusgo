import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_home.dart';
import '../../core/theme/og_layout.dart';
import '../../core/theme/og_type.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../clubs/application/club_providers.dart';
import '../earnings/application/earnings_providers.dart';
import '../feed/application/feed_providers.dart';
import '../game/application/game_providers.dart';
import '../play/application/play_providers.dart';
import '../play/domain/activity.dart';
import '../shell/main_shell.dart';
import '../social/application/social_providers.dart';
import 'home_blocks.dart';
import 'home_rows.dart';

/// Home (owner, 14 Nov 2026): an orange hero with the greeting, the search
/// bar over its edge, your favourites, more services, an ad, then rows of
/// challenges, Meets, events, tournaments, players and popular items. A row
/// with nothing in it is not drawn.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(sessionProfileProvider.notifier).reload();
    ref.invalidate(upcomingMeetsProvider);
    ref.invalidate(upcomingOfKindProvider);
    ref.invalidate(clubListProvider);
    ref.invalidate(teamListProvider);
    ref.invalidate(suggestedPlayersProvider);
    ref.invalidate(pointsSummaryProvider);
    ref.invalidate(feedStatusProvider);
    ref.invalidate(campaignsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: h.page,
      body: StatusScrim(
        color: h.page,
        after: OgHomeSize.hero,
        child: Stack(
          children: [
            // Pulling down past the top shows the hero colour, not the page,
            // so the clock stays readable.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: ListenableBuilder(
                listenable: _scroll,
                builder: (context, _) {
                  final over = _scroll.hasClients && _scroll.offset < 0
                      ? -_scroll.offset
                      : 0.0;
                  return ColoredBox(
                    color: h.hero,
                    child: SizedBox(height: over, width: double.infinity),
                  );
                },
              ),
            ),
            CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                CupertinoSliverRefreshControl(onRefresh: _refresh),
                SliverToBoxAdapter(child: HomeHero(top: top)),
                const SliverToBoxAdapter(child: HomeFavourites()),
                const SliverToBoxAdapter(child: HomeServices()),
                const SliverToBoxAdapter(child: HomeAd()),
                const SliverToBoxAdapter(child: HomeChallenges()),
                const SliverToBoxAdapter(
                  child: ActivityShelf(
                    kind: ActivityKind.meet,
                    title: 'Meets',
                    home: true,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: ActivityShelf(
                    kind: ActivityKind.event,
                    title: 'Events',
                    home: true,
                  ),
                ),
                const SliverToBoxAdapter(
                  child: ActivityShelf(
                    kind: ActivityKind.tournament,
                    title: 'Tournaments',
                    home: true,
                  ),
                ),
                const SliverToBoxAdapter(child: PlayerShelf(home: true)),
                const SliverToBoxAdapter(child: ProductShelf(home: true)),
                // Videos has no other way in, so its tile stays, below the rows.
                const SliverToBoxAdapter(child: HomeVideos()),
                SliverToBoxAdapter(
                  child: SizedBox(height: MainTabBar.reservedHeight(context)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A Home heading with its link on the right ("Your favourites", "Edit").
class HomeHeading extends StatelessWidget {
  const HomeHeading(this.title, {super.key, this.link, this.onLink});

  final String title;
  final String? link;
  final VoidCallback? onLink;

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OgHomeSize.side,
        0,
        OgHomeSize.side,
        OgSpace.s2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: context.type.title.copyWith(color: h.heading),
              ),
            ),
          ),
          if (link != null)
            KitLink(link!, onPressed: onLink, color: h.link, minHeight: 44),
        ],
      ),
    );
  }
}

/// The Videos tile, shown only when the server says this person has a feed.
class HomeVideos extends ConsumerWidget {
  const HomeVideos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!(ref.watch(feedStatusProvider).value?.open ?? false)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OgHomeSize.side,
        OgHomeSize.block,
        OgHomeSize.side,
        0,
      ),
      child: KitNavTile(
        icon: OgIcons.video,
        title: 'Videos',
        subtitle: 'From people you follow',
        padding: EdgeInsets.zero,
        minHeight: 68,
        onTap: () => context.push(Routes.videos),
      ),
    );
  }
}
