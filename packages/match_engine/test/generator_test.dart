import 'dart:math';

import 'package:match_engine/match_engine.dart';
import 'package:flutter_test/flutter_test.dart';

List<RosterPlayer> _roster(Random r, int n, {bool mixed = false}) => [
  for (var i = 0; i < n; i++)
    RosterPlayer(
      'p$i',
      skill: 1 + r.nextInt(8).toDouble(),
      gender: mixed ? (i.isEven ? 'm' : 'f') : null,
    ),
];

void _checkRound(Round round, int courts, List<RosterPlayer> roster) {
  final seen = <String>{};
  for (final m in round.matches) {
    for (final p in m.players) {
      expect(seen.add(p), isTrue, reason: '$p plays twice in a round');
    }
  }
  expect(round.matches.length, lessThanOrEqualTo(courts));
  final courtsUsed = {for (final m in round.matches) m.court};
  expect(courtsUsed.length, round.matches.length);
  expect(courtsUsed.every((c) => c >= 1 && c <= courts), isTrue);
  for (final p in roster) {
    expect(seen.contains(p.id) || round.byes.contains(p.id), isTrue);
  }
}

void main() {
  test('P3-02 Americano holds over 1,000 random rosters', () {
    final r = Random(7);
    for (var run = 0; run < 1000; run++) {
      final n = 4 + r.nextInt(21);
      final courts = 1 + r.nextInt(6);
      final roster = _roster(r, n);
      final draw = Americano(roster: roster, courts: courts, seed: run);
      final rounds = draw.rounds(6);
      final sitOuts = <String, int>{};
      for (final round in rounds) {
        _checkRound(round, courts, roster);
        expect(round.matches.length, min(courts, n ~/ 4));
        for (final b in round.byes) {
          sitOuts.update(b, (v) => v + 1, ifAbsent: () => 1);
        }
      }
      // Byes go round: nobody sits out twice before everyone has once.
      final counts = [for (final p in roster) sitOuts[p.id] ?? 0];
      expect(counts.reduce(max) - counts.reduce(min), lessThanOrEqualTo(1));
    }
  });

  test('P3-02 partner repeats stay low', () {
    final r = Random(11);
    final roster = _roster(r, 12);
    final rounds = Americano(roster: roster, courts: 3, seed: 1).rounds(5);
    final pairs = <String, int>{};
    for (final round in rounds) {
      for (final m in round.matches) {
        for (final side in [m.sideA, m.sideB]) {
          final k = ([...side]..sort()).join('+');
          pairs.update(k, (v) => v + 1, ifAbsent: () => 1);
        }
      }
    }
    expect(pairs.values.reduce(max), lessThanOrEqualTo(2));
  });

  test('P3-02 mixed pairs honour the gender split over 1,000 rosters', () {
    final r = Random(3);
    for (var run = 0; run < 1000; run++) {
      final n = 4 + 2 * r.nextInt(10);
      final courts = 1 + r.nextInt(4);
      final roster = _roster(r, n, mixed: true);
      final byId = {for (final p in roster) p.id: p};
      final rounds = Americano(
        roster: roster,
        courts: courts,
        seed: run,
        mixed: true,
      ).rounds(4);
      for (final round in rounds) {
        _checkRound(round, courts, roster);
        for (final m in round.matches) {
          for (final side in [m.sideA, m.sideB]) {
            expect({for (final id in side) byId[id]!.gender}, {'m', 'f'});
          }
        }
      }
    }
  });

  test('P3-02 the same seed gives the same draw', () {
    final roster = _roster(Random(1), 10);
    String draw() => Americano(roster: roster, courts: 2, seed: 5)
        .rounds(3)
        .map((r) => r.matches.map((m) => m.players.join(',')).join(';'))
        .join('|');
    expect(draw(), draw());
  });

  test('P3-02 regenerating handles a late arrival and an early leaver', () {
    final roster = _roster(Random(2), 8);
    final draw = Americano(roster: roster, courts: 2, seed: 9);
    draw.rounds(2);
    final now = [...roster.skip(1), const RosterPlayer('late')];
    final next = draw.rounds(2, from: 3, active: now);
    expect(next.first.number, 3);
    for (final round in next) {
      _checkRound(round, 2, now);
      expect(round.matches.any((m) => m.players.contains('p0')), isFalse);
    }
  });

  test('P3-02 fixed teams meet every other team once', () {
    for (var n = 2; n <= 12; n++) {
      final teams = [for (var i = 0; i < n; i++) 't$i'];
      final met = <String>{};
      for (final round in circleRounds(teams, courts: 2)) {
        final seen = <String>{};
        for (final m in round.matches) {
          for (final p in m.players) {
            expect(seen.add(p), isTrue);
          }
          expect(met.add(([...m.players]..sort()).join('-')), isTrue);
        }
        expect(round.matches.length, lessThanOrEqualTo(2));
      }
      expect(met.length, n * (n - 1) ~/ 2);
    }
  });
}
