import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_home.dart';
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
  final _orange = GlobalKey();

  /// How far Home scrolls before the hero is gone from under the clock. The
  /// hero is only as tall as its greeting, so this is measured.
  double _heroAfter = 0;

  void _measureHero(double top) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final height = _orange.currentContext?.size?.height;
      if (!mounted || height == null) return;
      final after = height - top;
      if (after != _heroAfter) setState(() => _heroAfter = after);
    });
  }

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
    ref.invalidate(myVouchersProvider);
    ref.invalidate(feedStatusProvider);
    ref.invalidate(campaignsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final h = context.home;
    final top = MediaQuery.paddingOf(context).top;
    _measureHero(top);
    return Scaffold(
      backgroundColor: h.page,
      body: StatusScrim(
        color: h.page,
        after: _heroAfter,
        // White clock over the orange, like the greeting; dark over lime.
        darkHero: Theme.of(context).brightness == Brightness.light,
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
                SliverToBoxAdapter(
                  child: HomeHero(top: top, orangeKey: _orange),
                ),
                const SliverToBoxAdapter(child: HomeShortcuts()),
                const SliverToBoxAdapter(child: HomeWalletPoints()),
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
