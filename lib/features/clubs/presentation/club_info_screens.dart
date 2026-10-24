import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/club_providers.dart';
import '../domain/club_models.dart';
import '../domain/club_sport.dart';
import 'club_widgets.dart';

/// Loads a club, then builds [builder]; shows a spinner or an error.
class ClubLoader extends ConsumerWidget {
  const ClubLoader({
    super.key,
    required this.id,
    required this.title,
    required this.builder,
  });

  final String id;
  final String title;
  final Widget Function(BuildContext context, Club club) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(clubProvider(id))) {
      AsyncData(:final value) => builder(context, value),
      AsyncError() => KitScaffold(
        header: KitHeader(title: title),
        children: const [OgErrorText("This club isn't loading. Try again.")],
      ),
      _ => Scaffold(
        backgroundColor: context.og.bg,
        body: SafeArea(
          child: Column(
            children: [
              KitHeader(title: title),
              const Expanded(
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

// ─── Club info ─────────────────────────────────────────────────────────────

/// "Club info": About, Rules, Details and Rating.
class ClubAboutScreen extends StatefulWidget {
  const ClubAboutScreen({super.key, required this.id});

  final String id;

  @override
  State<ClubAboutScreen> createState() => _ClubAboutScreenState();
}

class _ClubAboutScreenState extends State<ClubAboutScreen> {
  var _tab = 0;

  @override
  Widget build(BuildContext context) {
    return ClubLoader(
      id: widget.id,
      title: 'Club info',
      builder: (context, club) {
        final c = context.og;
        return Scaffold(
          backgroundColor: c.bg,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitHeader(
                  title: 'Club info',
                  center: false,
                  titleSize: 20,
                  trailing: club.canManage
                      ? KitIconButton(
                          icon: OgIcons.settings,
                          label: 'Club settings',
                          strokeWidth: 1.8,
                          border: true,
                          onPressed: () =>
                              context.push(Routes.clubSettings(club.id)),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.all(14).copyWith(left: 16),
                  child: Row(
                    children: [
                      ClubMark(club, size: 64, radius: 16, fontSize: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              club.name,
                              style: OgText.display(20, color: c.text),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              [
                                ?club.primarySport?.label,
                                club.area,
                                club.visibility.label,
                              ].join(' · '),
                              style: OgText.body(14, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                KitUnderlineTabs(
                  labels: const ['About', 'Rules', 'Details', 'Rating'],
                  selected: _tab,
                  spread: true,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  onSelect: (i) => setState(() => _tab = i),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      switch (_tab) {
                        0 => _Panel(
                          title: 'About',
                          child: Text(
                            club.description.isEmpty
                                ? 'The organizers have not written about the club yet.'
                                : club.description,
                            style: OgText.body(
                              15,
                              height: 1.5,
                              color: context.tones.onTag,
                            ),
                          ),
                        ),
                        1 => _Panel(
                          title: 'Club rules',
                          child: club.rules.isEmpty
                              ? Text(
                                  'No club rules yet.',
                                  style: OgText.body(15, color: c.textMuted),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: kitSpaced([
                                    for (var i = 0; i < club.rules.length; i++)
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            child: Text(
                                              '${i + 1}.',
                                              style: OgText.body(
                                                15,
                                                height: 1.45,
                                                color: context.tones.onTag,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              club.rules[i],
                                              style: OgText.body(
                                                15,
                                                height: 1.45,
                                                color: context.tones.onTag,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ], 8),
                                ),
                        ),
                        2 => _Details(club: club),
                        _ => _Rating(club: club),
                      },
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.title, this.gap = 8});

  final String? title;
  final Widget child;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.og.bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.og.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: OgText.display(16, color: context.og.text)),
            SizedBox(height: gap),
          ],
          child,
        ],
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final created = club.createdAt;
    final items = [
      ('Sport', club.sportLabels.isEmpty ? 'Not set' : club.sportLabels),
      ('Area', club.area),
      ('Level range', club.primaryRange.label),
      ('Club type', club.visibility.label),
      ('Home venue', club.homeVenue ?? 'Not set'),
      (
        'Created',
        created == null
            ? '—'
            : '${Fmt.monthsLong[created.month - 1]} ${created.year}',
      ),
    ];
    Widget cell((String, String) e) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(e.$1, style: OgText.body(13, color: c.textMuted)),
        const SizedBox(height: 2),
        Text(e.$2, style: OgText.body(15, weight: FontWeight.w600)),
      ],
    );
    return _Panel(
      child: Column(
        children: kitSpaced([
          for (var i = 0; i < items.length; i += 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: cell(items[i])),
                const SizedBox(width: 18),
                Expanded(child: cell(items[i + 1])),
              ],
            ),
        ], 18),
      ),
    );
  }
}

/// The rating panel, and for members a way to rate the club.
class _Rating extends ConsumerWidget {
  const _Rating({required this.club});

  final Club club;

  Future<void> _rate(BuildContext context, WidgetRef ref) async {
    var stars = club.myStars ?? 0;
    final review = TextEditingController();
    var busy = false;
    await showKitSheet<void>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, setSheet) {
          final t = sheet.tones;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kitSpaced([
              Text('Rate ${club.name}', style: OgText.heading(22)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    KitIconButton(
                      icon: OgIcons.star,
                      label: '$i ${i == 1 ? 'star' : 'stars'}',
                      size: 32,
                      fill: i <= stars,
                      color: i <= stars ? t.gold : sheet.og.textMuted,
                      onPressed: () => setSheet(() => stars = i),
                    ),
                ],
              ),
              KitTextArea(
                label: 'What is it like to play here?',
                optional: true,
                controller: review,
              ),
              KitButton(
                label: stars == 0 ? 'Pick the stars' : 'Save rating',
                loading: busy,
                onPressed: stars == 0
                    ? null
                    : () async {
                        setSheet(() => busy = true);
                        try {
                          await ref
                              .read(clubRepositoryProvider)
                              .rateClub(club.id, stars, review.text.trim());
                          ref.invalidate(clubProvider(club.id));
                          if (sheet.mounted) Navigator.of(sheet).pop();
                        } on AuthFailure catch (e) {
                          if (sheet.mounted) {
                            showOgToast(sheet, e.message, error: true);
                          }
                          setSheet(() => busy = false);
                        }
                      },
              ),
              const SizedBox(height: 8),
            ], 14),
          );
        },
      ),
    );
    review.dispose();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: kitSpaced([
        _RatingPanel(club: club),
        if (club.isMember && !club.isOwner)
          KitButton.outline(
            label: club.myStars == null
                ? 'Rate this club'
                : 'Your rating: ${club.myStars} stars · Change',
            onPressed: () => _rate(context, ref),
          ),
      ], 12),
    );
  }
}

class _RatingPanel extends StatelessWidget {
  const _RatingPanel({required this.club});

  final Club club;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    if (club.rating == null || club.ratingCount < 10) {
      return const _Panel(
        child: Text(
          'Members rate the club they play in. Clubs show a rating once they have at least 10 reviews.',
        ),
      );
    }
    final total = club.ratingSpread.fold(0, (a, b) => a + b);
    return _Panel(
      gap: 14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                club.rating!.toStringAsFixed(1),
                style: OgText.display(40, height: 1, color: c.text),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    label: '${club.rating!.toStringAsFixed(1)} out of 5 stars',
                    child: Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              CupertinoIcons.star_fill,
                              size: 18,
                              color: i <= club.rating!.round()
                                  ? t.gold
                                  : const Color(0xFFE7E5DC),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${club.ratingCount} Meet reviews · last 90 days',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var star = 5; star >= 1; star--)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text(
                      '$star★',
                      style: OgText.body(13, weight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: total == 0
                            ? 0
                            : club.ratingSpread[5 - star] / total,
                        backgroundColor: t.tag,
                        color: t.gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 22,
                    child: Text(
                      '${club.ratingSpread[5 - star]}',
                      textAlign: TextAlign.right,
                      style: OgText.body(13, color: c.textMuted),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Only players who checked in to a Meet can rate it. Clubs show a rating once they have at least 10 reviews.',
            style: OgText.body(14, height: 1.5, color: c.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard ───────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen> {
  ClubSport? _sport;

  @override
  Widget build(BuildContext context) {
    return ClubLoader(
      id: widget.id,
      title: 'Leaderboard',
      builder: (context, club) {
        final c = context.og;
        final sport = _sport ?? club.primarySport ?? ClubSport.badminton;
        final board = ref.watch(clubLeaderboardProvider(club.id, sport));
        final month = Fmt.monthsLong[DateTime.now().month - 1];
        return Scaffold(
          backgroundColor: c.bg,
          body: SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KitHeader(
                  title: 'Leaderboard',
                  subtitle: club.name,
                  titleSize: 19,
                  trailing: Builder(
                    builder: (context) => KitIconButton(
                      icon: OgIcons.shareUp,
                      label: 'Share leaderboard',
                      size: 20,
                      strokeWidth: 1.9,
                      onPressed: () => shareLink(
                        context,
                        '${club.name} leaderboard',
                        Links.leaderboard(club.id),
                      ),
                    ),
                  ),
                ),
                if (club.sports.length > 1)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: c.border)),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final s in club.sports) ...[
                            KitChip(
                              label: s.sport.label,
                              height: 38,
                              selected: s.sport == sport,
                              onTap: () => setState(() => _sport = s.sport),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: switch (board) {
                    AsyncData(:final value) => _Board(
                      title: '$month · ${sport.label}',
                      board: value,
                    ),
                    AsyncError() => const Padding(
                      padding: EdgeInsets.all(16),
                      child: OgErrorText(
                        "The leaderboard isn't loading. Try again.",
                      ),
                    ),
                    _ => const Center(child: CupertinoActivityIndicator()),
                  },
                ),
                if (board.value?.me case final me?)
                  _MeBar(
                    me: me,
                    rank: board.value!.myRank,
                    note: board.value!.myNote,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Board extends StatelessWidget {
  const _Board({required this.title, required this.board});

  final String title;
  final ClubLeaderboard board;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final rows = board.rows;
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: KitNote(
          'No confirmed matches yet this month. Play a ranked Meet to get on the board.',
        ),
      );
    }
    const blocks = [Color(0xFFF2C14E), Color(0xFFD9D9D2), Color(0xFFE0B08A)];
    const heights = [96.0, 72.0, 56.0];
    Widget podium(int i) {
      final e = rows[i];
      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          PlayerFace(e.player, size: i == 0 ? 56 : 46, ring: blocks[i]),
          const SizedBox(height: 6),
          Text(
            e.player.displayName,
            textAlign: TextAlign.center,
            style: OgText.body(14, weight: FontWeight.w600, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(e.score, style: OgText.display(16, color: c.text)),
          const SizedBox(height: 6),
          Container(
            height: heights[i],
            decoration: BoxDecoration(
              color: blocks[i],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            padding: const EdgeInsets.only(top: 8),
            alignment: Alignment.topCenter,
            child: Text(
              '${i + 1}',
              style: OgText.display(22, color: const Color(0xFF3A2C00)),
            ),
          ),
        ],
      );
    }

    (String, Color) move(String m) {
      if (m.startsWith('up')) return ('▲ ${m.substring(3)}', c.primary);
      if (m.startsWith('down')) return ('▼ ${m.substring(5)}', t.dangerText);
      if (m == 'new') return ('New', c.textMuted);
      return ('–', c.textMuted);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(title, style: OgText.display(17, color: c.text)),
            ),
            Text('Rating', style: OgText.body(13, color: c.textMuted)),
          ],
        ),
        const SizedBox(height: 14),
        if (rows.length >= 3)
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: podium(1)),
              const SizedBox(width: 8),
              Expanded(child: podium(0)),
              const SizedBox(width: 8),
              Expanded(child: podium(2)),
            ],
          ),
        if (rows.length > 3) ...[
          const SizedBox(height: 14),
          KitCard(
            children: [
              for (var i = 3; i < rows.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${i + 1}',
                          textAlign: TextAlign.center,
                          style: OgText.body(
                            14,
                            weight: FontWeight.w600,
                            color: t.onTag,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      PlayerFace(rows[i].player, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rows[i].player.displayName,
                              style: OgText.body(15, weight: FontWeight.w600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              rows[i].sub,
                              style: OgText.body(12, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            rows[i].score,
                            style: OgText.display(17, color: c.text),
                          ),
                          Text(
                            move(rows[i].move).$1,
                            style: OgText.body(
                              12,
                              weight: FontWeight.w600,
                              color: move(rows[i].move).$2,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Only confirmed matches count, with at least 4 this month. Resets monthly.',
          textAlign: TextAlign.center,
          style: OgText.body(13, height: 1.5, color: c.textMuted),
        ),
      ],
    );
  }
}

class _MeBar extends StatelessWidget {
  const _MeBar({required this.me, required this.rank, required this.note});

  final LeaderboardEntry me;
  final int? rank;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Container(
      color: c.inverseCard,
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom.clamp(14, 40),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              rank == null ? '–' : '#$rank',
              textAlign: TextAlign.center,
              style: OgText.body(14, weight: FontWeight.w600, color: t.gold),
            ),
          ),
          const SizedBox(width: 12),
          SolidAvatar(
            initials: me.player.initials,
            color: t.gold,
            ink: t.onGold,
            size: 40,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You',
                  style: OgText.body(
                    15,
                    weight: FontWeight.w600,
                    color: c.onInverseCard,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: OgText.body(12, color: const Color(0xFFC9C6BC)),
                ),
              ],
            ),
          ),
          Text(me.score, style: OgText.display(18, color: c.onInverseCard)),
        ],
      ),
    );
  }
}

// ─── Club reward ───────────────────────────────────────────────────────────

class ClubRewardScreen extends ConsumerWidget {
  const ClubRewardScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final reward = ref.watch(clubRewardProvider(id));
    return KitScaffold(
      header: const KitHeader(title: 'Club reward'),
      children: switch (reward) {
        AsyncData(:final value) => [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: c.inverseCard,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    OgIcon(
                      OgIcons.giftBox,
                      size: 28,
                      strokeWidth: 1.8,
                      color: c.highlight,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${value.done} of ${value.target} Meets',
                        style: OgText.heading(26, color: c.onInverseCard),
                      ),
                    ),
                    KitTag(
                      'This month',
                      background: c.highlight,
                      foreground: OgColors.charcoal900,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    minHeight: 10,
                    value: (value.done / value.target).clamp(0, 1),
                    backgroundColor: Colors.white.withAlpha(46),
                    color: c.highlight,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  value.done >= value.target
                      ? 'Unlocked: a ${value.prize} for the club.'
                      : '${value.target - value.done} more qualifying Meet${value.target - value.done == 1 ? '' : 's'} unlock a ${value.prize} for the club.',
                  style: OgText.body(
                    14,
                    height: 1.45,
                    color: const Color(0xFFD9D9D2),
                  ),
                ),
              ],
            ),
          ),
          KitBlock(
            title: 'How a Meet qualifies',
            child: KitCheckList([
              'Meets only. Tournaments and events do not count.',
              '${value.minPlayers} or more players paid and were marked Present',
              'The reward belongs to the club, not to one player',
            ]),
          ),
          KitBlock(
            title: 'This month',
            child: Column(
              children: [
                for (final m in value.meets)
                  Container(
                    constraints: const BoxConstraints(minHeight: 60),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: c.border)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: m.paidPresent >= value.minPlayers
                                ? c.inverseCard
                                : t.soft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: OgIcon(
                            m.paidPresent >= value.minPlayers
                                ? OgIcons.tick
                                : OgIcons.close,
                            size: 16,
                            strokeWidth: 2.6,
                            color: m.paidPresent >= value.minPlayers
                                ? c.highlight
                                : c.borderControl,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${m.title}, ${Fmt.day(m.at)}',
                                style: OgText.body(15, weight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                m.paidPresent >= value.minPlayers
                                    ? '${m.paidPresent} paid players present'
                                    : '${m.paidPresent} paid players present, needs ${value.minPlayers}',
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          m.paidPresent >= value.minPlayers
                              ? 'Counted'
                              : 'Not counted',
                          style: OgText.body(
                            13,
                            weight: FontWeight.w600,
                            color: m.paidPresent >= value.minPlayers
                                ? t.successInk
                                : c.borderControl,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (value.past.isNotEmpty)
            KitBlock(
              title: 'Past rewards',
              child: Column(
                children: [for (final p in value.past) KitKeyValue(p.$1, p.$2)],
              ),
            ),
          const KitNote(
            'Only the owner and Admins see this page. The voucher is paid from Olympus commission and is used at checkout in the Shop.',
          ),
        ],
        AsyncError() => const [
          OgErrorText("The club reward isn't loading. Try again."),
        ],
        _ => const [CupertinoActivityIndicator()],
      },
    );
  }
}
