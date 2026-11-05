/// One entry in the exercise catalogue.
class CatalogExercise {
  const CatalogExercise({
    required this.id,
    required this.name,
    required this.mark,
    required this.group,
    required this.equipment,
    this.muscles = const [],
    this.steps = const [],
    this.tip = '',
    this.safety = '',
    this.timed = false,
    this.weighted = false,
  });

  factory CatalogExercise.fromJson(Map<String, dynamic> r) => CatalogExercise(
    id: r['id'] as String,
    name: r['name'] as String,
    mark: r['mark'] as String,
    group: r['muscle_group'] as String,
    equipment: r['equipment'] as String,
    muscles: [...(r['muscles'] as List).cast<String>()],
    steps: [...(r['steps'] as List).cast<String>()],
    tip: r['tip'] as String? ?? '',
    safety: r['safety'] as String? ?? '',
    timed: r['unit'] == 'seconds',
    weighted: r['weighted'] as bool? ?? false,
  );

  final String id;
  final String name;

  /// The two letters on its tile.
  final String mark;

  /// `legs`, `core` or `upper`.
  final String group;
  final String equipment;
  final List<String> muscles;
  final List<String> steps;
  final String tip;
  final String safety;

  /// Logged in seconds, not reps.
  final bool timed;
  final bool weighted;

  String get sub => '${muscles.join(', ')} · ${equipment.toLowerCase()}';
}

/// One exercise on a program's day.
class ProgramItem {
  const ProgramItem({
    required this.exerciseId,
    required this.exercise,
    required this.mark,
    required this.sets,
    this.timed = false,
    this.weighted = false,
    this.reps,
    this.seconds,
    this.weightG,
    this.restSeconds = 60,
  });

  factory ProgramItem.of(CatalogExercise e) => ProgramItem(
    exerciseId: e.id,
    exercise: e.name,
    mark: e.mark,
    sets: 3,
    timed: e.timed,
    weighted: e.weighted,
    reps: e.timed ? null : 10,
    seconds: e.timed ? 30 : null,
  );

  factory ProgramItem.fromJson(Map<String, dynamic> r) => ProgramItem(
    exerciseId: r['exercise_id'] as String,
    exercise: r['exercise'] as String,
    mark: r['mark'] as String,
    sets: r['sets'] as int,
    timed: r['unit'] == 'seconds',
    weighted: r['weighted'] as bool? ?? false,
    reps: r['reps'] as int?,
    seconds: r['seconds'] as int?,
    weightG: r['weight_g'] as int?,
    restSeconds: r['rest_seconds'] as int? ?? 60,
  );

  final String exerciseId;
  final String exercise;
  final String mark;
  final int sets;
  final bool timed;
  final bool weighted;
  final int? reps;
  final int? seconds;

  /// Whole grams, so 72.5 kg never drifts.
  final int? weightG;
  final int restSeconds;

  ProgramItem change({
    int? sets,
    int? reps,
    int? seconds,
    int? weightG,
    bool noWeight = false,
    int? restSeconds,
  }) => ProgramItem(
    exerciseId: exerciseId,
    exercise: exercise,
    mark: mark,
    sets: sets ?? this.sets,
    timed: timed,
    weighted: weighted,
    reps: reps ?? this.reps,
    seconds: seconds ?? this.seconds,
    weightG: noWeight ? null : (weightG ?? this.weightG),
    restSeconds: restSeconds ?? this.restSeconds,
  );

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'exercise': exercise,
    'mark': mark,
    'unit': timed ? 'seconds' : 'reps',
    'weighted': weighted,
    'sets': sets,
    'reps': reps,
    'seconds': seconds,
    'weight_g': weightG,
    'rest_seconds': restSeconds,
  };
}

class ProgramDay {
  const ProgramDay({this.name = '', this.items = const []});

  factory ProgramDay.fromJson(Map<String, dynamic> r) => ProgramDay(
    name: r['name'] as String? ?? '',
    items: [
      for (final i in r['items'] as List)
        ProgramItem.fromJson(i as Map<String, dynamic>),
    ],
  );

  final String name;
  final List<ProgramItem> items;

  Map<String, dynamic> toJson() => {
    'name': name,
    'items': [for (final i in items) i.toJson()],
  };
}

/// A player's own program, or a template that no one owns.
class WorkoutProgram {
  const WorkoutProgram({
    required this.id,
    required this.name,
    required this.days,
    this.template = false,
    this.source = 'player',
  });

  factory WorkoutProgram.fromJson(Map<String, dynamic> r) => WorkoutProgram(
    id: r['id'] as String,
    name: r['name'] as String,
    template: r['template'] as bool? ?? false,
    source: r['source'] as String? ?? 'player',
    days: [
      for (final d in r['days'] as List)
        ProgramDay.fromJson(d as Map<String, dynamic>),
    ],
  );

  final String id;
  final String name;
  final bool template;

  /// `player`, or `ai` when AI wrote the first draft.
  final String source;
  final List<ProgramDay> days;

  bool get fromAi => source == 'ai';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'days': [for (final d in days) d.toJson()],
  };
}

/// One finished set.
class LoggedSet {
  const LoggedSet({
    required this.exerciseId,
    this.reps,
    this.seconds,
    this.weightG,
  });

  factory LoggedSet.fromJson(Map<String, dynamic> r) => LoggedSet(
    exerciseId: r['exercise_id'] as String,
    reps: r['reps'] as int?,
    seconds: r['seconds'] as int?,
    weightG: r['weight_g'] as int?,
  );

  final String exerciseId;
  final int? reps;
  final int? seconds;
  final int? weightG;

  Map<String, dynamic> toJson() => {
    'exercise_id': exerciseId,
    'reps': reps,
    'seconds': seconds,
    'weight_g': weightG,
  };
}

/// The workout in progress, kept on the phone until it saves.
class ActiveWorkout {
  const ActiveWorkout({
    required this.key,
    required this.name,
    required this.startedAt,
    required this.plan,
    this.programId,
    this.done = const [],
    this.item = 0,
    this.setsDone = 0,
    this.lastSetAt,
    this.endedAt,
  });

  factory ActiveWorkout.fromJson(Map<String, dynamic> r) => ActiveWorkout(
    key: r['key'] as String,
    name: r['name'] as String,
    startedAt: DateTime.parse(r['started_at'] as String),
    programId: r['program_id'] as String?,
    plan: [
      for (final i in r['plan'] as List)
        ProgramItem.fromJson(i as Map<String, dynamic>),
    ],
    done: [
      for (final s in r['done'] as List)
        LoggedSet.fromJson(s as Map<String, dynamic>),
    ],
    item: r['item'] as int,
    setsDone: r['sets_done'] as int,
    lastSetAt: r['last_set_at'] == null
        ? null
        : DateTime.parse(r['last_set_at'] as String),
    endedAt: r['ended_at'] == null
        ? null
        : DateTime.parse(r['ended_at'] as String),
  );

  /// Made once, so a retry can't save this workout twice.
  final String key;
  final String name;
  final DateTime startedAt;
  final String? programId;
  final List<ProgramItem> plan;
  final List<LoggedSet> done;

  /// Which item in [plan] is under way.
  final int item;

  /// Sets finished on that item.
  final int setsDone;

  final DateTime? lastSetAt;

  /// Set once the player finishes. Saving may still be waiting on a signal.
  final DateTime? endedAt;

  /// The server refuses a workout longer than this.
  static const longest = Duration(hours: 12);

  bool get finished => endedAt != null;

  /// Every planned set has been done.
  bool get complete => item >= plan.length;

  ProgramItem? get current => complete ? null : plan[item];

  ProgramItem? get next => item + 1 < plan.length ? plan[item + 1] : null;

  ActiveWorkout _with({
    List<ProgramItem>? plan,
    List<LoggedSet>? done,
    int? item,
    int? setsDone,
    DateTime? lastSetAt,
    DateTime? endedAt,
  }) => ActiveWorkout(
    key: key,
    name: name,
    startedAt: startedAt,
    programId: programId,
    plan: plan ?? this.plan,
    done: done ?? this.done,
    item: item ?? this.item,
    setsDone: setsDone ?? this.setsDone,
    lastSetAt: lastSetAt ?? this.lastSetAt,
    endedAt: endedAt ?? this.endedAt,
  );

  ActiveWorkout logged(LoggedSet set, DateTime at) {
    final moved = setsDone + 1 >= plan[item].sets;
    return _with(
      done: [...done, set],
      item: moved ? item + 1 : item,
      setsDone: moved ? 0 : setsDone + 1,
      lastSetAt: at,
    );
  }

  /// A changed weight or rep count for the rest of the current exercise.
  ActiveWorkout adjusted(ProgramItem changed) =>
      _with(plan: [...plan]..[item] = changed);

  /// Finishes at [at]. A workout left open too long ends at its last set, and
  /// a clock moved backwards ends at its start, so the end is never out of
  /// order. The server still refuses an end in the future, until that time
  /// has passed.
  ActiveWorkout ended(DateTime at) {
    final limit = startedAt.add(longest);
    final end = at.isAfter(limit) ? (lastSetAt ?? limit) : at;
    if (end.isBefore(startedAt)) return _with(endedAt: startedAt);
    return _with(endedAt: end.isAfter(limit) ? limit : end);
  }

  Map<String, dynamic> toJson() => {
    'key': key,
    'name': name,
    'started_at': startedAt.toUtc().toIso8601String(),
    'program_id': programId,
    'plan': [for (final i in plan) i.toJson()],
    'done': [for (final s in done) s.toJson()],
    'item': item,
    'sets_done': setsDone,
    'last_set_at': lastSetAt?.toUtc().toIso8601String(),
    'ended_at': endedAt?.toUtc().toIso8601String(),
  };

  /// What the server stores.
  Map<String, dynamic> toSave() => {
    'name': name,
    'program_id': programId,
    'started_at': startedAt.toUtc().toIso8601String(),
    'ended_at': (endedAt ?? DateTime.now()).toUtc().toIso8601String(),
    'sets': [for (final s in done) s.toJson()],
  };
}

/// What a player can do with AI plans today.
class AiStatus {
  const AiStatus({this.open = false, this.agreed = false, this.left = 0});

  factory AiStatus.fromJson(Map<String, dynamic> r) => AiStatus(
    open: r['open'] as bool? ?? false,
    agreed: r['agreed'] as bool? ?? false,
    left: (r['left'] as num?)?.toInt() ?? 0,
  );

  /// Off for under-18s and until AI plans are switched on.
  final bool open;
  final bool agreed;
  final int left;
}

/// The goals a plan can have, as the server's key and the screen's words.
const aiGoals = [
  ('speed', 'Move faster on court'),
  ('strength', 'Get stronger'),
  ('mobility', 'Keep mobile'),
  ('general', 'All-round fitness'),
];

/// A saved workout, as the log lists it.
class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.name,
    required this.startedAt,
    required this.seconds,
    required this.exercises,
    required this.liftedG,
  });

  factory WorkoutEntry.fromJson(Map<String, dynamic> r) => WorkoutEntry(
    id: r['id'] as String,
    name: r['name'] as String,
    startedAt: DateTime.parse(r['started_at'] as String).toLocal(),
    seconds: (r['seconds'] as num).toInt(),
    exercises: (r['exercises'] as num).toInt(),
    liftedG: (r['lifted_g'] as num).toInt(),
  );

  final String id;
  final String name;
  final DateTime startedAt;
  final int seconds;
  final int exercises;
  final int liftedG;
}

class PersonalBest {
  const PersonalBest({
    required this.exercise,
    required this.at,
    this.exerciseId = '',
    this.reps,
    this.seconds,
    this.weightG,
  });

  factory PersonalBest.fromJson(Map<String, dynamic> r) => PersonalBest(
    exerciseId: r['exercise_id'] as String? ?? '',
    exercise: r['exercise'] as String? ?? '',
    at: DateTime.parse(r['at'] as String).toLocal(),
    reps: r['reps'] as int?,
    seconds: r['seconds'] as int?,
    weightG: r['weight_g'] as int?,
  );

  final String exerciseId;
  final String exercise;
  final DateTime at;
  final int? reps;
  final int? seconds;
  final int? weightG;
}

class WorkoutSummary {
  const WorkoutSummary({
    this.minor = true,
    this.workouts = 0,
    this.seconds = 0,
    this.liftedG = 0,
    this.workouts30d = 0,
    this.weekStreak = 0,
    this.liftedWeekG = 0,
    this.recent = const [],
    this.bests = const [],
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> r) => WorkoutSummary(
    minor: r['minor'] as bool? ?? true,
    workouts: (r['workouts'] as num).toInt(),
    seconds: (r['seconds'] as num).toInt(),
    liftedG: (r['lifted_g'] as num).toInt(),
    workouts30d: (r['workouts_30d'] as num).toInt(),
    weekStreak: (r['week_streak'] as num).toInt(),
    liftedWeekG: (r['lifted_week_g'] as num).toInt(),
    recent: [
      for (final w in r['recent'] as List)
        WorkoutEntry.fromJson(w as Map<String, dynamic>),
    ],
    bests: [
      for (final b in r['bests'] as List)
        PersonalBest.fromJson(b as Map<String, dynamic>),
    ],
  );

  /// Treated as a minor until the server says otherwise.
  final bool minor;
  final int workouts;
  final int seconds;
  final int liftedG;
  final int workouts30d;
  final int weekStreak;
  final int liftedWeekG;
  final List<WorkoutEntry> recent;
  final List<PersonalBest> bests;
}

class ExerciseHistory {
  const ExerciseHistory({this.times = 0, this.best, this.recent = const []});

  factory ExerciseHistory.fromJson(Map<String, dynamic> r) => ExerciseHistory(
    times: (r['times'] as num).toInt(),
    best: r['best'] == null
        ? null
        : PersonalBest.fromJson(r['best'] as Map<String, dynamic>),
    recent: [
      for (final s in r['recent'] as List)
        PersonalBest.fromJson(s as Map<String, dynamic>),
    ],
  );

  final int times;
  final PersonalBest? best;
  final List<PersonalBest> recent;
}
