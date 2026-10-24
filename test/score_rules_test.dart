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
}
