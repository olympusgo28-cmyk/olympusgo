/// Which parts of the body outline each catalogue muscle lights up (owner,
/// 17 Nov 2026; `fitness-training-upgrades-design.md`, section 3).
///
/// The map shows where an exercise works. It says nothing about recovery or
/// about what a player should train (R-FIT-3).
library;

import 'fitness_models.dart';

/// The outline's parts for a muscle, on the front view and the back view.
typedef MuscleRegion = ({List<String> front, List<String> back});

/// Every muscle name the catalogue uses, and its parts of the outline. A
/// test fails if the catalogue gains a name that is not here.
const muscleRegions = <String, MuscleRegion>{
  'Core': (front: ['abs'], back: []),
  'Obliques': (front: ['obliques'], back: []),
  'Chest': (front: ['chest'], back: []),
  'Shoulders': (front: ['deltoids'], back: ['deltoids']),
  'Biceps': (front: ['biceps'], back: []),
  'Triceps': (front: ['triceps'], back: ['triceps']),
  'Forearms': (front: ['forearm'], back: ['forearm']),
  'Back': (front: [], back: ['upper-back', 'rhomboids', 'trapezius']),
  'Lower back': (front: [], back: ['lower-back']),
  'Glutes': (front: [], back: ['gluteal']),
  'Quads': (front: ['quadriceps'], back: []),
  'Inner thighs': (front: ['adductors'], back: ['adductors']),
  'Hamstrings': (front: [], back: ['hamstring']),
  'Calves': (front: ['calves'], back: ['calves']),
};

MuscleRegion? _region(String muscle) {
  final key = muscle.trim().toLowerCase();
  for (final e in muscleRegions.entries) {
    if (e.key.toLowerCase() == key) return e.value;
  }
  return null;
}

/// The front-view parts worked by [muscles]. Names the map does not know are
/// left out.
Set<String> frontParts(Iterable<String> muscles) => {
  for (final m in muscles) ...?_region(m)?.front,
};

/// The back-view parts worked by [muscles].
Set<String> backParts(Iterable<String> muscles) => {
  for (final m in muscles) ...?_region(m)?.back,
};

/// The names in [muscles] the map can show, once each, in the order given.
List<String> knownMuscles(Iterable<String> muscles) {
  final seen = <String>{};
  return [
    for (final m in muscles)
      if (_region(m) != null && seen.add(m.trim().toLowerCase())) m.trim(),
  ];
}

/// The muscles a list of planned exercises works, the most-used first. An
/// exercise missing from [catalogue] adds nothing.
List<String> musclesOf(
  List<ProgramItem> items,
  List<CatalogExercise> catalogue,
) {
  final byId = {for (final e in catalogue) e.id: e};
  final count = <String, int>{};
  final shown = <String, String>{};
  for (final i in items) {
    for (final m in knownMuscles(byId[i.exerciseId]?.muscles ?? const [])) {
      final key = m.toLowerCase();
      count[key] = (count[key] ?? 0) + 1;
      shown.putIfAbsent(key, () => m);
    }
  }
  final keys = count.keys.toList();
  // A stable order: the most exercises first, ties in the order first met.
  final first = {for (var i = 0; i < keys.length; i++) keys[i]: i};
  keys.sort((a, b) {
    final by = count[b]!.compareTo(count[a]!);
    return by != 0 ? by : first[a]!.compareTo(first[b]!);
  });
  return [for (final k in keys) shown[k]!];
}

/// "Quads, glutes and core": the names as one phrase, in sentence case.
String muscleList(List<String> muscles) {
  if (muscles.isEmpty) return '';
  final names = [
    for (var i = 0; i < muscles.length; i++)
      i == 0
          ? muscles[i][0].toUpperCase() + muscles[i].substring(1).toLowerCase()
          : muscles[i].toLowerCase(),
  ];
  if (names.length == 1) return names.single;
  return '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
}
