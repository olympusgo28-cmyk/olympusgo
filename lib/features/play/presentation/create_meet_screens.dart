import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/data/auth_repository.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/domain/club_sport.dart';
import '../../onboarding/domain/sport.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import 'play_screen.dart' show BandRangePicker;
import 'play_widgets.dart' show sportFormats;

/// Opens the create screens filled in from [a], to change it.
void editActivity(BuildContext context, WidgetRef ref, Activity a) {
  ref.read(activityDraftControllerProvider.notifier).startEdit(a);
  context.push(switch (a.kind) {
    ActivityKind.meet => Routes.newMeetBasics,
    ActivityKind.tournament => Routes.newTournDetails,
    ActivityKind.event => Routes.newEventDetails,
  });
}

/// The header of a create step: title, "Step 1 of 2 · Sport" and a bar.
class CreateStepHeader extends StatelessWidget {
  const CreateStepHeader({
    super.key,
    required this.title,
    required this.step,
    required this.of,
    required this.name,
    this.showSteps = true,
  });

  final String title;
  final int step;
  final int of;
  final String name;

  /// Off when editing: there are no steps, only the details.
  final bool showSteps;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(bottom: BorderSide(color: c.border)),
      ),
      child: Column(
        children: [
          KitHeader(
            title: title,
            subtitle: showSteps ? 'Step $step of $of · $name' : name,
            titleSize: 19,
            border: false,
          ),
          if (showSteps)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
              child: Row(
                children: [
                  for (var i = 1; i <= of; i++) ...[
                    if (i > 1) const SizedBox(width: 6),
                    Expanded(
                      child: Container(
                        height: 5,
                        decoration: BoxDecoration(
                          color: i <= step ? c.primary : c.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A titled block of a create form.
class CreateSection extends StatelessWidget {
  const CreateSection(this.title, {super.key, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: kitSpaced([
      Semantics(header: true, child: Text(title, style: OgText.heading(20))),
      ...children,
    ], 12),
  );
}

/// A label and its current value that opens a picker.
class CreatePickRow extends StatelessWidget {
  const CreatePickRow({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.hint,
    this.icon,
  });

  final String label;
  final String value;
  final String? hint;
  final String? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: '$label, $value',
      onPressed: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border, width: 1.5),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              OgIcon(icon!, size: 22, color: c.text),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    hint == null ? label : '$label · $hint',
                    style: OgText.body(12, color: c.textMuted),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OgText.body(16, weight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            OgIcon(OgIcons.chevronRight, size: 18, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}

/// − value + in a soft pill.
class CreateStepper extends StatelessWidget {
  const CreateStepper({
    super.key,
    required this.label,
    required this.value,
    required this.onLess,
    required this.onMore,
  });

  final String label;
  final String value;
  final VoidCallback? onLess;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    Widget button(String sign, String what, VoidCallback? tap) => Pressable(
      semanticLabel: what,
      onPressed: tap,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: context.og.bg, shape: BoxShape.circle),
        child: Text(
          sign,
          style: OgText.heading(
            20,
            color: tap == null ? context.og.textMuted : context.og.text,
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
      decoration: BoxDecoration(
        color: t.tag,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: OgText.body(15, weight: FontWeight.w600)),
          ),
          button('−', 'Lower $label', onLess),
          SizedBox(
            width: 64,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: OgText.heading(18),
            ),
          ),
          button('+', 'Raise $label', onMore),
        ],
      ),
    );
  }
}

/// The sports to offer: the hosting club's, or the usual racquet sports.
List<(Sport, String, bool)> _sportsFor(WidgetRef ref, String? clubId) {
  final club = clubId == null ? null : ref.watch(clubProvider(clubId)).value;
  if (club != null && club.sports.isNotEmpty) {
    return [
      for (final (i, s) in club.sports.indexed)
        (
          s.sport.playSport,
          'Club range ${s.range.label}${i == 0 ? ' · ${club.memberCount} members' : ''}',
          i == 0,
        ),
    ];
  }
  return [
    for (final s in const [
      Sport.badminton,
      Sport.pickleball,
      Sport.tennis,
      Sport.tableTennis,
      Sport.padel,
    ])
      (s, sportFormats(s), false),
  ];
}

/// Step 1: the sport (or, for events, the sports).
class NewSportScreen extends ConsumerWidget {
  const NewSportScreen({super.key, required this.kind});

  final ActivityKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(activityDraftControllerProvider);
    final edit = ref.read(activityDraftControllerProvider.notifier).edit;
    final sports = _sportsFor(ref, d.clubId);
    final club = d.clubId == null
        ? null
        : ref.watch(clubProvider(d.clubId!)).value;
    final multi = kind == ActivityKind.event;
    return KitScaffold(
      header: CreateStepHeader(
        title:
            'New ${kind == ActivityKind.meet ? 'Meet' : kind.label.toLowerCase()}',
        step: 1,
        of: kind == ActivityKind.tournament ? 4 : 2,
        name: 'Sport',
      ),
      bottom: [
        KitButton(
          label: 'Next',
          onPressed: d.sports.isEmpty
              ? null
              : () {
                  // Start from the club's level range for this sport.
                  final range = club?.sports
                      .where((s) => s.sport.playSport == d.sports.first)
                      .firstOrNull
                      ?.range;
                  if (range != null && !multi) {
                    edit(
                      (d) => d.copyWith(
                        levelMin: range.min + 1.0,
                        levelMax: range.max + 1.9,
                        restrictLevel: !range.isAll,
                      ),
                    );
                  }
                  context.push(switch (kind) {
                    ActivityKind.meet => Routes.newMeetBasics,
                    ActivityKind.event => Routes.newEventDetails,
                    ActivityKind.tournament => Routes.newTournDetails,
                  });
                },
        ),
      ],
      children: [
        KitTitle(switch (kind) {
          ActivityKind.meet => 'What are you playing?',
          ActivityKind.event => 'Which sports are at this event?',
          ActivityKind.tournament => 'Which sport is the tournament?',
        }, lead: multi ? 'Pick one or more.' : null),
        Column(
          children: [
            for (final (sport, sub, main) in sports)
              KitChoiceRow(
                title: sport.label,
                subtitle: sub,
                tag: main ? 'Main' : null,
                multi: multi,
                selected: multi
                    ? d.sports.contains(sport)
                    : d.sports.firstOrNull == sport,
                onTap: () => edit((d) {
                  if (!multi) return d.copyWith(sports: [sport]);
                  final next = [...d.sports];
                  next.contains(sport) ? next.remove(sport) : next.add(sport);
                  return d.copyWith(sports: next);
                }),
              ),
          ],
        ),
      ],
    );
  }
}

/// Step 2: Basics, Game and Fee on one page, one part at a time.
class NewMeetDetailsScreen extends ConsumerStatefulWidget {
  const NewMeetDetailsScreen({super.key});

  @override
  ConsumerState<NewMeetDetailsScreen> createState() =>
      _NewMeetDetailsScreenState();
}

class _NewMeetDetailsScreenState extends ConsumerState<NewMeetDetailsScreen> {
  static const _parts = ['Basics', 'Game', 'Fee'];
  static const _mins = {
    GameType.singles: 2,
    GameType.doubles: 4,
    GameType.social: 5,
  };

  int _part = 0;
  bool _busy = false;
  // Made up front: a lazy one first touched in dispose() would read ref
  // after the screen is gone.
  late final TextEditingController _title;
  late final TextEditingController _desc;
  late final TextEditingController _fee;

  @override
  void initState() {
    super.initState();
    final d = _d;
    _title = TextEditingController(text: d.title);
    _desc = TextEditingController(text: d.description);
    _fee = TextEditingController(
      text: d.feeCents == 0 ? '' : money(d.feeCents),
    );
  }

  ActivityDraft get _d => ref.read(activityDraftControllerProvider);
  void _edit(ActivityDraft Function(ActivityDraft) f) =>
      ref.read(activityDraftControllerProvider.notifier).edit(f);

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _fee.dispose();
    super.dispose();
  }

  /// What still stops this part from being done, or null.
  String? _missing(int part) {
    final d = _d;
    if (part == 0) {
      if (_title.text.trim().length < 3) return 'Give your Meet a title.';
      if (d.date == null) return 'Pick a date.';
      if (d.repeat != Repeat.once && d.repeatDays.isEmpty) {
        return 'Pick the days it repeats on.';
      }
      if (d.venue == null) return 'Pick a venue.';
    }
    if (part == 2 && d.chargeFee && d.feeCents <= 0) {
      return 'Set the fee per player, or make it free.';
    }
    return null;
  }

  void _go(int part) {
    _edit(
      (d) =>
          d.copyWith(title: _title.text.trim(), description: _desc.text.trim()),
    );
    if (part > _part) {
      for (var p = _part; p < part; p++) {
        if (_missing(p) case final why?) {
          showOgToast(context, why, error: true);
          return;
        }
      }
    }
    setState(() => _part = part);
  }

  Future<void> _create() async {
    _go(_part);
    for (var p = 0; p < 3; p++) {
      if (_missing(p) case final why?) {
        setState(() => _part = p);
        showOgToast(context, why, error: true);
        return;
      }
    }
    setState(() => _busy = true);
    try {
      final count = _d.occurrences.length;
      final editing = _d.editing;
      await ref.read(activityDraftControllerProvider.notifier).publish();
      HapticFeedback.mediumImpact();
      if (!mounted) return;
      if (editing) {
        showOgToast(context, 'Changes saved');
        context.pop();
        return;
      }
      showOgToast(context, count > 1 ? '$count Meets created' : 'Meet created');
      context.go(Routes.schedule(hosting: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(activityDraftControllerProvider);
    return KitScaffold(
      // A fresh scroll for each part, so it opens at the top.
      key: ValueKey(_part),
      header: CreateStepHeader(
        title: d.editing ? 'Edit Meet' : 'New Meet',
        showSteps: !d.editing,
        step: 2,
        of: 2,
        name: d.sports.first.label,
      ),
      bottom: [
        Row(
          children: [
            if (_part > 0) ...[
              Expanded(
                child: KitButton(
                  label: 'Back',
                  style: KitButtonStyle.outline,
                  onPressed: () => _go(_part - 1),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 2,
              child: KitButton(
                label: _part < 2
                    ? 'Next: ${_parts[_part + 1]}'
                    : d.editing
                    ? 'Save changes'
                    : 'Create Meet',
                loading: _busy,
                onPressed: _part < 2 ? () => _go(_part + 1) : _create,
              ),
            ),
          ],
        ),
      ],
      children: [
        Row(
          children: [
            for (final (i, label) in _parts.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _PartPill(
                  n: i + 1,
                  label: label,
                  on: _part == i,
                  done: _part > i,
                  onTap: () => _go(i),
                ),
              ),
            ],
          ],
        ),
        ...switch (_part) {
          0 => _basics(d),
          1 => _game(d),
          _ => _feePart(d),
        },
      ],
    );
  }

  List<Widget> _basics(ActivityDraft d) {
    final c = context.og;
    final repeating = d.repeat != Repeat.once;
    final dates = d.occurrences;
    const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    final time = d.startsAt == null
        ? Fmt.clock(d.hour, d.minute)
        : Fmt.timeRange(
            d.startsAt!,
            d.startsAt!.add(Duration(minutes: d.durationMinutes)),
          );
    return [
      CreateSection(
        'Meet details',
        children: [
          KitInput(
            label: 'Title',
            controller: _title,
            hint: 'Friday Night Doubles',
            maxLength: 60,
          ),
          KitTextArea(
            label: 'Description',
            optional: true,
            controller: _desc,
            hint: 'Rotating doubles, 21-point games. Shuttles provided.',
          ),
        ],
      ),
      CreateSection(
        'Time and location',
        children: [
          // One date of a series is changed on its own.
          if (!d.editing)
            KitSegments(
              labels: [for (final r in Repeat.values) r.label],
              selected: d.repeat.index,
              fontSize: 14,
              onSelect: (i) => _edit(
                (d) => d.copyWith(
                  repeat: Repeat.values[i],
                  repeatDays: d.repeatDays.isEmpty && d.date != null
                      ? [d.date!.weekday]
                      : d.repeatDays,
                ),
              ),
            ),
          CreatePickRow(
            label: repeating ? 'Starts' : 'Date',
            value: d.date == null ? 'Choose a date' : Fmt.day(d.date!),
            icon: OgIcons.calendarBox,
            onTap: () => context.push(Routes.createDate('start')),
          ),
          CreatePickRow(
            label: 'Time',
            hint: 'Same day only',
            value: time,
            icon: OgIcons.clockFace,
            onTap: () => context.push(Routes.createTime('start')),
          ),
          if (repeating) ...[
            Text(
              'Repeats on · Pick one or more days',
              style: OgText.body(13, color: c.textMuted),
            ),
            Row(
              children: [
                for (var i = 1; i <= 7; i++) ...[
                  if (i > 1) const SizedBox(width: 6),
                  Expanded(
                    child: _DayDot(
                      letter: letters[i - 1],
                      name: names[i - 1],
                      on: d.repeatDays.contains(i),
                      onTap: () => _edit((d) {
                        final days = [...d.repeatDays];
                        if (days.contains(i)) {
                          if (days.length > 1) days.remove(i);
                        } else {
                          days.add(i);
                        }
                        return d.copyWith(repeatDays: days);
                      }),
                    ),
                  ),
                ],
              ],
            ),
            CreateStepper(
              label: 'Repeat count',
              value: '${d.repeatCount}',
              onLess: d.repeatCount <= 2
                  ? null
                  : () => _edit(
                      (d) => d.copyWith(repeatCount: d.repeatCount - 1),
                    ),
              onMore: d.repeatCount >= 52
                  ? null
                  : () => _edit(
                      (d) => d.copyWith(repeatCount: d.repeatCount + 1),
                    ),
            ),
            if (dates.isNotEmpty)
              KitNote(
                '${d.recurrenceLabel}, $time. ${dates.length} Meets, last one '
                '${Fmt.day(dates.last)}.\nNext: '
                '${dates.take(4).map(Fmt.day).join(' · ')}'
                '${dates.length > 4 ? ' · +${dates.length - 4} more' : ''}.\n'
                'Each date has its own sign-ups and attendance.',
              ),
          ],
          CreatePickRow(
            label: 'Venue',
            hint: "Book courts on the venue's own site",
            value: d.venue == null
                ? 'Choose a venue'
                : '${d.venue!.name} · ${d.courts} ${d.courts == 1 ? 'court' : 'courts'}',
            icon: OgIcons.mapPin,
            onTap: () => context.push(Routes.createVenue),
          ),
        ],
      ),
    ];
  }

  List<Widget> _game(ActivityDraft d) {
    final c = context.og;
    final type = d.gameType ?? GameType.doubles;
    final min = _mins[type] ?? 4;
    final lo = (d.levelMin.floor() - 1).clamp(0, 7);
    final hi = (d.levelMax.floor() - 1).clamp(0, 7);
    final short = '${SkillBand.values[lo].code}–${SkillBand.values[hi].code}';
    final numbers = '${lo + 1}.0–${hi == 7 ? '8.0' : '${hi + 1}.9'}';
    return [
      CreateSection(
        'Game setup',
        children: [
          Text('Game type', style: OgText.body(13, color: c.textMuted)),
          Row(
            children: [
              for (final (i, g) in _mins.keys.indexed) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _TypeCard(
                    label: g.label,
                    sub: '${_mins[g]}+ players',
                    on: type == g,
                    onTap: () => _edit(
                      (d) => d.copyWith(
                        gameType: g,
                        minPlayers: _mins[g]!,
                        capacity: d.capacity < _mins[g]!
                            ? _mins[g]!
                            : d.capacity,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text('Players', style: OgText.body(13, color: c.textMuted)),
          CreateStepper(
            label: 'Minimum',
            value: '${d.minPlayers}',
            onLess: d.minPlayers <= min
                ? null
                : () => _edit((d) => d.copyWith(minPlayers: d.minPlayers - 1)),
            onMore: d.minPlayers >= 64
                ? null
                : () => _edit(
                    (d) => d.copyWith(
                      minPlayers: d.minPlayers + 1,
                      capacity: d.capacity <= d.minPlayers
                          ? d.minPlayers + 1
                          : d.capacity,
                    ),
                  ),
          ),
          CreateStepper(
            label: 'Maximum',
            value: '${d.capacity}',
            onLess: d.capacity <= d.minPlayers
                ? null
                : () => _edit((d) => d.copyWith(capacity: d.capacity - 1)),
            onMore: d.capacity >= 64
                ? null
                : () => _edit((d) => d.copyWith(capacity: d.capacity + 1)),
          ),
          Text(
            '${type.label} needs at least $min. Extra sign-ups join a '
            'waitlist. Below ${d.minPlayers} sign-ups 24 hours before, you '
            'choose to cancel or play.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
      KitCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          SwitchRow(
            compact: true,
            title: 'Restrict by skill level',
            subtitle: 'Only players in this range can join',
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
                  'Show level on the Meet card as',
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
      KitCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          SwitchRow(
            compact: true,
            title: 'Ranked game',
            subtitle: 'Scores update ratings and the leaderboard',
            value: d.ranked,
            onChanged: (v) => _edit((d) => d.copyWith(ranked: v)),
          ),
          if (d.ranked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: KitNote(
                'Camera scoring comes in Phase 2. For now, both sides confirm '
                'each score. Later a court camera scores ranked games and adds '
                'rally and smash stats.',
                tone: KitTone.info,
              ),
            ),
        ],
      ),
    ];
  }

  List<Widget> _feePart(ActivityDraft d) {
    final c = context.og;
    final paid = d.chargeFee;
    final cut = platformFee(d.feeCents);
    Widget rows(List<(String, String, bool)> lines) => Column(
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
    );
    return [
      CreateSection(
        'Fee',
        children: [
          KitSegments(
            labels: const ['Paid', 'Free'],
            selected: paid ? 0 : 1,
            onSelect: (i) => _edit((d) => d.copyWith(chargeFee: i == 0)),
          ),
          if (paid) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: KitInput(
                    label: 'Fee per player (SGD)',
                    controller: _fee,
                    hint: '6.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => _edit(
                      (d) => d.copyWith(
                        feeCents: ((double.tryParse(v) ?? 0) * 100).round(),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10, bottom: 16),
                  child: Text(
                    '/ person',
                    style: OgText.body(14, color: c.textMuted),
                  ),
                ),
              ],
            ),
            KitCard(
              padding: const EdgeInsets.all(14),
              children: [
                rows([
                  (
                    d.feeCents > 0 && cut == 200
                        ? 'Platform fee (minimum)'
                        : 'Platform fee (10%)',
                    'S\$${money(cut)}',
                    false,
                  ),
                  ('Each player pays', 'S\$${money(d.feeCents + cut)}', true),
                  ('You receive per player', 'S\$${money(d.feeCents)}', false),
                ]),
              ],
            ),
          ] else ...[
            Text(
              'Who pays the S\$2 platform fee?',
              style: OgText.body(15, weight: FontWeight.w700),
            ),
            KitChoiceRow(
              title: 'Me, the organizer',
              subtitle:
                  'Players join free. You pay S\$2 for each player who '
                  'joins.',
              selected: !d.playersPayFee,
              onTap: () => _edit((d) => d.copyWith(playersPayFee: false)),
            ),
            KitChoiceRow(
              title: 'Each player',
              subtitle: 'Players pay S\$2 to join.',
              selected: d.playersPayFee,
              onTap: () => _edit((d) => d.copyWith(playersPayFee: true)),
            ),
            KitCard(
              padding: const EdgeInsets.all(14),
              children: [
                rows(
                  d.playersPayFee
                      ? [
                          ('Meet fee', 'S\$0.00', false),
                          ('Each player pays', 'S\$2.00', true),
                          ('You receive', 'S\$0.00', false),
                        ]
                      : [
                          ('Each player pays', 'S\$0.00', true),
                          ('You pay per player', 'S\$2.00', false),
                          (
                            'If ${d.capacity} join, you pay',
                            'S\$${money(d.capacity * 200)}',
                            false,
                          ),
                        ],
                ),
              ],
            ),
          ],
          Text(
            'Platform fee: 10%, minimum S\$2. '
            '${!paid && !d.playersPayFee ? 'If a player leaves before the Meet starts, your S\$2 for them is refunded.' : 'Players who leave before the Meet starts get all of it back to their Wallet, or the price without the platform fee to their card. If you cancel, they get all of it back and card fees come off your earnings.'}',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      ),
      const KitNote(
        'Playing in your own Meet? Organizing only costs nothing and you are '
        'not counted as a player. To play too, take a spot on the Meet page '
        'after you publish. You pay the S\$2 platform fee and no session fee. '
        'When you play, you are marked Present automatically as you arrive at '
        'the venue.',
        tone: KitTone.info,
      ),
      Text(
        'You mark attendance at the Meet. Present players get Passport credit '
        'and points.',
        style: OgText.body(14, height: 1.45, color: c.textMuted),
      ),
      CreateSection(
        'Optional details',
        children: [
          KitCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              SwitchRow(
                compact: true,
                title: 'Allow guests',
                subtitle: 'Players can bring a friend',
                value: d.allowGuests,
                onChanged: (v) => _edit((d) => d.copyWith(allowGuests: v)),
              ),
              SwitchRow(
                compact: true,
                title: 'Only I can invite players',
                subtitle: 'Members can join, but only you can invite others',
                value: d.hostInvitesOnly,
                onChanged: (v) => _edit((d) => d.copyWith(hostInvitesOnly: v)),
              ),
              SwitchRow(
                compact: true,
                title: 'Mark game as public',
                subtitle:
                    'Anyone nearby can find and join. Needs the Make Meets '
                    'public permission',
                value: d.listPublicly,
                onChanged: (v) => _edit((d) => d.copyWith(listPublicly: v)),
              ),
            ],
          ),
        ],
      ),
    ];
  }
}

class _PartPill extends StatelessWidget {
  const _PartPill({
    required this.n,
    required this.label,
    required this.on,
    required this.done,
    required this.onTap,
  });

  final int n;
  final String label;
  final bool on;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    return Pressable(
      semanticLabel: 'Part $n, $label',
      selected: on,
      onPressed: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: on ? OgColors.ink : c.bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: on ? OgColors.ink : c.borderControl,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: on
                    ? c.primary
                    : done
                    ? t.successFill
                    : t.tag,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$n',
                style: OgText.body(
                  12,
                  weight: FontWeight.w800,
                  color: on
                      ? c.onPrimary
                      : done
                      ? t.onSuccessFill
                      : t.onTag,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: OgText.body(
                14,
                weight: FontWeight.w700,
                color: on ? Colors.white : c.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({
    required this.letter,
    required this.name,
    required this.on,
    required this.onTap,
  });

  final String letter;
  final String name;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: name,
      selected: on,
      onPressed: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? c.primary : c.bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: on ? c.primary : c.borderControl,
            width: 1.5,
          ),
        ),
        child: Text(
          letter,
          style: OgText.body(
            14,
            weight: FontWeight.w700,
            color: on ? c.onPrimary : c.text,
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.label,
    required this.sub,
    required this.on,
    required this.onTap,
  });

  final String label;
  final String sub;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    return Pressable(
      semanticLabel: '$label, $sub',
      selected: on,
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: on ? OgColors.ink : c.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: on ? OgColors.ink : c.borderControl,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: OgText.body(
                15,
                weight: FontWeight.w700,
                color: on ? Colors.white : c.text,
              ),
            ),
            Text(
              sub,
              style: OgText.body(
                12,
                color: on ? const Color(0xFFC9C6BC) : c.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
