import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/pressable.dart';
import '../../clubs/domain/club_sport.dart';
import '../../home/home_rows.dart';
import '../../onboarding/domain/sport.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import 'create_screens.dart';
import '../domain/hub.dart';
import 'play_card.dart';

/// The v2 icon for a Play sport.
String sportIcon(Sport s) => ClubSport.values
    .firstWhere((c) => c.playSport == s, orElse: () => ClubSport.badminton)
    .icon;

/// Sports without singles or doubles.
bool _teamless(Sport s) => s == Sport.running || s == Sport.hyrox;

/// Play: host your own session, filters, sport pills, my next session and
/// every upcoming Meet, tournament and event.
class PlayScreen extends ConsumerStatefulWidget {
  const PlayScreen({super.key, this.initialKind});

  final ActivityKind? initialKind;

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  late HubTab _tab = HubTab.of(widget.initialKind);

  Future<void> _refresh() async {
    ref.invalidate(playSportsProvider);
    ref.invalidate(hubActivitiesProvider);
    ref.invalidate(myScheduleProvider);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final top = MediaQuery.of(context).padding.top;
    final heroHeight = 300 + top;
    Crumbs.name(context, 'Play');
    final list = ref.watch(hubActivitiesProvider(_tab));
    final mine = (ref.watch(myScheduleProvider).value ?? const <Activity>[])
        .where((a) => a.startsAt.isAfter(DateTime.now()))
        .toList();
    return Scaffold(
      backgroundColor: c.bg,
      body: StatusScrim(
        after: heroHeight - top,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            CupertinoSliverRefreshControl(onRefresh: _refresh),
            SliverToBoxAdapter(
              child: SizedBox(
                height: heroHeight + 32,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: _Hero(height: heroHeight),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 0,
                      child: _FilterBar(tab: _tab),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: KitUnderlineTabs(
                  labels: [for (final t in HubTab.values) t.label],
                  selected: _tab.index,
                  onSelect: (i) => setState(() => _tab = HubTab.values[i]),
                ),
              ),
            ),
            SliverToBoxAdapter(child: _SportPills(tab: _tab)),
            if (mine.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                  child: _NextSession(next: mine.first, count: mine.length),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                10,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: switch (list) {
                AsyncData(:final value) when value.isEmpty =>
                  SliverToBoxAdapter(child: _Empty(tab: _tab)),
                AsyncData(:final value) => SliverList.separated(
                  itemCount: value.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => PlayCard(activity: value[i]),
                ),
                AsyncError() => const SliverToBoxAdapter(
                  child: KitNote(
                    "Couldn't load sessions. Pull down to try again.",
                  ),
                ),
                _ => const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CupertinoActivityIndicator(),
                  ),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final top = MediaQuery.of(context).padding.top;
    return CourtHero(
      color: c.primary,
      height: height,
      child: Stack(
        children: [
          Positioned(
            right: -36,
            bottom: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: const BoxDecoration(
                color: OgColors.ink,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                OgIcons.racquet,
                size: 100,
                strokeWidth: 1.1,
                color: OgColors.lime,
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
                Semantics(
                  header: true,
                  child: Text(
                    'Play',
                    style: OgText.heading(30, color: c.onPrimary),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            bottom: 54,
            width: 200,
            child: Pressable(
              semanticLabel: 'Host your own session: Meet, tournament, event',
              onPressed: () => showCreateMenu(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Host your own session',
                    style: OgText.heading(28, color: c.onPrimary, height: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Meet, tournament, event',
                    style: OgText.body(
                      13,
                      weight: FontWeight.w600,
                      color: c.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: OgColors.ink,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        'Create',
                        style: OgText.body(
                          14,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
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
}

/// The search pill: the tab's first three filters and a search button, all
/// opening the Filters sheet.
class _FilterBar extends ConsumerWidget {
  const _FilterBar({required this.tab});

  final HubTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final picked = ref.watch(playSportsProvider).value ?? const [];
    final f = ref.watch(hubFiltersProvider)[tab] ?? const {};
    String value(HubFilterGroup g) => g.isSport
        ? (picked.isEmpty ? 'All' : picked.map((p) => p.sport.label).join(', '))
        : f[g.key] ?? g.options.first;
    final bar = tab.groups.take(3).toList();
    void open() => showHubFilters(context, tab);
    return Container(
      height: 64,
      padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(32),
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
          for (var i = 0; i < bar.length; i++)
            Expanded(
              flex: i == 0 ? 5 : 4,
              child: Pressable(
                semanticLabel: '${bar[i].title}: ${value(bar[i])}',
                onPressed: open,
                child: Container(
                  height: 64,
                  padding: const EdgeInsets.fromLTRB(16, 0, 6, 0),
                  decoration: BoxDecoration(
                    border: i == 0
                        ? null
                        : Border(left: BorderSide(color: c.border)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        bar[i].title,
                        style: OgText.body(12, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        value(bar[i]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: OgText.body(
                          14,
                          weight: FontWeight.w500,
                          color: c.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Pressable(
            semanticLabel: 'Search',
            onPressed: open,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.primary,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: OgIcon(
                OgIcons.searchCircle,
                size: 22,
                strokeWidth: 2.2,
                color: c.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "All", the picked sports as dark pills, and Add sport.
class _SportPills extends ConsumerWidget {
  const _SportPills({required this.tab});

  final HubTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final picked = ref.watch(playSportsProvider).value ?? const [];
    final sports = ref.read(playSportsProvider.notifier);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Row(
        children: kitSpaced([
          KitChip(
            label: 'All',
            height: 44,
            selected: picked.isEmpty,
            onTap: () {
              HapticFeedback.selectionClick();
              sports.clear();
            },
          ),
          for (final p in picked)
            _SportPill(
              pref: p,
              tab: tab,
              onEdit: () => editPlaySport(context, ref, p.sport, tab),
              onRemove: () {
                HapticFeedback.selectionClick();
                sports.remove(p.sport);
              },
            ),
          _AddSportChip(onTap: () => context.push(Routes.playAddSportFor(tab))),
        ], 8),
      ),
    );
  }
}

class _SportPill extends StatelessWidget {
  const _SportPill({
    required this.pref,
    required this.tab,
    required this.onEdit,
    required this.onRemove,
  });

  final PlaySportPref pref;
  final HubTab tab;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final options = sportPillText(pref, tab);
    final text = options.isEmpty ? pref.sport.label : options;
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 2),
      decoration: BoxDecoration(
        color: OgColors.ink,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(
            semanticLabel: options.isEmpty
                ? pref.sport.label
                : 'Edit ${pref.sport.label}, $options',
            onPressed: onEdit,
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  OgIcon(
                    sportIcon(pref.sport),
                    size: 20,
                    strokeWidth: 1.9,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 7),
                  ExcludeSemantics(
                    child: Text(
                      '•',
                      style: OgText.body(
                        14,
                        weight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    text,
                    style: OgText.body(
                      14,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Pressable(
            semanticLabel: 'Remove ${pref.sport.label}',
            onPressed: onRemove,
            child: SizedBox(
              width: 40,
              height: 44,
              child: Center(
                child: OgIcon(
                  OgIcons.close,
                  size: 16,
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddSportChip extends StatelessWidget {
  const _AddSportChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: 'Add sport',
      onPressed: onTap,
      child: DashedBox(
        color: c.borderControl,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OgIcon(OgIcons.plus, size: 18, strokeWidth: 2.2, color: c.link),
              const SizedBox(width: 6),
              Text(
                'Add sport',
                style: OgText.body(14, weight: FontWeight.w700, color: c.link),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dark "My next session" card.
class _NextSession extends StatelessWidget {
  const _NextSession({required this.next, required this.count});

  final Activity next;
  final int count;

  @override
  Widget build(BuildContext context) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final when = nextLabel(next.startsAt).replaceFirst(', ', ' ');
    return Pressable(
      semanticLabel:
          'My next session: ${next.title}, $when, ${next.venue.name}. $count booked',
      onPressed: () => context.push(Routes.schedule()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: OgColors.ink,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    days[next.startsAt.weekday - 1],
                    style: OgText.body(
                      11,
                      weight: FontWeight.w700,
                      color: const Color(0xFFF2C14E),
                    ),
                  ),
                  Text(
                    '${next.startsAt.day}',
                    style: OgText.heading(30, color: Colors.white, height: 1.1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'My next session',
                        style: OgText.body(
                          13,
                          weight: FontWeight.w600,
                          color: const Color(0xFFC9C9CF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      KitTag(
                        '$count',
                        height: 20,
                        fontSize: 11,
                        background: OgColors.lime,
                        foreground: OgColors.ink,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    next.title,
                    style: OgText.body(
                      17,
                      weight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$when, ${next.venue.name}',
                    style: OgText.body(13, color: const Color(0xFFC9C9CF)),
                  ),
                ],
              ),
            ),
            OgIcon(
              OgIcons.chevronRight,
              size: 20,
              strokeWidth: 2,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class _Empty extends ConsumerWidget {
  const _Empty({required this.tab});

  final HubTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final what = switch (tab) {
      HubTab.all => 'sessions',
      HubTab.meet => 'Meets',
      HubTab.tournament => 'tournaments',
      HubTab.event => 'events',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'No $what match these filters',
            textAlign: TextAlign.center,
            style: OgText.body(17, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another day or sport, or host your own.',
            textAlign: TextAlign.center,
            style: OgText.body(14, color: c.textMuted),
          ),
          const SizedBox(height: 16),
          KitButton.outline(
            label: 'Clear filters',
            expand: false,
            height: 44,
            fontSize: 15,
            onPressed: () {
              ref.read(hubFiltersProvider.notifier).reset(tab);
              ref.read(playSportsProvider.notifier).clear();
            },
          ),
        ],
      ),
    );
  }
}

// ─── Filters sheet ─────────────────────────────────────────────────────────

/// The Filters sheet for a Play tab. Choices apply as they are tapped.
Future<void> showHubFilters(BuildContext context, HubTab tab) => showKitSheet(
  context,
  padding: const EdgeInsets.only(top: 10),
  builder: (_) => _HubFiltersSheet(tab: tab),
);

class _HubFiltersSheet extends ConsumerWidget {
  const _HubFiltersSheet({required this.tab});

  final HubTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final picked = ref.watch(playSportsProvider).value ?? const [];
    final f = ref.watch(hubFiltersProvider)[tab] ?? const {};
    final filters = ref.read(hubFiltersProvider.notifier);
    // Sport comes first in the sheet.
    final groups = [
      HubFilterGroup.sport,
      ...tab.groups.where((g) => !g.isSport),
    ];
    final note = picked.isEmpty
        ? (tab.hasLevels
              ? 'Add a sport to set its ${tab.hasGameType ? 'game type and ' : ''}skill level range.'
              : 'Add a sport to narrow the list.')
        : (tab.hasLevels
              ? 'Tap a sport to change its ${tab.hasGameType ? 'game type and ' : ''}skill level range, or add another.'
              : 'Tap a sport to remove it, or add another.');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tab == HubTab.all ? 'Filters' : '${tab.label} filters',
                  style: OgText.heading(26, color: c.text),
                ),
              ),
              KitIconButton(
                icon: OgIcons.close,
                label: 'Close',
                size: 20,
                background: context.tones.soft,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: kitSpaced([
                for (final g in groups)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: g.isSport
                            ? [
                                KitChip(
                                  label: 'All',
                                  selected: picked.isEmpty,
                                  onTap: () => ref
                                      .read(playSportsProvider.notifier)
                                      .clear(),
                                ),
                                for (final p in picked)
                                  KitChip(
                                    label: tab.hasLevels
                                        ? '${p.sport.label} • ${sportPillText(p, tab)}'
                                        : p.sport.label,
                                    icon: sportIcon(p.sport),
                                    selected: true,
                                    onTap: () => tab.hasLevels
                                        ? editPlaySport(
                                            context,
                                            ref,
                                            p.sport,
                                            tab,
                                          )
                                        : ref
                                              .read(playSportsProvider.notifier)
                                              .remove(p.sport),
                                  ),
                                KitChip(
                                  label: '+ Add sport',
                                  foreground: c.link,
                                  onTap: () =>
                                      context.push(Routes.playAddSportFor(tab)),
                                ),
                              ]
                            : [
                                for (final o in g.options)
                                  KitChip(
                                    label: o,
                                    selected:
                                        (f[g.key] ?? g.options.first) == o,
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      filters.set(tab, g.key, o);
                                    },
                                  ),
                              ],
                      ),
                      if (g.isSport) ...[
                        const SizedBox(height: 10),
                        Text(
                          note,
                          style: OgText.body(
                            13,
                            height: 1.35,
                            color: c.textMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
              ], 18),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: KitButton.outline(
                  label: 'Reset',
                  onPressed: () {
                    filters.reset(tab);
                    ref.read(playSportsProvider.notifier).clear();
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: KitButton(
                  label: 'Show results',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sport options ─────────────────────────────────────────────────────────

/// Adds, edits or removes a picked sport. On Meet and tournament tabs this
/// opens its options; elsewhere it toggles the sport. Returns true when
/// something changed.
Future<bool> editPlaySport(
  BuildContext context,
  WidgetRef ref,
  Sport sport,
  HubTab tab,
) async {
  final sports = ref.read(playSportsProvider.notifier);
  final current = (ref.read(playSportsProvider).value ?? const [])
      .where((p) => p.sport == sport)
      .firstOrNull;
  if (!tab.hasLevels) {
    HapticFeedback.selectionClick();
    current == null
        ? await sports.savePref(PlaySportPref(sport: sport))
        : await sports.remove(sport);
    return true;
  }
  final passport = (await ref.read(mySportsProvider.future))
      .where((s) => s.sport == sport.id)
      .firstOrNull;
  if (!context.mounted) return false;
  final result = await showKitSheet<_SportChoice>(
    context,
    builder: (_) => _SportOptionsSheet(
      sport: sport,
      tab: tab,
      current: current,
      passportLevel: passport?.level,
    ),
  );
  switch (result) {
    case _SportChoice(:final pref?):
      await sports.savePref(pref);
      return true;
    case _SportChoice(remove: true):
      await sports.remove(sport);
      return true;
    default:
      return false;
  }
}

class _SportChoice {
  const _SportChoice.save(PlaySportPref this.pref) : remove = false;
  const _SportChoice.remove() : pref = null, remove = true;

  final PlaySportPref? pref;
  final bool remove;
}

class _SportOptionsSheet extends StatefulWidget {
  const _SportOptionsSheet({
    required this.sport,
    required this.tab,
    required this.current,
    required this.passportLevel,
  });

  final Sport sport;
  final HubTab tab;
  final PlaySportPref? current;
  final double? passportLevel;

  @override
  State<_SportOptionsSheet> createState() => _SportOptionsSheetState();
}

class _SportOptionsSheetState extends State<_SportOptionsSheet> {
  late GameType? _game = widget.current?.gameType;
  late bool _custom = widget.current != null
      ? !(widget.current!.levelMin <= 1 && widget.current!.levelMax >= 8)
      : false;
  late int _lo;
  late int _hi;

  @override
  void initState() {
    super.initState();
    final cur = widget.current;
    if (cur != null && _custom) {
      _lo = SkillBand.forLevel(cur.levelMin).index;
      _hi = SkillBand.forLevel(cur.levelMax).index;
    } else {
      // Start around the Passport level, or the middle of the scale.
      final mine = widget.passportLevel == null
          ? null
          : SkillBand.forLevel(widget.passportLevel!).index;
      _lo = mine == null ? 3 : (mine - 1).clamp(0, 7);
      _hi = mine == null ? 5 : (mine + 1).clamp(0, 7);
    }
  }

  PlaySportPref get _pref => PlaySportPref(
    sport: widget.sport,
    gameType: widget.tab.hasGameType ? _game : widget.current?.gameType,
    levelMin: _custom ? _lo + 1.0 : 1,
    levelMax: _custom ? (_hi + 1.9).clamp(1, 8).toDouble() : 8,
  );

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final games = _teamless(widget.sport)
        ? const [null, GameType.social]
        : const [null, GameType.singles, GameType.doubles, GameType.social];
    final mine = widget.passportLevel == null
        ? null
        : SkillBand.forLevel(widget.passportLevel!);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kitSpaced([
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: OgColors.ink,
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: OgIcon(
                  sportIcon(widget.sport),
                  size: 24,
                  strokeWidth: 1.9,
                  color: OgColors.lime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(widget.sport.label, style: OgText.heading(26)),
              ),
              KitIconButton(
                icon: OgIcons.close,
                label: 'Close',
                size: 20,
                background: context.tones.soft,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          if (widget.tab.hasGameType)
            _Options(
              title: 'Game type',
              children: [
                for (final g in games)
                  KitChip(
                    label: g?.label ?? 'Any',
                    selected: _game == g,
                    onTap: () => setState(() => _game = g),
                  ),
              ],
            ),
          _Options(
            title: 'Skill level range',
            children: [
              KitChip(
                label: 'All',
                selected: !_custom,
                onTap: () => setState(() => _custom = false),
              ),
              KitChip(
                label: 'Custom',
                selected: _custom,
                onTap: () => setState(() => _custom = true),
              ),
            ],
            footer: [
              if (_custom) ...[
                const SizedBox(height: 10),
                BandRangePicker(
                  lo: _lo,
                  hi: _hi,
                  onChanged: (lo, hi) => setState(() {
                    _lo = lo;
                    _hi = hi;
                  }),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                !_custom
                    ? 'Every skill level is shown.'
                    : mine == null
                    ? 'Set a level on your Passport to see where you sit.'
                    : 'Your ${widget.sport.label} Passport level is ${mine.label}.',
                style: OgText.body(13, height: 1.35, color: c.textMuted),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (widget.current != null) ...[
                  Expanded(
                    child: KitButton(
                      label: 'Remove',
                      style: KitButtonStyle.dangerOutline,
                      onPressed: () =>
                          Navigator.of(context)
                              .pop(const _SportChoice.remove()),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  flex: 2,
                  child: KitButton(
                    label: widget.current == null ? 'Add sport' : 'Save',
                    onPressed: () =>
                        Navigator.of(context).pop(_SportChoice.save(_pref)),
                  ),
                ),
              ],
            ),
          ),
        ], 18),
      ),
    );
  }
}

class _Options extends StatelessWidget {
  const _Options({
    required this.title,
    required this.children,
    this.footer = const [],
  });

  final String title;
  final List<Widget> children;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: OgText.body(15, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: children),
        ...footer,
      ],
    );
  }
}

/// Eight bands from Low Beginner to Pro on a track. Tapping a band moves
/// the nearer end of the range to it.
class BandRangePicker extends StatefulWidget {
  const BandRangePicker({
    super.key,
    required this.lo,
    required this.hi,
    required this.onChanged,
  });

  final int lo;
  final int hi;
  final void Function(int lo, int hi) onChanged;

  @override
  State<BandRangePicker> createState() => _BandRangePickerState();
}

class _BandRangePickerState extends State<BandRangePicker> {
  /// The end being dragged: true for the low end.
  bool _draggingLo = true;

  int get lo => widget.lo;
  int get hi => widget.hi;

  int _bandAt(double dx, double cell) =>
      (dx / cell).floor().clamp(0, SkillBand.values.length - 1);

  void _dragStart(double dx, double cell) {
    final k = _bandAt(dx, cell);
    // Grab the nearer end; when they meet, the drag direction decides.
    _draggingLo = (k - lo).abs() < (k - hi).abs() || (lo == hi && k <= lo);
  }

  void _dragTo(double dx, double cell) {
    final k = _bandAt(dx, cell);
    var a = lo, b = hi;
    if (lo == hi && k != lo) _draggingLo = k < lo;
    if (_draggingLo) {
      a = k.clamp(0, hi);
    } else {
      b = k.clamp(lo, SkillBand.values.length - 1);
    }
    if (a != lo || b != hi) {
      HapticFeedback.selectionClick();
      widget.onChanged(a, b);
    }
  }

  void _pick(int k) {
    HapticFeedback.selectionClick();
    var a = lo, b = hi;
    if (k <= lo) {
      a = k;
    } else if (k >= hi) {
      b = k;
    } else if (k - lo <= hi - k) {
      a = k;
    } else {
      b = k;
    }
    widget.onChanged(a, b);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    const bands = SkillBand.values;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Min',
                      style: OgText.body(
                        12,
                        weight: FontWeight.w600,
                        color: c.textMuted,
                      ),
                    ),
                    Text(
                      bands[lo].label,
                      style: OgText.body(15, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Max',
                    style: OgText.body(
                      12,
                      weight: FontWeight.w600,
                      color: c.textMuted,
                    ),
                  ),
                  Text(
                    bands[hi].label,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 60,
            child: LayoutBuilder(
              builder: (context, box) {
                final cell = box.maxWidth / bands.length;
                double x(int k) => (k + 0.5) * cell;
                Widget handle(int k) => Positioned(
                  left: x(k) - 14,
                  top: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: OgColors.tangerineLine,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                );
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) =>
                      _dragStart(d.localPosition.dx, cell),
                  onHorizontalDragUpdate: (d) =>
                      _dragTo(d.localPosition.dx, cell),
                  child: Stack(
                    children: [
                      Positioned(
                        left: x(0),
                        right: box.maxWidth - x(bands.length - 1),
                        top: 10,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.borderControl,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Positioned(
                        left: x(lo),
                        width: x(hi) - x(lo),
                        top: 10,
                        height: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      handle(lo),
                      handle(hi),
                      Row(
                        children: [
                          for (var k = 0; k < bands.length; k++)
                            Expanded(
                              child: Pressable(
                                semanticLabel: bands[k].label,
                                selected: k >= lo && k <= hi,
                                onPressed: () => _pick(k),
                                child: Container(
                                  height: 60,
                                  alignment: Alignment.bottomCenter,
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    bands[k].code,
                                    style: OgText.body(
                                      12,
                                      weight: FontWeight.w700,
                                      color: k >= lo && k <= hi
                                          ? c.text
                                          : const Color(0xFF8A8A90),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Text(
            'Drag either end, or tap a level.',
            style: OgText.body(12, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Add sport ─────────────────────────────────────────────────────────────

/// Pick sports for Play. On Meet and tournament tabs each sport opens its
/// options; elsewhere a tap adds or removes it.
class PlayAddSportScreen extends ConsumerStatefulWidget {
  const PlayAddSportScreen({super.key, this.tab = HubTab.all});

  final HubTab tab;

  @override
  ConsumerState<PlayAddSportScreen> createState() => _PlayAddSportScreenState();
}

class _PlayAddSportScreenState extends ConsumerState<PlayAddSportScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final tab = widget.tab;
    final picked = ref.watch(playSportsProvider).value ?? const [];
    final passport = ref.watch(mySportsProvider).value ?? const [];
    final q = _q.trim().toLowerCase();
    final shown = Sport.play
        .where((s) => q.isEmpty || s.label.toLowerCase().contains(q))
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Add sport', border: true),
      gap: 0,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      children: [
        KitSearchField(
          hint: 'Search sports',
          soft: true,
          onChanged: (v) => setState(() => _q = v),
        ),
        const SizedBox(height: 14),
        Text(
          tab.hasLevels
              ? 'Pick a sport, then set its ${tab.hasGameType ? 'game type and ' : ''}skill level range. You can add more than one.'
              : 'Tap a sport to add it, tap it again to remove it.',
          style: OgText.body(13, height: 1.4, color: c.textMuted),
        ),
        const SizedBox(height: 6),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'No sport matches. Check the spelling or clear the search.',
              style: OgText.body(15, color: c.textMuted),
            ),
          ),
        for (final s in shown)
          Builder(
            builder: (context) {
              final pref = picked.where((p) => p.sport == s).firstOrNull;
              final level = passport
                  .where((p) => p.sport == s.id)
                  .firstOrNull
                  ?.level;
              final sub = pref != null
                  ? [
                      'Added',
                      if (tab.hasLevels) sportPillText(pref, tab),
                    ].join(' • ')
                  : level != null
                  ? 'Your Passport level: ${SkillBand.forLevel(level).code}'
                  : 'No Passport level yet';
              return Pressable(
                semanticLabel: '${s.label}. $sub',
                selected: pref != null,
                onPressed: () async {
                  final changed = await editPlaySport(context, ref, s, tab);
                  // Setting a sport's options finishes adding it.
                  if (changed && tab.hasLevels && context.mounted) {
                    kitPop(context);
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(minHeight: 68),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: c.border)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: pref != null ? OgColors.ink : t.soft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: OgIcon(
                          sportIcon(s),
                          size: 24,
                          strokeWidth: 1.9,
                          color: pref != null ? OgColors.lime : c.text,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.label,
                              style: OgText.body(16, weight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sub,
                              style: OgText.body(13, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      OgIcon(
                        pref != null ? OgIcons.tick : OgIcons.plus,
                        size: 22,
                        strokeWidth: 2.2,
                        color: pref != null ? c.link : const Color(0xFF9A9AA0),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
