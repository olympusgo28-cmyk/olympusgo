import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/breadcrumbs.dart';
import '../../../core/format.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pay_sheet.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../onboarding/domain/sport.dart';
import '../../play/domain/activity.dart';
import '../../wallet/application/wallet_providers.dart';
import '../../play/presentation/create_screens.dart' show showCreateMenu;
import '../application/venue_providers.dart';
import '../domain/venue_models.dart';

/// "7 AM", "11 PM".
String _hour(int h) => Fmt.clock(h, 0).replaceAll(':00', '');

/// "S$14", or "S$14.50".
String _price(int cents) => 'S\$${money(cents, decimals: cents % 100 != 0)}';

/// "12 badminton, 4 pickleball".
String _courtSummary(VenueDetail v) => v.courts
    .map(
      (c) => [
        '${c.count} ${c.sport.label.toLowerCase()}',
        if (c.note.isNotEmpty) c.note,
      ].join(', '),
    )
    .join(', ');

/// "Open now", or "Opens 7 AM".
String _openLabel(VenueDetail v) {
  final h = DateTime.now().hour;
  if (h >= v.opensHour && h < v.closesHour) return 'Open now';
  return 'Opens ${_hour(v.opensHour)}';
}

// ─── Venue category ────────────────────────────────────────────────────────

enum _When {
  any('Any time'),
  tonight('Free tonight'),
  weekend('Free this weekend');

  const _When(this.label);
  final String label;
}

/// Days the "free" filters look at, and the earliest hour that counts.
List<(DateTime, int)> _daysFor(_When w) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return switch (w) {
    _When.any => const [],
    _When.tonight => [(today, 18)],
    _When.weekend => [
      for (var i = 0; i < 7; i++)
        if (today.add(Duration(days: i)).weekday >= DateTime.saturday)
          (today.add(Duration(days: i)), 0),
    ],
  };
}

/// Venues with a free court on the filter's days, for one sport or any.
final _freeVenuesProvider = FutureProvider.autoDispose
    .family<Set<String>, (_When, Sport?)>((ref, key) async {
      final (filter, sport) = key;
      final venues = await ref.watch(venueListProvider.future);
      final days = _daysFor(filter);
      final free = <String>{};
      for (final v in venues) {
        search:
        for (final s in sport == null ? v.sports : {sport}) {
          if (!v.sports.contains(s)) continue;
          for (final (day, fromHour) in days) {
            final slots = await ref.watch(
              courtSlotsProvider(v.id, s, day, 1).future,
            );
            if (slots.any((x) => x.free && x.start.hour >= fromHour)) {
              free.add(v.id);
              break search;
            }
          }
        }
      }
      return free;
    });

class VenuesScreen extends ConsumerStatefulWidget {
  const VenuesScreen({super.key});

  @override
  ConsumerState<VenuesScreen> createState() => _VenuesScreenState();
}

class _VenuesScreenState extends ConsumerState<VenuesScreen> {
  String _q = '';
  Sport? _sport;
  _When _when = _When.any;

  static const _sports = [Sport.badminton, Sport.pickleball, Sport.tennis];

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    Crumbs.name(context, 'Venue');
    final top = MediaQuery.of(context).padding.top;
    final venues = ref.watch(venueListProvider);
    final free = _when == _When.any
        ? null
        : ref.watch(_freeVenuesProvider((_when, _sport))).value;
    final upcoming = (ref.watch(myCourtBookingsProvider).value ?? const [])
        .where(
          (b) =>
              b.status == BookingStatus.confirmed &&
              b.end.isAfter(DateTime.now()),
        )
        .toList();
    final q = _q.trim().toLowerCase();
    final shown = (venues.value ?? const <VenueDetail>[]).where((v) {
      if (q.isNotEmpty &&
          !'${v.name} ${v.address} ${_courtSummary(v)}'.toLowerCase().contains(
            q,
          )) {
        return false;
      }
      if (_sport != null && !v.sports.contains(_sport)) return false;
      if (free != null && !free.contains(v.id)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: c.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            // One box, so the search field paints above the dark header.
            SliverToBoxAdapter(
              child: Column(
                children: [
                  CourtHero(
                    color: OgColors.ink,
                    height: 150 + top,
                    child: Stack(
                      children: [
                        Positioned(
                          left: 12,
                          top: top + 14,
                          child: const KitBackPill(
                            background: Color(0x24FFFFFF),
                            color: Colors.white,
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 38,
                          child: Semantics(
                            header: true,
                            child: Text(
                              'Venue',
                              style: OgText.heading(44, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -26),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x2417171A),
                            blurRadius: 20,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: KitSearchField(
                        hint: 'Search courts and venues',
                        onChanged: (v) => setState(() => _q = v),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24 + MediaQuery.of(context).padding.bottom,
              ),
              sliver: SliverList.list(
                children: kitSpaced([
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      KitChip(
                        label: 'All sports',
                        selected: _sport == null,
                        onTap: () => setState(() => _sport = null),
                      ),
                      for (final s in _sports)
                        KitChip(
                          label: s.label,
                          selected: _sport == s,
                          onTap: () => setState(() => _sport = s),
                        ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in _When.values)
                        KitChip(
                          label: w.label,
                          selected: _when == w,
                          onTap: () => setState(() => _when = w),
                        ),
                    ],
                  ),
                  if (upcoming.isNotEmpty)
                    KitNavTile(
                      icon: OgIcons.calendarBox,
                      title: upcoming.length == 1
                          ? 'Your court booking'
                          : 'Your ${upcoming.length} court bookings',
                      subtitle:
                          '${upcoming.first.venueName} · ${Fmt.dayTimeComma(upcoming.first.start)}',
                      tile: t.soft,
                      padding: EdgeInsets.zero,
                      onTap: () =>
                          context.push(Routes.courtBooking(upcoming.first.id)),
                    ),
                  ...switch (venues) {
                    AsyncError() => [
                      const KitNote("Venues aren't loading. Try again."),
                    ],
                    AsyncData() when shown.isEmpty => [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Column(
                          children: [
                            Text('No venues match', style: OgText.heading(24)),
                            const SizedBox(height: 6),
                            Text(
                              'Check the spelling or try an area name.',
                              style: OgText.body(14, color: c.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ],
                    AsyncData() => [for (final v in shown) _VenueRow(venue: v)],
                    _ => [
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: CupertinoActivityIndicator(),
                      ),
                    ],
                  },
                ], 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueRow extends StatelessWidget {
  const _VenueRow({required this.venue});

  final VenueDetail venue;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final v = venue;
    final from = v.courts
        .map((x) => x.offPeakCents)
        .fold<int?>(null, (a, b) => a == null || b < a ? b : a);
    return Pressable(
      semanticLabel: [
        v.name,
        _courtSummary(v),
        v.distance,
        _openLabel(v),
        if (from != null) 'From ${_price(from)} an hour',
      ].join('. '),
      onPressed: () => context.push(Routes.venue(v.id)),
      child: Container(
        padding: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: CourtHero(
                color: Color(v.color),
                height: 140,
                style: CourtLines.tile,
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      bottom: 12,
                      child: Text(
                        v.mark,
                        style: OgText.heading(40, color: Color(v.ink)),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: KitTag(
                        _openLabel(v),
                        background: Colors.white,
                        foreground: OgColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        style: OgText.body(17, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          _courtSummary(v),
                          if (v.distance.isNotEmpty) v.distance,
                        ].join(' · '),
                        style: OgText.body(13, color: c.textMuted),
                      ),
                    ],
                  ),
                ),
                if (from != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    'From ${_price(from)} / hour',
                    style: OgText.body(
                      14,
                      weight: FontWeight.w700,
                      color: c.link,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Venue page ────────────────────────────────────────────────────────────

class VenuePageScreen extends ConsumerWidget {
  const VenuePageScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(venueDetailProvider(id))) {
      AsyncData(:final value) => _VenuePage(venue: value),
      AsyncError(:final error) => KitScaffold(
        header: const KitHeader(title: 'Venue'),
        children: [
          KitNote(
            error is AuthFailure
                ? error.message
                : "This venue isn't loading. Try again.",
          ),
        ],
      ),
      _ => const KitScaffold(
        header: KitHeader(title: 'Venue'),
        children: [CupertinoActivityIndicator()],
      ),
    };
  }
}

class _VenuePage extends ConsumerWidget {
  const _VenuePage({required this.venue});

  final VenueDetail venue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final v = venue;
    final on = ref.watch(venueActivitiesProvider(v.id)).value ?? const [];
    Widget heading(String text) =>
        Semantics(header: true, child: Text(text, style: OgText.heading(22)));
    return KitScaffold(
      header: KitHeader(title: 'Venue', crumb: v.name),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      bottom: [
        KitButton(
          label: 'Book a court',
          onPressed: v.courts.isEmpty
              ? null
              : () => context.push(Routes.bookCourt(v.id)),
        ),
        KitButton.outline(
          label: 'Create a Meet here',
          onPressed: () => showCreateMenu(context, venue: v.asVenue),
        ),
      ],
      children: [
        CourtHero(
          color: Color(v.color),
          height: 200,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                v.mark,
                style: OgText.heading(56, color: Color(v.ink)),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: kitSpaced([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(v.name, style: OgText.heading(32)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      v.address,
                      if (v.distance.isNotEmpty) v.distance,
                      'Open ${_hour(v.opensHour)} to ${_hour(v.closesHour)}',
                    ].join(' · '),
                    style: OgText.body(13, color: c.textMuted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (v.verified)
                        KitTag(
                          'Verified venue',
                          background: t.successFill,
                          foreground: t.onSuccessFill,
                        ),
                      if (v.rating != null)
                        KitTag(
                          '${v.rating!.toStringAsFixed(1)} from ${v.ratingCount} players',
                        ),
                      if (v.autoCheckIn)
                        KitTag(
                          'Auto check-in',
                          background: OgColors.ink,
                          foreground: OgColors.lime,
                        ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  heading('Courts'),
                  const SizedBox(height: 8),
                  for (final ct in v.courts)
                    KitKeyValue(
                      ct.sport.label,
                      '${ct.count} courts · ${_price(ct.offPeakCents)} off-peak, ${_price(ct.peakCents)} peak',
                    ),
                  const KitKeyValue(
                    'Peak hours',
                    'Weekdays 6 to 10 PM, weekends all day',
                  ),
                ],
              ),
              if (v.amenities.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    heading('Here'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [for (final a in v.amenities) KitTag(a)],
                    ),
                  ],
                ),
              if (on.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    heading('On here this week'),
                    const SizedBox(height: 8),
                    for (final a in on) _OnHereRow(activity: a),
                  ],
                ),
              const KitNote(
                'Cancel a booking free up to 24 hours before. Inside 24 '
                'hours the venue keeps the fee.',
              ),
            ], 18),
          ),
        ),
      ],
    );
  }
}

class _OnHereRow extends StatelessWidget {
  const _OnHereRow({required this.activity});

  final Activity activity;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final a = activity;
    final trailing = switch (a.kind) {
      ActivityKind.meet => a.isFull ? 'Full' : '${a.spotsLeft} spots',
      ActivityKind.tournament => 'Entries open',
      ActivityKind.event => a.isFree ? 'Free' : 'Tickets',
    };
    final when = a.multiDay
        ? Fmt.dayRange(a.startsAt, a.endsAt)
        : Fmt.dayTimeComma(a.startsAt);
    return Pressable(
      semanticLabel: '${a.title}. ${a.kind.label}, $when. $trailing',
      onPressed: () => context.push(Routes.activity(a.id)),
      child: Container(
        constraints: const BoxConstraints(minHeight: 60),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a.title,
                    style: OgText.body(15, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [a.kind.label, when, ?a.court].join(' · '),
                    style: OgText.body(13, color: c.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(trailing, style: OgText.body(15, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ─── Book a court ──────────────────────────────────────────────────────────

class BookCourtScreen extends ConsumerWidget {
  const BookCourtScreen({super.key, required this.venueId});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(venueDetailProvider(venueId))) {
      AsyncData(:final value) => _BookCourt(venue: value),
      AsyncError() => const KitScaffold(
        header: KitHeader(title: 'Book a court'),
        children: [KitNote("This venue isn't loading. Try again.")],
      ),
      _ => const KitScaffold(
        header: KitHeader(title: 'Book a court'),
        children: [CupertinoActivityIndicator()],
      ),
    };
  }
}

class _BookCourt extends ConsumerStatefulWidget {
  const _BookCourt({required this.venue});

  final VenueDetail venue;

  @override
  ConsumerState<_BookCourt> createState() => _BookCourtState();
}

class _BookCourtState extends ConsumerState<_BookCourt> {
  late Sport _sport = widget.venue.courts.first.sport;
  late DateTime _day = _days.first;
  int _hours = 2;
  DateTime? _start;
  bool _busy = false;
  CourtBooking? _done;

  VenueDetail get v => widget.venue;

  List<DateTime> get _days {
    final now = DateTime.now();
    return [
      for (var i = 0; i < 4; i++) DateTime(now.year, now.month, now.day + i),
    ];
  }

  String _dayLabel(DateTime d) => d == _days.first ? 'Today' : Fmt.day(d);

  /// Court price for [hours] from [start]; peak rates can change mid-way.
  int _courtCents(DateTime start) => [
    for (var i = 0; i < _hours; i++)
      v.rateCents(_sport, start.add(Duration(hours: i))),
  ].fold(0, (a, b) => a + b);

  String _timeRange(DateTime start) =>
      Fmt.timeRange(start, start.add(Duration(hours: _hours)));

  Future<void> _pay() async {
    final start = _start!;
    final court = _courtCents(start);
    final fee = platformFee(court);
    final method = await showPaySheet(
      context,
      kicker: 'Court booking',
      title: v.name,
      subtitle: '${_sport.label} · ${_dayLabel(_day)}, ${_timeRange(start)}',
      lines: [
        (
          'Court, $_hours ${_hours == 1 ? 'hour' : 'hours'}',
          'S\$${money(court)}',
        ),
        ('Platform fee, 10%', 'S\$${money(fee)}'),
      ],
      totalCents: court + fee,
      payee: v.name,
      notes: const [
        'Cancel more than 24 hours before: all of it back to your Wallet, '
            'or the court price to your card. The platform fee is not '
            'returned to a card.',
        "Inside 24 hours, or if you don't come: no refund. If the venue "
            'cancels, you get all of it back.',
      ],
    );
    if (method == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final b = await ref
          .read(venueRepositoryProvider)
          .book(
            venue: v,
            sport: _sport,
            start: start,
            hours: _hours,
            methodId: method.id,
          );
      HapticFeedback.mediumImpact();
      ref.invalidate(myCourtBookingsProvider);
      ref.invalidate(courtSlotsProvider);
      if (mounted) setState(() => _done = b);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
      ref.invalidate(courtSlotsProvider);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final done = _done;
    if (done != null) {
      return KitScaffold(
        header: const KitHeader(title: 'Book a court'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'See my booking',
            onPressed: () =>
                context.pushReplacement(Routes.courtBooking(done.id)),
          ),
          KitButton.outline(
            label: 'Create a Meet on this court',
            onPressed: () =>
                showCreateMenu(context, venue: v.asVenue, at: done.start),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Booked'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${done.sport.label}, ${done.court}',
                  style: OgText.heading(26),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_dayLabel(_day)}, ${Fmt.timeRange(done.start, done.end)}. '
                  'Your door code is in the booking.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final slots = ref.watch(courtSlotsProvider(v.id, _sport, _day, _hours));
    final start = _start;
    // A start that stops being free (another length, a new booking) clears.
    final picked =
        start != null &&
        (slots.value?.any((s) => s.start == start && s.free) ?? false);
    Widget heading(String text) =>
        Semantics(header: true, child: Text(text, style: OgText.heading(22)));
    return KitScaffold(
      header: const KitHeader(title: 'Book a court'),
      bottom: [
        KitButton(
          label: picked ? 'Continue to pay' : 'Pick a start time',
          loading: _busy,
          onPressed: picked ? _pay : null,
        ),
      ],
      children: [
        if (v.sports.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading('Sport'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in v.sports)
                    KitChip(
                      label: s.label,
                      selected: _sport == s,
                      onTap: () => setState(() => _sport = s),
                    ),
                ],
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('Day'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in _days)
                  KitChip(
                    label: _dayLabel(d),
                    selected: _day == d,
                    onTap: () => setState(() {
                      _day = d;
                      _start = null;
                    }),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            heading('How long'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final h in const [1, 2, 3])
                  KitChip(
                    label: '$h ${h == 1 ? 'hour' : 'hours'}',
                    selected: _hours == h,
                    onTap: () => setState(() => _hours = h),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading('Start time'),
            const SizedBox(height: 8),
            switch (slots) {
              AsyncData(:final value) when value.isEmpty => Text(
                'Nothing left to book on this day. Try another day.',
                style: OgText.body(14, color: c.textMuted),
              ),
              AsyncData(:final value) => GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.75,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  for (final s in value)
                    _SlotButton(
                      slot: s,
                      selected: s.start == start,
                      onTap: () => setState(() => _start = s.start),
                    ),
                ],
              ),
              AsyncError() => const KitNote(
                "Start times aren't loading. Try again.",
              ),
              _ => const Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoActivityIndicator(),
              ),
            },
          ],
        ),
        Column(
          children: [
            KitKeyValue('Court', '${_sport.label}, given when you book'),
            KitKeyValue(
              'Price',
              picked
                  ? '${_timeRange(start)} = S\$${money(_courtCents(start))}'
                  : 'Shown when you pick a time',
            ),
            Container(height: 1, color: t.divider),
          ],
        ),
      ],
    );
  }
}

class _SlotButton extends StatelessWidget {
  const _SlotButton({
    required this.slot,
    required this.selected,
    required this.onTap,
  });

  final CourtSlot slot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final off = !slot.free;
    final time = Fmt.time(slot.start);
    final sub = off ? 'Taken' : '${_price(slot.rateCents)} / h';
    return Pressable(
      semanticLabel: '$time, $sub',
      selected: selected,
      onPressed: off ? null : onTap,
      dimWhenDisabled: false,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? OgColors.ink
              : off
              ? t.soft
              : c.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? OgColors.ink
                : off
                ? c.border
                : c.borderControl,
            width: selected ? 2 : 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: OgText.body(
                15,
                weight: FontWeight.w700,
                color: selected
                    ? Colors.white
                    : (off ? t.onDisabledFill : c.text),
              ),
            ),
            Text(
              sub,
              style: OgText.body(
                12,
                color: selected
                    ? Colors.white
                    : (off ? t.onDisabledFill : c.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── My booking ────────────────────────────────────────────────────────────

class CourtBookingScreen extends ConsumerWidget {
  const CourtBookingScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.og;
    final t = context.tones;
    final booking = ref.watch(courtBookingProvider(id));
    final b = booking.value;
    if (b == null) {
      return KitScaffold(
        header: const KitHeader(title: 'My booking'),
        children: [
          if (booking.hasError)
            const KitNote("This booking isn't loading. Try again.")
          else
            const CupertinoActivityIndicator(),
        ],
      );
    }
    final cancelled = b.status == BookingStatus.cancelled;
    final over = b.end.isBefore(DateTime.now());
    return KitScaffold(
      header: const KitHeader(title: 'My booking'),
      bottom: [
        if (!cancelled && !over) ...[
          KitButton(
            label: 'Create a Meet on this court',
            onPressed: () => showCreateMenu(
              context,
              venue: Venue(
                id: b.venueId,
                name: b.venueName,
                address: b.venueAddress,
              ),
              at: b.start,
            ),
          ),
          KitButton.outline(
            label: 'Cancel booking',
            onPressed: () => context.push(Routes.cancelCourtBooking(b.id)),
          ),
        ] else
          KitButton.outline(
            label: 'Book again',
            onPressed: () => context.push(Routes.bookCourt(b.venueId)),
          ),
      ],
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: c.border),
          ),
          child: Column(
            children: kitSpaced([
              cancelled
                  ? KitTag(
                      'Cancelled',
                      background: t.dangerFill,
                      foreground: t.onDangerFill,
                    )
                  : KitTag(
                      over ? 'Played' : 'Confirmed',
                      background: OgColors.ink,
                      foreground: OgColors.lime,
                    ),
              if (!cancelled && !over) ...[
                Semantics(
                  label: 'Door code ${b.doorCode.split('').join(' ')}',
                  child: ExcludeSemantics(
                    child: Text(
                      b.doorCode.split('').join(' '),
                      style: OgText.heading(
                        64,
                        height: 1,
                      ).copyWith(letterSpacing: 5),
                    ),
                  ),
                ),
                Text(
                  'Door code for ${b.court}, works from 10 minutes before',
                  textAlign: TextAlign.center,
                  style: OgText.body(13, color: c.textMuted),
                ),
              ],
              Text(
                b.venueName,
                textAlign: TextAlign.center,
                style: OgText.heading(24),
              ),
              Text(
                '${Fmt.day(b.start)}, ${Fmt.timeRange(b.start, b.end)} · '
                '${b.sport.label}, ${b.court}\n${b.venueAddress}',
                textAlign: TextAlign.center,
                style: OgText.body(13, height: 1.45, color: c.textMuted),
              ),
            ], 14),
          ),
        ),
        Column(
          children: [
            KitKeyValue('Paid', 'S\$${money(b.paidCents)}, fee included'),
            if (cancelled)
              KitKeyValue('Refunded', 'S\$${money(b.refundCents)}')
            else if (!over)
              KitKeyValue(
                b.canCancelFree
                    ? 'Free to cancel until'
                    : 'Free cancelling ended',
                Fmt.dayTimeComma(b.freeCancelUntil),
              ),
            KitKeyValue('Booking', b.code),
          ],
        ),
        if (!cancelled && !over)
          const KitNote(
            'Running a Meet on this court? Create it from here and the venue '
            'and time fill in for you.',
          ),
      ],
    );
  }
}

// ─── Cancel a booking ──────────────────────────────────────────────────────

class CancelCourtBookingScreen extends ConsumerStatefulWidget {
  const CancelCourtBookingScreen({super.key, required this.id});

  final String id;

  @override
  ConsumerState<CancelCourtBookingScreen> createState() =>
      _CancelCourtBookingScreenState();
}

class _CancelCourtBookingScreenState
    extends ConsumerState<CancelCourtBookingScreen> {
  bool _toWallet = true;
  bool _understood = false;
  bool _busy = false;
  int? _refunded;

  Future<void> _cancel(CourtBooking b) async {
    setState(() => _busy = true);
    try {
      final refund = await ref
          .read(venueRepositoryProvider)
          .cancel(b.id, toWallet: _toWallet);
      HapticFeedback.mediumImpact();
      ref.invalidate(courtBookingProvider(b.id));
      ref.invalidate(myCourtBookingsProvider);
      ref.invalidate(courtSlotsProvider);
      ref.invalidate(walletSummaryProvider);
      if (mounted) setState(() => _refunded = refund);
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
    final b = ref.watch(courtBookingProvider(widget.id)).value;
    if (b == null) {
      return const KitScaffold(
        header: KitHeader(title: 'Cancel booking'),
        children: [CupertinoActivityIndicator()],
      );
    }
    final refunded = _refunded;
    if (refunded != null) {
      return KitScaffold(
        header: const KitHeader(title: 'Cancel booking'),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        bottom: [
          KitButton(
            label: 'Back to venue',
            onPressed: () => context.go(Routes.venue(b.venueId)),
          ),
        ],
        children: [
          const KitDoneBanner(title: 'Cancelled'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  refunded > 0 ? 'S\$${money(refunded)} refunded' : 'No refund',
                  style: OgText.heading(26),
                ),
                const SizedBox(height: 4),
                Text(
                  refunded == 0
                      ? 'It was inside 24 hours, so the venue keeps the fee. '
                            'The court is free for others to book.'
                      : 'It goes to ${_toWallet ? 'your Wallet, now' : 'your card, in 3 to 5 working days'}. '
                            'The court is free for others to book.',
                  style: OgText.body(15, height: 1.45, color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final free = b.canCancelFree;
    return KitScaffold(
      header: const KitHeader(title: 'Cancel booking'),
      bottom: [
        KitButton(
          label: 'Cancel booking',
          style: KitButtonStyle.danger,
          loading: _busy,
          onPressed: _understood ? () => _cancel(b) : null,
        ),
      ],
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: t.warnFill,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: OgIcon(OgIcons.warning, size: 30, color: t.onWarnFill),
          ),
        ),
        KitTitle(
          'Cancel ${b.court}?',
          size: 30,
          lead:
              '${Fmt.day(b.start)}, ${Fmt.timeRange(b.start, b.end)} · ${b.venueName}',
        ),
        Column(
          children: [
            KitKeyValue('You paid', 'S\$${money(b.paidCents)}'),
            KitKeyValue('Court', 'S\$${money(b.courtCents)}'),
            KitKeyValue('Platform fee', 'S\$${money(b.feeCents)}'),
            KitKeyValue(
              'Cancelling',
              free ? 'More than 24 hours before' : 'Less than 24 hours before',
            ),
          ],
        ),
        if (free)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Where should the refund go?', style: OgText.heading(22)),
              const SizedBox(height: 8),
              KitChoiceRow(
                title: 'Wallet',
                subtitle: 'All S\$${money(b.paidCents)} · instant',
                selected: _toWallet,
                onTap: () => setState(() => _toWallet = true),
              ),
              KitChoiceRow(
                title: 'Card',
                subtitle:
                    'S\$${money(b.courtCents)} · the S\$${money(b.feeCents)} platform fee stays · 3 to 5 working days',
                selected: !_toWallet,
                onTap: () => setState(() => _toWallet = false),
              ),
            ],
          )
        else
          KitNote(
            'It is less than 24 hours before, so the venue keeps the fee.',
            tone: KitTone.warn,
          ),
        KitKeyValue(
          'You get back',
          'S\$${money(b.refundTo(wallet: _toWallet))}',
        ),
        KitConfirmBox(
          label: 'I understand the court is released to other players',
          checked: _understood,
          onChanged: (v) => setState(() => _understood = v),
        ),
      ],
    );
  }
}
