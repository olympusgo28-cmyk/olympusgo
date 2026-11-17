import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/play/domain/meet_ops.dart';

/// Badminton games end at 21 with 2 clear, run on to a 2-point lead from
/// 20 all, and stop at 30.
void main() {
  test('finished games', () {
    expect(gameWinner(21, 15), 1);
    expect(gameWinner(19, 21), 2);
    expect(gameWinner(22, 20), 1);
    expect(gameWinner(30, 29), 1);
    expect(gameWinner(28, 30), 2);
  });

  test('scores that cannot end a game', () {
    expect(gameWinner(21, 20), -1);
    expect(gameWinner(18, 15), -1);
    expect(gameWinner(25, 10), -1);
    expect(gameWinner(31, 29), -1);
    expect(gameWinner(21, null), 0);
  });

  test('a match is decided by 2 games, with game 3 only after a split', () {
    expect(matchDecided([(21, 15), (21, 18)]), isTrue);
    expect(matchDecided([(21, 15), (21, 18), (null, null)]), isTrue);
    expect(matchDecided([(21, 15), (18, 21)]), isFalse);
    expect(matchDecided([(21, 15), (18, 21), (21, 17)]), isTrue);
    expect(matchDecided([(21, 15), (21, 18), (21, 17)]), isFalse);
    expect(matchDecided([(21, 15), (21, 20)]), isFalse);
  });

  test('pickleball games end at 11 with 2 clear', () {
    const p = ScoringPreset.pickleball;
    expect(gameWinner(11, 5, p), 1);
    expect(gameWinner(10, 12, p), 2);
    expect(gameWinner(11, 10, p), -1);
    expect(matchDecided([(11, 5), (11, 7)], p), isTrue);
  });

  test('junior badminton is 15 points, capped at 21', () {
    final p = ScoringPreset.fromJson({
      'points_to_win': 15,
      'win_by': 2,
      'cap': 21,
      'best_of': 3,
    });
    expect(gameWinner(15, 9, p), 1);
    expect(gameWinner(21, 20, p), 1);
    expect(gameWinner(15, 14, p), -1);
    expect(scoringHint(p), 'A game is won at 15 with 2 clear, or at 21.');
  });

  test('a format with no rules only refuses a level game', () {
    final p = ScoringPreset.fromJson(const {});
    expect(gameWinner(7, 3, p), 1);
    expect(gameWinner(5, 5, p), -1);
    expect(scoringHint(p), "A game can't end level.");
  });

  test('a score key is a version 4 id and differs each time', () {
    expect(
      newClientKey(),
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(newClientKey(), isNot(newClientKey()));
  });
}
