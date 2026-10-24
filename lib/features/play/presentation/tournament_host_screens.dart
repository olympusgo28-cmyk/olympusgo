import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/og_colors.dart';
import '../../../core/theme/og_text.dart';
import '../../../core/theme/og_tones.dart';
import '../../../core/widgets/og_icon.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/competition_providers.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import '../domain/tournament_models.dart';
import 'tournament_screens.dart' show tournamentDates;
import 'create_meet_screens.dart' show editActivity;

/// Loads the tournament, then builds [body].
class _WithTournament extends ConsumerWidget {
  const _WithTournament({
    required this.id,
    required this.title,
    required this.body,
  });

  final String id;
  final String title;
  final Widget Function(TournamentInfo t) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(tournamentInfoProvider(id))) {
        AsyncData(:final value) => body(value),
        AsyncError() => KitScaffold(
          header: KitHeader(title: title),
          children: const [KitNote("This isn't available any more.")],
        ),
        _ => KitScaffold(
          header: KitHeader(title: title),
          children: const [CupertinoActivityIndicator()],
        ),
      };
}

/// The organizer's tools for one tournament.
class TournamentManageScreen extends ConsumerWidget {
  const TournamentManageScreen({super.key, required this.activityId});

  final String activityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _WithTournament(
    id: activityId,
    title: 'Manage tournament',
    body: (t) {
      final a = t.activity;
      final open =
          a.registrationClosesAt == null ||
          DateTime.now().isBefore(a.registrationClosesAt!);
      Widget tile(
        String icon,
        String title,
        String sub,
        VoidCallback onTap, {
        bool danger = false,
      }) => KitNavTile(
        icon: icon,
        title: title,
        subtitle: sub,
        danger: danger,
        onTap: onTap,
      );
      return KitScaffold(
        header: const KitHeader(title: 'Manage tournament'),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              KitTag(
                'Organizer',
                background: context.tones.gold,
                foreground: context.tones.onGold,
              ),
              const SizedBox(height: 8),
              Text(a.title, style: OgText.heading(26)),
              const SizedBox(height: 4),
              Text(
                '${tournamentDates(a)} · ${t.entries} entries · registration '
                '${open ? 'open' : 'closed'}',
                style: OgText.body(14, color: context.og.textMuted),
              ),
            ],
          ),
          KitCard(
            children: [
              tile(
                OgIcons.pencil,
                'Edit details',
                'Dates, venue, tier, events and fees',
                () => editActivity(context, ref, a),
              ),
              tile(
                OgIcons.rosterCard,
                'Entries',
                '${t.entries} entries across ${t.divisions.length} ${t.divisions.length == 1 ? 'event' : 'events'}',
                () => context.push(Routes.tournamentEntries(a.id)),
              ),
              tile(
                OgIcons.personTick,
                'Check players in',
                '${t.checkedIn} of ${t.entries} here',
                () => context.push(Routes.tournamentCheckIn(a.id)),
              ),
              tile(
                OgIcons.trophyCup,
                'Draw and results',
                'Groups and knockout',
                () => context.push(Routes.tournamentTab(a.id, 'draw')),
              ),
              tile(
                OgIcons.megaphone,
                'Message entrants',
                'Schedule changes and reminders',
                () => context.push(Routes.tournamentMessage(a.id)),
              ),
              if (t.spectatorEventId != null)
                tile(
                  OgIcons.ticket,
                  'Spectator event',
                  '${t.spectatorTitle} page and tickets',
                  () => context.push(Routes.activity(t.spectatorEventId!)),
                ),
              tile(
                OgIcons.warning,
                'Cancel tournament',
                'Refund every entry',
                () => context.push(Routes.tournamentCancel(a.id)),
                danger: true,
              ),
            ],
          ),
          const KitNote(
            'Changes to dates, venue or fees are sent to every entrant. '
            'Entrants can withdraw for a full refund within 48 hours of a '
            'change.',
          ),
        ],
      );
    },
  );
}

/// Division chips as a horizontal row.
class _DivisionChips extends StatelessWidget {
  const _DivisionChips({
    required this.divisions,
    required this.selected,
    required this.onSelect,
  });

  final List<Division> divisions;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (final d in divisions) ...[
          KitChip(
            label: d.name,
            selected: d.id == selected,
            onTap: () => onSelect(d.id),
          ),
          const SizedBox(width: 8),
        ],
      ],
    ),
  );
}

/// Who entered each division, by seed.
class TournamentEntriesScreen extends ConsumerStatefulWidget {
  const TournamentEntriesScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<TournamentEntriesScreen> createState() =>
      _TournamentEntriesScreenState();
}

class _TournamentEntriesScreenState
    extends ConsumerState<TournamentEntriesScreen> {
  String? _division;

  @override
  Widget build(BuildContext context) => _WithTournament(
    id: widget.activityId,
    title: 'Entries',
    body: (t) {
      final c = context.og;
      final tones = context.tones;
      final d = t.divisions.firstWhere(
        (d) => d.id == _division,
        orElse: () => t.divisions.first,
      );
      final list = ref
          .watch(tournamentEntriesProvider(t.activity.id, d.id))
          .value;
      return KitScaffold(
        header: const KitHeader(title: 'Entries'),
        bottom: t.activity.iAmHost
            ? [
                KitButton(
                  label: 'Check players in',
                  onPressed: () =>
                      context.push(Routes.tournamentCheckIn(t.activity.id)),
                ),
                KitButton(
                  label: 'Message entrants',
                  style: KitButtonStyle.outline,
                  onPressed: () =>
                      context.push(Routes.tournamentMessage(t.activity.id)),
                ),
              ]
            : null,
        children: [
          if (t.divisions.length > 1)
            _DivisionChips(
              divisions: t.divisions,
              selected: d.id,
              onSelect: (id) => setState(() => _division = id),
            ),
          Text(
            '${d.entries} of ${d.capacity} entries'
            '${d.waiting > 0 ? ', ${d.waiting} waiting' : ''}',
            style: OgText.heading(22),
          ),
          if (list == null)
            const CupertinoActivityIndicator()
          else if (list.isEmpty)
            const KitNote('No entries yet.')
          else
            KitCard(
              children: [
                for (final e in list)
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
                            e.seed == null ? '' : '${e.seed}',
                            style: OgText.heading(17),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.names,
                                style: OgText.body(15, weight: FontWeight.w700),
                              ),
                              Text(
                                [
                                  ?e.club,
                                  if (e.rating != null)
                                    'rating ${e.rating!.toStringAsFixed(1)}',
                                ].join(', '),
                                style: OgText.body(13, color: c.textMuted),
                              ),
                            ],
                          ),
                        ),
                        KitTag(
                          switch (e.status) {
                            EntryStatus.paid => 'Paid',
                            EntryStatus.waitlist => 'Waitlist',
                            EntryStatus.partnerPending => 'Partner pending',
                          },
                          background: e.status == EntryStatus.paid
                              ? tones.successFill
                              : tones.tag,
                          foreground: e.status == EntryStatus.paid
                              ? tones.onSuccessFill
                              : tones.onTag,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          Text(
            'Seeding follows each player’s main rating.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      );
    },
  );
}

/// Mark who is here before their first match.
class TournamentCheckInScreen extends ConsumerStatefulWidget {
  const TournamentCheckInScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<TournamentCheckInScreen> createState() =>
      _TournamentCheckInScreenState();
}

class _TournamentCheckInScreenState
    extends ConsumerState<TournamentCheckInScreen> {
  String? _division;
  final _here = <String, bool>{};

  Future<void> _set(String id, Entry e, bool here) async {
    setState(() => _here[e.id] = here);
    HapticFeedback.selectionClick();
    try {
      await ref.read(tournamentRepositoryProvider).setCheckedIn(id, e.id, here);
      ref.invalidate(tournamentInfoProvider(id));
    } on AuthFailure catch (err) {
      if (!mounted) return;
      setState(() => _here.remove(e.id));
      showOgToast(context, err.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTournament(
    id: widget.activityId,
    title: 'Check-in',
    body: (t) {
      final c = context.og;
      final tones = context.tones;
      final d = t.divisions.firstWhere(
        (d) => d.id == _division,
        orElse: () => t.divisions.first,
      );
      final list =
          ref.watch(tournamentEntriesProvider(t.activity.id, d.id)).value ??
          const <Entry>[];
      final entries = list.where((e) => e.status == EntryStatus.paid).toList();
      bool here(Entry e) => _here[e.id] ?? e.checkedIn;
      final count = entries.where(here).length;
      final unit = d.doubles ? 'pairs' : 'players';
      return KitScaffold(
        header: KitHeader(title: 'Check-in', subtitle: t.activity.title),
        bottom: [
          KitButton(
            label: 'Scan a player’s code',
            icon: OgIcons.scan,
            style: KitButtonStyle.outline,
            onPressed: () => context.go(Routes.scan),
          ),
        ],
        children: [
          if (t.divisions.length > 1)
            _DivisionChips(
              divisions: t.divisions,
              selected: d.id,
              onSelect: (id) => setState(() => _division = id),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$count', style: OgText.heading(44)),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'of ${entries.length} $unit here',
                  style: OgText.body(15, weight: FontWeight.w700),
                ),
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: entries.isEmpty ? 0 : count / entries.length,
              minHeight: 10,
              backgroundColor: tones.tag,
              color: const Color(0xFFC6FF00),
            ),
          ),
          KitCard(
            children: [
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      SolidAvatar.forId(
                        e.id,
                        initials: e.names
                            .split(' and ')
                            .map((n) => n.isEmpty ? '' : n[0])
                            .take(2)
                            .join(),
                        size: 44,
                        fontSize: 14,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.names,
                              style: OgText.body(15, weight: FontWeight.w700),
                            ),
                            if (e.firstMatch != null)
                              Text(
                                e.firstMatch!,
                                style: OgText.body(13, color: c.textMuted),
                              ),
                          ],
                        ),
                      ),
                      here(e)
                          ? KitButton(
                              label: 'Here',
                              icon: OgIcons.tick,
                              expand: false,
                              height: 40,
                              radius: 20,
                              fontSize: 14,
                              padding: 14,
                              style: KitButtonStyle.dark,
                              onPressed: () => _set(t.activity.id, e, false),
                            )
                          : KitButton(
                              label: 'Check in',
                              expand: false,
                              height: 40,
                              radius: 20,
                              fontSize: 14,
                              padding: 14,
                              style: KitButtonStyle.outline,
                              onPressed: () => _set(t.activity.id, e, true),
                            ),
                    ],
                  ),
                ),
            ],
          ),
          Text(
            '${d.doubles ? 'Pairs' : 'Players'} who are not here 10 minutes '
            'before their first match get a reminder. Tap Here to undo a '
            'check-in.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      );
    },
  );
}

/// A notification to entrants: who gets it, a template or your own words.
class TournamentMessageScreen extends ConsumerStatefulWidget {
  const TournamentMessageScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<TournamentMessageScreen> createState() =>
      _TournamentMessageScreenState();
}

class _TournamentMessageScreenState
    extends ConsumerState<TournamentMessageScreen> {
  static const _templates = [
    (
      'Check-in reminder',
      'Check in at the desk 30 minutes before your first match.',
    ),
    (
      'Running late',
      'Matches are running about 20 minutes behind. Watch the draw for your '
          'court.',
    ),
    (
      'Court change',
      'Your court has changed. Open the draw to see the new one.',
    ),
    ('Write my own', 'Type a message below'),
  ];

  int _to = 0;
  int _template = 0;
  final _text = TextEditingController(text: _templates.first.$2);
  bool _busy = false;
  int? _sent;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send(TournamentInfo t, String to) async {
    setState(() => _busy = true);
    try {
      final n = await ref
          .read(tournamentRepositoryProvider)
          .message(t.activity.id, to: to, text: _text.text);
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _sent = n);
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTournament(
    id: widget.activityId,
    title: 'Message entrants',
    body: (t) {
      final c = context.og;
      final audiences = [
        'All ${t.entries} entrants',
        if (t.divisions.length > 1) '${t.divisions.first.name} only',
        'Not checked in yet',
      ];
      if (_sent != null) {
        return KitScaffold(
          header: const KitHeader(title: 'Message entrants'),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
          bottom: [
            KitButton(label: 'Back to manage', onPressed: () => context.pop()),
          ],
          children: [
            const KitDoneBanner(title: 'Sent'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  KitKeyValue('To', audiences[_to]),
                  const SizedBox(height: 8),
                  Text(
                    _text.text.trim(),
                    style: OgText.body(15, height: 1.45, color: c.textMuted),
                  ),
                ],
              ),
            ),
          ],
        );
      }
      return KitScaffold(
        header: const KitHeader(title: 'Message entrants'),
        bottom: [
          KitButton(
            label: 'Send message',
            loading: _busy,
            onPressed: () => _send(t, audiences[_to]),
          ),
        ],
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Who gets it', style: OgText.heading(20)),
              const SizedBox(height: 6),
              for (final (i, label) in audiences.indexed)
                KitChoiceRow(
                  title: label,
                  selected: _to == i,
                  onTap: () => setState(() => _to = i),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Message', style: OgText.heading(20)),
              const SizedBox(height: 6),
              for (final (i, (name, sub)) in _templates.indexed)
                KitChoiceRow(
                  title: name,
                  subtitle: sub,
                  selected: _template == i,
                  onTap: () => setState(() {
                    _template = i;
                    _text.text = i == _templates.length - 1 ? '' : sub;
                  }),
                ),
            ],
          ),
          KitTextArea(label: 'Your message', controller: _text, lines: 4),
          Text(
            'Sent as a notification from ${t.activity.title}. Players cannot '
            'reply to it.',
            style: OgText.body(13, height: 1.45, color: c.textMuted),
          ),
        ],
      );
    },
  );
}

/// Cancel the tournament and refund every entry.
class TournamentCancelScreen extends ConsumerStatefulWidget {
  const TournamentCancelScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<TournamentCancelScreen> createState() =>
      _TournamentCancelScreenState();
}

class _TournamentCancelScreenState
    extends ConsumerState<TournamentCancelScreen> {
  final _message = TextEditingController();
  bool _understood = false;
  bool _busy = false;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _cancel(Activity a) async {
    setState(() => _busy = true);
    try {
      await ref
          .read(tournamentRepositoryProvider)
          .cancel(a.id, message: _message.text.trim());
      HapticFeedback.mediumImpact();
      refreshCompetition(ref.invalidate);
      refreshPlay(ref.invalidate);
      if (!mounted) return;
      showOgToast(context, 'Tournament cancelled. Every entry is refunded.');
      context.go(Routes.schedule(hosting: true));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _WithTournament(
    id: widget.activityId,
    title: 'Cancel tournament',
    body: (t) {
      final c = context.og;
      final a = t.activity;
      final entryCents = t.divisions.fold(
        0,
        (s, d) => s + d.entries * d.feeCents,
      );
      final feeCents = t.divisions.fold(
        0,
        (s, d) => s + d.entries * platformFee(d.feeCents),
      );
      return KitScaffold(
        header: const KitHeader(title: 'Cancel tournament'),
        bottom: [
          KitButton(
            label: 'Cancel tournament',
            style: KitButtonStyle.danger,
            loading: _busy,
            onPressed: _understood ? () => _cancel(a) : null,
          ),
          KitButton(
            label: 'Keep tournament',
            style: KitButtonStyle.outline,
            onPressed: () => context.pop(),
          ),
        ],
        children: [
          KitTitle(
            'Cancel ${a.title}?',
            size: 26,
            lead: '${tournamentDates(a)} · ${t.entries} entries',
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Refunds', style: OgText.heading(20)),
              const SizedBox(height: 4),
              KitKeyValue('Entries refunded', '${t.entries}'),
              KitKeyValue('Entry fees', 'S\$${money(entryCents)}'),
              KitKeyValue(
                'Platform fees',
                'S\$${money(feeCents)}, refunded too',
              ),
              const KitKeyValue('Back to players in', '3 to 5 working days'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Also cancelled', style: OgText.heading(20)),
              const SizedBox(height: 8),
              KitCheckList([
                'The draw and all scheduled matches',
                if (t.spectatorTitle != null)
                  '${t.spectatorTitle} spectator event and its tickets',
                'Court bookings at ${a.venue.name}, by the venue’s own '
                    'cancellation rules',
              ]),
            ],
          ),
          KitTextArea(
            label: 'Message to entrants',
            optional: true,
            controller: _message,
            hint:
                'We are sorry to cancel this year’s tournament. Full refunds '
                'are on the way.',
          ),
          KitConfirmBox(
            label: 'I understand all ${t.entries} entries are refunded',
            checked: _understood,
            onChanged: (v) => setState(() => _understood = v),
          ),
          Text(
            'Entrants are told straight away.',
            style: OgText.body(13, color: c.textMuted),
          ),
        ],
      );
    },
  );
}
