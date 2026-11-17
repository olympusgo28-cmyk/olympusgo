import 'package:flutter_test/flutter_test.dart';
import 'package:olympus_go/features/fitness/domain/fitness_calc.dart';
import 'package:olympus_go/features/fitness/domain/fitness_models.dart';

final _at = DateTime.utc(2026, 11, 1, 9);

void main() {
  test('weights are whole grams and read back exactly', () {
    expect(gramsFrom('70'), 70000);
    expect(gramsFrom('72.5'), 72500);
    expect(gramsFrom('1.25'), 1250);
    expect(gramsFrom('0.1'), 100);
    expect(gramsFrom('abc'), isNull);
    expect(gramsFrom('-5'), isNull);
    expect(gramsFrom('1.2345'), isNull);
    expect(kgText(70000), '70');
    expect(kgText(72500), '72.5');
    expect(kgText(1250), '1.25');
    expect(kgText(100), '0.1');
  });

  test('totals read as the screens show them', () {
    expect(liftedText(8400000), '8.4 t');
    expect(liftedText(450000), '450 kg');
    expect(liftedText(999999), '1000 kg');
    expect(timeText(2760), '46 min');
    expect(timeText(30000), '8 h 20');
    expect(clockText(120), '2:00');
    expect(clockText(90), '1:30');
  });

  test('one-rep max matches the board', () {
    final est = oneRepMaxG(70000, 5)!;
    expect((est + 500) ~/ 1000, 79);
    expect((est * 8 + 5000) ~/ 10000, 63);
  });

  test('one-rep max refuses what it can\'t estimate', () {
    expect(oneRepMaxG(0, 5), isNull);
    expect(oneRepMaxG(70000, 0), isNull);
    expect(oneRepMaxG(70000, 13), isNull);
    expect(oneRepMaxG(70000, 1), 70000);
  });

  test('plates match the board', () {
    final p = platesPerSide(70000, 20000);
    expect(p.plates, [20000, 5000]);
    expect(p.left, 0);
  });

  test('plates say when no plate fits, and handle a bare bar', () {
    expect(platesPerSide(20000, 20000).plates, isEmpty);
    expect(platesPerSide(21000, 20000).left, 500);
    expect(platesPerSide(10000, 20000).plates, isEmpty);
  });

  test('body mass index matches the board, with no verdict', () {
    expect(bmiText(172, 68000), '23.0');
    expect(bmiText(50, 68000), isNull);
    expect(bmiText(172, 1000), isNull);
  });

  test('lines read as the board shows them', () {
    const item = ProgramItem(
      exerciseId: 'x',
      exercise: 'Back squat',
      mark: 'SQ',
      sets: 4,
      reps: 5,
      weightG: 70000,
      restSeconds: 120,
      weighted: true,
    );
    expect(itemLine(item), '4 sets × 5 · 70 kg · rest 2:00');
    expect(
      itemLine(
        const ProgramItem(
          exerciseId: 'p',
          exercise: 'Plank',
          mark: 'PL',
          sets: 3,
          seconds: 45,
          timed: true,
        ),
      ),
      '3 sets × 45 seconds · rest 1:00',
    );
    expect(bestText(reps: 5, weightG: 70000), '70 kg × 5');
    expect(bestText(reps: 8), '8 reps');
    expect(bestText(seconds: 45), '45 seconds');
  });

  test('a workout moves through its sets, then its exercises', () {
    const item = ProgramItem(
      exerciseId: 'a',
      exercise: 'A',
      mark: 'AA',
      sets: 2,
      reps: 5,
    );
    var w = ActiveWorkout(
      key: 'k',
      name: 'Legs',
      startedAt: DateTime(2026),
      plan: const [item, item],
    );
    const set = LoggedSet(exerciseId: 'a', reps: 5);
    w = w.logged(set, _at);
    expect((w.item, w.setsDone), (0, 1));
    w = w.logged(set, _at);
    expect((w.item, w.setsDone), (1, 0));
    w = w.logged(set, _at).logged(set, _at);
    expect(w.complete, isTrue);
    expect(w.done, hasLength(4));
  });

  test('a workout survives the trip to storage', () {
    final w = ActiveWorkout(
      key: 'k',
      name: 'Legs',
      startedAt: DateTime.utc(2026, 11, 1, 8),
      programId: 'p',
      plan: const [
        ProgramItem(
          exerciseId: 'a',
          exercise: 'A',
          mark: 'AA',
          sets: 2,
          reps: 5,
          weightG: 72500,
          weighted: true,
        ),
      ],
    ).logged(const LoggedSet(exerciseId: 'a', reps: 5, weightG: 72500), _at);
    final back = ActiveWorkout.fromJson(w.toJson());
    expect(back.key, 'k');
    expect(back.setsDone, 1);
    expect(back.done.single.weightG, 72500);
    expect(back.plan.single.weightG, 72500);
    expect(back.plan.single.weighted, isTrue);
    expect(back.finished, isFalse);
    expect(back.lastSetAt, _at);
  });

  test('a workout left open overnight ends at its last set', () {
    const set = LoggedSet(exerciseId: 'a', reps: 5);
    const item = ProgramItem(
      exerciseId: 'a',
      exercise: 'A',
      mark: 'AA',
      sets: 3,
      reps: 5,
    );
    final start = DateTime.utc(2026, 11, 1, 8);
    final w = ActiveWorkout(
      key: 'k',
      name: 'Legs',
      startedAt: start,
      plan: const [item],
    ).logged(set, start.add(const Duration(minutes: 40)));
    final next = start.add(const Duration(days: 1));
    expect(w.ended(next).endedAt, start.add(const Duration(minutes: 40)));

    final soon = start.add(const Duration(hours: 1));
    expect(w.ended(soon).endedAt, soon);

    final empty = ActiveWorkout(
      key: 'k',
      name: 'Legs',
      startedAt: start,
      plan: const [item],
    );
    expect(empty.ended(next).endedAt, start.add(ActiveWorkout.longest));

    final earlier = start.subtract(const Duration(hours: 1));
    expect(w.ended(earlier).endedAt, start);
  });

  test('a change to the weight stays with the workout', () {
    const item = ProgramItem(
      exerciseId: 'a',
      exercise: 'A',
      mark: 'AA',
      sets: 3,
      reps: 5,
      weightG: 70000,
      weighted: true,
    );
    final w = ActiveWorkout(
      key: 'k',
      name: 'Legs',
      startedAt: DateTime.utc(2026),
      plan: const [item],
    ).adjusted(item.change(weightG: 80000));
    final back = ActiveWorkout.fromJson(w.toJson());
    expect(back.current!.weightG, 80000);
    expect(item.change(noWeight: true).weightG, isNull);
  });
}
