import '../../../core/format.dart';
import 'tournament_models.dart';

/// "Final", "Semi-finals", "Quarter-finals", "Round of 16" for a knockout
/// round of [matches] matches.
String koRoundName(int matches, {bool single = false}) => switch (matches) {
  1 => 'Final',
  2 => single ? 'Semi-final' : 'Semi-finals',
  4 => single ? 'Quarter-final' : 'Quarter-finals',
  _ => 'Round of ${matches * 2}',
};

/// "SF", "QF", "R16", for "SF1 winner".
String _koShort(int matches) => switch (matches) {
  1 => 'F',
  2 => 'SF',
  4 => 'QF',
  _ => 'R${matches * 2}',
};

Map<int, int> koRoundSizes(Iterable<DrawMatch> ms) {
  final sizes = <int, int>{};
  for (final m in ms.where((m) => m.stage == DrawStage.knockout)) {
    sizes[m.round] = (sizes[m.round] ?? 0) + 1;
  }
  return sizes;
}

/// The stage as a player reads it: "Group B", "Semi-final", "3rd place".
String drawStageName(DrawMatch m, Map<int, int> sizes) => switch (m.stage) {
  DrawStage.group => m.group ?? 'Group',
  DrawStage.third => '3rd place',
  DrawStage.knockout => koRoundName(sizes[m.round] ?? 1, single: true),
};

/// A side's name, or where it comes from while it isn't known yet.
String drawSideName(DrawMatch m, {required bool sideA, Map<int, int>? sizes}) {
  final name = sideA ? m.a : m.b;
  if (name != null) return name;
  final src = sideA ? m.srcA : m.srcB;
  if (src == 'bye') return 'Bye';
  if (src != null && src.length >= 2) {
    return '$src · ${src.endsWith('1') ? 'winner' : 'runner-up'}';
  }
  final s = sizes ?? const {};
  if (m.stage == DrawStage.third) {
    return 'SF${sideA ? 1 : 2} loser';
  }
  if (m.stage == DrawStage.knockout && m.round > 1) {
    final prev = s[m.round - 1] ?? (s[m.round] ?? 1) * 2;
    return '${_koShort(prev)}${m.slot * 2 + (sideA ? 1 : 2)} winner';
  }
  return 'To be decided';
}

/// "21–17, 21–19", from side A, or from the viewer's side when [flip].
String gamesText(List<(int, int)> games, {bool flip = false}) =>
    [for (final g in games) flip ? '${g.$2}–${g.$1}' : '${g.$1}–${g.$2}']
        .join(', ');

String _when(DrawMatch m) {
  if (m.at == null) return m.bye ? 'Bye' : 'Time to be set';
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final at = m.at!.toLocal();
  return '${days[at.weekday - 1]} ${Fmt.time(at)}'
      '${m.court == null ? '' : ' · Court ${m.court}'}';
}

/// The knockout bracket, first round to the final, then the 3rd place
/// match.
List<KnockoutRound> knockoutRounds(List<DrawMatch> ms) {
  final sizes = koRoundSizes(ms);
  final rounds = sizes.keys.toList()..sort();
  KnockoutMatch card(DrawMatch m) => KnockoutMatch(
    drawSideName(m, sideA: true, sizes: sizes),
    drawSideName(m, sideA: false, sizes: sizes),
    _when(m),
    scoreA: m.done && m.games.isNotEmpty ? m.gamesA : null,
    scoreB: m.done && m.games.isNotEmpty ? m.gamesB : null,
  );
  return [
    for (final r in rounds)
      KnockoutRound(koRoundName(sizes[r]!), [
        for (final m
            in ms
                .where((m) => m.stage == DrawStage.knockout && m.round == r)
                .toList()
              ..sort((x, y) => x.slot.compareTo(y.slot)))
          card(m),
      ]),
    for (final m in ms.where((m) => m.stage == DrawStage.third))
      KnockoutRound('3rd place', [card(m)]),
  ];
}

/// The viewer's matches, in time order. The first one not played is next,
/// unless the organizer has called it to court.
List<MyMatch> myMatchesFrom(List<DrawMatch> ms) {
  final mine = ms.where((m) => m.mine && !m.bye && m.at != null).toList()
    ..sort((x, y) => x.at!.compareTo(y.at!));
  final sizes = koRoundSizes(ms);
  var nextGiven = false;
  return [
    for (final m in mine)
      () {
        final meA = m.mineA!;
        final state = switch (m.state) {
          DrawMatchState.done => MatchState.done,
          DrawMatchState.called => MatchState.called,
          DrawMatchState.waiting when !nextGiven && m.ready => MatchState.next,
          _ => MatchState.later,
        };
        if (state == MatchState.called || state == MatchState.next) {
          nextGiven = true;
        }
        return MyMatch(
          opponent: drawSideName(m, sideA: !meA, sizes: sizes),
          at: m.at!.toLocal(),
          court: m.court == null ? 'Court to be set' : 'Court ${m.court}',
          state: state,
          stage: drawStageName(m, sizes),
          score: !m.done
              ? null
              : m.walkover
              ? 'Walkover'
              : gamesText(m.games, flip: !meA),
          won: m.done && m.winnerA != null ? m.winnerA == meA : null,
        );
      }(),
  ];
}

/// How the viewer's event went, once every match in it is played.
/// [table] is the group standings, best first, for round robins.
TournamentResult? resultFrom({
  required String division,
  required List<DrawMatch> ms,
  required int entries,
  List<DrawGroup> table = const [],
}) {
  if (ms.isEmpty || ms.any((m) => !m.done)) return null;
  final sizes = koRoundSizes(ms);
  final ko = ms.where((m) => m.stage == DrawStage.knockout).toList();
  final mine = ms.where((m) => m.mine && !m.bye).toList()
    ..sort((x, y) => (x.at ?? DateTime(0)).compareTo(y.at ?? DateTime(0)));
  final wins = mine.where((m) => m.winnerA == m.mineA).length;
  final losses = mine.where((m) => m.winnerA != null && m.winnerA != m.mineA);

  String? winnerOf(DrawMatch? m) =>
      m == null || m.winnerA == null ? null : (m.winnerA! ? m.a : m.b);
  String? loserOf(DrawMatch? m) =>
      m == null || m.winnerA == null ? null : (m.winnerA! ? m.b : m.a);

  final podium = <String>[];
  int place;
  if (ko.isNotEmpty) {
    final last = sizes.keys.reduce((a, b) => a > b ? a : b);
    final finalMatch = ko.where((m) => m.round == last).firstOrNull;
    final third = ms.where((m) => m.stage == DrawStage.third).firstOrNull;
    podium.addAll([
      ?winnerOf(finalMatch),
      ?loserOf(finalMatch),
      ?winnerOf(third),
    ]);
    // Where the viewer went out decides their place.
    final out = mine
        .where((m) => m.stage != DrawStage.group && m.winnerA != m.mineA)
        .lastOrNull;
    final won = mine.where((m) => m.winnerA == m.mineA);
    if (finalMatch != null && finalMatch.mine) {
      place = finalMatch.winnerA == finalMatch.mineA ? 1 : 2;
    } else if (third != null && third.mine) {
      place = third.winnerA == third.mineA ? 3 : 4;
    } else if (out != null) {
      place = (sizes[out.round] ?? 1) + 1;
    } else if (won.any((m) => m.stage == DrawStage.knockout)) {
      place = 3;
    } else {
      // Didn't get out of the group.
      place = (sizes[1] ?? 1) * 2 + 1;
    }
  } else {
    final rows = [for (final g in table) ...g.rows];
    podium.addAll(rows.take(3).map((r) => r.names));
    place = rows.where((r) => r.mine).firstOrNull?.pos ?? rows.length;
  }

  while (podium.length < 3) {
    podium.add('–');
  }
  return TournamentResult(
    division: division,
    place: place,
    wins: wins,
    losses: losses.length,
    podium: podium,
    entries: entries,
    matches: myMatchesFrom(mine),
  );
}
