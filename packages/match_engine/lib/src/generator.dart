import 'dart:math';

/// A player available for this session.
class RosterPlayer {
  const RosterPlayer(this.id, {this.skill = 4, this.gender});

  final String id;
  final double skill;

  /// 'm' or 'f'. Only mixed pairs read this.
  final String? gender;
}

/// One court in one round.
class Pairing {
  const Pairing(this.court, this.sideA, this.sideB);

  final int court;
  final List<String> sideA;
  final List<String> sideB;

  Iterable<String> get players => [...sideA, ...sideB];
}

class Round {
  const Round(this.number, this.matches, this.byes);

  final int number;
  final List<Pairing> matches;
  final List<String> byes;
}

/// Fixed teams, every team against every other, by the circle method. A bye
/// goes round when the number is odd. Rounds that need more courts than there
/// are spill into the next round, in order.
List<Round> circleRounds(List<String> teams, {required int courts}) {
  final list = [...teams, if (teams.length.isOdd) ''];
  final n = list.length;
  final rounds = <Round>[];
  for (var r = 0; r < n - 1; r++) {
    final games = <(String, String)>[];
    final byes = <String>[];
    for (var i = 0; i < n ~/ 2; i++) {
      final a = list[i], b = list[n - 1 - i];
      if (a.isEmpty || b.isEmpty) {
        byes.add(a.isEmpty ? b : a);
      } else {
        games.add((a, b));
      }
    }
    for (var start = 0; start < games.length; start += courts) {
      final part = games.skip(start).take(courts).toList();
      final playing = {
        for (final g in part) ...[g.$1, g.$2],
      };
      rounds.add(
        Round(
          rounds.length + 1,
          [
            for (final (i, g) in part.indexed) Pairing(i + 1, [g.$1], [g.$2]),
          ],
          [
            ...byes,
            if (start > 0 || start + courts < games.length)
              for (final g in games)
                for (final t in [g.$1, g.$2])
                  if (!playing.contains(t)) t,
          ],
        ),
      );
    }
    list.insert(1, list.removeLast());
  }
  return rounds;
}

/// Americano: new partners and opponents each round, with the fewest possible
/// byes and sides as even as the roster allows. Pass [mixed] to pair one man
/// and one woman on every side. The same [seed] gives the same draw.
class Americano {
  Americano({
    required this.roster,
    required this.courts,
    required this.seed,
    this.mixed = false,
  });

  final List<RosterPlayer> roster;
  final int courts;
  final int seed;
  final bool mixed;

  /// Rounds already played, so regenerating keeps counts fair when someone
  /// arrives late or leaves early.
  final _partners = <(String, String), int>{};
  final _opponents = <(String, String), int>{};
  final _sitOuts = <String, int>{};

  static (String, String) _key(String a, String b) =>
      a.compareTo(b) < 0 ? (a, b) : (b, a);

  /// Counts a round that has been played.
  void record(Round round) {
    for (final m in round.matches) {
      for (final side in [m.sideA, m.sideB]) {
        if (side.length == 2) {
          _partners.update(
            _key(side[0], side[1]),
            (v) => v + 1,
            ifAbsent: () => 1,
          );
        }
      }
      for (final a in m.sideA) {
        for (final b in m.sideB) {
          _opponents.update(_key(a, b), (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
    for (final b in round.byes) {
      _sitOuts.update(b, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  /// Rounds [from] onward for the roster as it is now. Earlier rounds stand.
  List<Round> rounds(int count, {int from = 1, List<RosterPlayer>? active}) {
    final out = <Round>[];
    for (var i = 0; i < count; i++) {
      final round = _next(from + i, active ?? roster);
      record(round);
      out.add(round);
    }
    return out;
  }

  Round _next(int number, List<RosterPlayer> players) {
    final random = Random(seed * 31 + number);
    final shuffled = [...players]..shuffle(random);
    // Whoever has sat out most plays first.
    shuffled.sort(
      (a, b) => (_sitOuts[b.id] ?? 0).compareTo(_sitOuts[a.id] ?? 0),
    );

    final (men, women) = (
      shuffled.where((p) => p.gender == 'm').toList(),
      shuffled.where((p) => p.gender == 'f').toList(),
    );
    final games = mixed
        ? min(courts, min(men.length, women.length) ~/ 2)
        : min(courts, players.length ~/ 4);
    final playing = mixed
        ? [...men.take(games * 2), ...women.take(games * 2)]
        : shuffled.take(games * 4).toList();

    final pairs = mixed ? _mixedPairs(men, women, games) : _pairs(playing);
    pairs.sort((a, b) => _skill(b).compareTo(_skill(a)));
    final matches = <Pairing>[];
    final remaining = [...pairs];
    for (var court = 1; court <= games; court++) {
      final first = remaining.removeAt(0);
      remaining.sort(
        (a, b) =>
            _opponentRepeats(first, a).compareTo(_opponentRepeats(first, b)),
      );
      final second = remaining.removeAt(0);
      matches.add(Pairing(court, first, second));
    }
    final used = {for (final m in matches) ...m.players};
    return Round(number, matches, [
      for (final p in players)
        if (!used.contains(p.id)) p.id,
    ]);
  }

  double _skill(List<String> pair) => pair.fold(
    0.0,
    (t, id) =>
        t +
        roster
            .firstWhere((p) => p.id == id, orElse: () => RosterPlayer(id))
            .skill,
  );

  int _opponentRepeats(List<String> a, List<String> b) {
    var n = 0;
    for (final x in a) {
      for (final y in b) {
        n += _opponents[_key(x, y)] ?? 0;
      }
    }
    return n;
  }

  /// Strongest with weakest, so sides come out even, moving a partner along
  /// when they would repeat.
  List<List<String>> _pairs(List<RosterPlayer> players) {
    final left = [...players]..sort((a, b) => b.skill.compareTo(a.skill));
    final pairs = <List<String>>[];
    while (left.length >= 2) {
      final top = left.removeAt(0);
      var best = left.length - 1;
      var bestCount = _partners[_key(top.id, left[best].id)] ?? 0;
      for (var i = left.length - 1; i >= 0 && bestCount > 0; i--) {
        final count = _partners[_key(top.id, left[i].id)] ?? 0;
        if (count < bestCount) {
          best = i;
          bestCount = count;
        }
      }
      pairs.add([top.id, left.removeAt(best).id]);
    }
    return pairs;
  }

  List<List<String>> _mixedPairs(
    List<RosterPlayer> men,
    List<RosterPlayer> women,
    int games,
  ) {
    final ws = women.take(games * 2).toList();
    return [
      for (final m in men.take(games * 2))
        () {
          var best = 0;
          for (var i = 1; i < ws.length; i++) {
            if ((_partners[_key(m.id, ws[i].id)] ?? 0) <
                (_partners[_key(m.id, ws[best].id)] ?? 0)) {
              best = i;
            }
          }
          return [m.id, ws.removeAt(best).id];
        }(),
    ];
  }
}
