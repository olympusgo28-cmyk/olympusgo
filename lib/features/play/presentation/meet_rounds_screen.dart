import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:match_engine/match_engine.dart';

import '../../../core/providers.dart';
import '../../../core/theme/og_type.dart';
import '../../../core/widgets/og_kit.dart';
import '../../../core/widgets/og_rows.dart';
import '../../../core/widgets/og_toast.dart';
import '../../auth/data/auth_repository.dart';
import '../application/play_providers.dart';
import '../domain/activity.dart';
import '../domain/meet_ops.dart';
import 'meet_action_screens.dart';

/// Who plays who on each court. The organizer generates rounds and regenerates
/// the rest when someone arrives late or leaves early. Everyone can read them.
class MeetRoundsScreen extends ConsumerStatefulWidget {
  const MeetRoundsScreen({super.key, required this.activityId});

  final String activityId;

  @override
  ConsumerState<MeetRoundsScreen> createState() => _MeetRoundsScreenState();
}

class _MeetRoundsScreenState extends ConsumerState<MeetRoundsScreen> {
  final _away = <String>{};
  int _style = 0;
  int _courts = 2;
  int _count = 6;
  int? _from;
  bool _busy = false;

  Future<void> _generate(
    Activity a,
    List<MeetPlayer> players,
    List<Round> saved,
    int from,
  ) async {
    final singles = a.gameType == GameType.singles;
    final active = [
      for (final p in players)
        if (!_away.contains(p.player.id))
          RosterPlayer(p.player.id, skill: p.rating ?? 4),
    ];
    final List<Round> rounds;
    if (_style == 0 && !singles) {
      final engine = Americano(
        roster: active,
        courts: _courts,
        seed: a.id.codeUnits.fold(from, (h, c) => h * 31 + c),
      );
      for (final r in saved) {
        if (r.number < from) engine.record(r);
      }
      rounds = engine.rounds(_count, from: from);
    } else {
      // With an odd number of pairs' worth of players, the last one sits out.
      final spare = !singles && active.length.isOdd
          ? [active.last.id]
          : <String>[];
      final teams = singles
          ? [for (final p in active) p.id]
          : [
              for (var i = 0; i + 1 < active.length; i += 2)
                '${active[i].id}+${active[i + 1].id}',
            ];
      rounds = [
        for (final r in circleRounds(teams, courts: _courts))
          Round(
            r.number + from - 1,
            [
              for (final m in r.matches)
                Pairing(
                  m.court,
                  m.sideA.expand((t) => t.split('+')).toList(),
                  m.sideB.expand((t) => t.split('+')).toList(),
                ),
            ],
            [...r.byes.expand((t) => t.split('+')), ...spare],
          ),
      ];
    }
    if (rounds.every((r) => r.matches.isEmpty)) {
      showOgToast(context, 'Not enough players for a match.', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(playRepositoryProvider).saveRounds(a.id, from, rounds);
      ref.invalidate(meetRoundsProvider(a.id));
      if (mounted) showOgToast(context, 'Rounds saved');
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickPreset(String activity, String preset) async {
    try {
      await ref.read(playRepositoryProvider).setPreset(activity, preset);
      ref.invalidate(activityScoringProvider(activity));
    } on AuthFailure catch (e) {
      if (mounted) showOgToast(context, e.message, error: true);
    }
  }

  @override
  Widget build(BuildContext context) => WithActivity(
    id: widget.activityId,
    title: 'Match rounds',
    body: (a) {
      final players = (ref.watch(meetPlayersProvider(a.id)).value ?? const [])
          .where(
            (p) =>
                p.waitlistAt == null &&
                !p.isGuest &&
                p.attendance != Attendance.absent,
          )
          .toList();
      final state = ref.watch(meetRoundsProvider(a.id));
      final saved = state.value ?? const <Round>[];
      final names = {
        for (final p in players) p.player.id: p.player.displayName,
      };
      String side(List<String> ids) =>
          ids.map((id) => names[id] ?? 'Player').join(' and ');
      final from = (_from ?? saved.length + 1).clamp(1, saved.length + 1);
      final needed = a.gameType == GameType.singles ? 2 : 4;
      final sport = a.sports.firstOrNull?.id;
      final presets = sport == null
          ? const <(String, String, ScoringPreset)>[]
          : ref.watch(scoringPresetsProvider(sport)).value ?? const [];
      final rules = ref.watch(activityScoringProvider(a.id)).value;
      final picked = presets.indexWhere(
        (p) => p.$3.pointsToWin == rules?.pointsToWin && p.$3.cap == rules?.cap,
      );
      final enough =
          players.where((p) => !_away.contains(p.player.id)).length >= needed;

      return KitScaffold(
        header: const KitHeader(title: 'Match rounds'),
        bottom: [
          if (a.iAmHost)
            KitButton(
              label: saved.isEmpty
                  ? 'Generate rounds'
                  : from > saved.length
                  ? 'Add rounds'
                  : 'Regenerate from round $from',
              loading: _busy,
              onPressed: enough
                  ? () => _generate(a, players, saved, from)
                  : null,
            ),
        ],
        children: [
          if (a.iAmHost) ...[
            if (presets.length > 1) ...[
              const KitSection('Scoring'),
              KitSegments(
                labels: [for (final p in presets) p.$2],
                selected: picked < 0 ? 0 : picked,
                onSelect: (i) => _pickPreset(a.id, presets[i].$1),
              ),
            ],
            const KitSection('Rounds'),
            // Singles has no partners to rotate: everyone plays everyone.
            if (a.gameType != GameType.singles)
              KitSegments(
                labels: const ['Rotating partners', 'Fixed teams'],
                selected: _style,
                onSelect: (i) => setState(() => _style = i),
              ),
            _Count(
              label: 'Courts',
              value: _courts,
              min: 1,
              onChange: (v) => setState(() => _courts = v),
            ),
            if (_style == 0 && a.gameType != GameType.singles)
              _Count(
                label: 'Rounds',
                value: _count,
                min: 1,
                onChange: (v) => setState(() => _count = v),
              ),
            if (saved.isNotEmpty)
              _Count(
                label: 'Change from round',
                value: from,
                min: 1,
                max: saved.length + 1,
                onChange: (v) => setState(() => _from = v),
              ),
            const KitSection('Who is here'),
            RowGroup(
              dividers: true,
              children: [
                for (final p in players)
                  SwitchRow(
                    title: p.player.displayName,
                    subtitle: p.band ?? 'Playing today',
                    value: !_away.contains(p.player.id),
                    onChanged: (v) => setState(
                      () => v
                          ? _away.remove(p.player.id)
                          : _away.add(p.player.id),
                    ),
                  ),
              ],
            ),
            if (!enough) KitNote('You need at least $needed players here.'),
          ],
          if (state.isLoading && saved.isEmpty)
            const CupertinoActivityIndicator()
          else if (state.hasError)
            const KitNote(
              "Can't load the rounds right now.",
              tone: KitTone.warn,
            )
          else if (saved.isEmpty)
            Text(
              a.iAmHost
                  ? 'No rounds yet.'
                  : 'The organizer has not set the rounds yet.',
              style: context.type.secondary,
            ),
          for (final r in saved) ...[
            KitSection('Round ${r.number}'),
            KitCard(
              padding: const EdgeInsets.all(16),
              children: [
                for (final m in r.matches) ...[
                  Text('Court ${m.court}', style: context.type.caption),
                  Text(
                    '${side(m.sideA)} vs ${side(m.sideB)}',
                    style: context.type.body,
                  ),
                  const SizedBox(height: 8),
                ],
                if (r.byes.isNotEmpty)
                  Text(
                    'Sitting out: ${side(r.byes)}',
                    style: context.type.caption,
                  ),
              ],
            ),
          ],
        ],
      );
    },
  );
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.value,
    required this.onChange,
    this.min = 1,
    this.max = 20,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: context.type.body)),
      KitQty(
        value: value,
        label: label,
        onLess: value > min ? () => onChange(value - 1) : null,
        onMore: value < max ? () => onChange(value + 1) : null,
      ),
    ],
  );
}
