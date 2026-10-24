import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/env.dart';
import '../../core/format.dart';
import '../../core/router/routes.dart';
import '../../core/theme/og_colors.dart';
import '../../core/theme/og_text.dart';
import '../../core/widgets/og_icon.dart';
import '../../core/widgets/og_kit.dart';
import '../../core/widgets/pressable.dart';
import '../clubs/application/club_providers.dart';
import '../clubs/data/club_repository.dart';
import '../clubs/presentation/club_widgets.dart';
import '../home/home_rows.dart';
import '../play/application/play_providers.dart';
import '../play/domain/activity.dart';
import '../shell/main_shell.dart';
import '../social/application/social_providers.dart';

/// What the scope chips can narrow Discover to.
enum _Scope {
  all('All'),
  meets('Meets'),
  events('Events'),
  tournaments('Tournaments'),
  clubs('Clubs'),
  players('Players'),
  malls('Malls'),
  items('Items');

  const _Scope(this.label);
  final String label;
}

const _navy = Color(0xFF2F3A5F);

// Distance is left out until venues carry coordinates.
const _filterGroups = [
  FilterGroup('sport', 'Sport', [
    'Badminton',
    'Pickleball',
    'Tennis',
    'Table tennis',
    'Running',
  ]),
  FilterGroup('when', 'When', ['Today', 'This week', 'This month']),
  FilterGroup('price', 'Price', ['Free', 'Paid']),
  FilterGroup('level', 'Skill level', ['Fits my level', 'All levels']),
];

/// Discover: a featured tournament, search, scope chips and rows of
/// everything nearby, narrowed by the Filters sheet.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  _Scope _scope = _Scope.all;
  Map<String, String> _filters = const {};

  bool _shows(_Scope s) => _scope == _Scope.all || _scope == s;

  Future<void> _refresh() async {
    ref.invalidate(upcomingOfKindProvider);
    ref.invalidate(clubListProvider);
    ref.invalidate(suggestedPlayersProvider);
  }

  Future<void> _openFilters() async {
    final next = await showFilterSheet(
      context,
      groups: _filterGroups,
      selected: _filters,
    );
    if (next != null) setState(() => _filters = next);
  }

  /// Applies the Filters sheet to an activity.
  bool _matches(Activity a, List<PlaySportPref> prefs) {
    final sport = _filters['sport'];
    if (sport != null && !a.sports.any((s) => s.label == sport)) {
      return false;
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = switch (_filters['when']) {
      'Today' => 1,
      'This week' => 7,
      'This month' => 31,
      _ => null,
    };
    if (days != null && !a.startsAt.isBefore(today.add(Duration(days: days)))) {
      return false;
    }
    switch (_filters['price']) {
      case 'Free' when a.feeCents > 0:
      case 'Paid' when a.feeCents == 0:
        return false;
    }
    if (_filters['level'] == 'Fits my level') {
      final mine = prefs.where((p) => a.sports.contains(p.sport)).firstOrNull;
      if (mine == null) return false;
      if (a.levelMin != null && a.levelMax != null) {
        if (a.levelMax! < mine.levelMin || a.levelMin! > mine.levelMax) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final prefs = ref.watch(playSportsProvider).value ?? const [];
    final sport = prefs.firstOrNull?.sport;
    bool where(Activity a) => _matches(a, prefs);
    final heroHeight = HeroWithSearch.heroHeight(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: StatusScrim(
        darkHero: true,
        after: heroHeight - MediaQuery.of(context).padding.top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refresh),
            SliverToBoxAdapter(
              child: HeroWithSearch(
                height: heroHeight,
                hero: _Hero(
                  height: heroHeight,
                  filtered: _filters.isNotEmpty,
                  onFilters: _openFilters,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 18),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Semantics(
                    label: 'Show',
                    child: Row(
                      children: [
                        for (final s in _Scope.values) ...[
                          if (s != _Scope.all) const SizedBox(width: 8),
                          KitChip(
                            label: s.label,
                            selected: _scope == s,
                            onTap: () => setState(() => _scope = s),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        // Venues have no coordinates yet, so live accounts
                        // see "near you" rather than a neighbourhood.
                        '${_filters['sport'] ?? sport?.label ?? 'Sports'} '
                        'near ${Env.hasSupabase ? 'you' : 'Tampines'}',
                        style: OgText.body(
                          14,
                          weight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                    KitLink(
                      'Change',
                      onPressed: () => context.push(Routes.playAddSport),
                    ),
                  ],
                ),
              ),
            ),
            if (_shows(_Scope.meets))
              SliverToBoxAdapter(
                child: ActivityShelf(
                  kind: ActivityKind.meet,
                  title: 'Meets',
                  where: where,
                ),
              ),
            if (_shows(_Scope.events))
              SliverToBoxAdapter(
                child: ActivityShelf(
                  kind: ActivityKind.event,
                  title: 'Events',
                  where: where,
                ),
              ),
            if (_shows(_Scope.tournaments))
              SliverToBoxAdapter(
                child: ActivityShelf(
                  kind: ActivityKind.tournament,
                  title: 'Tournaments',
                  where: where,
                ),
              ),
            if (_shows(_Scope.clubs))
              const SliverToBoxAdapter(
                child: ClubShelf(
                  title: 'Clubs to join',
                  tab: ClubTab.recommended,
                ),
              ),
            if (_shows(_Scope.players))
              SliverToBoxAdapter(
                child: PlayerShelf(
                  title: 'Players and creators',
                  linkLabel: 'Top creator',
                  linkRoute: Routes.creator('ravi'),
                ),
              ),
            if (_shows(_Scope.malls))
              const SliverToBoxAdapter(child: MallShelf()),
            if (_shows(_Scope.items))
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

class _Hero extends ConsumerWidget {
  const _Hero({
    required this.height,
    required this.filtered,
    required this.onFilters,
  });

  final double height;
  final bool filtered;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final top = MediaQuery.of(context).padding.top;
    // The soonest tournament with a cover is featured.
    final featured = ref
        .watch(upcomingOfKindProvider(ActivityKind.tournament))
        .value
        ?.where((a) => a.coverTitle != null)
        .firstOrNull;
    final closes = featured?.registrationClosesAt;
    return CourtHero(
      color: _navy,
      height: height,
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                OgIcons.trophyCup,
                size: 96,
                strokeWidth: 1.2,
                color: c.onPrimary,
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
                  child: Semantics(
                    header: true,
                    child: Text(
                      'Discover',
                      style: OgText.heading(32, color: Colors.white),
                    ),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    KitIconButton(
                      icon: OgIcons.sliders,
                      label: filtered ? 'Filters, on' : 'Filters',
                      strokeWidth: 1.9,
                      background: Colors.white,
                      color: OgColors.ink,
                      onPressed: onFilters,
                    ),
                    if (filtered)
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 56,
            width: 190,
            child: Pressable(
              semanticLabel: featured == null
                  ? 'Find your next game'
                  : 'Featured: ${featured.title}',
              onPressed: () => context.push(
                featured == null ? Routes.play : Routes.activity(featured.id),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  KitTag(
                    'Featured',
                    background: OgColors.ink,
                    foreground: OgColors.lime,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    featured?.title ?? 'Find your next game',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    // Sized down from the artboard's condensed face, as on
                    // Home, to stay clear of the circle.
                    style: OgText.heading(26, color: Colors.white, height: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    closes != null
                        ? 'Entries close ${Fmt.day(closes)}'
                        : 'Meets, tournaments, events',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: Colors.white,
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
