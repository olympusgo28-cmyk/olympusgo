/// Progression suggestions on the workout screen (owner, 17 Nov 2026; Q277
/// slice 3; R-FIT-11).
///
/// A suggestion is words and, sometimes, one number the player can take with
/// a tap. It is never applied by itself, it earns nothing (R-FIT-4), and it
/// makes no health claim (R-FIT-3). Under-18s get none: the server sends them
/// no numbers.
library;

import 'fitness_calc.dart';
import 'fitness_models.dart';

/// The most the database takes for a set.
const _maxWeightG = 500000;
const _maxReps = 200;
const _maxSeconds = 3600;

/// How many sets the history holds at most. With that many, the oldest
/// session in it may be cut short.
const _historySets = 30;

/// What the workout screen suggests for the exercise under way.
class Suggestion {
  const Suggestion(this.text, {this.weightG, this.reps, this.seconds});

  /// "Try 72.5 kg. You hit 5 reps on every set last time."
  final String text;

  /// The one number "Use" would set. All null when there is nothing to
  /// change ("Stay at 70 kg.").
  final int? weightG;
  final int? reps;
  final int? seconds;

  bool get usable => weightG != null || reps != null || seconds != null;
}

/// The sessions in [history], newest first, each with its sets in the order
/// done. A session that may be cut short by the history's limit is left out.
List<List<PersonalBest>> _sessions(ExerciseHistory history) {
  final out = <List<PersonalBest>>[];
  for (final set in history.recent) {
    if (out.isEmpty || out.last.first.at != set.at) {
      out.add([set]);
    } else {
      out.last.add(set);
    }
  }
  if (history.recent.length >= _historySets && out.isNotEmpty) out.removeLast();
  return [for (final s in out) s.reversed.toList()];
}

bool _hasWeight(int? g) => g != null && g > 0;

/// The suggestion for [item] from [history], or null when there is none: no
/// numbers from the server (an under-18, or config that can't be read), a
/// first time, or a last session that can't be judged fairly against what is
/// planned now.
///
/// The history holds what was done, not what was planned, so the last
/// session is measured against this workout's plan: it must have at least as
/// many sets as planned, all at one weight, and that weight must be the one
/// planned now.
Suggestion? suggestNext(ProgramItem item, ExerciseHistory history) {
  final rules = history.progress;
  if (rules == null || item.sets < 1) return null;
  final sessions = _sessions(history);
  if (sessions.isEmpty) return null;
  final last = sessions.first;
  if (last.length < item.sets) return null;

  if (item.timed) {
    // A timed exercise that also carries weight (a carry) could go up in
    // time or in load. Which is the owner's to decide (Q277 s): until then
    // it gets no suggestion.
    if (item.weighted) return null;
    final planned = item.seconds;
    if (planned == null || planned < 1) return null;
    if (last.any((s) => s.seconds == null)) return null;
    if (last.any((s) => s.seconds! < planned)) return null;
    if (rules.secondsStep < 1 || rules.secondsCap < 1) return null;
    final next = _capped(planned + rules.secondsStep, rules.secondsCap);
    if (next <= planned || next > _maxSeconds) return null;
    return Suggestion(
      'Try $next seconds. You held $planned on every set last time.',
      seconds: next,
    );
  }

  final planned = item.reps;
  if (planned == null || planned < 1) return null;
  if (last.any((s) => s.reps == null)) return null;

  final weight = item.weighted ? item.weightG : null;
  if (!_hasWeight(weight)) {
    // No weight planned: judged on reps, and only against a session that
    // carried no weight either.
    if (last.any((s) => _hasWeight(s.weightG))) return null;
    if (last.any((s) => s.reps! < planned)) return null;
    if (rules.repStep < 1 || rules.repCap < 1) return null;
    final next = _capped(planned + rules.repStep, rules.repCap);
    if (next <= planned || next > _maxReps) return null;
    return Suggestion(
      'Try $next reps. You hit $planned on every set last time.',
      reps: next,
    );
  }

  bool judged(List<PersonalBest> session) =>
      session.length >= item.sets &&
      session.every((s) => s.weightG == weight && s.reps != null);
  bool missed(List<PersonalBest> session) =>
      session.any((s) => s.reps! < planned);
  // The history does not store what was planned then. A session where no set
  // reached today's reps may have been done to a lower target that was met,
  // so it is no proof of a miss (Q277 r).
  bool aimedHere(List<PersonalBest> session) =>
      session.any((s) => s.reps! >= planned);

  if (!judged(last)) return null;
  if (rules.stepG < 1) return null;
  final kg = kgText(weight!);

  if (!missed(last)) {
    final next = weight + rules.stepG;
    if (next > _maxWeightG) return null;
    return Suggestion(
      'Try ${kgText(next)} kg. You hit $planned reps on every set last time.',
      weightG: next,
    );
  }

  // Missed on some set. If no set reached today's reps, the reps planned may
  // simply have been raised since: say nothing.
  if (!aimedHere(last)) return null;

  // Count the sessions in a row, newest first, at this weight that aimed at
  // these reps and missed.
  var inARow = 0;
  for (final s in sessions) {
    if (!judged(s) || !missed(s) || !aimedHere(s)) break;
    inARow++;
  }
  final stall = rules.stallSessions;
  final pct = rules.deloadPct;
  if (stall >= 1 && inARow >= stall && pct >= 1 && pct <= 99) {
    // Whole grams, rounded down to the step.
    final less = (weight * (100 - pct)) ~/ 100 ~/ rules.stepG * rules.stepG;
    if (less > 0 && less < weight) {
      final sessionsText = stall == 1 ? '1 session' : '$stall sessions';
      return Suggestion(
        'Try ${kgText(less)} kg. $sessionsText without hitting your reps.',
        weightG: less,
      );
    }
  }
  return Suggestion('Stay at $kg kg. You missed reps on a set last time.');
}

/// [value], but never past [cap].
int _capped(int value, int cap) => value > cap ? cap : value;
