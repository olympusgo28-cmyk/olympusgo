import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/pressable.dart';
import '../application/club_providers.dart';
import '../data/club_repository.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';
import 'club_widgets.dart';

const _filterGroups = [
  FilterGroup(
    'sport',
    'Sport',
    ['Badminton', 'Pickleball', 'Tennis', 'Table tennis', 'Running'],
    icons: [
      OgIcons.sportBadminton,
      OgIcons.sportPickleball,
      OgIcons.sportTennis,
      OgIcons.sportTableTennis,
      OgIcons.sportRunning,
    ],
  ),
  FilterGroup('dist', 'Distance', [
    'Within 2 km',
    'Within 5 km',
    'Within 10 km',
  ]),
  FilterGroup('level', 'Skill level', [
    'Fits my level',
    'Beginner friendly',
    'Advanced',
  ]),
  FilterGroup('join', 'Joining', ['Open to join', 'Ask to join']),
  FilterGroup('active', 'Activity', ['Meets this week', 'New this month']),
];

/// "Group": find a club or team, or start one.
class ClubsHomeScreen extends ConsumerStatefulWidget {
  const ClubsHomeScreen({super.key, this.teams = false});

  final bool teams;

  @override
  ConsumerState<ClubsHomeScreen> createState() => _ClubsHomeScreenState();
}

class _ClubsHomeScreenState extends ConsumerState<ClubsHomeScreen> {
  late bool _teams = widget.teams;
  var _tab = ClubTab.mine;
  var _query = '';
  var _filters = <String, String>{};

  bool _matches(Club c) {
    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty &&
        !'${c.name} ${c.area} ${c.primaryRange.label}'.toLowerCase().contains(
          q,
        )) {
      return false;
    }
    final sport = _filters['sport'];
    if (sport != null && !c.sports.any((s) => s.sport.label == sport)) {
      return false;
    }
    switch (_filters['level']) {
      case 'Fits my level':
        if (!c.primaryRange.contains(SkillBand.forLevel(4))) return false;
      case 'Beginner friendly':
        if (c.primaryRange.min > SkillBand.hb.index) return false;
      case 'Advanced':
        if (c.primaryRange.max < SkillBand.ad.index) return false;
    }
    switch (_filters['join']) {
      case 'Open to join':
        if (c.visibility != ClubVisibility.public ||
            c.joinMode != JoinMode.anyone) {
          return false;
        }
      case 'Ask to join':
        if (c.visibility == ClubVisibility.public &&
            c.joinMode == JoinMode.anyone) {
          return false;
        }
    }
    switch (_filters['active']) {
      case 'Meets this week':
        if (c.meetsPerWeek == 0) return false;
      case 'New this month':
        final created = c.createdAt;
        if (created == null || DateTime.now().difference(created).inDays > 31) {
          return false;
        }
    }
    return true;
  }

  Future<void> _openFilters() async {
    final picked = await showFilterSheet(
      context,
      groups: _filterGroups,
      selected: _filters,
    );
    if (picked != null) setState(() => _filters = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final tabNames = [_teams ? 'My teams' : 'My clubs', 'Recommended', 'New'];
    return Scaffold(
      backgroundColor: c.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // One box, so the overlapping search bar paints above the hero.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _hero(context),
                  Transform.translate(
                    offset: const Offset(0, -28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _searchBar(context),
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                child: KitSegments(
                  labels: const ['Clubs', 'Teams'],
                  selected: _teams ? 1 : 0,
                  onSelect: (i) => setState(() {
                    _teams = i == 1;
                    _tab = ClubTab.mine;
                  }),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: KitUnderlineTabs(
                labels: tabNames,
                selected: _tab.index,
                onSelect: (i) => setState(() => _tab = ClubTab.values[i]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList.list(
                children: [
                  if (_tab == ClubTab.recommended)
                    Padding(
                      padding: const EdgeInsets.only(top: 14, bottom: 2),
                      child: Text(
                        'Picked for your skill level range',
                        style: OgText.body(
                          13,
                          weight: FontWeight.w600,
                          color: c.textMuted,
                        ),
                      ),
                    ),
                  if (_teams) ..._teamRows(context) else ..._clubRows(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return CourtHero(
      color: const Color(0xFF0E6B4E),
      height: 300 + top,
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                color: context.tones.gold,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                OgIcons.group,
                size: 100,
                strokeWidth: 1.1,
                color: context.tones.onGold,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: top + 12,
            child: Row(
              children: [
                const KitBackPill(),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) {
                    Crumbs.name(context, 'Group');
                    return Text(
                      'Group',
                      style: OgText.heading(30, color: Colors.white),
                    );
                  },
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 54,
            width: 200,
            child: Pressable(
              semanticLabel: 'Start a club or a team',
              onPressed: () => context.push(Routes.createGroup),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start a club or a team',
                    style: OgText.heading(32, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bring your regulars together',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: OgColors.charcoal900,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Create',
                      style: OgText.body(
                        14,
                        weight: FontWeight.w600,
                        color: Colors.white,
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

  Widget _searchBar(BuildContext context) {
    final c = context.og;
    final active = _filters.isNotEmpty;
    return Container(
      height: 56,
      padding: const EdgeInsets.only(left: 18, right: 8),
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
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              textInputAction: TextInputAction.search,
              style: OgText.body(16, color: c.text),
              cursorColor: c.primary,
              decoration: InputDecoration(
                hintText: 'Search clubs and teams',
                hintStyle: OgText.body(16, color: c.textMuted),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          Container(width: 1, height: 28, color: c.border),
          KitIconButton(
            icon: OgIcons.sliders,
            label: active ? 'Filters, ${_filters.length} on' : 'Filters',
            strokeWidth: 1.9,
            color: active ? c.primary : c.text,
            onPressed: _openFilters,
          ),
        ],
      ),
    );
  }

  List<Widget> _clubRows(BuildContext context) {
    final list = ref.watch(clubListProvider(_tab));
    return switch (list) {
      AsyncData(:final value) => _rowsOrEmpty(context, [
        for (final item in value.where((i) => _matches(i.club)))
          _ClubRow(item: item),
      ]),
      AsyncError() => [
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: OgErrorText("Clubs aren't loading. Pull to try again."),
        ),
      ],
      _ => [_loading()],
    };
  }

  List<Widget> _teamRows(BuildContext context) {
    final list = ref.watch(teamListProvider(_tab));
    final q = _query.trim().toLowerCase();
    return switch (list) {
      AsyncData(:final value) => _rowsOrEmpty(context, [
        for (final item in value)
          if (q.isEmpty ||
              '${item.team.name} ${item.meta} ${item.tag}'
                  .toLowerCase()
                  .contains(q))
            _TeamRow(item: item),
      ]),
      AsyncError() => [
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: OgErrorText("Teams aren't loading. Try again."),
        ),
      ],
      _ => [_loading()],
    };
  }

  List<Widget> _rowsOrEmpty(BuildContext context, List<Widget> rows) {
    final c = context.og;
    if (rows.isNotEmpty) {
      return [
        for (var i = 0; i < rows.length; i++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i == rows.length - 1
                  ? null
                  : Border(bottom: BorderSide(color: c.border)),
            ),
            child: rows[i],
          ),
      ];
    }
    final searching = _query.trim().isNotEmpty || _filters.isNotEmpty;
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 10),
        child: Column(
          children: [
            Text(
              searching
                  ? 'No club or team matches'
                  : (_tab == ClubTab.mine
                        ? (_teams ? 'No teams yet' : 'No clubs yet')
                        : 'Nothing here yet'),
              textAlign: TextAlign.center,
              style: OgText.heading(24, color: c.text),
            ),
            const SizedBox(height: 6),
            Text(
              searching
                  ? 'Check the spelling or try an area name.'
                  : 'Start one, or look in Recommended.',
              textAlign: TextAlign.center,
              style: OgText.body(14, height: 1.45, color: c.textMuted),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _loading() => const Padding(
    padding: EdgeInsets.all(28),
    child: CupertinoActivityIndicator(),
  );
}

class _ClubRow extends StatelessWidget {
  const _ClubRow({required this.item});

  final ClubListItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final club = item.club;
    return Pressable(
      semanticLabel:
          '${club.name}, ${club.memberCount} members, ${club.area}. ${item.note}',
      onPressed: () => context.push(Routes.club(club.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: ExcludeSemantics(
          child: Row(
            children: [
              ClubMark(club, size: 56, radius: 18, fontSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            club.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: OgText.body(
                              17,
                              weight: FontWeight.w600,
                              color: c.text,
                            ),
                          ),
                        ),
                        if (club.visibility != ClubVisibility.public) ...[
                          const SizedBox(width: 6),
                          KitTag(
                            club.visibility.label,
                            height: 20,
                            fontSize: 11,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${club.memberCount} members, ${club.area}',
                      style: OgText.body(13, color: c.textMuted),
                    ),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.note,
                        style: OgText.body(
                          13,
                          weight: FontWeight.w600,
                          color: c.link,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 14),
              LevelTag(club.primaryRange.label),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.item});

  final TeamListItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final team = item.team;
    return Pressable(
      semanticLabel: '${team.name}, ${item.meta}. ${item.note}',
      onPressed: () => context.push(Routes.team(team.id)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: ExcludeSemantics(
          child: Row(
            children: [
              TeamMark(team, fontSize: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: OgText.body(
                        17,
                        weight: FontWeight.w600,
                        color: c.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(item.meta, style: OgText.body(13, color: c.textMuted)),
                    if (item.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.note,
                        style: OgText.body(
                          13,
                          weight: FontWeight.w600,
                          color: c.link,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (item.tag.isNotEmpty) ...[
                const SizedBox(width: 14),
                LevelTag(item.tag),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
