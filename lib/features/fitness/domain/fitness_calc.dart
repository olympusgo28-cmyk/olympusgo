import 'fitness_models.dart';

/// "70", "72.5", "1.25" from whole grams.
String kgText(int grams) {
  final whole = grams ~/ 1000;
  final rest = grams % 1000;
  if (rest == 0) return '$whole';
  final digits = rest
      .toString()
      .padLeft(3, '0')
      .replaceFirst(RegExp(r'0+$'), '');
  return '$whole.$digits';
}

/// "8.4 t" for a tonne or more, "450 kg" below that.
String liftedText(int grams) {
  if (grams < 1000000) return '${(grams + 500) ~/ 1000} kg';
  final tenths = (grams + 50000) ~/ 100000;
  return '${tenths ~/ 10}.${tenths % 10} t';
}

/// Whole grams from "72.5", without going through a decimal. Null when it
/// isn't a weight.
int? gramsFrom(String text) {
  final m = RegExp(r'^(\d{1,3})(?:\.(\d{1,3}))?$').firstMatch(text.trim());
  if (m == null) return null;
  final part = (m[2] ?? '').padRight(3, '0');
  return int.parse(m[1]!) * 1000 + int.parse(part);
}

/// "2:00" from seconds.
String clockText(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// "8 h 20" or "46 min".
String timeText(int seconds) {
  final minutes = (seconds + 30) ~/ 60;
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${(minutes % 60).toString().padLeft(2, '0')}';
}

/// "4 sets × 5 · 70 kg · rest 2:00".
String itemLine(ProgramItem i) => [
  '${i.sets} ${i.sets == 1 ? 'set' : 'sets'} × '
      '${i.timed ? '${i.seconds} seconds' : '${i.reps}'}',
  if (i.weightG != null && i.weightG! > 0) '${kgText(i.weightG!)} kg',
  'rest ${clockText(i.restSeconds)}',
].join(' · ');

/// "70 kg × 5", "8 reps" or "45 seconds".
String bestText({int? reps, int? seconds, int? weightG}) {
  if (seconds != null) return '$seconds seconds';
  if (weightG != null && weightG > 0) {
    return '${kgText(weightG)} kg × $reps';
  }
  return '$reps reps';
}

/// Roughly how long a day takes, in minutes. Each rep takes about 4 seconds.
int minutesFor(List<ProgramItem> items) {
  var seconds = 0;
  for (final i in items) {
    final work = i.timed ? (i.seconds ?? 0) : (i.reps ?? 0) * 4;
    seconds += i.sets * (work + i.restSeconds);
  }
  return (seconds + 30) ~/ 60;
}

/// The Brzycki estimate, in grams. Null past 12 reps, where it stops being a
/// useful guide.
int? oneRepMaxG(int weightG, int reps) {
  if (weightG <= 0 || reps < 1 || reps > 12) return null;
  return weightG * 36 ~/ (37 - reps);
}

/// Plates for one side of the bar, biggest first, and the grams left over that
/// no plate can make up.
({List<int> plates, int left}) platesPerSide(int targetG, int barG) {
  const sizes = [20000, 15000, 10000, 5000, 2500, 1250];
  var side = (targetG - barG) ~/ 2;
  if (side < 0) return (plates: const [], left: 0);
  final plates = <int>[];
  for (final s in sizes) {
    while (side >= s) {
      plates.add(s);
      side -= s;
    }
  }
  return (plates: plates, left: side);
}

/// Body mass index, to one decimal place. Null when an input isn't sensible.
String? bmiText(int heightCm, int weightG) {
  if (heightCm < 100 || heightCm > 250 || weightG < 20000) return null;
  final square = heightCm * heightCm;
  final tenths = (weightG * 200 + square) ~/ (square * 2);
  return '${tenths ~/ 10}.${tenths % 10}';
}
