import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/domain/club_sport.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import 'create_meet_screens.dart';
import 'play_screen.dart' show BandRangePicker;

/// The banner on tournament and event cards and pages: a short title on a
/// colour, with a live preview.
class BannerPicker extends StatelessWidget {
  const BannerPicker({
    super.key,
    required this.noun,
    required this.title,
    required this.color,
    required this.onColor,
    this.required = false,
  });

  /// "tournament", "event".
  final String noun;
  final TextEditingController title;
  final int color;
  final ValueChanged<int> onColor;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${noun[0].toUpperCase()}${noun.substring(1)} banner',
          style: OgText.heading(20),
        ),
        const SizedBox(height: 4),
        Text(
          'Shown on the $noun card and page.${required ? ' Required.' : ''}',
          style: OgText.body(13, color: c.textMuted),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: CourtHero(
            color: Color(color),
            height: 132,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: ValueListenableBuilder(
                  valueListenable: title,
                  builder: (context, v, _) => Text(
                    v.text.trim().isEmpty ? 'Banner title' : v.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.heading(
                      30,
                      color: Color(bannerInk(color))
                          .withValues(alpha: v.text.trim().isEmpty ? 0.5 : 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final (bg, _) in bannerColors)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Pressable(
                  semanticLabel: 'Banner colour',
                  selected: bg == color,
                  onPressed: () => onColor(bg),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Color(bg),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: bg == color ? c.primary : c.border,
                        width: bg == color ? 3 : 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        KitInput(
          label: 'Banner title',
          controller: title,
          hint: noun == 'event' ? 'Finals Day' : 'Tampines Open',
          maxLength: 40,
        ),
      ],
    );
  }
}

/// Rows of amounts with an optional bold total line.
class _Money extends StatelessWidget {
  const _Money(this.lines);

  final List<(String, String, bool)> lines;

  @override
  Widget build(BuildContext context) => KitCard(
    padding: const EdgeInsets.all(14),
    children: [
      Column(
        children: [
          for (final (k, v, bold) in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k,
                      style: OgText.body(
                        14,
                        weight: bold ? FontWeight.w800 : FontWeight.w400,
                      ),
                    ),
                  ),
                  Text(
                    v,
                    style: OgText.body(
                      14,
                      weight: bold ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}

/// Publishes the draft and lands on Hosting, or saves an edit and goes back.
Future<void> _publish(
  BuildContext context,
  WidgetRef ref,
  void Function(bool) busy,
) async {
  busy(true);
  try {
    final editing = ref.read(activityDraftControllerProvider).editing;
    await ref.read(activityDraftControllerProvider.notifier).publish();
    HapticFeedback.mediumImpact();
    if (!context.mounted) return;
    if (editing) {
      showOgToast(context, 'Changes saved');
      context.pop();
      return;
    }
    final kind = ref.read(activityDraftControllerProvider).kind;
    showOgToast(context, '${kind.label} published');
    context.go(Routes.schedule(hosting: true));
  } on AuthFailure catch (e) {
    if (context.mounted) showOgToast(context, e.message, error: true);
  } finally {
    busy(false);
  }
}

/// Event step 2: banner, name, when and where, tickets and options.
class NewEventScreen extends ConsumerStatefulWidget {
  const NewEventScreen({super.key});

  @override
  ConsumerState<NewEventScreen> createState() => _NewEventScreenState();
}

class _NewEventScreenState extends ConsumerState<NewEventScreen> {
  late final ActivityDraft _start = ref.read(activityDraftControllerProvider);
  late final _name = TextEditingController(text: _start.title);
  late final _desc = TextEditingController(text: _start.description);
  late final _banner = TextEditingController(text: _start.coverTitle ?? '');
  late final _price = TextEditingController(
    text: _start.feeCents == 0 ? '' : money(_start.feeCents),
  );
  bool _busy = false;

  void _edit(ActivityDraft Function(ActivityDraft) f) =>
      ref.read(activityDraftControllerProvider.notifier).edit(f);

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _banner.dispose();
    _price.dispose();
    super.dispose();
  }

  String? _missing(ActivityDraft d) {
    if (_name.text.trim().length < 3) return 'Give your event a name.';
    if (d.date == null) return 'Pick the date and time.';
    if (!d.online && d.venue == null) return 'Pick a venue.';
    if (d.chargeFee && d.feeCents <= 0) return 'Set the ticket price.';
    return null;
  }

  Future<void> _go() async {
    _edit(
      (d) => d.copyWith(
        title: _name.text.trim(),
        description: _desc.text.trim(),
        coverTitle: _banner.text.trim().isEmpty ? null : _banner.text.trim(),
      ),
    );
    final d = ref.read(activityDraftControllerProvider);
    if (_missing(d) case final why?) {
      showOgToast(context, why, error: true);
      return;
    }
    await _publish(context, ref, (b) => setState(() => _busy = b));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final d = ref.watch(activityDraftControllerProvider);
    final fee = d.chargeFee ? platformFee(d.feeCents) : 200;
    final hosting = ref.watch(hostingProvider).value ?? const <Activity>[];
    final tournaments = hosting
        .where((a) => a.kind == ActivityKind.tournament)
        .toList();
    return KitScaffold(
      header: CreateStepHeader(
        title: d.editing ? 'Edit event' : 'New event',
        showSteps: !d.editing,
        step: 2,
        of: 2,
        name: d.sports.map((s) => s.label).join(', '),
      ),
      bottom: [
        KitButton(
          label: d.editing ? 'Save changes' : 'Publish event',
          loading: _busy,
          onPressed: _go,
        ),
      ],
      children: [
        BannerPicker(
          noun: 'event',
          title: _banner,
          color: d.coverColor,
          onColor: (v) => _edit((d) => d.copyWith(coverColor: v)),
        ),
        CreateSection(
          'Event details',
          children: [
            KitInput(
              label: 'Event name',
              controller: _name,
              hint: 'East Side Sports Festival',
              maxLength: 60,
            ),
            KitTextArea(
              label: 'Description',
              controller: _desc,
              hint:
                  "Try-outs with 12 local clubs, coach clinics every hour, gear "
                  "booths and kids' games. Open to all ages and levels.",
            ),
          ],
        ),
        CreateSection(
          'Date and time',
          children: [
            CreatePickRow(
              label: 'When',
              value: d.startsAt == null
                  ? 'Choose a date'
                  : Fmt.dayTimeComma(d.startsAt!),
              icon: OgIcons.calendarBox,
              onTap: () => context.push(Routes.createDate('event')),
            ),
          ],
        ),
        CreateSection(
          'Where it happens',
          children: [
            KitSegments(
              labels: const ['Offline', 'Online'],
              selected: d.online ? 1 : 0,
              onSelect: (i) => _edit((d) => d.copyWith(online: i == 1)),
            ),
            CreatePickRow(
              label: 'Venue',
              hint: d.online
                  ? 'Optional · where it is filmed'
                  : "Offline · on the venue's activity list",
              value: d.venue?.name ?? 'Choose a venue',
              icon: OgIcons.mapPin,
              onTap: () => context.push(Routes.createVenue),
            ),
          ],
        ),
        CreateSection(
          'Tickets',
          children: [
            KitSegments(
              labels: const ['Free', 'Paid'],
              selected: d.chargeFee ? 1 : 0,
              onSelect: (i) => _edit((d) => d.copyWith(chargeFee: i == 1)),
            ),
            if (d.chargeFee)
              KitInput(
                label: 'Ticket price (SGD)',
                controller: _price,
                hint: '10.00',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                onChanged: (v) => _edit(
                  (d) => d.copyWith(
                    feeCents: ((double.tryParse(v) ?? 0) * 100).round(),
                  ),
                ),
              ),
            CreateStepper(
              label: 'Capacity',
              value: '${d.capacity}',
              onLess: d.capacity <= 10
                  ? null
                  : () => _edit((d) => d.copyWith(capacity: d.capacity - 10)),
              onMore: d.capacity >= 5000
                  ? null
                  : () => _edit((d) => d.copyWith(capacity: d.capacity + 10)),
            ),
            _Money(
              d.chargeFee
                  ? [
                      ('Ticket', 'S\$${money(d.feeCents)}', false),
                      (
                        'Platform fee (${fee == 200 ? 'minimum' : '10%'})',
                        'S\$${money(fee)}',
                        false,
                      ),
                      (
                        'Each attendee pays',
                        'S\$${money(d.feeCents + fee)}',
                        true,
                      ),
                      ('You receive', 'S\$${money(d.feeCents)}', false),
                    ]
                  : [
                      ('Each attendee pays', 'S\$0.00', true),
                      ('You pay per ticket taken', 'S\$2.00', false),
                      (
                        'If ${d.capacity} take one, you pay',
                        'S\$${money(d.capacity * 200)}',
                        false,
                      ),
                    ],
            ),
            Text(
              d.chargeFee
                  ? 'Attendees who cancel by the day before get all of it back '
                        'to their Wallet, or the ticket price to their card. If '
                        'you cancel, they get all of it back.'
                  : 'If someone releases their ticket, your S\$2 for it is '
                        'returned.',
              style: OgText.body(13, height: 1.45, color: c.textMuted),
            ),
          ],
        ),
        if (tournaments.isNotEmpty)
          CreateSection(
            'Options',
            children: [
              Text(
                'Link to another event · Show it on this event’s page',
                style: OgText.body(13, color: c.textMuted),
              ),
              for (final t in tournaments)
                KitChoiceRow(
                  title: t.title,
                  subtitle:
                      'Tournament · ${Fmt.day(t.startsAt)} · its schedule and '
                      'live results show here',
                  multi: true,
                  selected: d.linkedId == t.id,
                  onTap: () => _edit(
                    (d) =>
                        d.copyWith(linkedId: d.linkedId == t.id ? null : t.id),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// Tournament steps 2 to 4: Details, Game setup and Entry, one page each.
class NewTournamentScreen extends ConsumerStatefulWidget {
  const NewTournamentScreen({super.key});

  @override
  ConsumerState<NewTournamentScreen> createState() =>
      _NewTournamentScreenState();
}

class _NewTournamentScreenState extends ConsumerState<NewTournamentScreen> {
  static const _names = ['Details', 'Game setup', 'Entry'];
  static const _tiers = {
    'Club': 'For your own members. Shown as a Club tag on the card.',
    'Regional':
        'Open to players across clubs in your area. Shown as a Regional tag '
        'on the card.',
    'National':
        'Open to players nationwide. Shown as a National tag on the card.',
  };
  static const _draws = [
    (
      ActivityFormat.groupsKnockout,
      'Groups, then knockout',
      'Everyone plays at least 3 matches',
    ),
    (ActivityFormat.knockout, 'Knockout', 'Fastest. Lose once and you are out'),
    (
      ActivityFormat.roundRobin,
      'Round robin',
      'Everyone plays everyone. Best for small fields',
    ),
  ];

  int _step = 0;
  bool _busy = false;
  late final ActivityDraft _start = ref.read(activityDraftControllerProvider);
  late final _title = TextEditingController(text: _start.title);
  late final _desc = TextEditingController(text: _start.description);
  late final _banner = TextEditingController(text: _start.coverTitle ?? '');

  ActivityDraft get _d => ref.read(activityDraftControllerProvider);
  void _edit(ActivityDraft Function(ActivityDraft) f) =>
      ref.read(activityDraftControllerProvider.notifier).edit(f);

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _banner.dispose();
    super.dispose();
  }

  void _save() => _edit(
    (d) => d.copyWith(
      title: _title.text.trim(),
      description: _desc.text.trim(),
      coverTitle: _banner.text.trim().isEmpty ? null : _banner.text.trim(),
    ),
  );

  String? _missing(int step) {
    final d = _d;
    if (step == 0) {
      if (_title.text.trim().length < 3) return 'Give your tournament a title.';
      if (_banner.text.trim().isEmpty) return 'Add a banner title.';
      if (d.date == null || d.endDate == null) return 'Pick the dates.';
      if (d.venue == null) return 'Pick a venue.';
    }
    if (step == 1 && !d.teamEntry && d.divisionKeys.isEmpty) {
      return 'Pick at least one event.';
    }
    if (step == 2) {
      if (d.registrationCloses == null) return 'Pick when registration closes.';
      if (d.chargeFee && d.feeCents <= 0) return 'Set the fee per entry.';
    }
    return null;
  }

  Future<void> _next() async {
    _save();
    if (_missing(_step) case final why?) {
      showOgToast(context, why, error: true);
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    await _publish(context, ref, (b) => setState(() => _busy = b));
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(activityDraftControllerProvider);
    return KitScaffold(
      key: ValueKey(_step),
      header: CreateStepHeader(
        title: d.editing ? 'Edit tournament' : 'New tournament',
        showSteps: !d.editing,
        step: _step + 2,
        of: 4,
        name: '${_names[_step]} · ${d.sports.first.label}',
      ),
      bottom: [
        Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: KitButton(
                  label: 'Back',
                  style: KitButtonStyle.outline,
                  onPressed: () {
                    _save();
                    setState(() => _step--);
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: KitButton(
                label: _step < 2
                    ? 'Next'
                    : d.editing
                    ? 'Save changes'
                    : 'Publish tournament',
                loading: _busy,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ],
      children: switch (_step) {
        0 => _details(d),
        1 => _game(d),
        _ => _entry(d),
      },
    );
  }

  List<Widget> _details(ActivityDraft d) {
    final c = context.og;
    return [
      CreateSection(
        'Tournament details',
        children: [
          KitInput(
            label: 'Title',
            controller: _title,
            hint: 'Tampines Open 2026',
            maxLength: 60,
          ),
          KitTextArea(
            label: 'Description',
            optional: true,
            controller: _desc,
            hint: 'Two days of singles and doubles across 8 courts.',
          ),
          KitNote(
            '${d.sports.first.label} is played head to head, so this '
            'tournament uses draws and matches.',
            tone: KitTone.info,
          ),
          Text('Tier', style: OgText.body(15, weight: FontWeight.w700)),
          KitSegments(
            labels: _tiers.keys.toList(),
            selected: _tiers.keys.toList().indexOf(d.tier),
            onSelect: (i) =>
                _edit((d) => d.copyWith(tier: _tiers.keys.elementAt(i))),
          ),
          Text(
            _tiers[d.tier] ?? '',
            style: OgText.body(13, height: 1.4, color: c.textMuted),
          ),
        ],
      ),
      BannerPicker(
        noun: 'tournament',
        title: _banner,
        color: d.coverColor,
        required: true,
        onColor: (v) => _edit((d) => d.copyWith(coverColor: v)),
      ),
      CreateSection(
        'Time and location',
        children: [
          CreatePickRow(
            label: 'Dates',
            hint: 'One or more days',
            value: d.date == null
                ? 'Choose dates'
                : d.endDate == null || d.endDate == d.date
                ? Fmt.day(d.date!)
                : Fmt.dayRange(d.date!, d.endDate!),
            icon: OgIcons.calendarBox,
            onTap: () => context.push(Routes.createDate('range')),
          ),
          CreatePickRow(
            label: 'Daily start',
            value: Fmt.clock(d.hour, d.minute),
            icon: OgIcons.clockFace,
            onTap: () => context.push(Routes.createTime('start')),
          ),
          CreatePickRow(
            label: 'Venue',
            hint: "Book courts on the venue's own site",
            value: d.venue?.name ?? 'Choose a venue',
            icon: OgIcons.mapPin,
            onTap: () => context.push(Routes.createVenue),
          ),
          CreateStepper(
            label: 'Courts',
            value: '${d.courts}',
            onLess: d.courts <= 1
                ? null
                : () => _edit((d) => d.copyWith(courts: d.courts - 1)),
            onMore: d.courts >= 24
                ? null
                : () => _edit((d) => d.copyWith(courts: d.courts + 1)),
          ),
          Text(
            'Courts are used to build the match schedule.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      ),
    ];
  }

  List<Widget> _game(ActivityDraft d) {
    final c = context.og;
    final lo = (d.levelMin.floor() - 1).clamp(0, 7);
    final hi = (d.levelMax.floor() - 1).clamp(0, 7);
    final short = '${SkillBand.values[lo].code}–${SkillBand.values[hi].code}';
    final numbers = '${lo + 1}.0–${hi == 7 ? '8.0' : '${hi + 1}.9'}';
    return [
      CreateSection(
        'Who enters?',
        children: [
          KitSegments(
            labels: const ['Players', 'Teams'],
            selected: d.teamEntry ? 1 : 0,
            onSelect: (i) => _edit((d) => d.copyWith(teamEntry: i == 1)),
          ),
          Text(
            d.teamEntry
                ? 'Teams enter with a roster. Each tie is a set of matches.'
                : 'Players sign up for events alone or with a partner, up to '
                      '2 events each.',
            style: OgText.body(13, height: 1.4, color: c.textMuted),
          ),
        ],
      ),
      if (!d.teamEntry)
        CreateSection(
          'Events · ${d.divisionKeys.length} selected',
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in divisionNames.entries)
                  KitChip(
                    label: e.value,
                    selected: d.divisionKeys.contains(e.key),
                    onTap: () => _edit((d) {
                      final keys = [...d.divisionKeys];
                      keys.contains(e.key)
                          ? keys.remove(e.key)
                          : keys.add(e.key);
                      return d.copyWith(
                        divisionKeys: [
                          for (final k in divisionNames.keys)
                            if (keys.contains(k)) k,
                        ],
                      );
                    }),
                  ),
              ],
            ),
            Text(
              'The list comes from the sport: ${d.sports.first.label} has '
              'singles, doubles and mixed events.',
              style: OgText.body(13, height: 1.4, color: c.textMuted),
            ),
          ],
        ),
      CreateSection(
        'Draw',
        children: [
          for (final (f, label, sub) in _draws)
            KitChoiceRow(
              title: label,
              subtitle: sub,
              selected: d.format == f,
              onTap: () => _edit((d) => d.copyWith(format: f)),
            ),
        ],
      ),
      KitKeyValue(
        'Game scoring',
        d.sports.first.label == 'Badminton'
            ? 'Best of 3 games to 21'
            : 'Best of 3 games to 11',
      ),
      KitCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          SwitchRow(
            compact: true,
            title: 'Seed by rating',
            subtitle: 'Top-rated entries are kept apart in the draw',
            value: d.seedByLevel,
            onChanged: (v) => _edit((d) => d.copyWith(seedByLevel: v)),
          ),
          SwitchRow(
            compact: true,
            title: 'Umpire scores matches',
            subtitle: 'Players cannot enter their own score',
            value: d.umpireScores,
            onChanged: (v) => _edit((d) => d.copyWith(umpireScores: v)),
          ),
        ],
      ),
      KitCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          SwitchRow(
            compact: true,
            title: 'Restrict by skill level',
            subtitle: 'Only players in this range can enter',
            value: d.restrictLevel,
            onChanged: (v) => _edit((d) => d.copyWith(restrictLevel: v)),
          ),
          if (d.restrictLevel)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                BandRangePicker(
                  lo: lo,
                  hi: hi,
                  onChanged: (a, b) => _edit(
                    (d) => d.copyWith(levelMin: a + 1.0, levelMax: b + 1.9),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Show level on the card as',
                  style: OgText.body(13, color: c.textMuted),
                ),
                const SizedBox(height: 8),
                KitSegments(
                  labels: ['Short form · $short', 'Numbers · $numbers'],
                  selected: d.levelAsNumbers ? 1 : 0,
                  fontSize: 13,
                  onSelect: (i) =>
                      _edit((d) => d.copyWith(levelAsNumbers: i == 1)),
                ),
                const SizedBox(height: 12),
              ],
            ),
        ],
      ),
      CreateSection(
        'Age divisions',
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in const [
                'Open',
                'U13',
                'U15',
                'U17',
                'Masters 40+',
              ])
                KitChip(
                  label: a,
                  selected: d.ageDivisions.contains(a),
                  onTap: () => _edit((d) {
                    final list = [...d.ageDivisions];
                    list.contains(a) ? list.remove(a) : list.add(a);
                    return d.copyWith(
                      ageDivisions: list.isEmpty ? ['Open'] : list,
                    );
                  }),
                ),
            ],
          ),
          Text(
            'Date of birth is checked privately. Only the division is shown.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      ),
      const KitNote(
        'Ranked · every match counts. The umpire or both sides confirm each '
        'score. Results update ratings and the linked event. Camera scoring '
        'comes in Phase 2.',
        tone: KitTone.info,
      ),
    ];
  }

  List<Widget> _entry(ActivityDraft d) {
    final c = context.og;
    final unit = d.teamEntry ? 'teams' : 'entries per event';
    final prices = d.teamEntry
        ? const [4000, 6000, 8000, 10000]
        : const [1000, 1500, 2000, 3000];
    final fee = platformFee(d.feeCents);
    final hosting = ref.watch(hostingProvider).value ?? const <Activity>[];
    final events = hosting.where((a) => a.kind == ActivityKind.event).toList();
    final drawLabel = _draws
        .where((x) => x.$1 == d.format)
        .map((x) => x.$2)
        .firstOrNull;
    return [
      CreateSection(
        'Entries',
        children: [
          CreateStepper(
            label: 'Minimum',
            value: '${d.minEntries}',
            onLess: d.minEntries <= 2
                ? null
                : () => _edit((d) => d.copyWith(minEntries: d.minEntries - 1)),
            onMore: () => _edit(
              (d) => d.copyWith(
                minEntries: d.minEntries + 1,
                capacity: d.capacity <= d.minEntries
                    ? d.minEntries + 1
                    : d.capacity,
              ),
            ),
          ),
          CreateStepper(
            label: 'Maximum',
            value: '${d.capacity}',
            onLess: d.capacity <= d.minEntries
                ? null
                : () => _edit((d) => d.copyWith(capacity: d.capacity - 1)),
            onMore: d.capacity >= 128
                ? null
                : () => _edit((d) => d.copyWith(capacity: d.capacity + 1)),
          ),
          Text(
            'Counted in $unit. If an event has fewer than ${d.minEntries} '
            'when registration closes, it is cancelled and everyone in it is '
            'refunded.',
            style: OgText.body(13, height: 1.4, color: c.textMuted),
          ),
          CreatePickRow(
            label: 'Registration closes',
            value: d.registrationCloses == null
                ? 'Choose'
                : Fmt.dayTimeComma(d.registrationCloses!),
            icon: OgIcons.clockFace,
            onTap: () => context.push(Routes.createDate('close')),
          ),
        ],
      ),
      CreateSection(
        d.teamEntry ? 'Fee per team' : 'Fee per entry',
        children: [
          Row(
            children: [
              for (final (i, p) in prices.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: KitChip(
                    label: 'S\$${p ~/ 100}',
                    selected: d.chargeFee && d.feeCents == p,
                    onTap: () =>
                        _edit((d) => d.copyWith(chargeFee: true, feeCents: p)),
                  ),
                ),
              ],
            ],
          ),
          Text(
            'Platform fee: 10%, minimum S\$2. Doubles pay per pair, twice the '
            'entry fee.',
            style: OgText.body(13, color: c.textMuted),
          ),
          _Money([
            (
              'Platform fee (${fee == 200 ? 'minimum' : '10%'})',
              'S\$${money(fee)}',
              false,
            ),
            (
              d.teamEntry ? 'Each team pays' : 'Each entry pays',
              'S\$${money(d.feeCents + fee)}',
              true,
            ),
            ('You receive', 'S\$${money(d.feeCents)}', false),
          ]),
          Text(
            'If they withdraw before registration closes: all of it back to '
            'their Wallet, or the entry fee to their card. If you cancel, they '
            'get all of it back.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
      CreateSection(
        'Options',
        children: [
          KitCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              SwitchRow(
                compact: true,
                title: 'Verified players only',
                subtitle: 'Mobile verified and 5+ confirmed matches',
                value: d.verifiedOnly,
                onChanged: (v) => _edit((d) => d.copyWith(verifiedOnly: v)),
              ),
              SwitchRow(
                compact: true,
                title: 'Match check-in',
                subtitle: 'Players check in at the desk or by QR',
                value: d.matchCheckIn,
                onChanged: (v) => _edit((d) => d.copyWith(matchCheckIn: v)),
              ),
              SwitchRow(
                compact: true,
                title: 'Waitlist when full',
                subtitle: 'Spots go to the waitlist in order',
                value: d.waitlistWhenFull,
                onChanged: (v) => _edit((d) => d.copyWith(waitlistWhenFull: v)),
              ),
              SwitchRow(
                compact: true,
                title: 'Mark as public',
                subtitle: 'Players outside the club can find and enter',
                value: d.listPublicly,
                onChanged: (v) => _edit((d) => d.copyWith(listPublicly: v)),
              ),
            ],
          ),
          if (events.isNotEmpty) ...[
            Text(
              'Link to an event · Show this tournament on an event page',
              style: OgText.body(13, color: c.textMuted),
            ),
            for (final e in events)
              KitChoiceRow(
                title: e.title,
                subtitle:
                    'Event · ${Fmt.day(e.startsAt)} · ${e.online ? 'Offline and online' : 'Offline'}',
                multi: true,
                selected: d.linkedId == e.id,
                onTap: () => _edit(
                  (d) => d.copyWith(linkedId: d.linkedId == e.id ? null : e.id),
                ),
              ),
          ],
        ],
      ),
      CreateSection(
        'Summary',
        children: [
          KitKeyValue('Sport', '${d.sports.first.label} · Bracket'),
          KitKeyValue(
            'Entry',
            d.teamEntry ? 'Teams' : '${d.divisionKeys.length} events',
          ),
          KitKeyValue('Draw', drawLabel ?? 'Groups, then knockout'),
          KitKeyValue('Tier', d.tier),
          KitKeyValue(
            'Dates',
            d.date == null
                ? '–'
                : d.endDate == null || d.endDate == d.date
                ? Fmt.day(d.date!)
                : Fmt.dayRange(d.date!, d.endDate!),
          ),
          Text(
            'Results update ratings. Tournament leaderboard points apply once '
            '16+ entries are confirmed and the organizer is verified.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
    ];
  }
}
