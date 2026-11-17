/// Step tracking (owner, 17 Nov 2026; `docs/features/fitness-steps-design.md`).
///
/// Steps come from the phone's health store and stay on the phone. Nothing
/// here earns points or makes a health claim (R-FIT-3, R-FIT-4).
library;

/// The daily goal until the player picks their own. The owner has not
/// confirmed this number (Q276); there is no client reader for `app_settings`
/// yet, so it is a constant for now.
const defaultStepGoal = 10000;
const minStepGoal = 1000;
const maxStepGoal = 50000;
const stepGoalStep = 500;

/// A goal inside the allowed range, in steps of [stepGoalStep].
int clampStepGoal(int goal) {
  final stepped = (goal / stepGoalStep).round() * stepGoalStep;
  return stepped.clamp(minStepGoal, maxStepGoal);
}

/// The steps taken on one local day. [day] is that day at midnight.
class StepsDay {
  const StepsDay(this.day, this.steps);

  final DateTime day;
  final int steps;
}

/// What the app may read.
enum StepsAccess {
  /// The player has not been asked yet.
  notAsked,

  /// Allowed. On iPhone the app cannot tell a refusal from "no steps", so
  /// once asked it is treated as allowed.
  allowed,

  /// Refused (Android's Health Connect says so).
  denied,

  /// No health store on this phone.
  unavailable,
}

/// Where steps are read from. Tests and demo mode use a fake.
abstract interface class StepSource {
  Future<StepsAccess> access();

  /// Asks the player, once, and says what they answered.
  Future<StepsAccess> request();

  /// One entry per local day from [from] to [to], both included, oldest
  /// first. A day with no steps is 0.
  Future<List<StepsDay>> days(DateTime from, DateTime to);

  /// The steps in each hour of [day]: 24 numbers.
  Future<List<int>> hours(DateTime day);

  /// Opens the phone's settings, so a refusal can be undone.
  Future<void> openSettings();
}

/// The three ranges on the Steps screen.
enum StepsRange {
  day('Day'),
  week('Week'),
  month('Month');

  const StepsRange(this.label);
  final String label;
}

/// The last 30 days of steps and the goal, with the numbers the screens show.
class StepsSummary {
  const StepsSummary({
    required this.days,
    required this.goal,
    required this.asOf,
  });

  /// The last 30 local days, oldest first, the last one today.
  final List<StepsDay> days;
  final int goal;

  /// When the numbers were read.
  final DateTime asOf;

  int get today => days.isEmpty ? 0 : days.last.steps;

  /// 0 to 1, for the ring; a full ring from the goal on.
  double get progress =>
      goal <= 0 ? 0 : (today / goal).clamp(0.0, 1.0).toDouble();

  /// 0 to 100, shown inside the ring.
  int get percent => (progress * 100).floor();

  bool get reached => goal > 0 && today >= goal;

  /// Today has no steps yet (or none were read).
  bool get none => today == 0;

  /// The days in [range]: the last 7 for a week, all 30 for a month.
  List<StepsDay> inRange(StepsRange range) => switch (range) {
    StepsRange.day => days.isEmpty ? const [] : [days.last],
    StepsRange.week => days.length <= 7 ? days : days.sublist(days.length - 7),
    StepsRange.month => days,
  };

  /// The average of the days in [range] that have steps. A day with none is
  /// not counted: a phone left at home would pull the average down.
  int average(StepsRange range) {
    final counted = inRange(range).where((d) => d.steps > 0).toList();
    if (counted.isEmpty) return 0;
    final total = counted.fold<int>(0, (a, d) => a + d.steps);
    return (total / counted.length).round();
  }

  /// The day with the most steps in [range], or null when there are none.
  StepsDay? best(StepsRange range) {
    StepsDay? best;
    for (final d in inRange(range)) {
      if (d.steps > 0 && (best == null || d.steps > best.steps)) best = d;
    }
    return best;
  }
}
