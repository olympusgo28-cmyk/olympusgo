import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/og_buttons.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../../play/application/play_providers.dart';
import '../../play/domain/activity.dart';
import '../../shell/tab_page.dart';
import '../application/social_providers.dart';
import '../domain/social_models.dart';

/// Recent searches for this session, newest first.
final recentSearchesProvider = NotifierProvider<RecentSearches, List<String>>(
  RecentSearches.new,
);

class RecentSearches extends Notifier<List<String>> {
  @override
  List<String> build() => const [
    'Badminton doubles Tampines',
    'Hannah Goh',
    'Pickleball Sunday',
  ];

  void add(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    state = [
      t,
      ...state.where((s) => s.toLowerCase() != t.toLowerCase()),
    ].take(5).toList();
  }
}

final playerSearchProvider = FutureProvider.autoDispose
    .family<List<PlayerSummary>, String>(
      (ref, q) => ref.watch(socialRepositoryProvider).search(q),
    );

final activitySearchProvider = FutureProvider.autoDispose
    .family<List<Activity>, String>(
      (ref, q) => ref.watch(playRepositoryProvider).search(q),
    );

Widget _searchHeader(
  BuildContext context, {
  required TextEditingController controller,
  required ValueChanged<String> onSubmitted,
  bool autofocus = false,
}) {
  return Row(
    children: [
      // The chevron sits 10px left of its box, so the field lands 34 + 8 in.
      const SizedBox(width: 42, child: OgBackButton()),
      Expanded(
        child: OgSearchField(
          hint: 'Search Meets, players and clubs',
          controller: controller,
          autofocus: autofocus,
          onSubmitted: onSubmitted,
        ),
      ),
    ],
  );
}

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _go(String q) {
    if (q.trim().isEmpty) return;
    ref.read(recentSearchesProvider.notifier).add(q);
    context.push(Routes.searchResults(q.trim()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final recent = ref.watch(recentSearchesProvider);
    return TabPage(
      children: [
        _searchHeader(
          context,
          controller: _q,
          onSubmitted: _go,
          autofocus: true,
        ),
        if (recent.isNotEmpty) ...[
          const SectionLabel('Recent', top: 22, size: 13),
          for (final r in recent)
            ListRow(
              minHeight: 52,
              onTap: () => _go(r),
              leading: OgIcon(OgIcons.clock, size: 22, color: c.textMuted),
              title: r,
            ),
        ],
        const SectionLabel('Browse by sport', top: 22, size: 13),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in [
              'Badminton',
              'Tennis',
              'Pickleball',
              'Table tennis',
              'Running',
              'Padel',
            ])
              OgChip(label: s, onTap: () => _go(s)),
          ],
        ),
        const SectionLabel('Trending near you', top: 22, size: 13),
        for (final m
            in ref.watch(upcomingMeetsProvider).value ?? const <Activity>[])
          ListRow(
            onTap: () => context.push(Routes.activity(m.id)),
            leading: Avatar(
              initials: m.title[0],
              tone: AvatarTone.forId(m.id),
              square: true,
            ),
            title: m.title,
            subtitle: '${m.venue.name} · ${Fmt.dayTime(m.startsAt)}',
            trailing: OgIcon(
              OgIcons.chevronRight,
              size: 22,
              color: c.text,
              strokeWidth: 2.5,
            ),
          ),
      ],
    );
  }
}

enum _Filter { all, players, meets, clubs, venues }

class SearchResultsScreen extends ConsumerStatefulWidget {
  const SearchResultsScreen({super.key, required this.query});

  final String query;

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late final _q = TextEditingController(text: widget.query);
  late String _query = widget.query;
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final players = ref.watch(playerSearchProvider(_query));
    final mine = ref.watch(myFollowingProvider).value ?? const {};
    final showPlayers = _filter == _Filter.all || _filter == _Filter.players;
    final showMeets = _filter == _Filter.all || _filter == _Filter.meets;

    return TabPage(
      children: [
        _searchHeader(
          context,
          controller: _q,
          onSubmitted: (v) {
            ref.read(recentSearchesProvider.notifier).add(v);
            setState(() => _query = v.trim());
          },
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: [
              for (final f in _Filter.values) ...[
                if (f != _Filter.all) const SizedBox(width: 8),
                OgChip(
                  label: switch (f) {
                    _Filter.all => 'All',
                    _Filter.players => 'Players',
                    _Filter.meets => 'Meets',
                    _Filter.clubs => 'Clubs',
                    _Filter.venues => 'Venues',
                  },
                  selected: f == _filter,
                  onTap: () => setState(() => _filter = f),
                ),
              ],
            ],
          ),
        ),
        if (showPlayers) ...[
          const SectionLabel('Players', top: 22, size: 13),
          ...switch (players) {
            AsyncData(:final value) when value.isEmpty => [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No players match "$_query".',
                  style: OgText.body(15, color: c.textMuted),
                ),
              ),
            ],
            AsyncData(:final value) => [
              for (final p in value)
                ListRow(
                  onTap: () => context.push(Routes.player(p.id)),
                  leading: Avatar(
                    initials: p.initials,
                    tone: AvatarTone.forId(p.id),
                    imageUrl: p.avatarUrl,
                  ),
                  title: p.displayName,
                  subtitle: p.handle,
                  trailing: FollowButton(
                    following: mine.contains(p.id),
                    minWidth: 84,
                    onPressed: () async {
                      try {
                        await ref
                            .read(myFollowingProvider.notifier)
                            .toggle(p.id);
                      } on AuthFailure catch (e) {
                        if (context.mounted) {
                          showOgToast(context, e.message, error: true);
                        }
                      }
                    },
                  ),
                ),
            ],
            AsyncError() => [
              const OgErrorText("Search isn't available right now. Try again."),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(20),
                child: CupertinoActivityIndicator(),
              ),
            ],
          },
        ],
        if (showMeets) ...[
          const SectionLabel('Meets', top: 22, size: 13),
          ...switch (ref.watch(activitySearchProvider(_query))) {
            AsyncData(:final value) when value.isEmpty => [
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'No Meets match "$_query".',
                  style: OgText.body(15, color: c.textMuted),
                ),
              ),
            ],
            AsyncData(:final value) => [
              for (final m in value)
                ListRow(
                  onTap: () => context.push(Routes.activity(m.id)),
                  leading: Avatar(
                    initials: m.title[0],
                    tone: AvatarTone.forId(m.id),
                    square: true,
                  ),
                  title: m.title,
                  subtitle:
                      '${m.venue.name} · ${Fmt.dayTime(m.startsAt)} · ${m.isFull ? 'Full' : '${m.spotsLeft} spots left'}',
                ),
            ],
            _ => [
              const Padding(
                padding: EdgeInsets.all(20),
                child: CupertinoActivityIndicator(),
              ),
            ],
          },
        ],
        if (_filter == _Filter.clubs || _filter == _Filter.venues)
          Padding(
            padding: const EdgeInsets.only(top: 22),
            child: Text(
              _filter == _Filter.clubs
                  ? 'Club search arrives with Clubs.'
                  : 'Venue search arrives with court booking.',
              style: OgText.body(15, color: c.textMuted),
            ),
          ),
      ],
    );
  }
}

/// Opens (or creates) the chat with a player, then shows it.
class OpenChatScreen extends ConsumerStatefulWidget {
  const OpenChatScreen({super.key, required this.playerId});

  final String playerId;

  @override
  ConsumerState<OpenChatScreen> createState() => _OpenChatScreenState();
}

class _OpenChatScreenState extends ConsumerState<OpenChatScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  Future<void> _open() async {
    try {
      final id = await ref
          .read(chatRepositoryProvider)
          .openDirect(widget.playerId);
      if (mounted) context.pushReplacement(Routes.chat(id));
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.og.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const OgBackButton(),
              const Spacer(),
              Center(
                child: _error == null
                    ? const CupertinoActivityIndicator()
                    : Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: OgText.lead(context.og.textMuted),
                      ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
