import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_screen.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/pressable.dart';
import '../../clubs/application/club_providers.dart';
import '../../clubs/data/club_repository.dart';
import '../../clubs/domain/club_models.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import 'play_widgets.dart';

/// Kinds a club role allows, and the permission each needs.
const _hostable = [
  (
    ActivityKind.meet,
    ClubPermission.createMeet,
    'A play session for members. Singles, doubles or social.',
    Routes.newMeetSport,
  ),
  (
    ActivityKind.tournament,
    ClubPermission.tournament,
    'Draws, schedules and results. Individual or team entries.',
    Routes.newTournSport,
  ),
  (
    ActivityKind.event,
    ClubPermission.events,
    'Festivals, watch parties and online events. Free or ticketed.',
    Routes.newEventSports,
  ),
];

/// "Create": Meets, tournaments and events are hosted by a club, so this
/// asks which club hosts and offers only what that club role allows. With no
/// such club it sends the player to start a group first. [clubId] picks the
/// host when opened from a club page.
///
/// [venue] and [at] prefill where and when, from a venue or court booking.
Future<void> showCreateMenu(
  BuildContext context, {
  String? clubId,
  Venue? venue,
  DateTime? at,
}) => showKitSheet(
  context,
  background: context.tones.soft,
  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
  builder: (_) => _CreateMenu(clubId: clubId, venue: venue, at: at),
);

class _CreateMenu extends ConsumerStatefulWidget {
  const _CreateMenu({this.clubId, this.venue, this.at});

  final String? clubId;
  final Venue? venue;
  final DateTime? at;

  @override
  ConsumerState<_CreateMenu> createState() => _CreateMenuState();
}

class _CreateMenuState extends ConsumerState<_CreateMenu> {
  late String? _host = widget.clubId;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final t = context.tones;
    final clubs = ref.watch(clubListProvider(ClubTab.mine));
    final hosts = [
      for (final item in clubs.value ?? const <ClubListItem>[])
        if (_hostable.any((h) => item.club.can(h.$2))) item.club,
    ];
    final host =
        hosts.where((h) => h.id == _host).firstOrNull ?? hosts.firstOrNull;

    Widget kind((ActivityKind, ClubPermission, String, String) h, bool last) {
      final (k, _, sub, route) = h;
      final (bg, ink, icon) = switch (k) {
        ActivityKind.meet => (t.successFill, t.onSuccessFill, OgIcons.racquet),
        ActivityKind.tournament => (
          t.warnFill,
          t.onWarnFill,
          OgIcons.trophyTeam,
        ),
        ActivityKind.event => (t.dangerFill, t.onDangerFill, OgIcons.heart),
      };
      return Pressable(
        semanticLabel: '${k.label}. $sub',
        onPressed: () {
          final draft = ref.read(activityDraftControllerProvider.notifier)
            ..start(k, clubId: host!.id);
          final at = widget.at;
          draft.edit(
            (d) => d.copyWith(
              venue: widget.venue ?? d.venue,
              date: at ?? d.date,
              hour: at?.hour ?? d.hour,
              minute: at?.minute ?? d.minute,
            ),
          );
          Navigator.of(context).pop();
          context.push(route);
        },
        child: Container(
          constraints: const BoxConstraints(minHeight: 84),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: last ? null : Border(bottom: BorderSide(color: t.divider)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: OgIcon(icon, size: 24, strokeWidth: 1.9, color: ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.label,
                      style: OgText.body(17, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: OgText.body(14, height: 1.4, color: c.textMuted),
                    ),
                  ],
                ),
              ),
              OgIcon(OgIcons.chevronRight, size: 20, color: c.textMuted),
            ],
          ),
        ),
      );
    }

    final allowed = host == null
        ? const <(ActivityKind, ClubPermission, String, String)>[]
        : _hostable.where((h) => host.can(h.$2)).toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: kitSpaced([
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create', style: OgText.heading(22)),
                if (host != null)
                  Text(
                    'Hosted by ${host.name}',
                    style: OgText.body(14, color: c.textMuted),
                  ),
              ],
            ),
          ),
          if (clubs.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            )
          else if (host == null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start a group first',
                    style: OgText.body(17, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Meets, tournaments and events are hosted by a club. Start '
                    'your own, or ask a club admin for a role that can create '
                    'them.',
                    style: OgText.body(14, height: 1.45, color: c.textMuted),
                  ),
                ],
              ),
            ),
            KitButton(
              label: 'Start a group',
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.createGroup);
              },
            ),
            KitButton.outline(
              label: 'Find a club',
              onPressed: () {
                Navigator.of(context).pop();
                context.push(Routes.clubs);
              },
            ),
          ] else ...[
            if (hosts.length > 1)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: kitSpaced([
                    for (final h in hosts)
                      KitChip(
                        label: h.name,
                        selected: h.id == host.id,
                        onTap: () => setState(() => _host = h.id),
                      ),
                  ], 8),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: c.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (var i = 0; i < allowed.length; i++)
                    kind(allowed[i], i == allowed.length - 1),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'You only see what your role allows. Meets need "Create '
                'Meets", tournaments need "Run tournaments", events need '
                '"Create events".',
                style: OgText.body(13, height: 1.45, color: c.textMuted),
              ),
            ),
          ],
          KitButton.outline(
            label: 'Cancel',
            height: 48,
            radius: 24,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ], 14),
      ),
    );
  }
}

/// Shared shell for the pickers: title, content and a Done button.
class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.children,
    required this.button,
    required this.onNext,
    this.lead,
  });

  final String title;
  final String? lead;
  final List<Widget> children;
  final String button;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => KitScaffold(
    header: KitHeader(title: title),
    bottom: [KitButton(label: button, onPressed: onNext)],
    children: [
      if (lead != null)
        Text(lead!, style: OgText.body(15, color: context.og.textMuted)),
      ...children.where((w) => w is! SizedBox || w.child != null),
    ],
  );
}

/// Date picker screens. [field] is start, event (date and time), range
/// (tournament first and last day) or close (registration closes).
class PickDateScreen extends ConsumerStatefulWidget {
  const PickDateScreen({super.key, required this.field});

  final String field;

  @override
  ConsumerState<PickDateScreen> createState() => _PickDateScreenState();
}

class _PickDateScreenState extends ConsumerState<PickDateScreen> {
  late final ActivityDraft _start = ref.read(activityDraftControllerProvider);
  late DateTime? _date = widget.field == 'close'
      ? _start.registrationCloses
      : _start.date;
  late DateTime? _end = _start.endDate;
  late int _hour = widget.field == 'close'
      ? (_start.registrationCloses?.hour ?? 23)
      : _start.hour;
  late int _minute = widget.field == 'close'
      ? (_start.registrationCloses?.minute ?? 45)
      : _start.minute;
  bool _pickingEnd = false;

  bool get _withTime => widget.field == 'event' || widget.field == 'close';

  void _onDay(DateTime day) => setState(() {
    if (widget.field != 'range') {
      _date = day;
      return;
    }
    if (!_pickingEnd || _date == null || day.isBefore(_date!)) {
      _date = day;
      _end = day;
      _pickingEnd = true;
    } else {
      _end = day;
      _pickingEnd = false;
    }
  });

  void _done() {
    final edit = ref.read(activityDraftControllerProvider.notifier).edit;
    switch (widget.field) {
      case 'close':
        if (_date != null) {
          edit(
            (d) => d.copyWith(
              registrationCloses: DateTime(
                _date!.year,
                _date!.month,
                _date!.day,
                _hour,
                _minute,
              ),
            ),
          );
        }
      case 'range':
        edit((d) => d.copyWith(date: _date, endDate: _end ?? _date));
      default:
        edit((d) => d.copyWith(date: _date, hour: _hour, minute: _minute));
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.field) {
      'event' => 'Date and time',
      'range' => 'Tournament dates',
      'close' => 'Registration closes',
      _ => 'Pick a date',
    };
    final lead = switch (widget.field) {
      'range' => 'Pick the first and last day.',
      'close' => 'Teams cannot join after this.',
      _ => null,
    };
    return _Step(
      title: title,
      lead: lead,
      button: 'Done',
      onNext: _date == null ? null : _done,
      children: [
        const SizedBox(height: 16),
        MonthCalendar(
          selected: _date,
          rangeEnd: widget.field == 'range' ? _end : null,
          onSelected: _onDay,
        ),
        if (_withTime) ...[
          const SizedBox(height: 12),
          _TimeSelects(
            hour: _hour,
            minute: _minute,
            onChanged: (h, m) => setState(() {
              _hour = h;
              _minute = m;
            }),
          ),
        ],
      ],
    );
  }
}

/// Hour, minute and AM / PM selects (12-hour, as in the design).
class _TimeSelects extends StatelessWidget {
  const _TimeSelects({
    required this.hour,
    required this.minute,
    required this.onChanged,
  });

  final int hour;
  final int minute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final h12 = hour % 12 == 0 ? 12 : hour % 12;
    final pm = hour >= 12;
    int to24(int h, bool p) => (h % 12) + (p ? 12 : 0);
    return Row(
      children: [
        Expanded(
          child: LabeledSelect<int>(
            label: 'Hour',
            value: h12,
            items: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
            text: (v) => '$v',
            onChanged: (v) => onChanged(to24(v, pm), minute),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LabeledSelect<int>(
            label: 'Minute',
            value: minute,
            items: const [0, 15, 30, 45],
            text: (v) => v.toString().padLeft(2, '0'),
            onChanged: (v) => onChanged(hour, v),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: LabeledSelect<bool>(
            label: 'AM / PM',
            value: pm,
            items: const [false, true],
            text: (v) => v ? 'PM' : 'AM',
            onChanged: (v) => onChanged(to24(h12, v), minute),
          ),
        ),
      ],
    );
  }
}

/// Time picker: start time (and duration for Meets).
class PickTimeScreen extends ConsumerStatefulWidget {
  const PickTimeScreen({super.key});

  @override
  ConsumerState<PickTimeScreen> createState() => _PickTimeScreenState();
}

class _PickTimeScreenState extends ConsumerState<PickTimeScreen> {
  late final ActivityDraft _d = ref.read(activityDraftControllerProvider);
  late int _hour = _d.hour;
  late int _minute = _d.minute;
  late int _duration = _d.durationMinutes;

  @override
  Widget build(BuildContext context) {
    final tournament = _d.kind == ActivityKind.tournament;
    return _Step(
      title: tournament ? 'Daily start' : 'Pick a time',
      lead: tournament ? 'First matches begin at this time each day.' : null,
      button: 'Done',
      onNext: () {
        ref
            .read(activityDraftControllerProvider.notifier)
            .edit(
              (d) => d.copyWith(
                hour: _hour,
                minute: _minute,
                durationMinutes: _duration,
              ),
            );
        context.pop();
      },
      children: [
        const SizedBox(height: 14),
        _TimeSelects(
          hour: _hour,
          minute: _minute,
          onChanged: (h, m) => setState(() {
            _hour = h;
            _minute = m;
          }),
        ),
        if (!tournament) ...[
          Text('Lasts', style: OgText.body(15, weight: FontWeight.w700)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in const [60, 90, 120, 180])
                KitChip(
                  label: switch (m) {
                    60 => '1 hour',
                    90 => '1.5 hours',
                    120 => '2 hours',
                    _ => '3 hours',
                  },
                  selected: _duration == m,
                  onTap: () => setState(() => _duration = m),
                ),
            ],
          ),
          Text(
            '${Fmt.clock(_hour, _minute)} to '
            '${Fmt.clock((_hour * 60 + _minute + _duration) ~/ 60 % 24, (_minute + _duration) % 60)}. '
            'A Meet starts and ends on the same day.',
            style: OgText.body(14, color: context.og.textMuted),
          ),
        ],
      ],
    );
  }
}

/// Venue picker with search.
class PickVenueScreen extends ConsumerStatefulWidget {
  const PickVenueScreen({super.key, this.forClub = false});

  /// Sets the home venue of the club being created instead.
  final bool forClub;

  @override
  ConsumerState<PickVenueScreen> createState() => _PickVenueScreenState();
}

class _PickVenueScreenState extends ConsumerState<PickVenueScreen> {
  String _q = '';
  late Venue? _venue = widget.forClub
      ? null
      : ref.read(activityDraftControllerProvider).venue;
  late int _courts = ref.read(activityDraftControllerProvider).courts;

  @override
  Widget build(BuildContext context) {
    final c = context.og;
    final venues = ref.watch(venueSearchProvider(_q));
    return _Step(
      title: 'Venue',
      button: 'Done',
      onNext: _venue == null
          ? null
          : () {
              final v = _venue!;
              if (widget.forClub) {
                // The area is the last part of the address: "…, Tampines".
                ref
                    .read(clubDraftControllerProvider.notifier)
                    .edit(
                      (d) => d.copyWith(
                        venueId: v.id,
                        venueName: v.name,
                        area: v.address.split(',').last.trim(),
                      ),
                    );
              } else {
                ref
                    .read(activityDraftControllerProvider.notifier)
                    .edit((d) => d.copyWith(venue: v, courts: _courts));
              }
              context.pop();
            },
      children: [
        KitSearchField(
          hint: 'Search venues',
          onChanged: (v) => setState(() => _q = v),
        ),
        ...switch (venues) {
          AsyncData(:final value) when value.isEmpty => [
            Text(
              'Nothing matches. Check the spelling or clear the search.',
              style: OgText.body(15, color: c.textMuted),
            ),
          ],
          AsyncData(:final value) => [
            Column(
              children: [
                for (final v in value)
                  KitChoiceRow(
                    title: v.name,
                    subtitle: v.address,
                    tag: v.distance.isEmpty ? null : v.distance,
                    selected: v.id == _venue?.id,
                    onTap: () => setState(() => _venue = v),
                  ),
              ],
            ),
            if (!widget.forClub &&
                ref.read(activityDraftControllerProvider).kind !=
                    ActivityKind.event) ...[
              Text(
                'Courts to book',
                style: OgText.body(15, weight: FontWeight.w700),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var n = 1; n <= 6; n++)
                    KitChip(
                      label: '$n',
                      selected: _courts == n,
                      onTap: () => setState(() => _courts = n),
                    ),
                ],
              ),
              Text(
                'Court fees are set by the venue and paid to them. Split them '
                'across players in the fee you set.',
                style: OgText.body(13, height: 1.45, color: c.textMuted),
              ),
            ],
          ],
          AsyncError() => [const OgErrorText("Can't load venues. Try again.")],
          _ => [
            const Padding(
              padding: EdgeInsets.all(24),
              child: CupertinoActivityIndicator(),
            ),
          ],
        },
      ],
    );
  }
}
