import 'package:match_engine/match_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const b = ScoringPreset.badminton;
  const p = ScoringPreset.pickleball;

  group('R-SCO-1 badminton', () {
    test('finished games', () {
      expect(b.gameWinner(21, 15), 1);
      expect(b.gameWinner(19, 21), 2);
      expect(b.gameWinner(22, 20), 1);
      expect(b.gameWinner(30, 29), 1);
      expect(b.gameWinner(30, 28), 1);
      expect(b.gameWinner(28, 30), 2);
    });

    test('scores that cannot end a game', () {
      expect(b.gameWinner(21, 20), -1);
      expect(b.gameWinner(22, 21), -1);
      expect(b.gameWinner(18, 15), -1);
      expect(b.gameWinner(25, 10), -1);
      expect(b.gameWinner(31, 29), -1);
      expect(b.gameWinner(21, 21), -1);
      expect(b.gameWinner(21, null), 0);
    });
  });

  test('P3-01 pickleball games to 11, win by 2', () {
    expect(p.gameWinner(11, 5), 1);
    expect(p.gameWinner(13, 11), 1);
    expect(p.gameWinner(11, 10), -1);
    expect(p.gameWinner(21, 15), -1);
  });

  test('junior badminton, 15 points cap 21', () {
    const j = ScoringPreset(pointsToWin: 15, cap: 21);
    expect(j.gameWinner(15, 10), 1);
    expect(j.gameWinner(21, 20), 1);
    expect(j.gameWinner(15, 14), -1);
  });

  test('a match is decided by 2 games, with game 3 only after a split', () {
    expect(b.matchDecided([(21, 15), (21, 18)]), isTrue);
    expect(b.matchDecided([(21, 15), (21, 18), (null, null)]), isTrue);
    expect(b.matchDecided([(21, 15), (18, 21)]), isFalse);
    expect(b.matchDecided([(21, 15), (18, 21), (21, 17)]), isTrue);
    expect(b.matchDecided([(21, 15), (21, 18), (21, 17)]), isFalse);
    expect(b.matchDecided([(21, 15), (21, 20)]), isFalse);
  });
}
