import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format.dart';
import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/share.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../social/application/social_providers.dart';
import '../../social/domain/social_models.dart';
import '../application/competition_providers.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import '../domain/event_models.dart';
import 'meet_detail_screen.dart' show showDoneSheet;
import 'create_meet_screens.dart' show editActivity;
import 'tournament_screens.dart'
    show CompetitionBanner, bannerButton, coverStatusBar;

/// "1,284".
String _thousands(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

/// The event page: when and where, the live court, the programme and
/// tickets.
class EventPageScreen extends ConsumerStatefulWidget {
  const EventPageScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<EventPageScreen> createState() => _EventPageScreenState();
}

class _EventPageScreenState extends ConsumerState<EventPageScreen> {
  Future<void> _toggleSave(Activity a) async {
    HapticFeedback.selectionClick();
    try {
      final saved = await ref
          .read(savedIdsProvider(SavedKind.meet).notifier)
          .toggle(a.id);
      if (mounted) showOgToast(context, saved ? 'Saved' : 'Removed from saved');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  Future<void> _directions(Activity a) async {
    final q = Uri.encodeQueryComponent('${a.venue.name}, ${a.venue.address}');
    final ok = await launchUrl(
      Uri.parse('https://maps.apple.com/?q=$q'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      await Clipboard.setData(ClipboardData(text: a.venue.address));
      if (mounted) showOgToast(context, 'Address copied');
    }
  }

  @override
  Widget build(BuildContext context) =>
      switch (ref.watch(eventInfoProvider(widget.activityId))) {
        AsyncData(:final value) => _page(value),
        AsyncError() => const KitScaffold(
          header: KitHeader(title: ''),
          children: [KitNote("This isn't available any more.")],
        ),
        _ => const KitScaffold(
          header: KitHeader(title: ''),
          children: [
            Padding(
              padding: EdgeInsets.only(top: 80),
              child: CupertinoActivityIndicator(),
            ),
          ],
        ),
      };

  Widget _page(EventInfo e) {
    final c = context.og;
    final a = e.activity;
    final top = MediaQuery.of(context).padding.top;
    final heroHeight = 210 + top;
    Crumbs.name(context, a.title);
    final saved =
        ref.watch(savedIdsProvider(SavedKind.meet)).value?.contains(a.id) ??
        false;
    return coverStatusBar(
      a,
      Scaffold(
        backgroundColor: c.bg,
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        CompetitionBanner(
                          activity: a,
                          height: heroHeight,
                          actions: [
                            bannerButton(
                              OgIcons.shareUp,
                              'Share event',
                              () => shareLink(
                                context,
                                a.title,
                                Links.event(a.id),
                              ),
                            ),
                            bannerButton(
                              OgIcons.heart,
                              saved ? 'Remove from saved' : 'Save event',
                              () => _toggleSave(a),
                              fill: saved,
                            ),
                          ],
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            heroHeight - 50,
                            16,
                            0,
                          ),
                          child: _IdentityCard(
                            info: e,
                            onDirections: () => _directions(a),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                    sliver: SliverList.list(children: kitSpaced(_body(e), 16)),
                  ),
                ],
              ),
            ),
            _BottomBar(info: e),
          ],
        ),
      ),
    );
  }

  List<Widget> _body(EventInfo e) {
    final c = context.og;
    final tones = context.tones;
    final a = e.activity;
    return [
      if (e.partOfId != null)
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.trophyCup,
              tile: tones.gold,
              ink: tones.onGold,
              title: 'Part of ${e.partOfTitle}',
              subtitle: 'Draws and results',
              onTap: () => context.push(Routes.activity(e.partOfId!)),
            ),
          ],
        ),
      if (e.live case final live?) _LiveCard(eventId: a.id, live: live),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('About this event', style: OgText.display(17, color: c.text)),
            const SizedBox(height: 8),
            Text(
              e.about,
              style: OgText.body(15, height: 1.5, color: tones.onTag),
            ),
          ],
        ),
      ),
      if (e.programme.isNotEmpty) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                e.linked ? 'Up next' : 'Schedule',
                style: OgText.heading(20),
              ),
            ),
            Text(e.programmeDay, style: OgText.body(13, color: c.textMuted)),
          ],
        ),
        KitCard(
          children: [
            for (final it in e.programme)
              _ProgrammeRow(eventId: a.id, item: it, follow: e.linked),
          ],
        ),
      ],
      if (e.gear.isNotEmpty) ...[
        Row(
          children: [
            Expanded(
              child: Text('What the finalists use', style: OgText.heading(20)),
            ),
            KitLink('Shop', onPressed: () => context.push(Routes.shop)),
          ],
        ),
        Row(
          children: [
            for (final (i, g) in e.gear.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: _GearCard(gear: g)),
            ],
          ],
        ),
        Text(
          'Players and creators earn a share when you buy through their gear.',
          style: OgText.body(13, color: c.textMuted),
        ),
      ],
      if (e.clubs.isNotEmpty) ...[
        Text(
          e.linked ? 'Host' : 'Clubs taking part',
          style: OgText.heading(20),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final cl in e.clubs)
              Container(
                padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SolidAvatar(
                      initials: cl.mark,
                      color: Color(cl.color),
                      ink: Color(cl.ink),
                      size: 32,
                      fontSize: 11,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cl.name,
                      style: OgText.body(14, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
      Align(
        alignment: Alignment.centerLeft,
        child: KitLink(
          'Report this event',
          color: c.textMuted,
          onPressed: () => context.push(Routes.reportActivity(a.id)),
        ),
      ),
    ];
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.info, required this.onDirections});

  final EventInfo info;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final a = info.activity;
    final faces = a.going.take(5).toList();
    final rest = a.spotsTaken - faces.length;
    final ticketMain = a.isFree
        ? 'Free entry'
        : 'S\$${money(a.totalCents)} per person';
    final ticketSub = a.isFree
        ? '${_thousands(a.capacity)} spots · nothing to pay · release your '
              'ticket if you can’t come'
        : 'S\$${money(a.feeCents)} + S\$${money(a.platformCents)} platform '
              'fee · ${_thousands(a.capacity)} seats'
              '${info.refundBy == null ? '' : ' · refund if you cancel by ${Fmt.dayTimeComma(info.refundBy!)}'}';
    Widget row(String icon, String main, String sub, {Widget? action}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OgIcon(icon, size: 22, color: c.text),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(main, style: OgText.body(15, weight: FontWeight.w700)),
                    Text(
                      sub,
                      style: OgText.body(13, height: 1.4, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              ?action,
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F16181B),
            blurRadius: 20,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              KitTag(
                info.live != null ? 'LIVE' : (a.online ? 'ONLINE' : 'OFFLINE'),
                background: info.live != null
                    ? const Color(0xFFD2342C)
                    : const Color(0xFF2F3A5F),
                foreground: Colors.white,
              ),
              const SizedBox(width: 8),
              KitTag(
                a.sports.length > 1
                    ? '${a.sports.first.label.toUpperCase()} +${a.sports.length - 1}'
                    : a.sports.first.label.toUpperCase(),
                background: t.tag,
                foreground: t.onTag,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Semantics(
            header: true,
            child: Text(a.title, style: OgText.heading(24, height: 1.15)),
          ),
          const SizedBox(height: 6),
          Text(
            info.clubs.length > 1
                ? '${info.clubs.first.name} · with ${info.clubs.length - 1} clubs'
                : (info.clubs.firstOrNull?.name ?? a.host.displayName),
            style: OgText.body(14, weight: FontWeight.w600, color: t.onTag),
          ),
          if (faces.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                for (final p in faces) ...[
                  SolidAvatar.forId(
                    p.id,
                    initials: p.initials,
                    size: 40,
                    fontSize: 13,
                  ),
                  const SizedBox(width: 6),
                ],
                if (rest > 0)
                  Container(
                    height: 40,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: t.tag,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      rest >= 1000
                          ? '${(rest / 1000).toStringAsFixed(1)}k'
                          : '+$rest',
                      style: OgText.body(
                        12,
                        weight: FontWeight.w800,
                        color: t.onTag,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(
            info.live != null
                ? '${_thousands(a.watching)} watching · ${a.isFree ? 'free' : 'S\$${money(a.totalCents)} / person'}'
                : '${_thousands(a.spotsTaken)} going · ${a.audience ?? 'all ages'} · ${a.isFree ? 'free entry' : 'S\$${money(a.totalCents)} / person'}',
            style: OgText.body(14, weight: FontWeight.w600, color: t.onTag),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 10),
            color: t.divider,
          ),
          row(
            OgIcons.calendarBox,
            a.multiDay
                ? Fmt.dayRange(a.startsAt, a.endsAt)
                : Fmt.dayTimeRange(a.startsAt, a.endsAt),
            a.subtitle ?? 'Drop in any time',
          ),
          row(
            OgIcons.mapPin,
            a.online ? '${a.venue.name} and online' : a.venue.name,
            a.online ? 'Watch live in the app' : 'Offline event',
            action: KitLink('Directions', onPressed: onDirections),
          ),
          row(OgIcons.ticket, ticketMain, ticketSub),
        ],
      ),
    );
  }
}

class _LiveCard extends ConsumerStatefulWidget {
  const _LiveCard({required this.eventId, required this.live});

  final String eventId;
  final LiveCourt live;

  @override
  ConsumerState<_LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends ConsumerState<_LiveCard> {
  late int _a = widget.live.cheersA;
  late int _b = widget.live.cheersB;

  void _cheer(bool sideA) {
    HapticFeedback.lightImpact();
    setState(() => sideA ? _a++ : _b++);
    ref.read(eventRepositoryProvider).cheer(widget.eventId, sideA: sideA);
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.live;
    const muted = Color(0xFFC9C6BC);
    const colA = Color(0xFFF28500);
    const colB = Color(0xFFC8553D);
    final pctA = (_a + _b) == 0 ? 0.5 : _a / (_a + _b);
    Widget side(String names, List<int> games, Color dot) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              names,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(
                15,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          for (final g in games)
            SizedBox(
              width: 36,
              child: Text(
                '$g',
                textAlign: TextAlign.end,
                style: OgText.heading(20, color: Colors.white),
              ),
            ),
        ],
      ),
    );
    Widget cheer(String label, int n, VoidCallback onTap) => Expanded(
      child: Pressable(
        semanticLabel: '$label, $n cheers',
        onPressed: onTap,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0x1AFFFFFF),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Text(
            'Cheer · ${_thousands(n)}',
            style: OgText.body(
              14,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OgColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFD2342C),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'LIVE · ${l.label}',
                style: OgText.body(
                  12,
                  weight: FontWeight.w800,
                  color: muted,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          side(l.sideA, l.gamesA, colA),
          side(l.sideB, l.gamesB, colB),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: Row(
              children: [
                Expanded(
                  flex: (pctA * 100).round().clamp(1, 99),
                  child: Container(height: 10, color: colA),
                ),
                Expanded(
                  flex: (100 - pctA * 100).round().clamp(1, 99),
                  child: Container(height: 10, color: colB),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              cheer('Cheer for ${l.sideA}', _a, () => _cheer(true)),
              const SizedBox(width: 10),
              cheer('Cheer for ${l.sideB}', _b, () => _cheer(false)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgrammeRow extends ConsumerStatefulWidget {
  const _ProgrammeRow({
    required this.eventId,
    required this.item,
    required this.follow,
  });

  final String eventId;
  final ProgrammeItem item;

  /// Matches are followed; other slots get a reminder.
  final bool follow;

  @override
  ConsumerState<_ProgrammeRow> createState() => _ProgrammeRowState();
}

class _ProgrammeRowState extends ConsumerState<_ProgrammeRow> {
  late bool _on = widget.item.reminded;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final it = widget.item;
    final follow = widget.follow && !it.plain;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(
              it.time,
              style: OgText.body(13, weight: FontWeight.w800),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(it.title, style: OgText.body(15, weight: FontWeight.w700)),
                Text(it.sub, style: OgText.body(13, color: c.textMuted)),
              ],
            ),
          ),
          KitChip(
            label: follow
                ? (_on ? 'Following' : 'Follow')
                : (_on ? 'On' : 'Remind'),
            selected: _on,
            height: 36,
            fontSize: 12,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _on = !_on);
              ref
                  .read(eventRepositoryProvider)
                  .remind(widget.eventId, it.id, _on);
            },
          ),
        ],
      ),
    );
  }
}

class _GearCard extends StatelessWidget {
  const _GearCard({required this.gear});

  final GearPick gear;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final g = gear;
    return Pressable(
      semanticLabel: '${g.name}, used by ${g.player}',
      onPressed: () => context.push(Routes.shop),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: g.racket
                    ? const Color(0xFFE3ECF3)
                    : const Color(0xFFFBE7B0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: OgIcon(
                g.racket ? OgIcons.racquet : OgIcons.bag,
                size: 40,
                color: g.racket
                    ? const Color(0xFF2F3A5F)
                    : const Color(0xFF5A4300),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Used by ${g.player}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(11, weight: FontWeight.w700, color: t.onTag),
            ),
            Text(
              g.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OgText.body(14, weight: FontWeight.w700),
            ),
            Text(
              'S\$${money(g.priceCents, decimals: false)}',
              style: OgText.body(13, color: c.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends ConsumerWidget {
  const _BottomBar({required this.info});

  final EventInfo info;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final a = info.activity;
    final bottom = MediaQuery.of(context).padding.bottom;
    final List<Widget> children;
    if (a.iAmHost) {
      children = [
        Expanded(
          child: KitButton(
            label: 'Manage event',
            icon: OgIcons.clipboardList,
            style: KitButtonStyle.dark,
            onPressed: () => context.push(Routes.eventManage(a.id)),
          ),
        ),
      ];
    } else if (info.tickets > 0) {
      children = [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your ticket · ${info.tickets} ${info.tickets == 1 ? 'person' : 'people'}',
                style: OgText.body(15, weight: FontWeight.w700),
              ),
              Text(
                a.isFree
                    ? 'Free entry · release it if you can’t come'
                    : 'Cancel by ${info.refundBy == null ? 'the day before' : Fmt.dayTimeComma(info.refundBy!)} for a refund',
                style: OgText.body(12, color: c.textMuted),
              ),
            ],
          ),
        ),
        KitButton(
          label: 'Show QR',
          expand: false,
          onPressed: () => context.push(Routes.eventTicket(a.id)),
        ),
      ];
    } else {
      children = [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                a.isFree ? 'Free' : 'S\$${money(a.totalCents)}',
                style: OgText.heading(20),
              ),
              Text(
                a.isFree
                    ? 'per person · nothing to pay'
                    : 'per person · incl. S\$${money(a.platformCents)} fee',
                style: OgText.body(12, color: c.textMuted),
              ),
            ],
          ),
        ),
        KitButton(
          label: 'Get ticket',
          expand: false,
          padding: 28,
          radius: 26,
          onPressed: a.isFull
              ? null
              : () => showKitSheet<void>(
                  context,
                  builder: (_) => _TicketSheet(activity: a),
                ),
        ),
      ];
    }
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + (bottom > 0 ? bottom : 12)),
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: Row(children: children),
    );
  }
}

/// How many people, the price, then pay (or take free tickets).
class _TicketSheet extends ConsumerStatefulWidget {
  const _TicketSheet({required this.activity});

  final Activity activity;

  @override
  ConsumerState<_TicketSheet> createState() => _TicketSheetState();
}

class _TicketSheetState extends ConsumerState<_TicketSheet> {
  int _qty = 1;
  bool _busy = false;

  Activity get a => widget.activity;

  Future<void> _get() async {
    final nav = Navigator.of(context);
    final outer = Navigator.of(context, rootNavigator: true).context;
    if (!a.isFree) {
      nav.pop();
      final method = await showPaySheet(
        outer,
        kicker: 'Tickets',
        title: a.title,
        subtitle: '${Fmt.dayTimeComma(a.startsAt)} · ${a.venue.name}',
        lines: [
          (
            'Ticket · S\$${money(a.feeCents)} × $_qty',
            'S\$${money(a.feeCents * _qty)}',
          ),
          (
            'Platform fee · S\$${money(a.platformCents)} × $_qty',
            'S\$${money(a.platformCents * _qty)}',
          ),
        ],
        totalCents: a.totalCents * _qty,
        payee: a.host.displayName,
        notes: [
          'Cancel by the day before: all of it back to your Wallet, or the '
              'ticket price to your card. The platform fee is not returned to '
              'a card.',
          'You earn ${4 * _qty} points after your ticket is scanned.',
        ],
      );
      if (method == null || !outer.mounted) return;
      await _buy(outer);
      return;
    }
    setState(() => _busy = true);
    nav.pop();
    await _buy(outer);
  }

  Future<void> _buy(BuildContext outer) async {
    try {
      final t = await ref.read(eventRepositoryProvider).buy(a.id, qty: _qty);
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (!outer.mounted) return;
      await showDoneSheet(
        outer,
        title: t.qty == 1 ? 'You have a ticket' : 'You have ${t.qty} tickets',
        body: '${a.title}. Show the code at the door.',
        rows: [
          if (a.isFree) ('Tickets', '$_qty · free entry'),
          (
            'Paid',
            a.isFree ? 'Nothing to pay' : 'S\$${money(a.totalCents * _qty)}',
          ),
        ],
        next: 'Show my ticket',
        onNext: () => outer.push(Routes.eventTicket(a.id)),
      );
    } on AuthFailure catch (e) {
      if (outer.mounted) showOgToast(outer, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            a.isFree ? 'NOTHING TO PAY' : 'TICKETS',
            style: OgText.body(
              12,
              weight: FontWeight.w800,
              color: c.textMuted,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(a.title, style: OgText.heading(24)),
          Text(
            '${Fmt.dayTimeComma(a.startsAt)} · ${a.venue.name}',
            style: OgText.body(14, color: c.textMuted),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
            decoration: BoxDecoration(
              color: t.tag,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'People',
                        style: OgText.body(15, weight: FontWeight.w700),
                      ),
                      Text(
                        'Up to 6 per order',
                        style: OgText.body(12, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                KitQty(
                  value: _qty,
                  label: 'people',
                  onLess: _qty <= 1 ? null : () => setState(() => _qty--),
                  onMore: _qty >= 6 ? null : () => setState(() => _qty++),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (a.isFree)
            KitKeyValue('Ticket × $_qty', 'Free')
          else ...[
            KitKeyValue(
              'Ticket · S\$${money(a.feeCents)} × $_qty',
              'S\$${money(a.feeCents * _qty)}',
            ),
            KitKeyValue(
              'Platform fee · S\$${money(a.platformCents)} × $_qty',
              'S\$${money(a.platformCents * _qty)}',
            ),
            KitKeyValue('Total', 'S\$${money(a.totalCents * _qty)}'),
          ],
          const SizedBox(height: 8),
          Text(
            a.isFree
                ? 'Entry is free. The organizer covers the platform fee. Can’t '
                      'come? Release your ticket so someone else can have it.'
                : 'Nothing is charged until you confirm on the next step.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
          const SizedBox(height: 16),
          KitButton(
            label: a.isFree
                ? 'Get $_qty ${_qty == 1 ? 'ticket' : 'tickets'}'
                : 'Continue to pay',
            loading: _busy,
            onPressed: _get,
          ),
        ],
      ),
    );
  }
}

/// The ticket to show at the door.
class EventTicketScreen extends ConsumerWidget {
  const EventTicketScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final ticket = ref.watch(eventTicketProvider(activityId));
    final tk = ticket.value;
    if (ticket.isLoading) {
      return const KitScaffold(
        header: KitHeader(title: 'My ticket'),
        children: [CupertinoActivityIndicator()],
      );
    }
    if (tk == null) {
      return KitScaffold(
        header: const KitHeader(title: 'My ticket'),
        bottom: [
          KitButton(label: 'Back to event', onPressed: () => context.pop()),
        ],
        children: const [KitNote('You have no tickets for this event.')],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'My ticket'),
      bottom: [
        KitButton(
          label: 'Add to my schedule',
          style: KitButtonStyle.outline,
          onPressed: () => showOgToast(context, 'It is in your schedule'),
        ),
        KitButton(label: 'Back to event', onPressed: () => context.pop()),
      ],
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: OgColors.ink,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              KitTag(
                'Valid · ${tk.qty} ${tk.qty == 1 ? 'ticket' : 'tickets'}',
                background: t.successFill,
                foreground: t.onSuccessFill,
              ),
              const SizedBox(height: 10),
              Text(
                tk.title,
                textAlign: TextAlign.center,
                style: OgText.heading(22, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                Fmt.dayTimeRange(tk.startsAt, tk.endsAt),
                style: OgText.body(14, color: const Color(0xFFC9C6BC)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Semantics(
                  label: 'Ticket code ${tk.code}',
                  child: QrImageView(
                    data: 'olympusgo:ticket:${tk.eventId}:${tk.code}',
                    size: 180,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                tk.code,
                style: OgText.body(
                  15,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        Column(
          children: [
            KitKeyValue('Where', tk.venue),
            KitKeyValue('Ticket type', 'Adult × ${tk.qty}'),
            KitKeyValue(
              'Paid',
              tk.paidCents == 0
                  ? 'Free entry'
                  : 'S\$${money(tk.paidCents)}, fee included',
            ),
            KitKeyValue('Booking', tk.code),
            KitKeyValue('Points', '${tk.points} after you are scanned in'),
          ],
        ),
        Text(
          'Show this code at the entrance.',
          style: OgText.body(13, color: c.textMuted),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: KitLink(
            'Can’t come? Release tickets',
            color: t.onDangerFill,
            onPressed: () => context.push(Routes.eventRelease(activityId)),
          ),
        ),
      ],
    );
  }
}

/// Give tickets back; paid ones are refunded until the deadline.
class EventReleaseScreen extends ConsumerStatefulWidget {
  const EventReleaseScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<EventReleaseScreen> createState() => _EventReleaseScreenState();
}

class _EventReleaseScreenState extends ConsumerState<EventReleaseScreen> {
  int? _qty;
  bool _busy = false;
  (int, int)? _done;

  Future<void> _release(int qty) async {
    setState(() => _busy = true);
    try {
      final back = await ref
          .read(eventRepositoryProvider)
          .release(widget.activityId, qty: qty);
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (mounted) setState(() => _done = (qty, back));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    if (_done case (final n, final back)) {
      return KitScaffold(
        header: const KitHeader(title: 'Release tickets'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to event',
            onPressed: () => context.go(Routes.activity(widget.activityId)),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Released'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$n ${n == 1 ? 'ticket' : 'tickets'} released. '
              '${back > 0 ? 'S\$${money(back)} is on its way back to how you paid.' : 'There is nothing to refund.'}',
              style: OgText.body(15, height: 1.45, color: c.textMuted),
            ),
          ),
        ],
      );
    }
    final tk = ref.watch(eventTicketProvider(widget.activityId)).value;
    if (tk == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Release tickets'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final qty = _qty ?? tk.qty;
    final inTime = tk.refundBy == null || DateTime.now().isBefore(tk.refundBy!);
    final back = !inTime || tk.qty == 0 ? 0 : tk.paidCents * qty ~/ tk.qty;
    return KitScaffold(
      header: const KitHeader(title: 'Release tickets'),
      bottom: [
        KitButton(
          label: 'Release ${qty == 1 ? 'ticket' : '$qty tickets'}',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: () => _release(qty),
        ),
      ],
      children: [
        KitTitle(
          'Can’t come?',
          lead:
              'You have ${tk.qty} ${tk.qty == 1 ? 'ticket' : 'tickets'} for '
              '${tk.title}. Choose how many to give back.',
        ),
        if (tk.qty > 1)
          Column(
            children: [
              for (var n = 1; n <= tk.qty; n++)
                KitChoiceRow(
                  title: n == tk.qty
                      ? (tk.qty == 2 ? 'Both tickets' : 'All $n tickets')
                      : '$n ${n == 1 ? 'ticket' : 'tickets'}',
                  selected: qty == n,
                  onTap: () => setState(() => _qty = n),
                ),
            ],
          ),
        Column(
          children: [
            KitKeyValue(
              'Paid',
              tk.paidCents == 0
                  ? 'Free entry'
                  : 'S\$${money(tk.paidCents)} for ${tk.qty} ${tk.qty == 1 ? 'ticket' : 'tickets'}',
            ),
            if (tk.refundBy != null)
              KitKeyValue('Refund deadline', Fmt.dayTimeComma(tk.refundBy!)),
            KitKeyValue('You get back', 'S\$${money(back)}'),
          ],
        ),
        Text(
          'Released tickets go to the next person waiting. For a free event '
          'there is nothing to refund, and the organizer gets the fee back.',
          style: OgText.body(13, height: 1.45, color: c.textMuted),
        ),
      ],
    );
  }
}

/// The organizer's tools for one event.
class EventManageScreen extends ConsumerWidget {
  const EventManageScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = ref.watch(eventInfoProvider(activityId)).value;
    if (e == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Manage event'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final a = e.activity;
    final t = context.tones;
    return KitScaffold(
      header: const KitHeader(title: 'Manage event'),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            KitTag('Organizer', background: t.gold, foreground: t.onGold),
            const SizedBox(height: 8),
            Text(a.title, style: OgText.heading(26)),
            const SizedBox(height: 4),
            Text(
              '${Fmt.day(a.startsAt)} · ${a.online ? 'Offline and online' : 'Offline'} · '
              '${_thousands(a.spotsTaken)} ${a.isFree ? 'free ' : ''}tickets taken',
              style: OgText.body(14, color: context.og.textMuted),
            ),
          ],
        ),
        KitCard(
          children: [
            KitNavTile(
              icon: OgIcons.pencil,
              title: 'Edit details',
              subtitle: 'Date, venue, tickets and banner',
              onTap: () => editActivity(context, ref, a),
            ),
            KitNavTile(
              icon: OgIcons.scan,
              title: 'Check in guests',
              subtitle: 'Check ticket codes at the door · ${e.scannedIn} in',
              onTap: () => context.push(Routes.eventScan(a.id)),
            ),
            KitNavTile(
              icon: OgIcons.warning,
              title: 'Cancel event',
              subtitle: 'Cancel every ticket',
              danger: true,
              onTap: () => context.push(Routes.eventCancel(a.id)),
            ),
          ],
        ),
        KitNote(
          a.isFree
              ? 'Tickets are free for guests. You pay the S\$2 platform fee for '
                    'each ticket taken. Ticket holders are told about any '
                    'change to date or venue.'
              : 'Guests pay the ticket price plus the platform fee. Ticket '
                    'holders are told about any change to date or venue.',
        ),
      ],
    );
  }
}

/// Cancel the event and every ticket.
class EventCancelScreen extends ConsumerStatefulWidget {
  const EventCancelScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<EventCancelScreen> createState() => _EventCancelScreenState();
}

class _EventCancelScreenState extends ConsumerState<EventCancelScreen> {
  final _message = TextEditingController();
  bool _understood = false;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _cancel() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(eventRepositoryProvider)
          .cancel(widget.activityId, message: _message.text.trim());
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (!mounted) return;
      showOgToast(context, 'Event cancelled. Ticket holders are told.');
      context.go(Routes.schedule(hosting: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = ref.watch(eventInfoProvider(widget.activityId)).value;
    if (e == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Cancel event'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final a = e.activity;
    final n = a.spotsTaken;
    return KitScaffold(
      header: const KitHeader(title: 'Cancel event'),
      bottom: [
        KitButton(
          label: 'Cancel event',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: _understood ? _cancel : null,
        ),
        KitButton(
          label: 'Keep event',
          style: KitButtonStyle.outline,
          onPressed: () => context.pop(),
        ),
      ],
      children: [
        KitTitle(
          'Cancel ${a.title}?',
          size: 26,
          lead:
              '${Fmt.day(a.startsAt)} · ${_thousands(n)} ${a.isFree ? 'free ' : ''}tickets taken',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('What happens', style: OgText.heading(20)),
            const SizedBox(height: 4),
            KitKeyValue(
              'Tickets cancelled',
              '${_thousands(n)}, holders are told',
            ),
            KitKeyValue(
              'Guests paid',
              a.isFree
                  ? 'S\$0.00, tickets were free'
                  : 'S\$${money(a.totalCents * n)}, refunded in full',
            ),
            if (a.isFree)
              KitKeyValue(
                'Platform fees you paid',
                'S\$${money(200 * n)}, returned to you',
              ),
          ],
        ),
        KitTextArea(
          label: 'Message to ticket holders',
          optional: true,
          controller: _message,
          hint:
              'We have had to cancel the event. Sorry for the change of plan.',
        ),
        KitConfirmBox(
          label: 'I understand all ${_thousands(n)} tickets are cancelled',
          checked: _understood,
          onChanged: (v) => setState(() => _understood = v),
        ),
      ],
    );
  }
}

/// Check a ticket code at the door.
class ScanTicketScreen extends ConsumerStatefulWidget {
  const ScanTicketScreen({super.key, required this.activityId, this.code});

  final String activityId;

  /// A booking code read by the camera, checked straight away.
  final String? code;

  @override
  ConsumerState<ScanTicketScreen> createState() => _ScanTicketScreenState();
}

class _ScanTicketScreenState extends ConsumerState<ScanTicketScreen> {
  late final _code = TextEditingController(text: widget.code);
  bool _busy = false;
  ScanResult? _result;

  @override
  void initState() {
    super.initState();
    if (widget.code != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _check());
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      showOgToast(context, 'Type the booking code.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final r = await ref
          .read(eventRepositoryProvider)
          .scan(widget.activityId, code);
      HapticFeedback.mediumImpact();
      ref.invalidate(eventInfoProvider(widget.activityId));
      if (mounted) setState(() => _result = r);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final r = _result;
    if (r != null) {
      return KitScaffold(
        header: const KitHeader(title: 'Check a ticket'),
        bottom: [
          KitButton(
            label: 'Check the next ticket',
            onPressed: () => setState(() {
              _result = null;
              _code.clear();
            }),
          ),
          KitButton(
            label: 'Done checking in',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: r.valid ? t.successFill : t.dangerFill,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OgIcon(
                  r.valid ? OgIcons.check : OgIcons.warning,
                  size: 34,
                  strokeWidth: 3,
                  color: r.valid ? t.onSuccessFill : t.onDangerFill,
                ),
                const SizedBox(height: 8),
                Text(
                  r.valid ? 'Valid ticket' : 'Already used',
                  style: OgText.heading(
                    28,
                    color: r.valid ? t.onSuccessFill : t.onDangerFill,
                  ),
                ),
                Text(
                  '${r.qty} ${r.qty == 1 ? 'adult' : 'adults'}',
                  style: OgText.heading(
                    20,
                    color: r.valid ? t.onSuccessFill : t.onDangerFill,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              KitKeyValue('Event', r.title),
              KitKeyValue('Booked by', r.bookedBy),
              KitKeyValue('Scanned in', '${r.scanned} of ${r.capacity}'),
              if (r.usedAt != null)
                KitKeyValue('Used', Fmt.dayTimeComma(r.usedAt!)),
            ],
          ),
          Text(
            'A ticket works once. If it is scanned again you see who used it '
            'and when.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      );
    }
    return KitScaffold(
      header: const KitHeader(title: 'Check a ticket'),
      bottom: [
        KitButton(label: 'Check ticket', loading: _busy, onPressed: _check),
      ],
      children: [
        const KitTitle(
          'Booking code',
          lead:
              'Type the code under the guest’s QR, or scan it from the Scan '
              'tab.',
        ),
        KitInput(label: 'Code', controller: _code, hint: 'OG-123456'),
      ],
    );
  }
}

/// Event tickets the player holds, newest first.
class MyTicketsScreen extends ConsumerWidget {
  const MyTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final events = ref
        .watch(myScheduleProvider)
        .value
        ?.where((a) => a.kind == ActivityKind.event && !a.iAmHost)
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'My tickets'),
      children: [
        if (events == null)
          const CupertinoActivityIndicator()
        else if (events.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'No tickets yet. Events you get tickets for show up here.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else
          KitCard(
            children: [
              for (final a in events)
                KitNavTile(
                  icon: OgIcons.ticket,
                  title: a.title,
                  subtitle: '${Fmt.dayTime(a.startsAt)} · ${a.venue.name}',
                  onTap: () => context.push(Routes.eventTicket(a.id)),
                ),
            ],
          ),
        const KitNote('Show the code at the door. Each ticket works once.'),
      ],
    );
  }
}

/// Picks one of the organizer's events to check tickets at the door.
class CheckTicketsScreen extends ConsumerWidget {
  const CheckTicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final events = ref
        .watch(hostingProvider)
        .value
        ?.where((a) => a.kind == ActivityKind.event)
        .toList();
    return KitScaffold(
      header: const KitHeader(title: 'Check a ticket'),
      children: [
        const KitTitle(
          'Which event?',
          lead: 'Pick the event, then type or scan each booking code.',
        ),
        if (events == null)
          const CupertinoActivityIndicator()
        else if (events.isEmpty)
          DashedBox(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'You are not running any events. Tickets are checked by the event’s organizers.',
                style: OgText.body(14, color: c.textMuted),
              ),
            ),
          )
        else
          KitCard(
            children: [
              for (final a in events)
                KitNavTile(
                  icon: OgIcons.scan,
                  title: a.title,
                  subtitle: '${Fmt.dayTime(a.startsAt)} · ${a.venue.name}',
                  onTap: () => context.push(Routes.eventScan(a.id)),
                ),
            ],
          ),
      ],
    );
  }
}
