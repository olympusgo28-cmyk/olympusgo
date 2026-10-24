import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/format.dart';
import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/theme/og_tones.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/pressable.dart';
import '../clubs/application/club_providers.dart';
import '../play/application/play_providers.dart';
import '../play/domain/activity.dart';
import '../shell/main_shell.dart';
import '../social/application/social_providers.dart';
import '../wallet/application/wallet_providers.dart';
import 'application/home_categories.dart';
import 'home_rows.dart';

/// Home: hero, search, categories, Wallet and points, then rows of Meets,
/// events, tournaments, clubs, players, malls and popular items.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    await ref.read(sessionProfileProvider.notifier).reload();
    ref.invalidate(upcomingMeetsProvider);
    ref.invalidate(upcomingOfKindProvider);
    ref.invalidate(clubListProvider);
    ref.invalidate(teamListProvider);
    ref.invalidate(suggestedPlayersProvider);
    ref.invalidate(walletSummaryProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    return Scaffold(
      backgroundColor: c.bg,
      body: StatusScrim(
        after:
            HeroWithSearch.heroHeight(context) -
            MediaQuery.of(context).padding.top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: () => _refresh(ref)),
            SliverToBoxAdapter(
              child: HeroWithSearch(
                hero: const _Hero(),
                height: HeroWithSearch.heroHeight(context),
              ),
            ),
            const SliverToBoxAdapter(child: _Categories()),
            const SliverToBoxAdapter(child: _Balances()),
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
            const SliverToBoxAdapter(child: ClubShelf()),
            const SliverToBoxAdapter(child: PlayerShelf()),
            const SliverToBoxAdapter(child: MallShelf()),
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

// ─── Hero ──────────────────────────────────────────────────────────────────

class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final top = MediaQuery.of(context).padding.top;
    final first = ref.watch(sessionProfileProvider).value?.firstName ?? '';
    final now = DateTime.now();
    final date =
        '${weekdayNames[now.weekday - 1]} ${now.day} ${Fmt.monthsLong[now.month - 1]}';
    // The featured creator challenge arrives with the Creator phase; until
    // then live accounts see an invitation to play.
    final demo = !Env.hasSupabase;
    return CourtHero(
      color: c.primary,
      height: HeroWithSearch.heroHeight(context),
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -30,
            child: Container(
              width: 236,
              height: 236,
              decoration: BoxDecoration(
                color: c.inverseCard,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: demo
                  ? Text('CR', style: OgText.heading(92, color: t.gold))
                  : OgIcon(
                      OgIcons.racquet,
                      size: 96,
                      strokeWidth: 1.2,
                      color: t.gold,
                    ),
            ),
          ),
          Positioned(
            left: 20,
            right: 12,
            top: top + 12,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        date,
                        style: OgText.body(
                          13,
                          weight: FontWeight.w600,
                          color: c.onPrimary,
                        ),
                      ),
                      Text(
                        first.isEmpty ? 'Hi there' : 'Hi $first',
                        style: OgText.heading(32, color: c.onPrimary),
                      ),
                    ],
                  ),
                ),
                KitIconButton(
                  icon: OgIcons.calendarBox,
                  label: 'My schedule',
                  strokeWidth: 1.9,
                  background: Colors.white,
                  color: OgColors.ink,
                  onPressed: () => context.push(Routes.schedule()),
                ),
                const SizedBox(width: 8),
                KitIconButton(
                  icon: OgIcons.heart,
                  label: 'Saved',
                  strokeWidth: 1.9,
                  background: Colors.white,
                  color: OgColors.ink,
                  onPressed: () => context.push(Routes.saved),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 56,
            width: 190,
            child: Pressable(
              semanticLabel: demo
                  ? "Creator challenge: Coach Ravi's 30-day smash challenge"
                  : 'Find your next game',
              onPressed: () =>
                  context.push(demo ? Routes.creatorChallenges : Routes.play),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KitTag(
                    demo ? 'Creator challenge' : 'Play',
                    fontSize: 12,
                    background: c.onPrimary,
                    foreground: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    demo
                        ? "Coach Ravi's 30-day smash challenge"
                        : 'Find your next game',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    // Archivo runs much wider than the artboard's condensed
                    // face, so 26 keeps three lines clear of the circle.
                    style: OgText.heading(26, color: c.onPrimary, height: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    demo ? '412 players joined' : 'Meets, tournaments, events',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: c.onPrimary,
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

class _Categories extends ConsumerWidget {
  const _Categories();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final prefs = ref.watch(homeCategoriesControllerProvider);
    final items = [
      for (final h in prefs.order)
        if (prefs.shown.contains(h)) (h.icon, h.label, h.route),
    ];
    Widget cell(
      Widget tile,
      String label,
      String route, {
      bool muted = false,
    }) => Pressable(
      semanticLabel: label,
      onPressed: () => context.push(route),
      child: Column(
        children: [
          tile,
          const SizedBox(height: 8),
          Text(
            label,
            style: OgText.body(
              13,
              weight: FontWeight.w600,
              color: muted ? c.textMuted : c.text,
            ),
          ),
        ],
      ),
    );
    final cells = [
      for (final i in items)
        cell(
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: t.soft,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: OgIcon(i.$1, size: 26, strokeWidth: 1.7, color: c.text),
          ),
          i.$2,
          i.$3,
        ),
      cell(
        DashedBox(
          child: SizedBox(
            width: 64,
            height: 64,
            child: Center(
              child: OgIcon(
                OgIcons.dots,
                size: 26,
                strokeWidth: 3,
                color: c.textMuted,
              ),
            ),
          ),
        ),
        'Edit',
        Routes.editCategories,
        muted: true,
      ),
    ];
    return HomeSection(
      title: 'Categories',
      top: 18,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            for (var row = 0; row < cells.length; row += 4) ...[
              if (row > 0) const SizedBox(height: 18),
              Row(
                children: [
                  for (var i = row; i < row + 4; i++)
                    Expanded(
                      child: i < cells.length
                          ? Center(child: cells[i])
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Balances extends ConsumerWidget {
  const _Balances();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final w = ref.watch(walletSummaryProvider).value;
    Widget card({
      required Color bg,
      required String label,
      required Color labelColor,
      required String icon,
      required Color iconColor,
      required double stroke,
      required String value,
      required Color valueColor,
      required String note,
      required Color noteColor,
      required String route,
    }) => Expanded(
      child: Pressable(
        semanticLabel: '$label, $value. $note',
        onPressed: () => context.push(route),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: OgText.body(
                        13,
                        weight: FontWeight.w700,
                        color: labelColor,
                      ),
                    ),
                  ),
                  OgIcon(icon, size: 20, strokeWidth: stroke, color: iconColor),
                ],
              ),
              const SizedBox(height: 6),
              Text(value, style: OgText.heading(34, color: valueColor)),
              const SizedBox(height: 6),
              Text(
                note,
                style: OgText.body(
                  12,
                  weight: FontWeight.w600,
                  color: noteColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Row(
        children: [
          card(
            bg: t.soft,
            label: 'Wallet',
            labelColor: c.textMuted,
            icon: OgIcons.walletCard,
            iconColor: c.text,
            stroke: 1.8,
            value: 'S\$${money(w?.balanceCents ?? 0)}',
            valueColor: c.text,
            note: 'Refunds and history',
            noteColor: c.textMuted,
            route: Routes.wallet,
          ),
          const SizedBox(width: 12),
          card(
            bg: c.inverseCard,
            label: 'Points',
            labelColor: const Color(0xFFC9C9CF),
            icon: OgIcons.pointsStar,
            iconColor: c.accent,
            stroke: 1.6,
            value: (w?.points ?? 0).toStringAsFixed(1),
            valueColor: c.accent,
            note: (w?.pendingPoints ?? 0) > 0
                ? '${(w!.pendingPoints).toStringAsFixed(0)} more pending'
                : 'Earn by playing',
            noteColor: const Color(0xFFC9C9CF),
            route: Routes.points,
          ),
        ],
      ),
    );
  }
}
