import 'package:flutter_test/flutter_test.dart';
import 'package:match_engine/match_engine.dart';

/// What the generator hands the rounds screen for a real Meet size.
void main() {
  test('P3-02 eight players on two courts: nobody plays twice in a round', () {
    final roster = [
      for (var i = 0; i < 8; i++) RosterPlayer('p$i', skill: 3 + i / 4),
    ];
    final rounds = Americano(roster: roster, courts: 2, seed: 7).rounds(6);
    expect(rounds, hasLength(6));
    for (final r in rounds) {
      final seen = r.matches.expand((m) => m.players).toList();
      expect(seen.toSet(), hasLength(seen.length));
      expect(r.matches.length, lessThanOrEqualTo(2));
    }
  });

  test('P3-02 a late arrival joins the rounds that remain', () {
    final roster = [for (var i = 0; i < 8; i++) RosterPlayer('p$i')];
    final engine = Americano(roster: roster, courts: 2, seed: 7);
    final first = engine.rounds(2);
    final later = [...roster, const RosterPlayer('late')];
    final rest = engine.rounds(2, from: 3, active: later);
    expect(first.last.number, 2);
    expect(rest.first.number, 3);
    final everyone = rest
        .expand((r) => [...r.matches.expand((m) => m.players), ...r.byes])
        .toSet();
    expect(everyone, contains('late'));
  });
}
