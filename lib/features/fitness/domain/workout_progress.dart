/// What the workout screen says about earlier sessions: last time's sets and
/// a new best (owner, 17 Nov 2026; `fitness-training-upgrades-design.md`).
///
/// A new best is a line of text. It earns nothing (R-FIT-4).
library;

import '../../../core/format.dart';
import 'fitness_calc.dart';
import 'fitness_models.dart';

/// How much "Add 30 seconds" adds to a rest. The owner has not confirmed
/// this number (Q277 b).
const restAddSeconds = 30;

/// The sets of the most recent saved workout with this exercise, in the
/// order they were done.
List<PersonalBest> lastSession(ExerciseHistory history) {
  if (history.recent.isEmpty) return const [];
  final at = history.recent.first.at;
  // The history lists the newest set first.
  return history.recent.takeWhile((s) => s.at == at).toList().reversed.toList();
}

/// "70 kg × 5, 5, 4 · Thu 12 Nov", "10, 10, 8 reps · Thu 12 Nov" or
/// "30, 30, 25 seconds · Thu 12 Nov". Null when there is no earlier session.
String? lastTimeText(ExerciseHistory history) {
  final sets = lastSession(history);
  if (sets.isEmpty) return null;
  final String what;
  if (sets.every((s) => s.seconds != null)) {
    what = '${sets.map((s) => s.seconds).join(', ')} seconds';
  } else if (sets.any((s) => (s.weightG ?? 0) > 0)) {
    // Sets at the same weight share it: "70 kg × 5, 5; 72.5 kg × 4".
    final groups = <String>[];
    int? weight;
    var reps = <int>[];
    void close() {
      if (reps.isEmpty) return;
      groups.add(
        (weight ?? 0) > 0
            ? '${kgText(weight!)} kg × ${reps.join(', ')}'
            : '${reps.join(', ')} reps',
      );
      reps = [];
    }

    for (final s in sets) {
      if (s.weightG != weight) close();
      weight = s.weightG;
      reps.add(s.reps ?? 0);
    }
    close();
    what = groups.join('; ');
  } else {
    what = '${sets.map((s) => s.reps ?? 0).join(', ')} reps';
  }
  return '$what · ${Fmt.day(sets.first.at)}';
}

/// The weight of the last set done last time, to start from when the program
/// plans none. Null when last time carried no weight.
int? lastWeightG(ExerciseHistory history) {
  final sets = lastSession(history);
  if (sets.isEmpty) return null;
  final weight = sets.last.weightG;
  return weight != null && weight > 0 ? weight : null;
}

/// Above zero when the first set is better than the second, the way the
/// database orders a best: weight, then reps, then seconds. No weight and
/// 0 kg are the same and count as the least, so 0 kg never beats a set done
/// with no weight.
int _compare(
  ({int? weightG, int? reps, int? seconds}) a,
  ({int? weightG, int? reps, int? seconds}) b,
) {
  int kg(int? g) => g == null || g <= 0 ? -1 : g;
  final weight = kg(a.weightG).compareTo(kg(b.weightG));
  if (weight != 0) return weight;
  final reps = (a.reps ?? -1).compareTo(b.reps ?? -1);
  if (reps != 0) return reps;
  return (a.seconds ?? -1).compareTo(b.seconds ?? -1);
}

({int? weightG, int? reps, int? seconds}) _of(LoggedSet s) =>
    (weightG: s.weightG, reps: s.reps, seconds: s.seconds);

/// Whether the set at [index] in [done] is a new best for its exercise: it
/// beats the saved best in [history] and every earlier set of that exercise
/// in this workout. A first time has nothing to beat, so it is never one, and
/// neither is an exercise whose history could not be read.
bool isNewBest(List<LoggedSet> done, int index, ExerciseHistory? history) {
  final best = history?.best;
  if (best == null || index < 0 || index >= done.length) return false;
  final set = done[index];
  final saved = (weightG: best.weightG, reps: best.reps, seconds: best.seconds);
  if (_compare(_of(set), saved) <= 0) return false;
  for (var i = 0; i < index; i++) {
    if (done[i].exerciseId != set.exerciseId) continue;
    if (_compare(_of(set), _of(done[i])) <= 0) return false;
  }
  return true;
}

/// The best set of each exercise in this workout that beat its saved best,
/// in the order the exercises were done. One per exercise.
List<LoggedSet> newBests(
  List<LoggedSet> done,
  Map<String, ExerciseHistory> histories,
) {
  final top = <String, LoggedSet>{};
  for (var i = 0; i < done.length; i++) {
    final set = done[i];
    if (isNewBest(done, i, histories[set.exerciseId])) {
      top[set.exerciseId] = set;
    }
  }
  return top.values.toList();
}
